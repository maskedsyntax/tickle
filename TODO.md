# TODO List — Tickle Counter App Development

Below is the structured checklist for building the Tickle app. This file tracks our development progress.

## Phase 1: Workspace & Core Configuration
- [x] Initialize Root Workspace
  - [x] Create root `pubspec.yaml` defining the Dart workspace
  - [x] Create `.gitignore` if not present or configure it for Flutter
- [x] Implement `packages/tickle_core`
  - [x] Initialize core package with `pubspec.yaml`
  - [x] Define the `Counter` data model (properties: title, emoji, colorHex, currentCount, goalValue, etc.)
  - [x] Define the `CounterLog` data model (properties: timestamp, actionType, resultingCount, delta)
  - [x] Create the `CountersRepository` abstract interface
- [x] Implement `packages/tickle_data`
  - [x] Initialize data package with `pubspec.yaml` (dependencies: drift, sqlite3_flutter_libs, path_provider)
  - [x] Define Drift tables (`CountersTable`, `CounterLogsTable`) and schema
  - [x] Run `build_runner` code generator to generate database code
  - [x] Implement the `DriftCountersRepository` class conforming to the core interface

## Phase 2: Mobile Application Foundation (`apps/tickle_mobile`)
- [x] Initialize Mobile App
  - [x] Run `flutter create` to initialize the mobile client
  - [x] Set up `pubspec.yaml` dependencies (flutter_bloc, fl_chart, intl, path, local workspace references)
- [x] Setup State Management
  - [x] Implement `CountersCubit` (CRUD operations, archiving, sorting/reordering counters)
  - [x] Implement `CounterDetailCubit` (incrementing, decrementing, logging, and loading history logs)
  - [x] Implement `StatsCubit` (statistics aggregation: streaks, daily/weekly/monthly averages, heatmap prep)
- [x] Build Design System & Adaptive Theme
  - [x] Implement custom fonts, color utilities (gradients, primary/secondary palettes)
  - [x] Design tactile micro-animations (spring scales, press shrink-and-expand)
  - [x] Define iOS Cupertino and Android Material 3 design variants (scaffold, navigation bars, page routes)

## Phase 3: Screens & Custom Interactions
- [x] Home Screen
  - [x] Clean list of active counters with modern visual cards
  - [x] Tap-to-increment interaction with satisfying haptic response and scale animation
  - [x] Swipe gestures (left to decrement/reset, right to edit/delete)
  - [x] Drag-and-drop list reordering
  - [x] Filter categories (All, Active, Archived)
- [x] Counter Detail Screen
  - [x] Display large, bold counts and dynamic circular goal progress ring
  - [x] Increment/decrement tactile buttons (ideal for thumb operation)
  - [x] Graph of historical metrics (last 7 days, last 30 days) using `fl_chart`
  - [x] Scrollable timeline of history logs (timestamp, count changes) with clear action option
- [x] Settings Screen
  - [x] Light / Dark / System theme configuration
  - [x] Haptic feedback intensity settings (Off / Light / Medium / Heavy)
  - [x] CSV / JSON data backup export and file restore import

## Phase 4: Polish, Haptics, and Native Quality
- [x] Integrate native iOS Haptics (Cupertino style) and standard Android vibration ticks
- [x] Fine-tune transitions and list animations for a lightweight, native look and feel
- [x] Verification and bug fixing on the iOS Simulator

---

## Phase 5: Verification & Launch
- [x] Run automated tests inside core, data, and mobile packages
- [x] Perform build verification on iOS Simulator
- [x] Final manual review of responsive UX layout

---

## Phase 6: Tickle Pro (Premium Features)
- [x] Implement `PremiumCubit` and Mock Paywall UI
  - [x] Add "Tickle Pro" section to Settings Screen
  - [x] Add state management for Pro status
- [ ] Implement Home Screen Widgets
  - [x] iOS WidgetKit implementation (SwiftUI) *(Note: Requires manual Xcode target linkage and App Group setup)*
  - [x] Android AppWidget implementation
  - [x] Flutter `home_widget` integration for DB reading
- [x] Implement Cloud Synchronization (Pro)
  - [x] iOS: iCloud Key-Value or CloudKit sync for SQLite
  - [x] Android: Google Drive sync
- [x] Implement Local Reminders (Pro)
  - [x] Setup `flutter_local_notifications`
  - [x] Add scheduling UI for daily nudges

---

## Phase 7: iOS App Store Launch Prep
- [x] In-App Purchase (Tickle Pro — $4.99 lifetime, non-consumable) — **iOS verified in sandbox**
  - [x] Wire RevenueCat `appl_` SDK key into `PremiumCubit` (iOS live, not mock)
  - [x] App Store Connect: Paid Apps agreement active
  - [x] App Store Connect: create non-consumable IAP `com.maskedsyntax.tickle.tickleMobile.pro_lifetime` ($4.99), **Ready to Submit**
  - [x] RevenueCat: App Store app config with `.p8` In-App Purchase key
  - [x] RevenueCat: register the product (Product ID matches)
  - [x] RevenueCat: attach the product to the `tickle_pro` **entitlement**
  - [x] RevenueCat: add the product as the **Lifetime** package in the **current** offering
  - [x] App Store Connect: create a **Sandbox tester** account
  - [x] Sandbox-test the real $4.99 purchase on device (paywall shows $4.99, purchase unlocks Pro)
  - [ ] (Android, later) add the `goog_` key + Play Console product
- [ ] App Store compliance
  - [x] Add app-level `PrivacyInfo.xcprivacy` (UserDefaults + file-timestamp reasons)
  - [ ] App Store Connect: fill the **App Privacy** questionnaire (declare RevenueCat purchase data) + add a **privacy policy URL**
  - [ ] Consider removing unused `NSPhotoLibraryUsageDescription` (backup import uses the document picker)
- [ ] Build & submit
  - [ ] Verify iCloud container + App Groups are on the App ID and in the **distribution** provisioning profiles (Runner + widget)
  - [ ] Bump build number; archive a **Release** build and run **Validate** in Xcode Organizer
  - [ ] App Store Connect: screenshots, description, keywords, age rating
  - [ ] Submit the app **with** the IAP attached to the version

