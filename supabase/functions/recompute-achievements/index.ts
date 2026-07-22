// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TMDB_API_KEY = Deno.env.get("TMDB_API_KEY") || Deno.env.get("tmdb_proxy_key");
const TMDB_BASE = "https://api.themoviedb.org/3";

// ---- Helpers ----

const SEASONAL_IDS = new Set(["halloween", "christmas", "summer_vacation"]);

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

function parsePgArray(raw: any): string[] {
  if (!raw) return [];
  if (Array.isArray(raw)) return raw.map(String).filter(Boolean);
  if (typeof raw === "string") {
    const cleaned = raw.replace(/[{}"]/g, "").trim();
    if (!cleaned) return [];
    return cleaned.split(",").map((s) => s.trim()).filter(Boolean);
  }
  return [];
}

function episodeIsValid(row: any): boolean {
  const ep = row?.episode_number;
  if (ep == null) return false;
  const n = typeof ep === "number" ? ep : parseInt(String(ep), 10);
  return !isNaN(n) && n > 0;
}

// ---- TMDB ----

const tmdbCache = new Map<string, any>();

async function tmdbFetch(path: string): Promise<any> {
  const cached = tmdbCache.get(path);
  if (cached) return cached;

  if (!TMDB_API_KEY) throw new Error("TMDB_API_KEY not configured");
  const url = `${TMDB_BASE}${path}${path.includes("?") ? "&" : "?"}api_key=${TMDB_API_KEY}`;
  const res = await fetch(url, {
    headers: { Accept: "application/json", "User-Agent": "NextUp/1.0" },
  });
  if (!res.ok) throw new Error(`TMDB ${res.status}: ${path}`);
  const data = await res.json();
  tmdbCache.set(path, data);
  return data;
}

async function getShowDetails(tmdbId: number) {
  return tmdbFetch(`/tv/${tmdbId}`);
}

async function getMovieDetails(tmdbId: number) {
  return tmdbFetch(`/movie/${tmdbId}`);
}

// ---- Activity stats (mirror of UserActivityStats.fromHistory) ----

interface ActivityStats {
  totalShows: number;
  totalMovies: number;
  totalEpisodes: number;
  totalHours: number;
  longestStreak: number;
  currentStreak: number;
  isNightOwl: boolean;
  isEarlyBird: boolean;
  watchedInOctober: boolean;
  watchedInDecember: boolean;
  watchedInSummer: boolean;
  genreCounts: Record<string, number>;   // distinct titles per genre
  countryCounts: Record<string, number>; // distinct titles per country
  watchlistCount: number;
  favoriteCount: number;
}

async function computeStats(
  history: any[],
  watchlist: any[],
  favorites: any[]
): ActivityStats {
  const showIds = new Set<string>();
  const movieIds = new Set<string>();
  let totalEpisodes = 0;
  const monthlyWatched: Record<string, number> = {};
  const showEpisodeCounts: Record<string, number> = {};
  const dayOfWeekCounts: Record<number, number> = {};
  const hourCounts: Record<number, number> = {};
  const activeDays = new Set<string>();
  let isNightOwl = false;
  let isEarlyBird = false;
  let watchedInOctober = false;
  let watchedInDecember = false;
  let watchedInSummer = false;

  for (const item of history) {
    const tmdbId = item.tmdb_id?.toString();
    const mediaType = item.media_type ?? "tv";
    if (mediaType === "tv") {
      if (tmdbId) showIds.add(tmdbId);
      if (episodeIsValid(item)) {
        totalEpisodes++;
        if (tmdbId) showEpisodeCounts[tmdbId] = (showEpisodeCounts[tmdbId] ?? 0) + 1;
      }
    } else {
      if (tmdbId) movieIds.add(tmdbId);
    }
    if (item.watched_at) {
      const d = new Date(item.watched_at);
      if (!isNaN(d.getTime())) {
        const mk = `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
        monthlyWatched[mk] = (monthlyWatched[mk] ?? 0) + 1;
        dayOfWeekCounts[d.getUTCDay()] = (dayOfWeekCounts[d.getUTCDay()] ?? 0) + 1;
        hourCounts[d.getUTCHours()] = (hourCounts[d.getUTCHours()] ?? 0) + 1;
        const dayKey = `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}-${String(d.getUTCDate()).padStart(2, "0")}`;
        activeDays.add(dayKey);
        if (d.getUTCHours() >= 0 && d.getUTCHours() < 4) isNightOwl = true;
        if (d.getUTCHours() >= 5 && d.getUTCHours() < 7) isEarlyBird = true;
        if (d.getUTCMonth() + 1 === 10) watchedInOctober = true;
        if (d.getUTCMonth() + 1 === 12) watchedInDecember = true;
        if (d.getUTCMonth() + 1 >= 6 && d.getUTCMonth() + 1 <= 8) watchedInSummer = true;
      }
    }
  }

  const totalShows = showIds.size;
  const totalMovies = movieIds.size;
  const totalHours = Math.floor((totalEpisodes * 45 + totalMovies * 120) / 60);

  // Longest streak
  const sortedDays = [...activeDays].sort();
  let longestStreak = 0;
  let tempStreak = 1;
  for (let i = 1; i < sortedDays.length; i++) {
    const prev = new Date(sortedDays[i - 1]);
    const curr = new Date(sortedDays[i]);
    const diff = (curr.getTime() - prev.getTime()) / 86400000;
    if (diff === 1) tempStreak++;
    else { if (tempStreak > longestStreak) longestStreak = tempStreak; tempStreak = 1; }
  }
  if (tempStreak > longestStreak) longestStreak = tempStreak;

  // Current streak
  const now = new Date();
  let currentStreak = 0;
  for (let i = 0; i < 365; i++) {
    const cd = new Date(now.getTime() - i * 86400000);
    const ck = `${cd.getUTCFullYear()}-${String(cd.getUTCMonth() + 1).padStart(2, "0")}-${String(cd.getUTCDate()).padStart(2, "0")}`;
    if (activeDays.has(ck)) currentStreak++;
    else if (i > 0) break;
  }

  // Genres: prefer denormalized columns (distinct title keys)
  const genreTitleSets: Record<string, Set<string>> = {};
  const countryTitleSets: Record<string, Set<string>> = {};
  const missingMeta: Array<{ tmdbId: number; mediaType: string; key: string }> = [];
  const seenTitles = new Set<string>();

  for (const item of history) {
    const tmdbId = item.tmdb_id;
    const mediaType = item.media_type ?? "tv";
    if (tmdbId == null) continue;
    const titleKey = `${mediaType}:${tmdbId}`;
    if (seenTitles.has(titleKey)) continue;
    seenTitles.add(titleKey);

    const genres = parsePgArray(item.genres);
    const countries = parsePgArray(item.origin_countries);

    if (genres.length === 0 && countries.length === 0) {
      missingMeta.push({ tmdbId: Number(tmdbId), mediaType, key: titleKey });
      continue;
    }
    for (const g of genres) {
      if (!genreTitleSets[g]) genreTitleSets[g] = new Set();
      genreTitleSets[g].add(titleKey);
    }
    for (const c of countries) {
      if (!countryTitleSets[c]) countryTitleSets[c] = new Set();
      countryTitleSets[c].add(titleKey);
    }
  }

  // Fetch missing from TMDB (cap 30)
  let genreFetchOk = 0;
  for (const row of missingMeta.slice(0, 30)) {
    try {
      const data = row.mediaType === "tv"
        ? await getShowDetails(row.tmdbId)
        : await getMovieDetails(row.tmdbId);
      genreFetchOk++;
      const genres: string[] = (data.genres ?? []).map((g: any) => g.name).filter(Boolean);
      let countries: string[] = [];
      if (row.mediaType === "tv") {
        countries = (data.origin_country ?? []).map(String);
      } else {
        countries = (data.production_countries ?? []).map((c: any) => c.iso_3166_1).filter(Boolean);
      }
      for (const g of genres) {
        if (!genreTitleSets[g]) genreTitleSets[g] = new Set();
        genreTitleSets[g].add(row.key);
      }
      for (const c of countries) {
        if (!countryTitleSets[c]) countryTitleSets[c] = new Set();
        countryTitleSets[c].add(row.key);
      }
      await sleep(80); // rate limit
    } catch (_) { /* skip */ }
  }

  const genreCounts: Record<string, number> = {};
  for (const [g, s] of Object.entries(genreTitleSets)) genreCounts[g] = s.size;
  const countryCounts: Record<string, number> = {};
  for (const [c, s] of Object.entries(countryTitleSets)) countryCounts[c] = s.size;

  return {
    totalShows,
    totalMovies,
    totalEpisodes,
    totalHours,
    longestStreak,
    currentStreak,
    isNightOwl,
    isEarlyBird,
    watchedInOctober,
    watchedInDecember,
    watchedInSummer,
    genreCounts,
    countryCounts,
    watchlistCount: watchlist.length,
    favoriteCount: favorites.length,
  };
}

// ---- Achievement rules (mirror of _buildAchievements) ----

interface AchievementRule {
  id: string;
  xpReward: number;
  evaluate: (s: ActivityStats) => boolean;
  current: (s: ActivityStats) => number;
}

const ACHIEVEMENTS: AchievementRule[] = [
  { id: "first_episode", xpReward: 10, evaluate: (s) => s.totalEpisodes >= 1, current: (s) => s.totalEpisodes },
  { id: "binge_master", xpReward: 25, evaluate: (s) => s.totalEpisodes >= 50, current: (s) => s.totalEpisodes },
  { id: "marathon_monster", xpReward: 50, evaluate: (s) => s.totalEpisodes >= 200, current: (s) => s.totalEpisodes },
  { id: "night_owl", xpReward: 15, evaluate: (s) => s.isNightOwl, current: (s) => s.isNightOwl ? 1 : 0 },
  { id: "early_bird", xpReward: 15, evaluate: (s) => s.isEarlyBird, current: (s) => s.isEarlyBird ? 1 : 0 },
  { id: "daily_streak", xpReward: 30, evaluate: (s) => s.longestStreak >= 7, current: (s) => s.longestStreak },
  { id: "monthly_streak", xpReward: 100, evaluate: (s) => s.longestStreak >= 30, current: (s) => s.longestStreak },
  { id: "year_streak", xpReward: 500, evaluate: (s) => s.longestStreak >= 365, current: (s) => s.longestStreak },
  { id: "movie_maniac", xpReward: 100, evaluate: (s) => s.totalMovies >= 100, current: (s) => s.totalMovies },
  { id: "series_addict", xpReward: 100, evaluate: (s) => s.totalShows >= 50, current: (s) => s.totalShows },
  { id: "episode_hunter", xpReward: 250, evaluate: (s) => s.totalEpisodes >= 1000, current: (s) => s.totalEpisodes },
  { id: "action_lover", xpReward: 15, evaluate: (s) => (s.genreCounts["Action"] ?? 0) >= 5, current: (s) => s.genreCounts["Action"] ?? 0 },
  { id: "comedy_expert", xpReward: 15, evaluate: (s) => (s.genreCounts["Comedy"] ?? 0) >= 5, current: (s) => s.genreCounts["Comedy"] ?? 0 },
  { id: "scifi_explorer", xpReward: 15, evaluate: (s) => (s.genreCounts["Science Fiction"] ?? 0) >= 5, current: (s) => s.genreCounts["Science Fiction"] ?? 0 },
  { id: "fantasy_wizard", xpReward: 15, evaluate: (s) => (s.genreCounts["Fantasy"] ?? 0) >= 5, current: (s) => s.genreCounts["Fantasy"] ?? 0 },
  { id: "crime_detective", xpReward: 15, evaluate: (s) => (s.genreCounts["Crime"] ?? 0) >= 5, current: (s) => s.genreCounts["Crime"] ?? 0 },
  { id: "horror_survivor", xpReward: 20, evaluate: (s) => (s.genreCounts["Horror"] ?? 0) >= 5, current: (s) => s.genreCounts["Horror"] ?? 0 },
  { id: "romance_expert", xpReward: 15, evaluate: (s) => (s.genreCounts["Romance"] ?? 0) >= 5, current: (s) => s.genreCounts["Romance"] ?? 0 },
  { id: "genre_explorer", xpReward: 30, evaluate: (s) => Object.keys(s.genreCounts).length >= 5, current: (s) => Object.keys(s.genreCounts).length },
  { id: "hollywood_tourist", xpReward: 15, evaluate: (s) => (s.countryCounts["US"] ?? 0) >= 5, current: (s) => s.countryCounts["US"] ?? 0 },
  { id: "korean_fan", xpReward: 20, evaluate: (s) => (s.countryCounts["KR"] ?? 0) >= 5, current: (s) => s.countryCounts["KR"] ?? 0 },
  { id: "anime_world", xpReward: 20, evaluate: (s) => (s.countryCounts["JP"] ?? 0) >= 5, current: (s) => s.countryCounts["JP"] ?? 0 },
  { id: "first_save", xpReward: 10, evaluate: (s) => s.watchlistCount >= 1, current: (s) => s.watchlistCount },
  { id: "collector", xpReward: 25, evaluate: (s) => s.watchlistCount >= 10, current: (s) => s.watchlistCount },
  { id: "wishlist_king", xpReward: 100, evaluate: (s) => s.watchlistCount >= 100, current: (s) => s.watchlistCount },
  { id: "first_favorite", xpReward: 10, evaluate: (s) => s.favoriteCount >= 1, current: (s) => s.favoriteCount },
  { id: "favorites_10", xpReward: 25, evaluate: (s) => s.favoriteCount >= 10, current: (s) => s.favoriteCount },
  { id: "favorites_50", xpReward: 100, evaluate: (s) => s.favoriteCount >= 50, current: (s) => s.favoriteCount },
  { id: "hours_10", xpReward: 10, evaluate: (s) => s.totalHours >= 10, current: (s) => s.totalHours },
  { id: "hours_100", xpReward: 50, evaluate: (s) => s.totalHours >= 100, current: (s) => s.totalHours },
  { id: "hours_500", xpReward: 100, evaluate: (s) => s.totalHours >= 500, current: (s) => s.totalHours },
  { id: "hours_1000", xpReward: 250, evaluate: (s) => s.totalHours >= 1000, current: (s) => s.totalHours },
  { id: "unique_50", xpReward: 30, evaluate: (s) => (s.totalShows + s.totalMovies) >= 50, current: (s) => s.totalShows + s.totalMovies },
  { id: "unique_100", xpReward: 50, evaluate: (s) => (s.totalShows + s.totalMovies) >= 100, current: (s) => s.totalShows + s.totalMovies },
  { id: "unique_500", xpReward: 250, evaluate: (s) => (s.totalShows + s.totalMovies) >= 500, current: (s) => s.totalShows + s.totalMovies },
  { id: "pizza_movies", xpReward: 15, evaluate: (s) => s.totalMovies >= 10, current: (s) => s.totalMovies },
  { id: "cry_baby", xpReward: 15, evaluate: (s) => (s.genreCounts["Drama"] ?? 0) >= 10, current: (s) => s.genreCounts["Drama"] ?? 0 },
  // Seasonal — based on watched_at evidence
  { id: "halloween", xpReward: 25, evaluate: (s) => s.watchedInOctober, current: (s) => s.watchedInOctober ? 1 : 0 },
  { id: "christmas", xpReward: 25, evaluate: (s) => s.watchedInDecember, current: (s) => s.watchedInDecember ? 1 : 0 },
  { id: "summer_vacation", xpReward: 15, evaluate: (s) => s.watchedInSummer, current: (s) => s.watchedInSummer ? 1 : 0 },
];

// ---- User recompute ----

async function recomputeUser(
  admin: any,
  tmdb: typeof tmdbFetch,
  userId: string
): Promise<{ unlocked: number; newUnlocks: number; removed: number; backfilled: number }> {
  // 1. Backfill genres (up to 50)
  let backfilled = 0;
  const { data: missingRows } = await admin
    .from("watch_history")
    .select("tmdb_id, media_type")
    .eq("user_id", userId)
    .or("genres.is.null,genres.eq.{}")
    .limit(50);

  if (missingRows?.length) {
    const seen = new Set<string>();
    for (const row of missingRows) {
      const tmdbId = row.tmdb_id;
      const mt = row.media_type ?? "tv";
      const key = `${tmdbId}:${mt}`;
      if (!tmdbId || seen.has(key)) continue;
      seen.add(key);
      try {
        const data = mt === "tv" ? await getShowDetails(tmdbId) : await getMovieDetails(tmdbId);
        const genres: string[] = (data.genres ?? []).map((g: any) => g.name).filter(Boolean);
        let countries: string[] = [];
        if (mt === "tv") {
          countries = (data.origin_country ?? []).map(String);
        } else {
          countries = (data.production_countries ?? []).map((c: any) => c.iso_3166_1).filter(Boolean);
        }
        if (genres.length || countries.length) {
          await admin.from("watch_history").update({ genres, origin_countries: countries })
            .eq("user_id", userId).eq("tmdb_id", tmdbId).eq("media_type", mt);
          backfilled++;
        }
        await sleep(80);
      } catch (_) { /* skip */ }
    }
  }

  // 2. Fetch data
  const [historyRes, watchlistRes, favoritesRes, persistedRes] = await Promise.all([
    admin.from("watch_history").select("*").eq("user_id", userId),
    admin.from("watchlist").select("*").eq("user_id", userId),
    admin.from("favorites").select("*").eq("user_id", userId),
    admin.from("user_achievements").select("achievement_id, xp_awarded").eq("user_id", userId),
  ]);

  const history = historyRes.data ?? [];
  const watchlist = watchlistRes.data ?? [];
  const favorites = favoritesRes.data ?? [];
  const persisted = persistedRes.data ?? [];

  // 3. Compute stats
  const stats = computeStats(history, watchlist, favorites);

  // 4. Rule-based unlocks
  const ruleUnlocked = new Map<string, number>();
  for (const ach of ACHIEVEMENTS) {
    if (ach.evaluate(stats)) ruleUnlocked.set(ach.id, ach.xpReward);
  }

  // 5. Persisted map
  const persistedMap = new Map<string, number>();
  for (const row of persisted) {
    if (row.achievement_id) persistedMap.set(row.achievement_id, row.xp_awarded ?? 0);
  }

  // 6. Cleanup seasonal (wrong ones)
  let removed = 0;
  for (const sid of SEASONAL_IDS) {
    if (persistedMap.has(sid) && !ruleUnlocked.has(sid)) {
      await admin.from("user_achievements").delete()
        .eq("user_id", userId).eq("achievement_id", sid);
      persistedMap.delete(sid);
      removed++;
    }
  }

  // 7. Final unlocks = persisted ∪ newly rule-unlocked (never revoke non-seasonal)
  const finalUnlocked = new Map(persistedMap);
  const newlyUnlocked: Array<{ achievement_id: string; xp_awarded: number }> = [];
  for (const [id, xp] of ruleUnlocked) {
    if (!finalUnlocked.has(id)) {
      finalUnlocked.set(id, xp);
      newlyUnlocked.push({ achievement_id: id, xp_awarded: xp });
    }
  }

  // 8. Hidden completionist
  const nonCompletionistUnlocked = [...finalUnlocked.keys()].filter((k) => k !== "hidden_completionist").length;
  if (nonCompletionistUnlocked >= 20 && !finalUnlocked.has("hidden_completionist")) {
    finalUnlocked.set("hidden_completionist", 100);
    newlyUnlocked.push({ achievement_id: "hidden_completionist", xp_awarded: 100 });
  }

  // 9. Insert new unlocks
  if (newlyUnlocked.length > 0) {
    const rows = newlyUnlocked.map((u) => ({
      user_id: userId,
      achievement_id: u.achievement_id,
      xp_awarded: u.xp_awarded,
    }));
    await admin.from("user_achievements").upsert(rows, { onConflict: "user_id,achievement_id" });
  }

  // 10. Recalculate XP + level on profile
  const totalXp = [...finalUnlocked.values()].reduce((s, v) => s + v, 0);
  const level = Math.floor(totalXp / 100) + 1;
  await admin.from("profiles").update({ total_xp: totalXp, level }).eq("id", userId);

  return { unlocked: finalUnlocked.size, newUnlocks: newlyUnlocked.length, removed, backfilled };
}

// ---- Main handler ----

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-recompute-secret",
      },
    });
  }

  const corsHeaders: Record<string, string> = {
    "Access-Control-Allow-Origin": "*",
    "Content-Type": "application/json",
  };

  try {
    const secret = req.headers.get("x-recompute-secret");
    const expectedSecret = Deno.env.get("RECOMPUTE_SECRET");
    if (expectedSecret && secret !== expectedSecret) {
      return new Response(JSON.stringify({ error: "Invalid secret" }), { status: 401, headers: corsHeaders });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceKey);

    const body = await req.json().catch(() => ({}));
    const userId: string | undefined = body.user_id;
    const cursor: string | undefined = body.cursor;
    const batchSize: number = Math.min(body.batchSize ?? 10, 25);

    // Single user mode (dry-run / specific user)
    if (userId) {
      const result = await recomputeUser(admin, tmdbFetch, userId);
      return new Response(JSON.stringify({ done: true, users: [userId], result }), { status: 200, headers: corsHeaders });
    }

    // Batch mode
    let query = admin.from("profiles").select("id").order("id", { ascending: true }).limit(batchSize);
    if (cursor) query = query.gt("id", cursor);

    const { data: users, error } = await query;
    if (error) throw error;
    if (!users || users.length === 0) {
      return new Response(JSON.stringify({ done: true, message: "All users processed" }), { status: 200, headers: corsHeaders });
    }

    const results: Array<{ userId: string; result: any }> = [];
    for (const u of users) {
      try {
        const result = await recomputeUser(admin, tmdbFetch, u.id);
        results.push({ userId: u.id, result });
      } catch (e: any) {
        results.push({ userId: u.id, result: { error: e.message ?? "unknown" } });
      }
    }

    const lastId = users[users.length - 1].id;
    const hasMore = users.length === batchSize;

    return new Response(
      JSON.stringify({
        done: !hasMore,
        cursor: hasMore ? lastId : null,
        processed: users.length,
        results,
      }),
      { status: 200, headers: corsHeaders }
    );
  } catch (e: any) {
    return new Response(
      JSON.stringify({ error: e.message ?? "Internal server error" }),
      { status: 500, headers: corsHeaders }
    );
  }
});
