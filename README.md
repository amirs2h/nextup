# NextUp - Track Your Favorite Shows & Movies

A Flutter app for tracking TV shows and movies with social features.

## 🚀 Deploy to Cloudflare Pages

### Prerequisites
1. Create a free [Cloudflare account](https://dash.cloudflare.com/sign-up)
2. Install [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/)

### Option 1: Deploy via Cloudflare Dashboard (Recommended)
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/) → Pages
2. Click "Create a project" → "Connect to Git"
3. Connect your GitHub account
4. Select the `nextup` repository
5. Configure build settings:
   - **Build command:** `flutter build web --release --dart-define=TMDB_API_KEY=$TMDB_API_KEY --dart-define=OMDB_API_KEY=$OMDB_API_KEY --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY`
   - **Output directory:** `build/web`
6. Add Environment Variables in Settings:
   - `TMDB_API_KEY`
   - `OMDB_API_KEY`
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
7. Click "Save and Deploy"

### Option 2: Deploy via Wrangler CLI
```bash
# Install Wrangler
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Build
flutter build web --release --dart-define=TMDB_API_KEY=YOUR_KEY --dart-define=OMDB_API_KEY=YOUR_KEY --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_KEY

# Deploy
wrangler pages deploy build/web --project-name=nextup
```

### Option 3: Push to GitHub (Auto-deploy)
1. Push code to GitHub
2. Cloudflare Pages will auto-deploy on every push

## 📱 Install as PWA

### iOS (Safari)
1. Open the app URL in Safari
2. Tap the Share button
3. Tap "Add to Home Screen"
4. Tap "Add"

### Android (Chrome)
1. Open the app URL in Chrome
2. Tap the menu (3 dots)
3. Tap "Add to Home screen"
4. Tap "Add"

## 🔧 Environment Variables

| Variable | Description |
|----------|-------------|
| `TMDB_API_KEY` | TMDB API key for movie/show data |
| `OMDB_API_KEY` | OMDB API key for Rotten Tomatoes ratings |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key |

## 📦 Tech Stack

- **Frontend:** Flutter
- **Backend:** Supabase
- **State Management:** BLoC/Cubit
- **Routing:** GoRouter
- **Hosting:** Cloudflare Pages
