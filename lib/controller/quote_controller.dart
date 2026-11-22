import 'package:get/get.dart';
import '../model/quote_model.dart';
import '../service/api_service.dart';

/// Controller for Daily Stoic & Discipline Quotes HUD Card
/// Handles loading states, asynchronous REST API fetches, and offline fallbacks.
class QuoteController extends GetxController {
  static QuoteController get to => Get.find<QuoteController>();

  final ApiService _apiService;
  QuoteController({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final Rxn<QuoteModel> quote = Rxn<QuoteModel>();
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchQuote();
  }

  /// Fetches daily quote from API with automatic fallback
  Future<void> fetchQuote() async {
    if (Get.testMode) {
      quote.value = ApiService.getRandomFallbackQuote();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final fetched = await _apiService.fetchDailyQuote();
      quote.value = fetched;
    } catch (_) {
      quote.value = ApiService.getRandomFallbackQuote();
    } finally {
      isLoading.value = false;
    }
  }
}
