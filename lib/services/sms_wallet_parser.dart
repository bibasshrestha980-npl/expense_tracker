/// Result of parsing an SMS, digital wallet alert, or payment receipt.
class ParsedTransaction {
  final double amount;
  final bool isIncome;
  final String title;
  final String category;
  final String? merchant;
  final String? referenceId;
  final String rawText;

  const ParsedTransaction({
    required this.amount,
    required this.isIncome,
    required this.title,
    required this.category,
    this.merchant,
    this.referenceId,
    required this.rawText,
  });

  /// Amount in integer paisa/cents.
  int get amountCents => (amount * 100).round();
}

/// Intelligent parser for Nepali bank SMS, eSewa, Khalti, and Fonepay transaction alerts.
class SmsWalletParser {
  /// Parses raw SMS, clipboard text, or digital receipt string into a [ParsedTransaction].
  /// Returns `null` if no valid financial transaction can be detected.
  static ParsedTransaction? parse(String text, {bool defaultIsIncome = false}) {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    final lower = clean.toLowerCase();
    // Ignore authentication OTP and security messages
    if (lower.contains('otp') ||
        lower.contains('verification code') ||
        lower.contains('security code') ||
        lower.contains('do not share') ||
        lower.contains('password')) {
      return null;
    }

    final amount = _extractAmount(clean);
    if (amount == null || amount <= 0) return null;

    final isIncome = _detectIsIncome(clean, defaultIsIncome: defaultIsIncome);
    final referenceId = _extractReferenceId(clean);
    final merchant = _extractMerchant(clean);
    final category = _detectCategory(clean, merchant, isIncome);
    final title = _generateTitle(clean, merchant, category, isIncome);

    return ParsedTransaction(
      amount: amount,
      isIncome: isIncome,
      title: title,
      category: category,
      merchant: merchant,
      referenceId: referenceId,
      rawText: clean,
    );
  }

  /// Extracts transaction amount from patterns like:
  /// - `Rs. 1,500.00` / `Rs 1500` / `NPR 2,500.50` / `रु ५००` / `रु. १,२००`
  /// - `income 60000` / `salary 50000` / `60000`
  static double? _extractAmount(String text) {
    // 1. Normalized Nepali digits to English digits
    final normalized = _convertNepaliDigits(text);

    // Look for explicit currency prefixes first: Rs.?, NPR, NRs, रु.?
    final currencyPattern = RegExp(
      r'(?:Rs\.?|NPR\.?|NRs\.?|रु\.?)\s*([0-9,]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );

    final match = currencyPattern.firstMatch(normalized);
    if (match != null) {
      final rawNum = match.group(1)?.replaceAll(',', '');
      if (rawNum != null) {
        final val = double.tryParse(rawNum);
        if (val != null && val > 0) return val;
      }
    }

    // Secondary pattern: keywords followed by number:
    // e.g. "income 60000", "salary: 50000", "debited by 2500", "paid 450", "credited 10000"
    final keywordPattern = RegExp(
      r'(?:debited|credited|paid|transferred|income|salary|expense|spent|received|deposited|deposit|allowance|freelance|gift|refund|amount|sum|cost|bill|fare|fee|bonus|तलब|आम्दानी|कमाई|खर्च)\s*(?:by|with|of|is|:|=|for)?\s*(?:Rs\.?|NPR|NRs\.?|रु\.?)?\s*([0-9,]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final keyMatch = keywordPattern.firstMatch(normalized);
    if (keyMatch != null) {
      final rawNum = keyMatch.group(1)?.replaceAll(',', '');
      if (rawNum != null) {
        final val = double.tryParse(rawNum);
        if (val != null && val > 0) return val;
      }
    }

    // Reverse keyword pattern: number followed by keyword (e.g. "60000 income", "50000 salary", "500 momo")
    final reverseKeywordPattern = RegExp(
      r'([0-9,]+(?:\.[0-9]+)?)\s*(?:Rs\.?|NPR|NRs\.?|रु\.?)?\s*(?:debited|credited|paid|transferred|income|salary|expense|spent|received|deposited|bonus|allowance|freelance|gift|refund|तलब|आम्दानी|कमाई|खर्च)',
      caseSensitive: false,
    );
    final revMatch = reverseKeywordPattern.firstMatch(normalized);
    if (revMatch != null) {
      final rawNum = revMatch.group(1)?.replaceAll(',', '');
      if (rawNum != null) {
        final val = double.tryParse(rawNum);
        if (val != null && val > 0) return val;
      }
    }

    // Fallback: any number in the string (integers or decimals), excluding common account/code numbers
    // Remove reference patterns, account patterns first
    final sanitized = normalized
        .replaceAll(
          RegExp(
            r'(?:Txn\s*ID|Ref\s*No|Trace|A/c|Account|\*)[A-Za-z0-9_\-:*]+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\b(?:202[0-9]|208[0-9])\b'),
          '',
        ); // filter out year 2026, 2083 etc.

    final anyNumberPattern = RegExp(r'\b([0-9,]+(?:\.[0-9]+)?)\b');
    for (final m in anyNumberPattern.allMatches(sanitized)) {
      final raw = m.group(1)?.replaceAll(',', '');
      if (raw != null) {
        final val = double.tryParse(raw);
        if (val != null && val > 0) return val;
      }
    }

    return null;
  }

  /// Determines whether the transaction is an Income (credit) or Expense (debit).
  static bool _detectIsIncome(String text, {bool defaultIsIncome = false}) {
    final lower = text.toLowerCase();

    // Check strong credit/income keywords first
    final creditKeywords = [
      'income',
      'credited',
      'credit',
      'received',
      'deposited',
      'deposit',
      'cashback',
      'refund',
      'salary',
      'stipend',
      'bonus',
      'allowance',
      'freelance',
      'earning',
      'earnings',
      'gift',
      'जम्मा',
      'आएको',
      'प्राप्त',
      'फिर्ता',
      'आम्दानी',
      'तलब',
      'कमाई',
    ];

    for (final kw in creditKeywords) {
      if (lower.contains(kw)) return true;
    }

    // Check debit/expense keywords
    final debitKeywords = [
      'debited',
      'debit',
      'paid',
      'spent',
      'expense',
      'payment',
      'sent',
      'withdrawn',
      'purchase',
      'fare',
      'fee',
      'bill',
      'काटिएको',
      'तिरेको',
      'गएको',
      'खर्च',
    ];

    for (final kw in debitKeywords) {
      if (lower.contains(kw)) return false;
    }

    return defaultIsIncome;
  }

  /// Extracts reference number or transaction ID if present.
  static String? _extractReferenceId(String text) {
    final refPattern = RegExp(
      r'(?:Txn\s*ID|TxnNo|TxnID|Ref\s*No|Ref\s*ID|Ref|Reference|Trace\s*No|Code)[\s:=#]+([A-Za-z0-9_\-]+)',
      caseSensitive: false,
    );
    final match = refPattern.firstMatch(text);
    return match?.group(1);
  }

  /// Extracts known merchant names or contextual counterparties.
  static String? _extractMerchant(String text) {
    final lower = text.toLowerCase();

    final knownMerchants = {
      'bhatbhateni': 'Bhatbhateni Supermarket',
      'big mart': 'Big Mart',
      'daraz': 'Daraz Online',
      'sastodeal': 'SastoDeal',
      'himalayan java': 'Himalayan Java Coffee',
      'foodmandu': 'Foodmandu',
      'bhoj': 'Bhoj Deals',
      'pathao': 'Pathao',
      'indrive': 'InDrive',
      'worldlink': 'Worldlink Communications',
      'vianet': 'Vianet Communications',
      'subisu': 'Subisu Internet',
      'dishhome': 'DishHome',
      'ntc': 'Nepal Telecom (NTC)',
      'ncell': 'Ncell',
      'qfx': 'QFX Cinemas',
      'big movies': 'Big Movies',
      'nea': 'Nepal Electricity Authority',
      'khanepani': 'Khanepani (Water Bill)',
      'esewa': 'eSewa Wallet',
      'khalti': 'Khalti Wallet',
      'fonepay': 'Fonepay QR',
      'nabil': 'Nabil Bank',
      'nic asia': 'NIC Asia Bank',
      'global ime': 'Global IME Bank',
      'sanima': 'Sanima Bank',
      'prabhu': 'Prabhu Bank',
      'laxmi sunrise': 'Laxmi Sunrise Bank',
      'kumari': 'Kumari Bank',
      'everest bank': 'Everest Bank',
    };

    for (final entry in knownMerchants.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Try finding "to <Merchant>" or "at <Merchant>"
    final toPattern = RegExp(
      r'(?:to|at|paid to|sent to|at POS|merchant)\s+([A-Z0-9\s&]{3,25})(?:\s+via|\s+on|\.|$)',
      caseSensitive: false,
    );
    final match = toPattern.firstMatch(text);
    if (match != null) {
      final name = match.group(1)?.trim();
      if (name != null &&
          name.isNotEmpty &&
          !name.toLowerCase().contains('account') &&
          !name.toLowerCase().contains('a/c') &&
          !name.toLowerCase().contains('npr') &&
          !name.toLowerCase().contains('rs')) {
        return name;
      }
    }

    return null;
  }

  /// Intelligently matches a category based on the extracted merchant or keywords.
  static String _detectCategory(String text, String? merchant, bool isIncome) {
    if (isIncome) {
      final lower = text.toLowerCase();
      if (lower.contains('salary') || lower.contains('payroll') || lower.contains('तलब')) {
        return 'Salary';
      }
      if (lower.contains('freelance') || lower.contains('consulting') || lower.contains('contract') || lower.contains('client')) {
        return 'Freelance';
      }
      if (lower.contains('allowance') || lower.contains('भत्ता') || lower.contains('pocket money')) {
        return 'Allowance';
      }
      if (lower.contains('gift') || lower.contains('उपहार') || lower.contains('dakshina') || lower.contains('दक्षिणा')) {
        return 'Gift';
      }
      if (lower.contains('refund') || lower.contains('reimbursement') || lower.contains('cashback') || lower.contains('फिर्ता')) {
        return 'Refund';
      }
      if (lower.contains('opening') || lower.contains('balance') || lower.contains('surplus')) {
        return 'Opening balance';
      }
      return 'Other income';
    }

    final combined = '${merchant ?? ''} $text'.toLowerCase();

    // Food & Dining
    if (combined.contains('food') ||
        combined.contains('foodmandu') ||
        combined.contains('bhoj') ||
        combined.contains('java') ||
        combined.contains('cafe') ||
        combined.contains('restaurant') ||
        combined.contains('momo') ||
        combined.contains('bakery') ||
        combined.contains('pizza') ||
        combined.contains('kfc') ||
        combined.contains('dining') ||
        combined.contains('khaja')) {
      return 'Food';
    }

    // Groceries
    if (combined.contains('bhatbhateni') ||
        combined.contains('big mart') ||
        combined.contains('supermarket') ||
        combined.contains('grocery') ||
        combined.contains('mart') ||
        combined.contains('kirana') ||
        combined.contains('vegetable') ||
        combined.contains('sabji')) {
      return 'Groceries';
    }

    // Transport
    if (combined.contains('pathao') ||
        combined.contains('indrive') ||
        combined.contains('petrol') ||
        combined.contains('fuel') ||
        combined.contains('bus') ||
        combined.contains('taxi') ||
        combined.contains('airlines') ||
        combined.contains('flight') ||
        combined.contains('yatri') ||
        combined.contains('transport')) {
      return 'Transport';
    }

    // Utilities & Bills
    if (combined.contains('worldlink') ||
        combined.contains('vianet') ||
        combined.contains('subisu') ||
        combined.contains('ntc') ||
        combined.contains('ncell') ||
        combined.contains('nea') ||
        combined.contains('electricity') ||
        combined.contains('khanepani') ||
        combined.contains('dishhome') ||
        combined.contains('internet') ||
        combined.contains('recharge') ||
        combined.contains('water bill') ||
        combined.contains('utility')) {
      return 'Utilities';
    }

    // Entertainment
    if (combined.contains('qfx') ||
        combined.contains('cinema') ||
        combined.contains('movie') ||
        combined.contains('netflix') ||
        combined.contains('spotify') ||
        combined.contains('entertainment')) {
      return 'Entertainment';
    }

    // Shopping
    if (combined.contains('daraz') ||
        combined.contains('sastodeal') ||
        combined.contains('shopping') ||
        combined.contains('clothing') ||
        combined.contains('wear') ||
        combined.contains('mall')) {
      return 'Shopping';
    }

    // Health
    if (combined.contains('pharmacy') ||
        combined.contains('hospital') ||
        combined.contains('clinic') ||
        combined.contains('medical') ||
        combined.contains('doctor') ||
        combined.contains('lab')) {
      return 'Health';
    }

    // Education
    if (combined.contains('college') ||
        combined.contains('school') ||
        combined.contains('tuition') ||
        combined.contains('fee') ||
        combined.contains('book') ||
        combined.contains('university')) {
      return 'Education';
    }

    // Rent
    if (combined.contains('rent') || combined.contains('room') || combined.contains('flat')) {
      return 'Rent';
    }

    // Personal Care
    if (combined.contains('salon') || combined.contains('barber') || combined.contains('spa')) {
      return 'Personal Care';
    }

    return 'Other';
  }

  /// Generates a clean human-readable title for the transaction.
  static String _generateTitle(
    String text,
    String? merchant,
    String category,
    bool isIncome,
  ) {
    if (merchant != null && merchant.isNotEmpty) {
      return isIncome ? 'Received from $merchant' : merchant;
    }

    if (isIncome) {
      if (category == 'Salary') return 'Monthly Salary';
      if (category == 'Freelance') return 'Freelance Payment';
      if (category == 'Allowance') return 'Monthly Allowance';
      if (category == 'Gift') return 'Gift / Dakshina';
      if (category == 'Refund') return 'Refund / Cashback';
      final cleanText = text.replaceAll(RegExp(r'[0-9,.:]'), '').trim();
      if (cleanText.isNotEmpty && cleanText.length <= 40) {
        final words = cleanText.split(' ').where((w) => w.isNotEmpty);
        if (words.isNotEmpty) {
          return words
              .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
              .join(' ');
        }
      }
      return 'Income';
    }

    // Contextual expense title
    switch (category) {
      case 'Food':
        return 'Food & Dining';
      case 'Groceries':
        return 'Groceries & Household';
      case 'Transport':
        return 'Transport / Ride Fare';
      case 'Utilities':
        return 'Utility & Internet Bill';
      case 'Entertainment':
        return 'Entertainment & Outing';
      case 'Shopping':
        return 'Shopping Expense';
      default:
        return 'Expense';
    }
  }

  /// Converts Devanagari numerals (०-९) to ASCII numerals (0-9).
  static String _convertNepaliDigits(String input) {
    const devanagari = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(devanagari[i], i.toString());
    }
    return result;
  }
}
