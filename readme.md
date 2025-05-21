# EasyHabit

[中文版](https://github.com/cherishh/minimal-habit-tracker/blob/main/readme_CN.md)

**Version:** 0.1

EasyHabit is a minimalist habit tracking app for iOS, designed to help you build and maintain routines using a GitHub contributions-style heatmap. At its core, EasyHabit offers a clean interface and intuitive controls, making it simple to manage and visualize your progress.

## Key Features

* **Habit Management**:
    * Create, edit, and delete habits with ease.
    * Customize each habit with a name, Emoji, and color theme.
    * Two habit types to suit your needs:
        * **Checkbox**: A simple tap to mark as done (e.g., "Daily Breakfast").
        * **Count**: Set a daily target and check in multiple times (e.g., "Drink X Glasses of Water").
    * Organize your habits by sorting the list.
* **Widgets - A Core Experience**:
    * Track selected habits directly from your Home Screen with a heatmap widget.
    * Log habit completion químicafrom the widget – no need to open the app.
    * Add multiple habit widgets and swipe through them using an iOS widget stack.
* **Visual Tracking**:
    * The main list view displays habits as cards, each with a mini heatmap of recent activity.
    * Dive into the details page for a full-year, GitHub-style heatmap and a monthly calendar view for easy logging and review.
* **Progress Statistics**:
    * The details page shows total days logged, longest streak, and current streak.
    * Heatmaps and calendar views provide an at-a-glance understanding of your consistency and completion.
* **UI & UX**:
    * Supports Light and Dark Mode, and can follow your system's appearance settings.
    * Choose from a variety of preset color themes to personalize each habit.
    * Designed with simplicity and ease-of-use in mind for an intuitive experience.
    * Localized for Chinese, English, Japanese, Russian, Spanish, German, and French.
* **Data Management**:
    * All your data is stored locally on your device.
    * Export all habits and check-in records to a CSV file for backup.
    * Import data from a CSV file to restore backups or migrate from another app.

## Tech Stack

* **UI Framework**: SwiftUI
* **State Management**: `@EnvironmentObject` and `@StateObject` for managing the core `HabitStore`.
* **Data Persistence**:
    * Habit and log data are serialized using the `Codable` protocol and stored in `UserDefaults` (shared with the widget via an App Group).
    * User settings (theme, language) are also saved using `UserDefaults` (`@AppStorage`).
* **WidgetKit**: Powers the iOS Home Screen widget, including data display and interactions.
* **AppIntents**: Handles widget interactions, like checking in a habit.
* **Localization**: Implemented using a custom `LanguageManager` and structured translation files.

## Setup and Running the Project

1.  **Configure App Group**:
    * To enable data sharing between the main app and the widget (via `UserDefaults`), you'll need to set up an App Group in Xcode for both the app target and the widget extension target.
    * Detailed instructions can be found in the `AppGroup_Setup.md` file in this repository.
    * The App Group ID is `group.com.xi.HabitTracker.minimal-habit-tracker`.
2.  **Build and Run**:
    * Open the project in Xcode.
    * Ensure your signing and App Group configurations are correct.
    * Select the main app target (`minimal habit tracker`) or the widget extension target (`mid-widgetExtension`).
    * Choose a simulator or a connected physical device.
    * Click the "Build and Run" (play) button.

## Project Directory Overview

* `minimal habit tracker/`: Main application source code.
    * `Models/`: Core data models (e.g., `Habit.swift`, `HabitLog.swift`, `HabitStore.swift`, `ColorTheme.swift`).
    * `Views/`: SwiftUI views composing the app's UI (e.g., `ContentView.swift`, `HabitDetailView.swift`, `NewHabitView.swift`, `SettingsView.swift`).
    * `Languages/`: Localization files, including `LanguageManager.swift` and translation structs for each language.
    * `Assets.xcassets/`: Asset catalog for the main app (icons, images).
* `mid-widget/`: Widget extension source code.
    * `mid_widget.swift`: Core widget logic, including the `Provider`, `Entry`, view (`HabitWidgetEntryView`), and `CheckInHabitIntent`.
    * `mid_widgetBundle.swift`: Widget Bundle definition.
    * `Assets.xcassets/`: Asset catalog for the widget.
* `AppGroup_Setup.md`: Guide for configuring App Groups.
* `emojis.md`: A reference list of Emojis potentially used in the project.
* `prd.md`: Product Requirements Document for the planned iCloud sync feature.
* `spec.md`: Technical specifications for the planned iCloud sync feature.

## Todos / Future Enhancements

-   [ ] Invite a buddy feature
-   [ ] Implement Pro version features
-   [ ] Cloud data synchronization (iCloud)
-   [ ] Auto-scroll heatmap to the current date as the last column
-   [ ] Set daily reminders for check-ins
-   [ ] Optimize longest streak calculation (max 365 days, can span across years)
-   [ ] Audio feedback/features
-   [ ] Notion synchronization
-   [ ] Note-taking functionality for habits

## Contributing

Suggestions and bug reports are welcome! Please feel free to contribute by submitting an Issue or Pull Request.

---

**Developer**: 图蜥 (Tuxi)