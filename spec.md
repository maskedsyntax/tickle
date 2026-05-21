# Tickle — Product Specification

> "Count anything. Instantly."

Version: 0.1  
Platform Targets:
- iOS
- Android
- Apple Watch (future)
- Wear OS (future)

---

# 1. Overview

Tickle is a minimal yet powerful counter application designed for quickly tracking repeated actions, events, habits, sessions, and occurrences.

The app focuses on:
- instant interaction
- low friction
- tactile feedback
- offline reliability
- beautiful simplicity

Unlike traditional habit trackers, Tickle is event-first.

Users should be able to:
- open the app
- tap once
- close the app

within seconds.

At the same time, power users can organize counters, analyze trends, and sync across devices.

---

# 2. Core Philosophy

## Principles

### Fast
The app should feel instantaneous.

### Calm
No clutter, noise, or aggressive productivity pressure.

### Tactile
Interactions should feel satisfying through animation, haptics, and motion.

### Offline First
Everything should work without internet.

### Native Feeling
The UI should feel at home on both iOS and Android.

---

# 3. Use Cases

Users may use Tickle for:

- workout reps
- meditation sessions
- water intake
- habit occurrences
- study sessions
- mistakes/slips
- sobriety tracking
- prayers/mantras
- attendance counting
- inventory counting
- meeting tallies
- breathing exercises
- pain/symptom tracking
- custom repetitive actions

---

# 4. MVP Features

## 4.1 Counters

Users can:
- create counters
- rename counters
- delete counters
- duplicate counters
- reorder counters
- archive counters

Each counter includes:
- title
- optional emoji/icon
- accent color
- current count
- created date
- optional goal

---

## 4.2 Counting

Supported actions:
- increment
- decrement
- reset
- long press for rapid count
- swipe gestures

Interaction goals:
- minimal latency
- satisfying haptic feedback
- smooth animations

---

## 4.3 History

Every counter action is logged.

Each log stores:
- timestamp
- action type
- resulting count

Users can:
- view history
- clear history
- filter by day/week/month

---

## 4.4 Statistics

Basic insights:
- daily totals
- weekly totals
- monthly totals
- streaks
- peak days
- average counts

Visualizations:
- bar graphs
- activity heatmaps
- streak indicators

---

## 4.5 Widgets

Initial widgets:
- single counter widget
- quick increment widget
- compact lock screen widget (iOS)

---

## 4.6 Backup & Sync

Phase 1:
- local storage only

Phase 2:
- iCloud sync
- Google backup support

---

# 5. Future Features

## Watch Apps

### Apple Watch
- wrist tap counting
- complications
- quick counters
- haptics optimized for watch

### Wear OS
- quick tiles
- tap gestures
- complications

---

## Smart Features

Potential future ideas:
- voice counting
- Siri shortcuts
- AI-generated insights
- location-based counters
- NFC triggers
- recurring reset schedules

---

# 6. Design Language

## Aesthetic

The UI should feel:
- soft
- tactile
- breathable
- lightweight

Inspirations:
- Apple Health
- Gentler Streak
- Things
- Arc Search
- Not Boring apps

---

## Visual Direction

### Shapes
- rounded corners
- soft cards
- floating surfaces

### Motion
- subtle spring animations
- responsive scaling
- tactile press feedback

### Typography
- large readable counts
- strong visual hierarchy
- minimal labels

---

# 7. UX Goals

## One-Hand Friendly

The app should be extremely easy to use with one thumb.

---

## Low Cognitive Load

Users should never feel overwhelmed.

Avoid:
- excessive charts
- too many tabs
- unnecessary setup flows

---

## Instant Access

Target:
- tap within 2 seconds of app launch

---

# 8. Navigation Structure

## Bottom Navigation

### Home
List of counters

### Insights
Statistics and history

### Settings
Preferences and backups

---

# 9. Counter Detail Screen

Displays:
- current count
- increment/decrement controls
- graph/history
- notes
- streaks
- goal progress

---

# 10. Technical Stack

## Mobile

Recommended:
- Flutter

Reason:
- fast cross-platform iteration
- smooth animations
- future watch support
- single codebase

Alternative:
- React Native

---

# 11. Storage

Recommended:
- SQLite

Potential abstraction:
- Drift (Flutter)

Requirements:
- fast local reads
- offline reliability
- history persistence

---

# 12. Performance Goals

- app launch under 1 second
- counter interaction under 16ms
- low battery usage
- smooth 60fps animations

---

# 13. Monetization

Potential premium features:
- unlimited counters
- advanced insights
- cloud sync
- themes
- custom icons
- export functionality
- watch support

No ads.

---

# 14. App Store Positioning

Tickle is not just a "number button."

It is positioned as:
- a personal event tracker
- a repetition logger
- a minimal habit utility
- a tactile counting experience

The app should feel intentional and polished enough to avoid "minimum functionality" concerns.

---

# 15. Possible Differentiators

- best-in-class interaction quality
- tactile animations
- beautiful widgets
- ultra-fast counting
- watch-first workflows
- timeline/history system
- calm UI with zero clutter

---

# 16. Risks

## Oversimplicity

Risk:
Apple may consider the app too trivial.

Mitigation:
- widgets
- history
- analytics
- multi-counter system
- polished UX
- sync
- watch integration roadmap

---

# 17. Potential App Names

Current:
- Tickle

Possible future alternatives:
- Tally
- Tick
- Countly
- Taps
- PulseCount
- Pebble
- LoopCount

---

# 18. Success Criteria

A successful v1 should:
- feel delightful
- work instantly
- encourage repeated daily usage
- become a utility users open multiple times daily

---

# 19. Long-Term Vision

Tickle aims to become the simplest and most delightful way to track repeated actions across phones, watches, widgets, and ambient devices.
