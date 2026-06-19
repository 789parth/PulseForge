# ⚡ PulseForge

A premium, offline-first fitness tracking app built with **Flutter**, featuring a high-performance glassmorphic UI, custom charts, and robust database state management.

---

## 🚀 Key Features

* **Live Activity Tracking** — Simulates steps, active minutes, calories, and distance tracking in real-time.
* **Workout Logger** — Track workout sessions (Gym, Running, Yoga, Cycling) with note attachments and flexible calorie manual override.
* **Goal Setting** — Customize daily step and calorie targets with real-time progress visualizers.
* **Advanced Analytics** — Weekly calorie bar charts, step line charts, and monthly overviews.
* **Personalized Settings** — System-wide dark/light mode toggle and custom haptic feedback toggles.

---

## 🛠️ Technology Stack & Architecture

PulseForge follows a **feature-first clean architecture** for modular development:

* **State Management**: [Riverpod](https://pub.dev/packages/flutter_riverpod) (Notifier, FutureProvider, StateNotifier)
* **Routing**: [GoRouter](https://pub.dev/packages/go_router) (Indexed stacks, shell routes, root nav guards)
* **Local Database**: [Drift](https://pub.dev/packages/drift) (SQLite) with custom indexing and database migrations (Version 2)
* **Graphics & Rendering**: GPU-accelerated custom painters (no heavy third-party chart dependencies, keeping app bundle size extremely lightweight)

```
lib/
├── core/           # Database, router, themes, constants, custom widgets
└── features/       # Modular features containing presentation, domain, and data layers
    ├── activity/   # Step tracking & daily goals progress
    ├── analytics/  # Progress tracking charts
    ├── dashboard/  # Main overview hub
    ├── goals/      # Target metrics setting
    ├── settings/   # App settings toggles
    └── workout/    # Logs, history, details, and addition forms
```

---

## ⚡ Performance Optimizations

* **Impeller Renderer** enabled for smooth 60/120fps UI animations.
* Granular **RepaintBoundaries** placed around dynamic canvas painters (charts, progress rings, shimmers) to isolate repaint overlays.
* GPU-driven animation curves with cached `Paint` objects and pre-allocated `TextPainter`s.
* **Isolates** via Flutter's `compute` method for complex weekly analytics calculation.

---

## 🏁 Getting Started

Clone the repository and run the following commands:

```bash
# Get dependencies
flutter pub get

# Generate database schema models
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```
