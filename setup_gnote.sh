#!/usr/bin/env bash
# ============================================================
# GNOTE — SETUP SCRIPT
#
# Usage:
#   chmod +x setup_gnote.sh
#   ./setup_gnote.sh
#
# What this does:
#   1. Scaffolds a new Flutter project called gnote
#   2. Copies lib/ files from this package into the project
#   3. Copies pubspec.yaml (replaces generated one)
#   4. Copies supabase/schema.sql
#   5. Runs flutter pub get
#   6. Runs build_runner (generates *.g.dart adapters)
#   7. Prints the Going Live checklist
#
# Prerequisites:
#   - Flutter 3.19+ installed and on PATH
#   - Dart 3.3+ (comes with Flutter)
#   - Run this script from the directory containing gnote_src/
# ============================================================

set -e

PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="gnote"
PROJECT_DIR="$PACKAGE_DIR/$PROJECT_NAME"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         GNOTE SETUP                  ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── Step 1: Flutter scaffold ──────────────────────────────────
echo "▶ 1/6  Scaffolding Flutter project..."
if [ -d "$PROJECT_DIR" ]; then
  echo "   ⚠  '$PROJECT_DIR' already exists — skipping flutter create."
  echo "   Delete the folder and re-run to start fresh."
else
  flutter create \
    --org com.gnote \
    --project-name gnote \
    --platforms android,ios,web \
    "$PROJECT_DIR"
  echo "   ✅ Flutter project created."
fi

# ── Step 2: Copy lib/ ─────────────────────────────────────────
echo ""
echo "▶ 2/6  Copying lib/ source files..."
rm -rf "$PROJECT_DIR/lib"
cp -r "$PACKAGE_DIR/lib" "$PROJECT_DIR/lib"
echo "   ✅ lib/ copied."

# ── Step 3: pubspec.yaml ──────────────────────────────────────
echo ""
echo "▶ 3/6  Replacing pubspec.yaml..."
cp "$PACKAGE_DIR/pubspec.yaml" "$PROJECT_DIR/pubspec.yaml"
echo "   ✅ pubspec.yaml replaced."

# ── Step 4: Supabase schema ───────────────────────────────────
echo ""
echo "▶ 4/6  Copying Supabase schema..."
mkdir -p "$PROJECT_DIR/supabase"
cp "$PACKAGE_DIR/supabase/schema.sql" "$PROJECT_DIR/supabase/schema.sql"
echo "   ✅ supabase/schema.sql copied."
echo "   ⚠  Remember to run this in the Supabase SQL editor."

# ── Step 5: flutter pub get ───────────────────────────────────
echo ""
echo "▶ 5/6  Installing packages (flutter pub get)..."
cd "$PROJECT_DIR"
flutter pub get
echo "   ✅ Packages installed."

# ── Step 6: build_runner ──────────────────────────────────────
echo ""
echo "▶ 6/6  Running build_runner (generates *.g.dart)..."
dart run build_runner build --delete-conflicting-outputs
echo "   ✅ Hive adapters generated."

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  SETUP COMPLETE                                          ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Project:  $PROJECT_DIR"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  GOING LIVE CHECKLIST                                    ║"
echo "║                                                          ║"
echo "║  SUPABASE                                                ║"
echo "║  □ Run supabase/schema.sql in Supabase SQL editor        ║"
echo "║  □ Uncomment Supabase.initialize() in lib/main.dart      ║"
echo "║  □ Add dart-define flags to run/build:                   ║"
echo "║    --dart-define=SUPABASE_URL=https://xxx.supabase.co    ║"
echo "║    --dart-define=SUPABASE_ANON_KEY=eyJ...                ║"
echo "║                                                          ║"
echo "║  MOCK FLAGS (flip one at a time)                         ║"
echo "║  □ core/router.dart          kRouterMockMode = false     ║"
echo "║  □ pages/anchor_page.dart    kMockMode = false           ║"
echo "║  □ pages/capture_page.dart   kMockMode = false           ║"
echo "║  □ pages/habit_page.dart     kMockMode = false           ║"
echo "║  □ pages/daily3_page.dart    _kMock = false              ║"
echo "║  □ pages/responsibility_page.dart  _kMock = false        ║"
echo "║  □ pages/login_page.dart     _kMock = false              ║"
echo "║  □ pages/signup_page.dart    _kMock = false              ║"
echo "║  □ pages/profile_page.dart   _kMock = false              ║"
echo "║  □ pages/add_tasks.dart      _kMock = false              ║"
echo "║  □ pages/add_persons.dart    _kMock = false              ║"
echo "║                                                          ║"
echo "║  PLATFORM                                                ║"
echo "║  □ AndroidManifest.xml — add INTERNET permission         ║"
echo "║  □ AndroidManifest.xml — add whatsapp intent-filter      ║"
echo "║  □ Info.plist (iOS) — add whatsapp to LSApplicationQueriesSchemes ║"
echo "║                                                          ║"
echo "║  NOTIFICATIONS                                           ║"
echo "║  □ After login: call NotificationService.scheduleAll()   ║"
echo "║  □ Sign out: NotificationService.cancelAll() ✅ (done)   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "To run the app (mock mode — no Supabase needed):"
echo "  cd $PROJECT_DIR"
echo "  flutter run"
echo ""
