#!/bin/bash
# Cloudflare Pages Build Script for Flutter Web

set -e

FLUTTER_DIR="flutter"

# Install Flutter (skip if already exists and working)
if [ ! -d "$FLUTTER_DIR/bin" ]; then
  rm -rf "$FLUTTER_DIR"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:$(pwd)/$FLUTTER_DIR/bin"

# Verify Flutter
flutter --version

# Get dependencies
flutter pub get

# Build for web
# pwa-strategy=none: no aggressive service-worker shell cache (users get updates without clear-cache)
flutter build web --release \
  --pwa-strategy=none \
  --dart-define=TMDB_API_KEY="$TMDB_API_KEY" \
  --dart-define=OMDB_API_KEY="$OMDB_API_KEY" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

# Preserve custom headers for Cloudflare Pages
if [ -f "web/_headers" ]; then
  cp web/_headers /tmp/nextup_headers
fi

# Copy build output to web/ directory (Cloudflare Pages reads from here)
rm -rf web/*
cp -r build/web/* web/

if [ -f /tmp/nextup_headers ]; then
  cp /tmp/nextup_headers web/_headers
fi

# Ensure version.json is never missing
if [ -f build/web/version.json ]; then
  cp build/web/version.json web/version.json
fi

echo "Build complete!"
cat web/version.json 2>/dev/null || true
