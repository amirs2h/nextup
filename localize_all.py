import pathlib
import re

# ============================================================
# STEP 1: Add missing keys to app_strings.dart
# ============================================================

app_strings_path = pathlib.Path('lib/core/localization/app_strings.dart')
content = app_strings_path.read_text(encoding='utf-8')

new_keys = """
  // ---- Missing keys for feature pages ----
  String get filters => _p('فیلترها', 'Filters');
  String get minimumRating => _p('حداقل امتیاز', 'Minimum Rating');
  String get loadingGenres => _p('در حال بارگذاری ژانرها...', 'Loading genres...');
  String get noEpisodesThisMonth => _p('قسمتی در این ماه نیست', 'No episodes this month');
  String get addShowsToSeeHere => _p('سریال‌ها را به لیست تماشا اضافه کنید تا اینجا ببینید', 'Add shows to your watchlist to see them here');
  String get today => _p('امروز', 'Today');
  String get checkYourEmail => _p('ایمیل خود را بررسی کنید', 'Check Your Email');
  String get failedToLoadComparison => _p('بارگذاری مقایسه ناموفق بود', 'Failed to load comparison');
  String get level => _p('سطح', 'Level');
  String levelN(int level) => _p('سطح $level', 'Level $level');
  String get noAchievementsYet => _p('هنوز دستاوردی نیست', 'No achievements yet');
  String get noSharedWatchHistory => _p('تاریخچه مشترکی نیست', 'No shared watch history yet');
  String youN(int count) => _p('شما · $count', 'You · $count');
  String get followPeopleToSeeActivity => _p('برای دیدن فعالیت افراد را دنبال کنید', 'Follow people to see their activity');
  String get noCustomListsYet => _p('هنوز لیست سفارشی نیست', 'No custom lists yet');
  String get createYourCollection => _p('مجموعه خود را بسازید', 'Create your own collection');
  String get friendRankings => _p('رده‌بندی دوستان', 'Friend Rankings');
  String get noRankingsYet => _p('هنوز رده‌بندی نیست', 'No rankings yet');
  String get followPeopleToSeeRankings => _p('برای دیدن رده‌بندی افراد را دنبال کنید', 'Follow people to see rankings');
  String get customList => _p('لیست سفارشی', 'Custom List');
  String get tapToAddShowsOrMovies => _p('برای افزودن سریال یا فیلم + را بزنید', 'Tap + to add shows or movies');
  String get removeItem => _p('حذف مورد', 'Remove Item');
  String removeFromListConfirm(String name) => _p('«$name» از این لیست حذف شود؟', 'Remove "$name" from this list?');
  String deleteListConfirm(String name) => _p('آیا از حذف «$name» مطمئن هستید؟ این کار غیرقابل بازگشت است.', 'Are you sure you want to delete "$name"? This cannot be undone.');
  String get biography => _p('بیوگرافی', 'Biography');
  String get knownFor => _p('معروف برای', 'Known For');
  String get noCommentsYet => _p('هنوز نظری نیست', 'No comments yet');
  String get beFirstToComment => _p('اولین نفر باشید!', 'Be the first to comment!');
  String get reply => _p('پاسخ', 'Reply');
  String get welcomeToNextUp => _p('به NextUp خوش آمدید!', 'Welcome to NextUp!');
  String get rateThisMovie => _p('به این فیلم امتیاز بدهید', 'Rate This Movie');
  String get rateThisShow => _p('به این سریال امتیاز بدهید', 'Rate This Show');
  String get similarMovies => _p('فیلم‌های مشابه', 'Similar Movies');
  String get similarShows => _p('سریال‌های مشابه', 'Similar Shows');
  String get reactions => _p('واکنش‌ها', 'Reactions');
  String get partOfCollection => _p('بخشی از مجموعه', 'Part of Collection');
  String get addToList => _p('افزودن به لیست', 'Add to List');
  String addToListConfirm(String title) => _p('«$title» را به لیست سفارشی اضافه کنید', 'Add "$title" to a custom list');
  String get allCaughtUp => _p('همه را دیدید!', 'All Caught Up!');
  String get watchedAllEpisodes => _p('همه قسمت‌ها را تماشا کرده‌اید', "You've watched all episodes");
  String get upNext => _p('بعدی', 'Up Next');
  String get seasons => _p('فصل‌ها', 'Seasons');
  String get allEpisodesMarked => _p('همه قسمت‌ها به‌عنوان تماشا شده علامت بخورد!', 'All episodes marked as watched!');
  String get watchStreak => _p('رکورد تماشا', 'Watch Streak');
  String bestN(int n) => _p('بهترین: $n', 'Best: $n');
  String get watchActivity => _p('فعالیت تماشا', 'Watch Activity');
  String get last6Months => _p('۶ ماه اخیر', 'Last 6 months');
  String get contentDistribution => _p('توزیع محتوا', 'Content Distribution');
  String get topGenres => _p('برترین ژانرها', 'Top Genres');
  String get insights => _p('نکات', 'Insights');
  String get nextUp => _p('NextUp', 'NextUp');
  String get sharedList => _p('لیست مشترک', 'Shared List');
  String get removeMember => _p('حذف عضو', 'Remove Member');
  String removeMemberConfirm(String username) => _p('$username از لیست حذف شود؟', 'Remove $username from the list?');
  String get noUsersFound => _p('کاربری یافت نشد', 'No users found');
  String get leaveListConfirm => _p('دیگر به این لیست دسترسی نخواهید داشت.', 'You will no longer have access to this list.');
  String get deleteListConfirmFull => _p('آیا مطمئن هستید؟ این کار لیست و همه موارد آن را برای همیشه حذف می‌کند.', 'Are you sure? This will permanently delete the list and all its items.');
  String get episodeNotFound => _p('قسمت یافت نشد', 'Episode not found');
  String get watchTogetherWithFriends => _p('با دوستان تماشا کنید', 'Watch together with friends');
  String get addMembers => _p('افزودن اعضا', 'Add Members');
  String selectedN(int n) => _p('انتخاب شده ($n)', 'Selected ($n)');
  String get unlocked => _p('باز شده', 'Unlocked');
  String get dontHaveAccount => _p('حساب کاربری ندارید؟ ', "Don't have an account? ");
"""

# Insert before the achievementTitle method
marker = "  // ---- Achievements ----"
if marker in content:
    content = content.replace(marker, new_keys + "\n" + marker)
    app_strings_path.write_text(content, encoding='utf-8')
    print("Added missing keys to app_strings.dart")
else:
    print("WARNING: Marker not found in app_strings.dart")

# ============================================================
# STEP 2: Process feature files
# ============================================================

def ensure_import(filepath, file_content):
    """Add AppStrings import if not present."""
    import_line = "import 'package:nextup/core/localization/app_strings.dart';"
    if 'app_strings.dart' in file_content:
        return file_content
    # Find the last import line
    lines = file_content.split('\n')
    last_import_idx = -1
    for i, line in enumerate(lines):
        if line.startswith("import '"):
            last_import_idx = i
    if last_import_idx >= 0:
        lines.insert(last_import_idx + 1, import_line)
        return '\n'.join(lines)
    return import_line + '\n' + file_content

def do_replacements(filepath, replacements):
    """Apply a list of (old, new) replacements to a file."""
    p = pathlib.Path(filepath)
    if not p.exists():
        print(f"  SKIP: {filepath} not found")
        return
    content = p.read_text(encoding='utf-8')
    content = ensure_import(filepath, content)
    count = 0
    for old, new in replacements:
        if old and old in content:
            content = content.replace(old, new, 1)
            count += 1
    p.write_text(content, encoding='utf-8')
    print(f"  {filepath}: {count} replacements")

# ---- filters_page.dart ----
do_replacements('lib/features/filters/presentation/pages/filters_page.dart', [
    ("Text('Filters',", "Text(AppStrings.of(context).filters,"),
    ("Text('Reset',", "Text(AppStrings.of(context).reset,"),
    ("Text('Minimum Rating',", "Text(AppStrings.of(context).minimumRating,"),
    ("Text('Loading genres...',", "Text(AppStrings.of(context).loadingGenres,"),
])

# ---- calendar_page.dart ----
do_replacements('lib/features/calendar/presentation/pages/calendar_page.dart', [
    ("Text('Calendar',", "Text(AppStrings.of(context).calendar,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('No episodes this month',", "Text(AppStrings.of(context).noEpisodesThisMonth,"),
    ("Text('Add shows to your watchlist to see them here',", "Text(AppStrings.of(context).addShowsToSeeHere,"),
    ("Text('Today',", "Text(AppStrings.of(context).today,"),
])

# ---- register_page.dart ----
do_replacements('lib/features/auth/presentation/pages/register_page.dart', [
    ("Text('Check Your Email',", "Text(AppStrings.of(context).checkYourEmail,"),
    ("const Text('Go to Login')", "Text(AppStrings.of(context).goToLogin)"),
])

# ---- compare_page.dart ----
do_replacements('lib/features/compare/presentation/pages/compare_page.dart', [
    ("Text('Failed to load comparison',", "Text(AppStrings.of(context).failedToLoadComparison,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("const Text('Go Back')", "Text(AppStrings.of(context).goBack)"),
    ("Text('Level',", "Text(AppStrings.of(context).level,"),
    ("Text('Stats',", "Text(AppStrings.of(context).stats,"),
    ("Text('Achievements',", "Text(AppStrings.of(context).achievements,"),
    ("Text('No achievements yet',", "Text(AppStrings.of(context).noAchievementsYet,"),
    ("Text('No shared watch history yet',", "Text(AppStrings.of(context).noSharedWatchHistory,"),
])

# ---- login_page.dart ----
do_replacements('lib/features/auth/presentation/pages/login_page.dart', [
    ("Text('Check Your Email',", "Text(AppStrings.of(context).checkYourEmail,"),
    ("const Text('Please enter your email first')", "Text(AppStrings.of(context).enterEmailFirst)"),
    ("const Text('Please enter a valid email')", "Text(AppStrings.of(context).enterValidEmail)"),
    ("const Text('Password reset email sent!')", "Text(AppStrings.of(context).passwordResetSent)"),
    ("const Text('Failed to send reset email. Please try again.')", "Text(AppStrings.of(context).failedToSendReset)"),
    ("Text('Or continue with',", "Text(AppStrings.of(context).orContinueWith,"),
    ("const Text('Coming soon!')", "Text(AppStrings.of(context).comingSoonSnackBar)"),
    ("const Text('Sign Up',", "Text(AppStrings.of(context).signUp,"),
])

# ---- activity_page.dart ----
do_replacements('lib/features/activity/presentation/pages/activity_page.dart', [
    ("Text('Activity',", "Text(AppStrings.of(context).activity,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('No activity yet',", "Text(AppStrings.of(context).noActivityYet,"),
    ("Text('Follow people to see their activity',", "Text(AppStrings.of(context).followPeopleToSeeActivity,"),
])

# ---- custom_lists_page.dart ----
do_replacements('lib/features/custom_lists/presentation/pages/custom_lists_page.dart', [
    ("Text('My Lists',", "Text(AppStrings.of(context).myLists,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('No custom lists yet',", "Text(AppStrings.of(context).noCustomListsYet,"),
    ("Text('Create your own collection',", "Text(AppStrings.of(context).createYourCollection,"),
])

# ---- rankings_page.dart ----
do_replacements('lib/features/rankings/presentation/pages/rankings_page.dart', [
    ("Text('Friend Rankings',", "Text(AppStrings.of(context).friendRankings,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('No rankings yet',", "Text(AppStrings.of(context).noRankingsYet,"),
    ("Text('Follow people to see rankings',", "Text(AppStrings.of(context).followPeopleToSeeRankings,"),
])

# ---- custom_list_detail_page.dart ----
do_replacements('lib/features/custom_lists/presentation/pages/custom_list_detail_page.dart', [
    ("Text('Custom List',", "Text(AppStrings.of(context).customList,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('No items yet',", "Text(AppStrings.of(context).noItemsYet,"),
    ("Text('Tap + to add shows or movies',", "Text(AppStrings.of(context).tapToAddShowsOrMovies,"),
    ("'Remove Item')", "AppStrings.of(context).removeItem)"),
    ("Text('Movies',", "Text(AppStrings.of(context).movies,"),
    ("const Text('Search failed. Please try again.')", "Text(AppStrings.of(context).searchFailed)"),
    ("Text('Search for shows or movies',", "Text(AppStrings.of(context).searchShowsOrMovies,"),
    ("const Text('Delete List',", "Text(AppStrings.of(context).deleteList,"),
    ("Text('This will permanently delete the list and all items',", "Text(AppStrings.of(context).deleteListWarning,"),
])

# ---- achievements_page.dart ----
do_replacements('lib/features/achievements/presentation/pages/achievements_page.dart', [
    ("Text('Achievements',", "Text(AppStrings.of(context).achievements,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('Unlocked',", "Text(AppStrings.of(context).unlocked,"),
])

# ---- person_detail_page.dart ----
do_replacements('lib/features/person/presentation/pages/person_detail_page.dart', [
    ("Text('Biography',", "Text(AppStrings.of(context).biography,"),
    ("Text('Known For',", "Text(AppStrings.of(context).knownFor,"),
    ("const Text('Failed to vote')", "Text(AppStrings.of(context).failedToVote)"),
])

# ---- watch_history_page.dart ----
do_replacements('lib/features/profile/presentation/pages/watch_history_page.dart', [
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('No watch history yet',", "Text(AppStrings.of(context).noWatchHistory,"),
    ("Text('Start watching to build your history',", "Text(AppStrings.of(context).startWatchingToBuildHistory,"),
    ("Text('Watch History',", "Text(AppStrings.of(context).watchHistory,"),
])

# ---- edit_profile_page.dart ----
do_replacements('lib/features/profile/presentation/pages/edit_profile_page.dart', [
    ("const Text('Profile updated successfully!')", "Text(AppStrings.of(context).profileUpdatedSuccessfully)"),
    ("Text('Edit Profile',", "Text(AppStrings.of(context).editProfile,"),
    ("Text('Tap to add header image',", "Text(AppStrings.of(context).tapToAddHeaderImage,"),
    ("Text('Cancel',", "Text(AppStrings.of(context).cancel,"),
    ("const Text('Avatar removed!')", "Text(AppStrings.of(context).avatarRemoved)"),
    ("const Text('Failed to remove avatar')", "Text(AppStrings.of(context).failedToRemoveAvatar)"),
    ("const Text('Header removed!')", "Text(AppStrings.of(context).headerRemoved)"),
    ("const Text('Failed to remove header')", "Text(AppStrings.of(context).failedToRemoveHeader)"),
    ("const Text('Avatar updated!')", "Text(AppStrings.of(context).avatarUpdated)"),
    ("const Text('Failed to upload avatar')", "Text(AppStrings.of(context).failedToUploadAvatar)"),
    ("const Text('Header image updated!')", "Text(AppStrings.of(context).headerImageUpdated)"),
    ("const Text('Failed to upload header image')", "Text(AppStrings.of(context).failedToUploadHeader)"),
    ("Text('Username',", "Text(AppStrings.of(context).usernameLabel,"),
    ("Text('Bio',", "Text(AppStrings.of(context).bio,"),
])

# ---- comments_page.dart ----
do_replacements('lib/features/comments/presentation/pages/comments_page.dart', [
    ("const Text('Comment is too long (max 500 characters)')", "Text(AppStrings.of(context).commentTooLong)"),
    ("Text('Comments',", "Text(AppStrings.of(context).comments,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('No comments yet',", "Text(AppStrings.of(context).noCommentsYet,"),
    ("Text('Be the first to comment!',", "Text(AppStrings.of(context).beFirstToComment,"),
    ("const Text('Failed to load replies')", "Text(AppStrings.of(context).failedToLoadReplies)"),
    ("const Text('Spoiler',", "Text(AppStrings.of(context).spoiler)"),
    ("Text('Reply',", "Text(AppStrings.of(context).reply,"),
    ("const Text('Delete Comment',", "Text(AppStrings.of(context).deleteComment,"),
    ("Text('Login to comment',", "Text(AppStrings.of(context).loginToComment,"),
])

# ---- user_profile_page.dart ----
do_replacements('lib/features/profile/presentation/pages/user_profile_page.dart', [
    ("const Text('Failed to update. Please try again.')", "Text(AppStrings.of(context).failedToUpdate)"),
    ("Text('Following',", "Text(AppStrings.of(context).following,"),
    ("Text('Not following anyone yet',", "Text(AppStrings.of(context).notFollowingAnyone,"),
    ("Text('Followers',", "Text(AppStrings.of(context).followers,"),
    ("Text('No followers yet',", "Text(AppStrings.of(context).noFollowers,"),
    ("Text('Could not load profile',", "Text(AppStrings.of(context).couldNotLoadProfile,"),
    ("Text('Check your internet connection and try again.',", "Text(AppStrings.of(context).checkConnection,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("const Text('Go Back')", "Text(AppStrings.of(context).goBack)"),
    ("Text('Compare Stats',", "Text(AppStrings.of(context).compareStats,"),
    ("Text('No activity yet',", "Text(AppStrings.of(context).noActivityYet,"),
    ("Text('This profile is private',", "Text(AppStrings.of(context).privateProfile,"),
    ("Text('Follow this user to see their content',", "Text(AppStrings.of(context).followToSeeContent,"),
    ("Text('See All',", "Text(AppStrings.of(context).seeAll,"),
])

# ---- onboarding_page.dart ----
do_replacements('lib/features/onboarding/presentation/pages/onboarding_page.dart', [
    ("const Text('Failed to save preferences')", "Text(AppStrings.of(context).failedToSavePreferences)"),
    ("Text('Welcome to NextUp!',", "Text(AppStrings.of(context).welcomeToNextUp,"),
    ("Text('Skip for now',", "Text(AppStrings.of(context).skipForNow,"),
])

# ---- movie_detail_page.dart ----
do_replacements('lib/features/movie/presentation/pages/movie_detail_page.dart', [
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('Rate This Movie',", "Text(AppStrings.of(context).rateThisMovie,"),
    ("Text('Overview',", "Text(AppStrings.of(context).overview,"),
    ("Text('Cast',", "Text(AppStrings.of(context).cast,"),
    ("Text('Similar Movies',", "Text(AppStrings.of(context).similarMovies,"),
    ("Text('Reactions',", "Text(AppStrings.of(context).reactions,"),
    ("const Text('Failed to add reaction')", "Text(AppStrings.of(context).failedToAddReaction)"),
    ("Text('Part of Collection',", "Text(AppStrings.of(context).partOfCollection,"),
    ("Text('Current',", "Text(AppStrings.of(context).current,"),
    ("const Text('Failed to load collection')", "Text(AppStrings.of(context).failedToLoadCollection)"),
    ("Text('Add to List',", "Text(AppStrings.of(context).addToList,"),
    ("const Text('Go to My Lists')", "Text(AppStrings.of(context).goToMyLists)"),
    ("Text('Cancel',", "Text(AppStrings.of(context).cancel,"),
])

# ---- show_detail_page.dart ----
do_replacements('lib/features/show/presentation/pages/show_detail_page.dart', [
    ("const Text('All episodes marked as watched!')", "Text(AppStrings.of(context).allEpisodesMarked)"),
    ("const Text('Failed to mark all episodes')", "Text(AppStrings.of(context).failedToMarkAll)"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('Rate This Show',", "Text(AppStrings.of(context).rateThisShow,"),
    ("Text('Overview',", "Text(AppStrings.of(context).overview,"),
    ("Text('Seasons',", "Text(AppStrings.of(context).seasons,"),
    ("Text('Cast',", "Text(AppStrings.of(context).cast,"),
    ("Text('Similar Shows',", "Text(AppStrings.of(context).similarShows,"),
    ("Text('All Caught Up!',", "Text(AppStrings.of(context).allCaughtUp,"),
    ("Text('Up Next',", "Text(AppStrings.of(context).upNext,"),
    ("Text('Watch',", "Text(AppStrings.of(context).watch,"),
    ("Text('Add to List',", "Text(AppStrings.of(context).addToList,"),
    ("const Text('Go to My Lists')", "Text(AppStrings.of(context).goToMyLists)"),
    ("Text('Cancel',", "Text(AppStrings.of(context).cancel,"),
])

# ---- season_detail_page.dart ----
do_replacements('lib/features/show/presentation/pages/season_detail_page.dart', [
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("const Text('Mark All Episodes')", "Text(AppStrings.of(context).markAllEpisodes)"),
    ("const Text('Mark all episodes in this season as watched?')", "Text(AppStrings.of(context).markAllEpisodesConfirm)"),
    ("Text('Cancel',", "Text(AppStrings.of(context).cancel,"),
    ("const Text('Mark All',", "Text(AppStrings.of(context).markAll,"),
    ("Text('No episodes available',", "Text(AppStrings.of(context).noEpisodes,"),
    ("Text('Comments',", "Text(AppStrings.of(context).comments,"),
    ("const Text('Failed to add reaction')", "Text(AppStrings.of(context).failedToAddReaction)"),
])

# ---- episode_detail_page.dart ----
do_replacements('lib/features/show/presentation/pages/episode_detail_page.dart', [
    ("const Text('Failed to update watch status')", "Text(AppStrings.of(context).failedToUpdateWatch)"),
    ("const Text('Failed to add reaction')", "Text(AppStrings.of(context).failedToAddReaction)"),
    ("Text('Cancel',", "Text(AppStrings.of(context).cancel,"),
    ("const Text('Failed to save rating')", "Text(AppStrings.of(context).failedToSaveRating)"),
    ("const Text('Rate')", "Text(AppStrings.of(context).rate)"),
    ("Text('Episode not found',", "Text(AppStrings.of(context).episodeNotFound,"),
    ("const Text('Go Back')", "Text(AppStrings.of(context).goBack)"),
    ("Text('Overview',", "Text(AppStrings.of(context).overview,"),
    ("Text('Reactions',", "Text(AppStrings.of(context).reactions,"),
    ("Text('Rating',", "Text(AppStrings.of(context).rating,"),
    ("Text('Comments',", "Text(AppStrings.of(context).comments,"),
    ("const Text('See All')", "Text(AppStrings.of(context).seeAll)"),
])

# ---- stats_page.dart ----
do_replacements('lib/features/statistics/presentation/pages/stats_page.dart', [
    ("Text('Statistics',", "Text(AppStrings.of(context).statistics,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('Watch Streak',", "Text(AppStrings.of(context).watchStreak,"),
    ("Text('Watch Activity',", "Text(AppStrings.of(context).watchActivity,"),
    ("Text('Last 6 months',", "Text(AppStrings.of(context).last6Months,"),
    ("Text('Content Distribution',", "Text(AppStrings.of(context).contentDistribution,"),
    ("Text('Top Genres',", "Text(AppStrings.of(context).topGenres,"),
    ("Text('Insights',", "Text(AppStrings.of(context).insights,"),
])

# ---- home_page.dart ----
do_replacements('lib/features/home/presentation/pages/home_page.dart', [
    ("Text('NextUp',", "Text(AppStrings.of(context).nextUp,"),
])

# ---- see_all_page.dart ----
do_replacements('lib/features/home/presentation/pages/see_all_page.dart', [
    ("Text('No items found',", "Text(AppStrings.of(context).noItemsFound,"),
])

# ---- shared_list_detail_page.dart ----
do_replacements('lib/features/shared_lists/presentation/pages/shared_list_detail_page.dart', [
    ("Text('Shared List',", "Text(AppStrings.of(context).sharedList,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('No items yet',", "Text(AppStrings.of(context).noItemsYet,"),
    ("Text('Tap + to add shows or movies',", "Text(AppStrings.of(context).tapToAddShowsOrMovies,"),
    ("'Remove Item')", "AppStrings.of(context).removeItem)"),
    ("Text('Members',", "Text(AppStrings.of(context).members,"),
    ("Text('No members yet',", "Text(AppStrings.of(context).noMembers,"),
    ("'Remove Member')", "AppStrings.of(context).removeMember)"),
    ("const Text('Delete List',", "Text(AppStrings.of(context).deleteList,"),
    ("Text('This will permanently delete the list and all items',", "Text(AppStrings.of(context).deleteListWarning,"),
    ("Text('Leave List',", "Text(AppStrings.of(context).leaveList,"),
    ("Text('You will no longer have access to this list',", "Text(AppStrings.of(context).leaveListWarning,"),
    ("Text('No users found',", "Text(AppStrings.of(context).noUsersFound,"),
    ("Text('Search for shows or movies',", "Text(AppStrings.of(context).searchShowsOrMovies,"),
])

# ---- shared_lists_page.dart ----
do_replacements('lib/features/shared_lists/presentation/pages/shared_lists_page.dart', [
    ("Text('Shared Lists',", "Text(AppStrings.of(context).sharedLists,"),
    ("Text('Watch together with friends',", "Text(AppStrings.of(context).watchTogetherWithFriends,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('No shared lists yet',", "Text(AppStrings.of(context).noSharedLists,"),
    ("Text('Create a list to watch together with friends',", "Text(AppStrings.of(context).createSharedListHint,"),
    ("Text('Add Members',", "Text(AppStrings.of(context).addMembers,"),
    ("Text('Following',", "Text(AppStrings.of(context).following,"),
])

# ---- user_list_page.dart ----
do_replacements('lib/features/profile/presentation/pages/user_list_page.dart', [
    ("Text('Failed to load. Please try again.',", "Text(AppStrings.of(context).failedToLoad,"),
    ("const Text('Retry')", "Text(AppStrings.of(context).retry)"),
    ("Text('No items yet',", "Text(AppStrings.of(context).noItemsYet,"),
])

# ---- profile_page.dart ----
do_replacements('lib/features/profile/presentation/pages/profile_page.dart', [
    ("Text('See All',", "Text(AppStrings.of(context).seeAll,"),
])

print("\nAll replacements done!")