import Foundation
import Combine
import RevenueCat

@MainActor
final class PurchaseService: NSObject, ObservableObject, PurchasesDelegate {
    @Published private(set) var isPro = AppConstants.sharedDefaults.bool(forKey: "is_pro")
    @Published private(set) var price = "$4.99"
    @Published private(set) var isLoading = false
    @Published private(set) var requiresSyncRestart = false
    @Published var errorMessage: String?
    private var lifetimePackage: Package?

    override init() {
        super.init()
        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: AppConstants.revenueCatAPIKey)
        Purchases.shared.delegate = self
        Task { await refresh() }
    }

    func refresh() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            apply(info)
            let offerings = try await Purchases.shared.offerings()
            lifetimePackage = offerings.current?.lifetime ?? offerings.current?.availablePackages.first
            if let localized = lifetimePackage?.storeProduct.localizedPriceString { price = localized }
        } catch { errorMessage = error.localizedDescription }
    }

    func purchase() async {
        guard let lifetimePackage else { errorMessage = "The lifetime product is unavailable."; return }
        isLoading = true; defer { isLoading = false }
        do {
            let result = try await Purchases.shared.purchase(package: lifetimePackage)
            apply(result.customerInfo)
        } catch ErrorCode.purchaseCancelledError { return }
        catch { errorMessage = error.localizedDescription }
    }

    func restore() async {
        isLoading = true; defer { isLoading = false }
        do { apply(try await Purchases.shared.restorePurchases()) }
        catch { errorMessage = error.localizedDescription }
    }

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in apply(customerInfo) }
    }

    private func apply(_ info: CustomerInfo) {
        let wasConfiguredForPro = AppConstants.sharedDefaults.bool(forKey: "is_pro")
        isPro = info.entitlements[AppConstants.proEntitlementID]?.isActive == true
        if isPro && !wasConfiguredForPro { requiresSyncRestart = true }
        AppConstants.sharedDefaults.set(isPro, forKey: "is_pro")
    }
}
