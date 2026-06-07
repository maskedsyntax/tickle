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

  /// Localized price to display on the paywall (e.g. "$4.99").
  /// Falls back to the configured default until real offerings load.
  final String priceString;

  const PremiumState({
    this.isPro = false,
    this.isLoading = false,
    this.error,
    this.priceString = PremiumCubit.defaultPrice,
  });

  PremiumState copyWith({
    bool? isPro,
    bool? isLoading,
    String? error,
    String? priceString,
    bool clearError = false,
  }) {
    return PremiumState(
      isPro: isPro ?? this.isPro,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      priceString: priceString ?? this.priceString,
    );
  }
}

class PremiumCubit extends Cubit<PremiumState> {
  // TODO: Replace with your actual RevenueCat API keys
  static const _appleApiKey = 'YOUR_APPLE_API_KEY';
  static const _googleApiKey = 'YOUR_GOOGLE_API_KEY';

  // Entitlement ID defined in RevenueCat dashboard
  static const _entitlementId = 'tickle_pro';

  /// Price shown before real store pricing loads, and in mock mode.
  /// Tickle Pro is a one-time lifetime unlock.
  static const String defaultPrice = '\$4.99';

  // Fallback key for mock mode if keys are not set
  static const _mockProKey = 'is_pro_unlocked_mock';

  bool get _isMockMode => _appleApiKey.contains('YOUR') || _googleApiKey.contains('YOUR');

  /// The lifetime package to purchase, resolved from RevenueCat offerings.
  Package? _proPackage;

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

      // Fetch initial status and available products
      final customerInfo = await Purchases.getCustomerInfo();
      _updateProStatusFromInfo(customerInfo);
      await _loadOfferings();
    } catch (e) {
      debugPrint('Failed to initialize RevenueCat: $e');
    }
  }

  /// Resolves the lifetime package and its localized price from offerings.
  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return;

      // Prefer the lifetime package; otherwise fall back to the first one.
      final package = current.lifetime ??
          (current.availablePackages.isNotEmpty
              ? current.availablePackages.first
              : null);
      if (package == null) return;

      _proPackage = package;
      emit(state.copyWith(priceString: package.storeProduct.priceString));
    } catch (e) {
      debugPrint('Failed to load offerings: $e');
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
      // Make sure we have a package to buy.
      if (_proPackage == null) {
        await _loadOfferings();
      }
      final package = _proPackage;
      if (package == null) {
        emit(state.copyWith(error: 'No products available to purchase.'));
        return;
      }

      final result = await Purchases.purchase(PurchaseParams.package(package));
      _updateProStatusFromInfo(result.customerInfo);
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
