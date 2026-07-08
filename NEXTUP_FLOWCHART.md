# NextUp - فلوچارت کامل و مستندات برنامه

## 📋 فهرست مطالب
1. [معماری کلی](#معماری-کلی)
2. [فلوچارت احراز هویت](#فلوچارت-احراز-هویت)
3. [فلوچارت ردیابی سریال/فیلم](#فلوچارت-ردیابی)
4. [فلوچارت وضعیت‌ها](#فلوچارت-وضعیت‌ها)
5. [فلوچارت اجتماعی](#فلوچارت-اجتماعی)
6. [فلوچارت کشف و جستجو](#فلوچارت-کشف)
7. [ساختار دیتابیس](#ساختار-دیتابیس)
8. [لیست باگ‌های شناسایی شده](#باگ‌ها)
9. [وضعیت پیاده‌سازی ویژگی‌ها](#وضعیت-ویژگی‌ها)

---

## معماری کلی

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                          │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (Pages + Widgets)                       │
│  ├── Home, Search, Discover, Watchlist, Profile             │
│  ├── Show Detail, Movie Detail, Episode Detail              │
│  ├── Comments, Notifications, Settings                      │
│  └── Shared Widgets (GlassContainer, AppBackground, etc.)   │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer (Cubits/BLoC)                                 │
│  ├── AuthCubit, HomeCubit, SearchCubit                      │
│  ├── WatchlistCubit, DiscoverCubit                          │
│  ├── ShowDetailCubit, MovieDetailCubit                      │
│  ├── ProfileCubit, CommentsCubit                            │
│  └── NotificationsCubit, StatsCubit, etc.                   │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Services)                                      │
│  ├── SupabaseService (Auth, DB, Storage)                    │
│  ├── TmdbService (TMDB API with proxy)                      │
│  └── OmdbService (OMDB API for RT ratings)                  │
├─────────────────────────────────────────────────────────────┤
│  Backend                                                    │
│  ├── Supabase (Auth, Postgres, Edge Functions, Storage)     │
│  ├── TMDB API (Movie/Show data)                             │
│  └── OMDB API (Rotten Tomatoes ratings)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## فلوچارت احراز هویت

```
شروع برنامه
    │
    ▼
┌─────────────┐
│ Splash Page  │ (2 ثانیه انیمیشن)
└──────┬──────┘
       │
       ▼
┌─────────────────┐     بله      ┌──────────────┐
│ Session موجود؟  │─────────────│ Home Page    │
└──────┬──────────┘              └──────────────┘
       │ خیر
       ▼
┌─────────────────┐
│ Onboarding      │ (اولین اجرا)
│ انتخاب ژانرها   │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ Login Page      │
│ ┌─────────────┐ │
│ │ Email/Pass  │ │
│ │ Google OAuth│ │
│ │ Register    │ │
│ └─────────────┘ │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐     بله      ┌──────────────┐
│ موفق؟           │─────────────│ Home Page    │
└──────┬──────────┘              └──────────────┘
       │ خیر
       ▼
┌─────────────────┐
│ نمایش خطا       │
└─────────────────┘
```

---

## فلوچارت ردیابی سریال/فیلم

```
صفحه سریال/فیلم
    │
    ▼
┌─────────────────────────────────────────┐
│ نمایش اطلاعات:                         │
│ - عنوان، خلاصه، امتیاز                 │
│ - IMDB، Rotten Tomatoes                 │
│ - بازیگران، تریلر، پلتفرم‌ها           │
└──────┬──────────────────────────────────┘
       │
       ├─── [Add to Watchlist] ──► ذخیره در watchlist
       │                              │
       │                              ▼
       │                    ┌──────────────────┐
       │                    │ وضعیت: watchlist  │
       │                    └──────────────────┘
       │
       ├─── [Mark Watched] ───► ذخیره در watch_history
       │                              │
       │                              ▼
       │                    ┌──────────────────┐
       │                    │ محاسبه وضعیت خودکار│
       │                    └──────────────────┘
       │
       ├─── [Rate] ──────────► ذخیره در ratings
       │
       ├─── [Favorite] ─────► ذخیره در favorites
       │
       └─── [Comments] ─────► صفحه کامنت‌ها
```

---

## فلوچارت وضعیت‌ها (Status)

```
اضافه کردن سریال به واچ‌لیست
    │
    ▼
┌──────────────┐
│  watchlist   │ (پیش‌فرض)
└──────┬───────┘
       │
       │ اولین اپیزود دیده شد
       ▼
┌──────────────┐
│  watching    │
└──────┬───────┘
       │
       ├─── همه اپیزودها دیده شد + سریال Ended
       │         │
       │         ▼
       │   ┌──────────────┐
       │   │  completed   │
       │   └──────────────┘
       │
       ├─── همه اپیزودهای پخش شده دیده شد + سریال ادامه دارد
       │         │
       │         ▼
       │   ┌──────────────┐
       │   │  up_to_date  │
       │   └──────────────┘
       │
       └─── کاربر دستی متوقف کرد
                 │
                 ▼
           ┌──────────────┐
           │   stopped    │
           └──────────────┘

فیلم:
  watchlist ──[Mark Watched]──► completed
```

**منطق خودکار (computeAndSetShowStatus):**
```dart
if (watchedCount == 0) → watchlist
else if (watchedCount >= totalEpisodes && totalEpisodes > 0)
    if (showStatus == 'Ended' || 'Canceled') → completed
    else → up_to_date
else → watching
```

---

## فلوچارت اجتماعی

```
┌─────────────────────────────────────────────────────┐
│                    کاربر A                           │
└──────┬──────────────────────────────────────────────┘
       │
       ├─── Follow ────────► کاربر B
       │                      │
       │                      ▼
       │              ┌───────────────┐
       │              │ Notification  │
       │              │ "A شما رو     │
       │              │  دنبال کرد"   │
       │              └───────────────┘
       │
       ├─── Activity Feed ◄── نمایش فعالیت دنبال‌شوندگان
       │
       ├─── Shared Lists ──► لیست‌های مشترک
       │                      │
       │                      ├── اعضا اضافه/حذف
       │                      └── آیتم‌ها اضافه/حذف
       │
       └─── Rankings ──────► رتبه‌بندی ساعت تماشا
```

---

## فلوچارت کشف و جستجو

```
┌─────────────────────────────────────────────────────┐
│                    Search / Discover                  │
└──────┬──────────────────────────────────────────────┘
       │
       ├─── Search Page
       │    │
       │    ├── جستجوی سریال (TMDB API)
       │    ├── جستجوی فیلم (TMDB API)
       │    └── جستجوی کاربر (Supabase)
       │
       └─── Discover Page
            │
            ├── فیلتر نوع (TV/Movie)
            ├── فیلتر وضعیت سریال (Returning/Ended/Canceled)
            ├── فیلتر مرتب‌سازی (Popular/Newest/Highest Rated)
            ├── فیلتر سال
            ├── فیلتر امتیاز
            └── فیلتر ژانر
```

---

## ساختار دیتابیس

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   profiles   │     │  watchlist   │     │watch_history │
│──────────────│     │──────────────│     │──────────────│
│ id (UUID)    │◄────│ user_id (FK) │     │ user_id (FK) │
│ username     │     │ tmdb_id      │     │ tmdb_id      │
│ email        │     │ media_type   │     │ media_type   │
│ avatar_url   │     │ status       │     │ season_num   │
│ bio          │     │ list_name    │     │ episode_num  │
│ is_public    │     │ added_at     │     │ watched_at   │
│ language     │     └──────────────┘     └──────────────┘
│ theme        │
└──────┬───────┘     ┌──────────────┐     ┌──────────────┐
       │             │  favorites   │     │   comments   │
       │             │──────────────│     │──────────────│
       │             │ user_id (FK) │     │ user_id (FK) │
       │             │ tmdb_id      │     │ tmdb_id      │
       │             │ media_type   │     │ media_type   │
       │             └──────────────┘     │ content      │
       │                                  │ season_num   │
       │     ┌──────────────┐             │ episode_num  │
       │     │   follows    │             │ created_at   │
       │     │──────────────│             └──────────────┘
       │     │ follower_id  │
       │     │ following_id │     ┌──────────────┐
       │     └──────────────┘     │   ratings    │
       │                          │──────────────│
       │     ┌──────────────┐     │ user_id (FK) │
       │     │  reactions   │     │ tmdb_id      │
       │     │──────────────│     │ media_type   │
       │     │ user_id (FK) │     │ rating       │
       │     │ tmdb_id      │     │ season_num   │
       │     │ emoji        │     │ episode_num  │
       │     │ season_num   │     └──────────────┘
       │     │ episode_num  │
       │     └──────────────┘     ┌──────────────┐
       │                          │notifications │
       │     ┌──────────────┐     │──────────────│
       │     │comment_likes │     │ user_id (FK) │
       │     │──────────────│     │ type         │
       │     │ user_id (FK) │     │ title        │
       │     │ comment_id   │     │ body         │
       │     └──────────────┘     │ data (JSONB) │
       │                          │ is_read      │
       │     ┌──────────────┐     └──────────────┘
       │     │custom_lists  │
       │     │──────────────│     ┌──────────────┐
       │     │ user_id (FK) │     │custom_list   │
       │     │ name         │     │   _items     │
       │     │ description  │     │──────────────│
       │     │ is_public    │     │ list_id (FK) │
       │     └──────────────┘     │ tmdb_id      │
       │                          │ media_type   │
       │     ┌──────────────┐     └──────────────┘
       │     │shared_lists  │
       │     │──────────────│     ┌──────────────┐
       │     │ creator_id   │     │shared_list   │
       │     │ name         │     │  _members    │
       │     │ description  │     │──────────────│
       │     └──────────────┘     │ list_id (FK) │
       │                          │ user_id (FK) │
       │     ┌──────────────┐     │ role         │
       │     │character     │     └──────────────┘
       │     │  _votes      │
       │     │──────────────│     ┌──────────────┐
       │     │ user_id (FK) │     │shared_list   │
       │     │ person_id    │     │   _items     │
       │     │ tmdb_id      │     │──────────────│
       │     │ character    │     │ list_id (FK) │
       │     │ vote_type    │     │ tmdb_id      │
       │     └──────────────┘     │ media_type   │
       │                          │ added_by     │
       └──────────────────────────└──────────────┘
```

---

## باگ‌های شناسایی شده

### 🔴 بحرانی (نیاز به رفع فوری)

| # | فایل | مشکل |
|---|------|-------|
| 1 | `main.dart:84` | Stream subscription هرگز لغو نمی‌شه → memory leak |
| 2 | `main.dart:95` | `dispose()` بعد از unmount به `context.read` دسترسی داره → crash |
| 3 | `tmdb_service.dart:30` | زبان فقط در حالت proxy کار می‌کنه |
| 4 | `supabase_service.dart:236` | upsert با season/episode null ممکنه fail بشه |

### 🟡 متوسط

| # | فایل | مشکل |
|---|------|-------|
| 5 | `activity_cubit.dart:136` | `DateTime.parse` بدون null check |
| 6 | `show_detail_cubit.dart:163` | کدگذاری اپیزود `sn*1000` شکننده |
| 7 | `notifications_cubit.dart:56` | دسترسی مستقیم به Supabase singleton |
| 8 | `episode_detail_page.dart:143` | خطای toggle watched بدون feedback |
| 9 | `modern_widgets.dart:250` | دکمه clear search واکنشی نیست |

### 🟢 کم‌اهمیت

| # | فایل | مشکل |
|---|------|-------|
| 10 | `stats_cubit.dart:17` | فیلد `topGenres` هرگز پر نمی‌شه |
| 11 | `person_cubit.dart:3` | import بدون استفاده |
| 12 | `calendar_cubit.dart:66` | محدودیت ۱۰ نمایش |
| 13 | چندین فایل | `print()` دیباگ در کد production |
| 14 | چندین فایل | رنگ‌های hardcoded به جای AppColors |

---

## وضعیت ویژگی‌ها

| ویژگی | وضعیت | توضیح |
|-------|-------|-------|
| احراز هویت Email/Password | ✅ کامل | ثبت‌نام، ورود، بازیابی رمز |
| احراز هویت Google | ✅ کامل | Supabase OAuth |
| واچ‌لیست | ✅ کامل | اضافه/حذف، فیلتر وضعیت |
| وضعیت خودکار | ✅ کامل | watching/completed/up_to_date |
| علاقه‌مندی‌ها | ✅ کامل | اضافه/حذف، نمایش در پروفایل |
| تاریخچه تماشا | ✅ کامل | ثبت خودکار، نمایش در پروفایل |
| امتیازدهی | ✅ کامل | سریال/فیلم/اپیزود |
| امتیازات خارجی | ✅ کامل | IMDB، Rotten Tomatoes |
| کامنت‌ها | ✅ کامل | اضافه/حذف، لایک، اسپویلر |
| واکنش‌ها (Emoji) | ✅ کامل | روی اپیزودها |
| دنبال کردن | ✅ کامل | فالو/آنفالو |
| فعالیت (Activity) | ✅ کامل | فید فعالیت دنبال‌شوندگان |
| رتبه‌بندی | ✅ کامل | ساعت تماشا |
| آمار | ✅ کامل | نمودار ماهانه |
| دستاوردها | ✅ کامل | ۱۳ بج |
| تقویم | ✅ کامل | اپیزودهای آینده |
| به‌زودی | ✅ کامل | فیلم‌های آینده |
| کشف (Discover) | ✅ کامل | فیلتر ژانر/سال/امتیاز/وضعیت |
| جستجو | ✅ کامل | سریال/فیلم/کاربر |
| لیست‌های سفارشی | ✅ کامل | ایجاد/حذف، جستجوی اسمی |
| لیست‌های مشترک | ✅ کامل | اعضا، جستجوی اسمی |
| رأی‌گیری شخصیت‌ها | ✅ کامل | لایک/دیسلایک |
| آپلود آواتار | ✅ کامل | Supabase Storage |
| نوتیفیکیشن In-App | ✅ کامل | Realtime |
| Deep Linking | ✅ کامل | nextup:// scheme |
| RTL فارسی | ✅ کامل | Directionality |
| Glassmorphism UI | ✅ کامل | GlassContainer, GlassCard |
| حالت تاریک/روشن | ✅ کامل | با AppColors |
| اشتراک‌گذاری | ✅ کامل | share_plus |

---

## نتیجه‌گیری

**برنامه NextUp از نظر عملکردی کامل است.** تمام ویژگی‌های اصلی TV Time پیاده شده و برخی ویژگی‌ها (لیست‌های مشترک، امتیازات خارجی، رأی‌گیری شخصیت‌ها) فراتر از TV Time هستند.

**باگ‌های بحرانی شناسایی شده:** ۴ عدد که نیاز به رفع فوری دارند.

**پیشنهادات بهبود:**
1. رفع memory leak در main.dart
2. رفع مشکل زبان در حالت non-proxy
3. بهبود عملکرد تقویم (parallel API calls)
4. حذف print()های دیباگ
5. یکسان‌سازی رنگ‌های hardcoded با AppColors
