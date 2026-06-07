import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumState {
  final bool isPro;
  final bool isLoading;
  final String? error;

  const PremiumState({
    this.isPro = false,
    this.isLoading = false,
    this.error,
  });

  PremiumState copyWith({bool? isPro, bool? isLoading, String? error, bool clearError = false}) {
    return PremiumState(
      isPro: isPro ?? this.isPro,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PremiumCubit extends Cubit<PremiumState> {
  // TODO: Replace with your actual RevenueCat API keys
  static const _appleApiKey = 'YOUR_APPLE_API_KEY';
  static const _googleApiKey = 'YOUR_GOOGLE_API_KEY';
  
  // Entitlement ID defined in RevenueCat dashboard
  static const _entitlementId = 'tickle_pro';

  // Fallback key for mock mode if keys are not set
  static const _mockProKey = 'is_pro_unlocked_mock';
  
  bool get _isMockMode => _appleApiKey.contains('YOUR') || _googleApiKey.contains('YOUR');

  PremiumCubit() : super(const PremiumState()) {
    _init();
  }

  Future<void> _init() async {
    if (_isMockMode) {
      await _loadMockStatus();
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      
      late PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_googleApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_appleApiKey);
      }
      await Purchases.configure(configuration);
      
      // Listen to customer info updates (e.g. from background sync)
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateProStatusFromInfo(customerInfo);
      });

      // Fetch initial status
      final customerInfo = await Purchases.getCustomerInfo();
      _updateProStatusFromInfo(customerInfo);
    } catch (e) {
      debugPrint('Failed to initialize RevenueCat: $e');
    }
  }

  void _updateProStatusFromInfo(CustomerInfo customerInfo) {
    final isPro = customerInfo.entitlements.all[_entitlementId]?.isActive == true;
    emit(state.copyWith(isPro: isPro));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  Future<void> purchasePro() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    if (_isMockMode) {
      // Mock purchase
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mockProKey, true);
      emit(state.copyWith(isPro: true, isLoading: false));
      return;
    }

    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        final package = offerings.current!.availablePackages.first;
        final result = await Purchases.purchasePackage(package);
        _updateProStatusFromInfo(result.customerInfo);
      } else {
        emit(state.copyWith(error: 'No packages available to purchase.'));
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        emit(state.copyWith(error: e.message ?? 'Unknown error occurred'));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> restorePurchases() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    if (_isMockMode) {
      await Future.delayed(const Duration(seconds: 1));
      await _loadMockStatus();
      emit(state.copyWith(isLoading: false));
      return;
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateProStatusFromInfo(customerInfo);
    } on PlatformException catch (e) {
      emit(state.copyWith(error: e.message ?? 'Failed to restore purchases'));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  // --- MOCK METHODS FOR DEVELOPMENT ---
  
  Future<void> _loadMockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool(_mockProKey) ?? false;
    emit(state.copyWith(isPro: isPro));
  }

  Future<void> debugResetPro() async {
    if (_isMockMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mockProKey, false);
      emit(state.copyWith(isPro: false));
    }
  }
}
