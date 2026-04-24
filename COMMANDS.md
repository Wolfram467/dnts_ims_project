# Command Reference

## Setup Commands

```bash
# Install dependencies
flutter pub get

# Clean build (if needed)
flutter clean
flutter pub get

# Run on web
flutter run -d chrome

# Run on specific device
flutter devices              # List available devices
flutter run -d <device-id>   # Run on specific device
```

## Testing Commands

```bash
# Run with verbose logging
flutter run -d chrome --verbose

# Hot reload (while app is running)
# Press 'r' in terminal

# Hot restart (while app is running)
# Press 'R' in terminal

# Quit app (while running)
# Press 'q' in terminal
```

## Debug Commands

```bash
# Check Flutter doctor
flutter doctor

# Check Flutter version
flutter --version

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Check for outdated packages
flutter pub outdated
```

## Browser DevTools (for Web)

When running on web, open browser DevTools:
- **Chrome/Edge**: Press `F12` or `Ctrl+Shift+I`
- **Console tab**: See print statements
- **Application tab**: View localStorage (SharedPreferences data)

## In-App Actions

### Map Screen Toolbar
- **Zoom Out**: Click 🔍- button
- **Zoom In**: Click 🔍+ button
- **Refresh**: Click 🔄 button (reload Supabase data)
- **Seed Data**: Click ☁️ button (run seed script)
- **List Data**: Click 📋 button (list stored data)

### Desk Interaction
- **Click any desk**: View workstation details
- **Check terminal**: See query logs
- **Check modal**: See asset data

## Terminal Output Commands

All print statements go to:
- **IDE Debug Console**: Check your IDE's debug/console panel
- **Terminal**: If running from command line
- **Browser Console**: If running on web (F12 → Console)

## Storage Management

### View Storage (Web)
1. Open browser DevTools (F12)
2. Go to **Application** tab
3. Expand **Local Storage**
4. Click on your app's URL
5. Look for keys starting with `flutter.workstation_`

### Clear Storage (Web)
1. Open browser DevTools (F12)
2. Go to **Application** tab
3. Right-click **Local Storage** → **Clear**
4. Or use the app's clear function (if implemented)

### View Storage (Android)
```bash
# Using adb
adb shell
run-as com.example.dnts_ims
cd shared_prefs
cat FlutterSharedPreferences.xml
```

### View Storage (iOS)
```bash
# Using Xcode
# Window → Devices and Simulators → Select device → View container
```

## Quick Test Sequence

```bash
# 1. Start app
flutter run -d chrome

# 2. In app:
#    - Navigate to Map
#    - Click ☁️ (seed)
#    - Click 📋 (list)
#    - Click desk L5_T01

# 3. Check terminal for:
#    - Seed confirmation
#    - List output
#    - Desk click logs
```

## Useful Shortcuts

### While App is Running
- `r` - Hot reload
- `R` - Hot restart
- `q` - Quit
- `h` - Help
- `d` - Detach (keep app running)
- `c` - Clear screen
- `v` - Open DevTools

### VS Code
- `Ctrl+Shift+P` - Command palette
- `F5` - Start debugging
- `Shift+F5` - Stop debugging
- `Ctrl+F5` - Run without debugging

### Android Studio
- `Shift+F10` - Run
- `Shift+F9` - Debug
- `Ctrl+F2` - Stop

## Troubleshooting Commands

```bash
# If build fails
flutter clean
flutter pub get
flutter run -d chrome

# If dependencies conflict
flutter pub upgrade
flutter pub get

# If cache issues
flutter pub cache repair

# If platform issues (web)
flutter config --enable-web
flutter create .
flutter run -d chrome

# Check for issues
flutter doctor -v
flutter analyze
```

## Package-Specific Commands

```bash
# Check shared_preferences version
flutter pub deps | grep shared_preferences

# Update shared_preferences
flutter pub upgrade shared_preferences

# Add shared_preferences (if not added)
flutter pub add shared_preferences
```

## Git Commands (if using version control)

```bash
# Check status
git status

# Stage changes
git add .

# Commit changes
git commit -m "Wire Map UI to local storage"

# View changes
git diff

# View commit history
git log --oneline
```

## Performance Profiling

```bash
# Run with performance overlay
flutter run -d chrome --profile

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Then in browser, connect to running app
```

## Common Issues & Fixes

### Issue: "flutter: command not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Or on Windows (PowerShell)
$env:Path += ";C:\path\to\flutter\bin"
```

### Issue: "Waiting for another flutter command to release the startup lock"
```bash
# Kill the lock file
rm -rf /path/to/flutter/bin/cache/lockfile

# Or on Windows
del C:\path\to\flutter\bin\cache\lockfile
```

### Issue: "Unable to locate Android SDK"
```bash
# Set ANDROID_HOME
export ANDROID_HOME=/path/to/android/sdk

# Or on Windows
set ANDROID_HOME=C:\path\to\android\sdk
```

### Issue: Web not enabled
```bash
flutter config --enable-web
flutter create .
```

## Quick Reference Card

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Run on web | `flutter run -d chrome` |
| Hot reload | Press `r` |
| Hot restart | Press `R` |
| Quit | Press `q` |
| Clean build | `flutter clean` |
| Check issues | `flutter doctor` |
| View logs | Check IDE console or browser DevTools |
| Seed data | Click ☁️ in app |
| List data | Click 📋 in app |
| View storage | Browser DevTools → Application → Local Storage |
