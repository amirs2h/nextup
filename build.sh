#!/bin/bash
# Cloudflare Pages Build Script for Flutter Web

# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Verify Flutter
flutter --version
flutter doctor

# Get dependencies
flutter pub get

# Build for web with WASM
flutter build web --release --wasm \
  --dart-define=TMDB_API_KEY=$TMDB_API_KEY \
  --dart-define=OMDB_API_KEY=$OMDB_API_KEY \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

echo "Build complete!"
