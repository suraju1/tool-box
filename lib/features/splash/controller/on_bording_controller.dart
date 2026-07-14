import 'package:flutter/material.dart';
import 'package:tool_bocs/core/api/api_client.dart';
import 'package:tool_bocs/features/splash/model/on_bording_model.dart';

class OnBoardingController extends ChangeNotifier {
  int currentPage = 0;
  List<OnBoardingModel> onBoardingList = [
    OnBoardingModel(
      id: 1,
      title: "Welcome to ToolBox",
      description:
          "Your ultimate community platform to borrow, share, and trade tools easily.",
      imageUrl: "assets/onBoarding1.png",
      screenOrder: 1,
    ),
    OnBoardingModel(
      id: 2,
      title: "Find Tools Near You",
      description:
          "Browse a wide variety of tools available in your neighborhood and request them instantly.",
      imageUrl: "assets/onBoarding2.png",
      screenOrder: 2,
    ),
    OnBoardingModel(
      id: 3,
      title: "Share & Earn",
      description:
          "List your unused tools, help your community, and earn rewards or trades.",
      imageUrl: "assets/onBoarding3.png",
      screenOrder: 3,
    ),
  ];
  bool isLoading = false;
  String? errorMessage;

  final ApiClient _apiClient = ApiClient();

  void setCurrentPage(int page) {
    currentPage = page;
    notifyListeners();
  }

  Future<void> fetchOnboardingData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('onboarding');
      final data = response.data;
      if (data is Map<String, dynamic> && data['status'] == true) {
        final List<dynamic> list = data['data'] ?? [];
        if (list.isNotEmpty) {
          onBoardingList = list
              .map((json) =>
                  OnBoardingModel.fromJson(json as Map<String, dynamic>))
              .toList();
          onBoardingList.sort(
              (a, b) => (a.screenOrder ?? 0).compareTo(b.screenOrder ?? 0));
        }
      } else if (data is List) {
        if (data.isNotEmpty) {
          onBoardingList = data
              .map((json) =>
                  OnBoardingModel.fromJson(json as Map<String, dynamic>))
              .toList();
          onBoardingList.sort(
              (a, b) => (a.screenOrder ?? 0).compareTo(b.screenOrder ?? 0));
        }
      } else {
        errorMessage = data is Map
            ? (data['message'] ?? 'Failed to fetch onboarding data')
            : 'Unexpected response format';
      }
    } catch (e) {
      errorMessage = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
