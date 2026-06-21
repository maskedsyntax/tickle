import CloudKit
import Combine

@MainActor
final class SyncStatusService: ObservableObject {
    enum Status: String { case checking = "Checking…", available = "Active", unavailable = "Unavailable" }
    @Published private(set) var status: Status = .checking

    func refresh() async {
        do {
            status = try await CKContainer(identifier: AppConstants.cloudContainerID).accountStatus() == .available ? .available : .unavailable
        } catch { status = .unavailable }
    }
}
