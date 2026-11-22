import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../model/quote_model.dart';

/// API Service for REST Endpoints
/// Conforms to `docs/api_spec.md` (Module 5).
/// All public endpoints without API key, with 8-second timeout and offline fallback.
class ApiService {
  static const String quoteApiUrl = 'https://dummyjson.com/quotes/random';
  static const Duration timeoutDuration = Duration(seconds: 8);

  /// Offline fallback quotes with discipline and self-mastery themes
  static const List<QuoteModel> fallbackQuotes = [
    QuoteModel(
      id: 1,
      quote: "Discipline is choosing between what you want now and what you want most.",
      author: "Abraham Lincoln",
    ),
    QuoteModel(
      id: 2,
      quote: "We suffer more often in imagination than in reality.",
      author: "Seneca",
    ),
    QuoteModel(
      id: 3,
      quote: "No man is free who is not master of himself.",
      author: "Epictetus",
    ),
    QuoteModel(
      id: 4,
      quote: "The impediment to action advances action. What stands in the way becomes the way.",
      author: "Marcus Aurelius",
    ),
    QuoteModel(
      id: 5,
      quote: "He who has a why to live can bear almost any how.",
      author: "Friedrich Nietzsche",
    ),
    QuoteModel(
      id: 6,
      quote: "Self-conquest is the greatest of victories.",
      author: "Plato",
    ),
  ];

  static QuoteModel getRandomFallbackQuote() {
    final rand = Random();
    return fallbackQuotes[rand.nextInt(fallbackQuotes.length)];
  }

  /// Fetches daily random quote from REST API with 8-second timeout
  /// Gracefully falls back to offline curated quotes on network failure or timeout
  Future<QuoteModel> fetchDailyQuote({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(Uri.parse(quoteApiUrl))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return QuoteModel.fromJson(data);
      } else {
        return getRandomFallbackQuote();
      }
    } catch (_) {
      return getRandomFallbackQuote();
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
