import { readFileSync } from 'node:fs';
import { before, after, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, Timestamp } from 'firebase/firestore';

let env;
const path = 'users/alice/expenses/example';
const record = () => ({title:'Lunch', category:'Food', amountCents:45000, date:Timestamp.now(), note:'', type:'expense'});
const contributionPath = 'users/alice/contributions/example';
const contribution = () => ({title:'Fix documentation', repository:'owner/project', type:'Pull request', date:Timestamp.now(), note:''});
before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run using the Firestore emulator. Never target production.');
  env = await initializeTestEnvironment({projectId:'demo-pocket-security', firestore:{rules:readFileSync(new URL('../firestore.rules',import.meta.url),'utf8')}});
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async c => setDoc(doc(c.firestore(),path),record()));
});
test('owner can read, query, update and delete own transactions', async () => {
  const db=env.authenticatedContext('alice').firestore();
  await assertSucceeds(getDoc(doc(db,path)));
  await assertSucceeds(getDocs(collection(db,'users/alice/expenses')));
  await assertSucceeds(updateDoc(doc(db,path),{amountCents:100}));
  await assertSucceeds(deleteDoc(doc(db,path)));
});
for (const identity of ['unauthenticated','bob']) {
  test(`${identity} cannot read, list, create, modify or delete Alice's data`,async () => {
    const db=(identity==='unauthenticated'?env.unauthenticatedContext():env.authenticatedContext(identity)).firestore();
    await assertFails(getDoc(doc(db,path)));
    await assertFails(getDocs(collection(db,'users/alice/expenses')));
    await assertFails(setDoc(doc(db,'users/alice/expenses/new'),record()));
    await assertFails(updateDoc(doc(db,path),{title:'Tampered'}));
    await assertFails(deleteDoc(doc(db,path)));
  });
}
for (const [name,patch] of Object.entries({negative:{amountCents:-1},zero:{amountCents:0},fractional:{amountCents:1.5},overflow:{amountCents:100000000000},stringAmount:{amountCents:'100'},invalidDate:{date:'today'},extraField:{admin:true},longTitle:{title:'x'.repeat(81)},longNote:{note:'x'.repeat(301)},emptyTitle:{title:''},invalidCategory:{category:'Salary'},invalidType:{type:'admin'}})) {
  test(`rejects malformed transaction: ${name}`,async () => {
    const db=env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db,path),{...record(),...patch}));
  });
}
test('valid income and legacy expenses remain supported',async () => {
  const db=env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(db,path),{...record(),type:'income',category:'Salary'}));
  const legacy=record(); delete legacy.type;
  await assertSucceeds(setDoc(doc(db,path),legacy));
});
test('missing required fields are rejected',async () => {
  const db=env.authenticatedContext('alice').firestore();
  const data=record(); delete data.note;
  await assertFails(setDoc(doc(db,path),data));
});
test('owners can count contributions across their repositories',async () => {
  const db=env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(db,contributionPath),contribution()));
  await assertSucceeds(getDocs(collection(db,'users/alice/contributions')));
  await assertSucceeds(deleteDoc(doc(db,contributionPath)));
});
test('other users cannot access contributions',async () => {
  await env.withSecurityRulesDisabled(async c=>setDoc(doc(c.firestore(),contributionPath),contribution()));
  const db=env.authenticatedContext('bob').firestore();
  await assertFails(getDoc(doc(db,contributionPath)));
  await assertFails(getDocs(collection(db,'users/alice/contributions')));
  await assertFails(setDoc(doc(db,contributionPath),contribution()));
  await assertFails(deleteDoc(doc(db,contributionPath)));
});
for (const [name,patch] of Object.entries({emptyTitle:{title:''},longTitle:{title:'x'.repeat(121)},longRepository:{repository:'x'.repeat(101)},invalidType:{type:'admin'},invalidDate:{date:'today'},longNote:{note:'x'.repeat(301)},extraField:{count:4}})) {
  test(`rejects malformed contribution: ${name}`,async () => {
    const db=env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db,contributionPath),{...contribution(),...patch}));
  });
}
test('profile privilege injection, user enumeration and unknown paths are denied',async () => {
  const db=env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db,'users/alice'),{admin:true}));
  await assertFails(getDocs(collection(db,'users')));
  await assertFails(getDoc(doc(db,'users/bob')));
  await assertFails(setDoc(doc(db,'admin/config'),{enabled:true}));
  await assertFails(getDoc(doc(db,'admin/config')));
  await assertSucceeds(deleteDoc(doc(db,'users/alice')));
});
test('authenticated guests are limited to their own data',async () => {
  const db=env.authenticatedContext('guest',{firebase:{sign_in_provider:'anonymous'}}).firestore();
  await assertSucceeds(setDoc(doc(db,'users/guest/expenses/new'),record()));
  await assertFails(getDoc(doc(db,path)));
});
const envelope=()=>({v:1,nonce:'A'.repeat(16),mac:'A'.repeat(24),ciphertext:'encrypted'});
test('retired vault cannot be created or modified; existing metadata remains owner-only',async()=>{
  await env.withSecurityRulesDisabled(async c=>setDoc(doc(c.firestore(),'users/alice/vault/config'),envelope()));
  const db=env.authenticatedContext('alice').firestore();
  await assertSucceeds(getDoc(doc(db,'users/alice/vault/config')));
  await assertFails(setDoc(doc(db,'users/alice/vault/config'),envelope()));
  await assertFails(setDoc(doc(db,'users/alice/vault/new'),envelope()));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(),'users/alice/vault/config')));
  await assertSucceeds(deleteDoc(doc(db,'users/alice/vault/config')));
});
test('owner can convert existing ciphertext to validated transactions; new ciphertext is denied',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    await setDoc(doc(c.firestore(),'users/alice/vault/config'),envelope());
    await setDoc(doc(c.firestore(),path),envelope());
  });
  const db=env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(env.authenticatedContext('bob').firestore(),path),record()));
  await assertSucceeds(setDoc(doc(db,path),record()));
  await assertFails(setDoc(doc(db,path),envelope()));
  await assertFails(updateDoc(doc(db,path),{admin:true}));
});
