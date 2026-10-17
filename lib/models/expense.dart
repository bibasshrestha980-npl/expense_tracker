import 'package:cloud_firestore/cloud_firestore.dart';

const categories = [
  'Food',
  'Transport',
  'Shopping',
  'Bills',
  'Health',
  'Education',
  'Other',
];
const incomeCategories = [
  'Salary',
  'Freelance',
  'Allowance',
  'Gift',
  'Refund',
  'Opening balance',
  'Other income',
];

const Map<String, List<String>> aiCategorySuggestions = {
  'Food': [
    'Momo & Chowmein',
    'Lunch / Khaja',
    'Groceries & Vegetables',
    'Coffee & Bakery',
    'Dinner & Drinks',
    'Tea & Snacks (Chiya Khaja)',
  ],
  'Transport': [
    'Bus / Micro fare',
    'Pathao / InDrive ride',
    'Petrol / Fuel refill',
    'Taxi fare',
    'Vehicle servicing',
  ],
  'Shopping': [
    'Clothes & Apparel',
    'Daily essentials',
    'Electronics & Gadgets',
    'Shoes & Footwear',
    'Home & Kitchen items',
  ],
  'Bills': [
    'Electricity bill (NEA)',
    'Internet / Wi-Fi',
    'Mobile recharge & Data',
    'Water bill (Khanepani)',
    'House / Room rent',
  ],
  'Health': [
    'Pharmacy & Medicines',
    'Doctor consultation',
    'Lab tests & Checkup',
    'Dental care',
    'Gym / Fitness',
  ],
  'Education': [
    'Books & Stationery',
    'College / Tuition fees',
    'Exam registration',
    'Online course / Certification',
  ],
  'Other': [
    'Personal care & Grooming',
    'Donation / Puja',
    'Pet supplies',
    'Miscellaneous expense',
  ],
  'Salary': ['Monthly salary', 'Advance salary', 'Bonus payment'],
  'Freelance': ['Client project', 'Design gig', 'Consulting fee'],
  'Allowance': ['Monthly allowance', 'Family support', 'Stipend'],
  'Gift': ['Birthday gift', 'Festive cash (Dashain/Tihar)', 'Prize money'],
  'Refund': ['Security deposit return', 'Online return refund', 'Overpayment refund'],
  'Opening balance': ['Cash in hand', 'Bank balance starting point'],
  'Other income': ['Interest earned', 'Asset sale', 'Side income'],
};

const Map<String, List<String>> aiCategorySuggestionsNe = {
  'Food': [
    'मोमो र चाउमिन',
    'खाजा / खाना',
    'किराना तथा तरकारी',
    'कफी तथा बेकरी',
    'बेलुकीको खाना',
    'चिया खाजा',
  ],
  'Transport': [
    'बस / माइक्रो भाडा',
    'पठाओ / इनड्राइभ यात्रा',
    'पेट्रोल / इन्धन',
    'ट्याक्सी भाडा',
    'गाडी मर्मत',
  ],
  'Shopping': [
    'लत्ताकपडा',
    'दैनिक उपभोग्य सामान',
    'इलेक्ट्रोनिक्स र ग्याजेट',
    'जुत्ता चप्पल',
    'घरायसी सामान',
  ],
  'Bills': [
    'विद्युत महसुल (NEA)',
    'इन्टरनेट / वाइफाइ',
    'मोबाइल रिचार्ज र डाटा',
    'खानेपानी महसुल',
    'घर / कोठा भाडा',
  ],
  'Health': [
    'औषधि तथा फार्मेसी',
    'डाक्टर परामर्श',
    'ल्याब परीक्षण',
    'दन्त उपचार',
    'जिम / फिटनेस',
  ],
  'Education': [
    'किताब तथा स्टेशनरी',
    'कलेज / ट्युसन शुल्क',
    'परीक्षा फारम शुल्क',
    'अनलाइन कोर्स',
  ],
  'Other': [
    'व्यक्तिगत हेरचाह',
    'दान / पूजा',
    'घरपालुवा जनावर सामग्री',
    'विविध खर्च',
  ],
  'Salary': [
    'मासिक तलब',
    'पेस्की तलब',
    'बोनस रकम',
  ],
  'Freelance': [
    'प्रोजेक्ट भुक्तानी',
    'डिजाइन काम',
    'परामर्श शुल्क',
  ],
  'Allowance': [
    'मासिक भत्ता',
    'पारिवारिक सहयोग',
    'छात्रवृत्ति / स्टाइपेन्ड',
  ],
  'Gift': [
    'जन्मदिनको उपहार',
    'चाडपर्व दक्षिणा (दसैं/तिहार)',
    'पुरस्कार रकम',
  ],
  'Refund': [
    'धरौटी रकम फिर्ता',
    'अनलाइन अर्डर फिर्ता',
    'बढी भुक्तानी फिर्ता',
  ],
  'Opening balance': [
    'हातमा रहेको नगद',
    'सुरुवाती बैंक मौज्दात',
  ],
  'Other income': [
    'ब्याज आम्दानी',
    'सम्पत्ति बिक्री',
    'अतिरिक्त आम्दानी',
  ],
};


class Expense {
  final String id, title, category, note;
  final int amountCents;
  final DateTime date;
  final bool isIncome;
  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amountCents,
    required this.date,
    this.note = '',
    this.isIncome = false,
  });
  factory Expense.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Expense.fromMap(doc.id, doc.data() ?? {});

  factory Expense.fromMap(String id, Map<String, dynamic> d) {
    final rawDate = d['date'];
    final DateTime resolvedDate;
    if (rawDate is Timestamp) {
      resolvedDate = rawDate.toDate();
    } else if (rawDate is String) {
      resolvedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      resolvedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      resolvedDate = DateTime.now();
    }
    return Expense(
      id: id,
      title: d['title'] as String? ?? '',
      category: d['category'] as String? ?? 'Other',
      amountCents: (d['amountCents'] as num?)?.toInt() ?? 0,
      date: resolvedDate,
      note: d['note'] as String? ?? '',
      isIncome: d['type'] == 'income',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'category': category,
    'amountCents': amountCents,
    'date': Timestamp.fromDate(date),
    'note': note,
    'type': isIncome ? 'income' : 'expense',
  };
}

int? parseAmount(String input) {
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(input.trim())) return null;
  final parts = input.trim().split('.');
  final whole = int.tryParse(parts[0]);
  if (whole == null || whole > 999999999) return null;
  final cents =
      whole * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return cents > 0 ? cents : null;
}
