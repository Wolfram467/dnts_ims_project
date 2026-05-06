# DNTS Inventory Management System (IMS)

## 🚀 Quick Start - Map Storage Setup

The Map UI is wired to permanent local storage. Follow these steps to get started:

### 1️⃣ Add Your Data
Open `lib/seed_lab5_data.dart` and paste your workstation data into the `workstationData` Map (line ~13).

### 2️⃣ Run the App
```bash
flutter pub get
flutter run -d chrome
```

### 3️⃣ Test It
- Go to **Interactive Map**
- Click ☁️ button (Seed data)
- Click any **Lab 5** desk
- Check terminal for output: `✅ Found in local storage: ...`

---

## 📚 Project Documentation

Detailed documentation has been organized into the following categories in the `docs/` folder:

*   **[Architecture Guide](docs/ARCHITECTURE.md)**: System design, database schema, and technical specifications.
*   **[User Guides](docs/USER_GUIDES.md)**: Visual guides, keyboard shortcuts, and step-by-step instructions for adding data.
*   **[Implementation History](docs/IMPLEMENTATION_HISTORY.md)**: A complete log of all completed phases, features, and technical milestones.
*   **[Developer Notes](docs/DEV_NOTES.md)**: Technical notes, bug fixes, and verification checklists.

---

## 🎯 Quick Reference

### Core Files
*   `lib/seed_lab5_data.dart`: **Add your workstation data here.**
*   `lib/screens/interactive_map_screen.dart`: Main map logic and drag-and-drop implementation.
*   `GEMINI.md`: Project-specific coding standards and naming conventions.
*   `COMMANDS.md`: Useful CLI commands for development.

### UI Buttons
| Button | Function |
|--------|----------|
| ☁️ | **Seed data** (Click after adding data) |
| 📊 | Toggle Spreadsheet/Map view |
| 📋 | List stored data (Debug) |
| 🔄 | Refresh data |

---

## 🛠️ Tech Stack
*   **Framework**: Flutter (Web)
*   **State Management**: Provider
*   **Storage**: Shared Preferences (Local) / Supabase (Remote)
*   **Styling**: Minimalist Black/White Aesthetic

---

For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/).
