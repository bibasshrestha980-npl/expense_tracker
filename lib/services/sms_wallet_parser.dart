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
  static ParsedTransaction? parse(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    final amount = _extractAmount(clean);
    if (amount == null || amount <= 0) return null;

    final isIncome = _detectIsIncome(clean);
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

    // Secondary pattern: `debited by / credited with / paid / transferred ... [number]`
    final verbPattern = RegExp(
      r'(?:debited|credited|paid|transferred|amount of|sum of)\s*(?:by|with|of)?\s*(?:Rs\.?|NPR)?\s*([0-9,]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final verbMatch = verbPattern.firstMatch(normalized);
    if (verbMatch != null) {
      final rawNum = verbMatch.group(1)?.replaceAll(',', '');
      if (rawNum != null) {
        final val = double.tryParse(rawNum);
        if (val != null && val > 0) return val;
      }
    }

    // Fallback: search for numbers with decimals like 1250.00 or integers >= 10
    final genericNumPattern = RegExp(
      r'(?:^|\s)([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})|[0-9]+(?:\.[0-9]{2}))(?:\s|$)',
    );
    final genMatch = genericNumPattern.firstMatch(normalized);
    if (genMatch != null) {
      final rawNum = genMatch.group(1)?.replaceAll(',', '');
      if (rawNum != null) {
        final val = double.tryParse(rawNum);
        if (val != null && val > 0) return val;
      }
    }

    return null;
  }

  /// Determines whether the transaction is an Income (credit) or Expense (debit).
  static bool _detectIsIncome(String text) {
    final lower = text.toLowerCase();

    // Check strong credit/income keywords first
    final creditKeywords = [
      'credited',
      'credit',
      'received',
      'deposited',
      'cashback',
      'refund',
      'salary',
      'stipend',
      'bonus',
      'जम्मा',
      'आएको',
      'प्राप्त',
      'फिर्ता',
    ];

    for (final kw in creditKeywords) {
      if (lower.contains(kw)) return true;
    }

    return false; // Default to Expense (debit)
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
      if (lower.contains('bonus') || lower.contains('cashback') || lower.contains('reward')) {
        return 'Bonus';
      }
      if (lower.contains('dividend') || lower.contains('interest') || lower.contains('stock')) {
        return 'Investments';
      }
      if (lower.contains('refund') || lower.contains('reimbursement')) {
        return 'Refund';
      }
      return 'Other Income';
    }

    final combined = '${merchant ?? ''} $text'.toLowerCase();

    // Food & Dining
    if (combined.contains('foodmandu') ||
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
      if (category == 'Bonus') return 'Cashback / Bonus Received';
      return 'Money In';
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
