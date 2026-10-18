// AI Service powered by Google Gemini REST API for Pocket
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiService {
  // ── Gemini API key (supports --dart-define=GEMINI_API_KEY=...) ──
  static final String _apiKey = const String.fromEnvironment('GEMINI_API_KEY').isNotEmpty
      ? const String.fromEnvironment('GEMINI_API_KEY')
      : utf8.decode(base64Decode('QVEuQWI4Uk42SWYzd3dENkw0R3UyVUkyWnRQS2ZfelY3ek5nc2pDYXdGOU1iVVE0UGdPaUE='));

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

  // Cache to avoid redundant API calls
  static final Map<String, List<String>> _suggestionCache = {};
  static final Map<String, String> _insightCache = {};

  const AiService();

  /// Whether the AI service is configured with a real API key and not running in widget tests.
  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      !_apiKey.startsWith('YOUR_') &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  /// Call the Gemini REST API with a prompt and return the text response.
  Future<String?> _callGemini(String prompt) async {
    if (!isConfigured) return null;

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$_apiKey'),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content?['parts'] as List?;
          if (parts != null) {
            for (final part in parts) {
              if (part is Map &&
                  part.containsKey('text') &&
                  part['text'] is String) {
                final txt = (part['text'] as String).trim();
                if (txt.isNotEmpty) return txt;
              }
            }
          }
        }
      } else {
        debugPrint('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Gemini network/parse error: $e');
    }
    return null;
  }

  /// Fetch AI-generated expense/income title suggestions for a [category].
  /// Returns a list of 5-8 smart, contextual suggestions.
  Future<List<String>> fetchSuggestions({
    required String category,
    bool nepali = false,
    bool isIncome = false,
  }) async {
    if (!isConfigured) return [];

    final cacheKey = '${category}_${isIncome ? "inc" : "exp"}_${nepali ? "ne" : "en"}';
    if (_suggestionCache.containsKey(cacheKey)) {
      return _suggestionCache[cacheKey]!;
    }

    final hour = DateTime.now().hour;
    final timeOfDay = hour >= 5 && hour < 12
        ? 'morning'
        : hour >= 12 && hour < 17
            ? 'afternoon'
            : hour >= 17 && hour < 21
                ? 'evening'
                : 'night';

    final prompt = isIncome
        ? (nepali
            ? '''तपाईं नेपालमा बस्ने व्यक्तिको लागि आम्दानी ट्र्याकर AI हो।
"$category" आम्दानी श्रेणीको लागि ६-८ वटा छोटो र सामान्य आम्दानी स्रोत/शीर्षकहरू दिनुहोस्।
नेपाली सन्दर्भमा (जस्तै: मासिक तलब, भत्ता, दक्षिणा, बोनस, आदि)।

नियम:
- प्रत्येक शीर्षक २-४ शब्दको हुनुपर्छ
- नेपालीमा लेख्नुहोस्
- प्रत्येक नयाँ लाइनमा एक शीर्षक मात्र
- कुनै नम्बर, बुलेट वा चिन्ह नराख्नुहोस्
- केवल शीर्षकहरू मात्र लेख्नुहोस्'''
            : '''You are a personal finance income tracker AI in Nepal.
Suggest 6-8 common, realistic income source titles for the "$category" category.
Use Nepal-relevant context (e.g., Monthly salary, Dashain bonus, Freelance project, Stipend).

Rules:
- 2 to 4 words per item
- In English
- One item per line
- No numbering, asterisks, or bullet points
- Return ONLY the list of titles''')
        : (nepali
            ? '''तपाईं नेपालमा बस्ने व्यक्तिको लागि खर्च ट्र्याकर AI हो।
"$category" श्रेणीको लागि ६-८ वटा सामान्य खर्च शीर्षकहरू दिनुहोस्।
अहिलेको समय: $timeOfDay।
नेपाली सन्दर्भमा (जस्तै: मोमो, चिया, किराना, पठाओ, eSewa, आदि)।

नियम:
- प्रत्येक शीर्षक २-४ शब्दको हुनुपर्छ
- नेपालीमा लेख्नुहोस्
- प्रत्येक नयाँ लाइनमा एक शीर्षक मात्र
- कुनै नम्बर, बुलेट वा चिन्ह नराख्नुहोस्
- केवल शीर्षकहरू मात्र लेख्नुहोस्'''
            : '''You are an expense tracker AI for someone living in Nepal.
Suggest 6-8 common expense titles for the "$category" category.
Current time of day is $timeOfDay.
Use Nepal context (e.g., Momo, tea, groceries, Pathao, eSewa, rent).

Rules:
- 2 to 4 words per item
- In English
- One item per line
- No numbering, asterisks, or bullet points
- Return ONLY the list of titles''');

    final text = await _callGemini(prompt);
    if (text == null || text.trim().isEmpty) return [];

    final suggestions = text
        .split('\n')
        .map((s) => s.trim())
        .map((s) => s.replaceAll(RegExp(r'^[\*\-\d\.\)\s]+'), '').trim())
        .map((s) => s.replaceAll(RegExp(r'["`*]'), '').trim())
        .where((s) =>
            s.isNotEmpty &&
            s.length <= 45 &&
            !s.toLowerCase().startsWith('here') &&
            !s.toLowerCase().startsWith('sure') &&
            !s.contains(':'))
        .take(8)
        .toList();

    if (suggestions.isNotEmpty) {
      _suggestionCache[cacheKey] = suggestions;
    }

    return suggestions;
  }

  /// Generate a smart financial coach insight based on actual user totals.
  Future<String?> getFinancialCoachInsight({
    required int totalExpensesCents,
    required int totalIncomeCents,
    required String topCategory,
    required int topCategoryCents,
    bool nepali = false,
  }) async {
    if (!isConfigured) return null;

    final exp = (totalExpensesCents / 100).toStringAsFixed(0);
    final inc = (totalIncomeCents / 100).toStringAsFixed(0);
    final topAmt = (topCategoryCents / 100).toStringAsFixed(0);

    final cacheKey = '${exp}_${inc}_${topCategory}_${nepali ? "ne" : "en"}';
    if (_insightCache.containsKey(cacheKey)) {
      return _insightCache[cacheKey]!;
    }

    final prompt = nepali
        ? '''तपाईं "Pocket" एपको व्यक्तिगत AI वित्तीय सल्लाहकार (Financial Coach) हुनुहुन्छ।
प्रयोगकर्ताको यस महिनाको वित्तीय अवस्था:
- कुल खर्च: रु $exp
- कुल आम्दानी: रु $inc
- सबैभन्दा बढी खर्च भएको श्रेणी: $topCategory (रु $topAmt)

नेपालीमा १-२ वाक्यको उत्साहवर्धक, स्पष्ट र उपयोगी वित्तीय सुझाव दिनुहोस्।
नेपाली सन्दर्भ (रुपैयाँ, बचत) अनुसार छोटकरीमा मात्र लेख्नुहोस्। कुनै शीर्षक नराख्नुहोस्।'''
        : '''You are the personal AI Financial Coach for the "Pocket" expense tracker app in Nepal.
The user's current month summary:
- Total expenses: NPR $exp
- Total income: NPR $inc
- Top expense category: $topCategory (NPR $topAmt)

Give a friendly, sharp 1-2 sentence actionable financial insight or encouragement.
Keep it concise, friendly, and practical for Nepal. Return ONLY the insight text without quotes or headers.''';

    final text = await _callGemini(prompt);
    if (text != null && text.trim().isNotEmpty) {
      final clean = text.replaceAll(RegExp(r'^["`]+|["`]+$'), '').trim();
      _insightCache[cacheKey] = clean;
      return clean;
    }
    return null;
  }

  /// Clear all cached AI responses
  static void clearCache() {
    _suggestionCache.clear();
    _insightCache.clear();
  }
}
