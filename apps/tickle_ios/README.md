# Tickle for iOS

Native SwiftUI rewrite of the shipped Flutter iOS application.

## Generate and build

```sh
cd apps/tickle_ios
xcodegen generate
xcodebuild -project Tickle.xcodeproj -scheme Tickle -destination 'generic/platform=iOS' build
```

`project.yml` is the project source of truth. Commit changes to it and regenerate the Xcode project.

## Release configuration

- Main bundle: `com.maskedsyntax.tickle.tickleMobile`
- App Group: `group.com.maskedsyntax.tickle.tickleMobile`
- CloudKit container: `iCloud.com.maskedsyntax.tickle.tickleMobile`
- RevenueCat entitlement: `tickle_pro`

Before TestFlight, enable App Groups, CloudKit, and remote notifications for the application and widget identifiers. Initialize the SwiftData CloudKit schema in the development environment, verify it in CloudKit Console, and promote it to production before release.

## Upgrade migration

On first native launch, `LegacyMigrationService` imports `Documents/tickle.sqlite` into the shared SwiftData store. It preserves IDs, counters, archives, order, and logs; reconciles pending legacy widget increments; verifies imported IDs; and only then records completion. The original SQLite files are never deleted.

Test an App Store-style upgrade from Flutter `1.1.0 (4)` on a physical device before shipping `1.2.0 (5)`.
