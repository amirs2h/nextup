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
flutter build web --release \
  --dart-define=TMDB_API_KEY="$TMDB_API_KEY" \
  --dart-define=OMDB_API_KEY="$OMDB_API_KEY" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

# Copy build output to web/ directory (Cloudflare Pages reads from here)
rm -rf web/*
cp -r build/web/* web/

echo "Build complete!"
