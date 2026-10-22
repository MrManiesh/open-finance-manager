# 💰 Open Finance Manager

A modern, privacy-first personal and shared finance tracking application for Android built with **Flutter**. Manage multiple financial groups (Family, Friends, Business/Company, Daily Essentials), track incomes and expenses, split bills with partners, and auto-sync your data directly to your private **Google Drive**.

---

## ✨ Features

- 👥 **Multiple Finance Circles / Groups**:
  - Independent ledgers for **Family**, **Friends**, **Company**, **Milk & Daily Needs**, or custom circles.
  - Multi-partner support with quick-add suggestions (`Mom`, `Dad`, `Partner`, `Roommate`, `Colleague`, etc.) and bulk comma-separated adding.
- 💵 **Fast Income & Expense Tracking**:
  - Segmented `+ Income` / `- Expense` switcher.
  - Categories with icons, custom notes, timestamps, and formatted currencies (`₹`, `$`, `€`, `£`, `₨`, etc.).
- 🤝 **Dual Attribution & Bill Splitting**:
  - Distinguish between **Who Paid** and **Entered By** (record on behalf of another partner).
  - Split bills equally or with custom shares.
  - **"Who Owes Who" (Settlements)**: Automatic net balance calculation and WhatsApp-ready settlement summary sharing.
- ☁️ **Google Drive Auto-Sync**:
  - **Local-First**: Works 100% offline using SQLite (`open_finance_manager.db`).
  - Automatically syncs and backs up changes to your private Google Drive (`Open Finance Manager/open_finance_vault.json`).
  - Live status indicator (Drive Synced, Syncing, Offline).
  - Offline JSON backup export & restore.
- 📊 **Interactive Analytics**:
  - Category breakdown pie chart and comparative progress metrics.

---

## 🤖 CI / CD (GitHub Actions)

Every push to `main` automatically triggers our GitHub Action (`.github/workflows/build_apk.yml`) to:
1. Run static analysis (`flutter analyze`)
2. Run automated tests (`flutter test`)
3. Compile and build the Android Release APK (`OpenFinanceManager-APK`)
4. Upload the downloadable `.apk` artifact directly to the GitHub Actions tab.

---

## 📱 Local Build & Development

```bash
# Get dependencies
flutter pub get

# Run tests & analysis
flutter test
flutter analyze

# Run on connected device / emulator
flutter run

# Build release APK
flutter build apk --release --no-tree-shake-icons
```
