import 'package:flutter/widgets.dart';

/// Central place for all user-facing strings.
///
/// Usage:
///   AppStrings.of(context).retry
/// or for a raw locale check:
///   AppStrings.isFa(context)
///
/// The app defaults to English; when the user selects Persian (fa) every
/// screen that uses these getters switches automatically. RTL layout is
/// handled in main.dart via Directionality based on the locale.
class AppStrings {
  final bool fa;
  const AppStrings(this.fa);

  /// Build from the current context's Directionality/locale.
  static AppStrings of(BuildContext context) {
    return AppStrings(isFa(context));
  }

  /// Whether the active locale is Persian. Falls back to text direction.
  static bool isFa(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    if (locale != null) return locale.languageCode == 'fa';
    return Directionality.of(context) == TextDirection.rtl;
  }

  String _p(String faText, String enText) => fa ? faText : enText;

  // ---- Common ----
  String get retry => _p('تلاش مجدد', 'Retry');
  String get cancel => _p('لغو', 'Cancel');
  String get delete => _p('حذف', 'Delete');
  String get remove => _p('حذف', 'Remove');
  String get ok => _p('باشه', 'OK');
  String get goBack => _p('بازگشت', 'Go Back');
  String get goHome => _p('خانه', 'Go Home');
  String get save => _p('ذخیره', 'Save');
  String get change => _p('تغییر', 'Change');
  String get seeAll => _p('مشاهده همه', 'See All');
  String get login => _p('ورود', 'Login');
  String get signUp => _p('ثبت‌نام', 'Sign Up');
  String get loading => _p('در حال بارگذاری...', 'Loading...');
  String get somethingWrong => _p('مشکلی پیش آمد. لطفاً دوباره تلاش کنید.', 'Something went wrong. Please try again.');
  String get create => _p('ایجاد', 'Create');
  String get confirm => _p('تأیید', 'Confirm');

  // ---- Navigation / titles ----
  String get home => _p('خانه', 'Home');
  String get search => _p('جستجو', 'Search');
  String get watchlist => _p('لیست تماشا', 'Watchlist');
  String get profile => _p('پروفایل', 'Profile');
  String get discover => _p('کشف', 'Discover');
  String get settings => _p('تنظیمات', 'Settings');
  String get notifications => _p('اعلان‌ها', 'Notifications');
  String get statistics => _p('آمار', 'Statistics');
  String get achievements => _p('دستاوردها', 'Achievements');
  String get activity => _p('فعالیت', 'Activity');
  String get calendar => _p('تقویم', 'Calendar');
  String get comingSoon => _p('به‌زودی', 'Coming Soon');
  String get rankings => _p('رده‌بندی', 'Rankings');
  String get comments => _p('نظرات', 'Comments');
  String get sharedLists => _p('لیست‌های مشترک', 'Shared Lists');
  String get customLists => _p('لیست‌های سفارشی', 'Custom Lists');
  String get favorites => _p('علاقه‌مندی‌ها', 'Favorites');
  String get watchHistory => _p('تاریخچه تماشا', 'Watch History');

  // ---- Home ----
  String hiUser(String name) => _p('سلام، $name', 'Hi, $name');
  String get searchHint => _p('جستجوی سریال، فیلم...', 'Search shows, movies...');
  String get searchFullHint => _p('جستجوی سریال، فیلم، افراد...', 'Search shows, movies, people...');
  String get noItemsFound => _p('موردی یافت نشد', 'No items found');
  String get noResultsFound => _p('نتیجه‌ای یافت نشد', 'No results found');
  String get recentSearches => _p('جستجوهای اخیر', 'Recent Searches');
  String get clear => _p('پاک کردن', 'Clear');
  String get users => _p('کاربران', 'Users');
  String get tvShows => _p('سریال‌ها', 'TV Shows');
  String get friendsAreWatching => _p('دوستان در حال تماشا', 'Friends Are Watching');
  String get friendsAreWatchingSub => _p('چیزی که دوستانت الان می‌بینن', 'What your friends are watching right now');
  String get forYou => _p('برای تو', 'For You');
  String get forYouSub => _p('بر اساس تاریخچه تماشای تو', 'Based on your watch history');
  String get trendingShows => _p('سریال‌های پرطرفدار', 'Trending Shows');
  String get trendingShowsSub => _p('محبوب‌ترین‌های این هفته', 'Most popular this week');
  String get trendingMovies => _p('فیلم‌های پرطرفدار', 'Trending Movies');
  String get trendingMoviesSub => _p('فیلم‌های محبوب این روزها', 'Popular movies right now');
  String get topRated => _p('برترین‌ها', 'Top Rated');
  String get topRatedSub => _p('بالاترین امتیاز سریال‌ها', 'Highest rated shows');
  String get trendingShowBadge => _p('سریال پرطرفدار', 'TRENDING SHOW');
  String get trendingMovieBadge => _p('فیلم پرطرفدار', 'TRENDING MOVIE');
  String get guest => _p('مهمان', 'Guest');
  String get user => _p('کاربر', 'User');

  // ---- Auth ----
  String get enterEmailFirst => _p('ابتدا ایمیل خود را وارد کنید', 'Please enter your email first');
  String get enterValidEmail => _p('یک ایمیل معتبر وارد کنید', 'Please enter a valid email');
  String get orContinueWith => _p('یا ادامه با', 'Or continue with');
  String get goToLogin => _p('رفتن به ورود', 'Go to Login');
  String get failedToSignOut => _p('خطا در خروج', 'Failed to sign out');

  // ---- Watchlist ----
  String get loginToWatchlist => _p('برای دیدن لیست تماشا وارد شوید', 'Please login to view your watchlist');
  String get watchlistEmpty => _p('لیست تماشای شما خالی است', 'Your watchlist is empty');
  String get addShowsToWatchLater => _p('سریال و فیلم برای تماشای بعدی اضافه کنید', 'Add shows and movies to watch later');
  String get findShows => _p('یافتن سریال‌ها', 'Find Shows');
  String get removeFromWatchlist => _p('حذف از لیست تماشا', 'Remove from Watchlist');
  String removeFromWatchlistConfirm(String name) => _p('«$name» از لیست تماشا حذف شود؟', 'Remove "$name" from your watchlist?');
  String get changeStatus => _p('تغییر وضعیت', 'Change Status');
  String get all => _p('همه', 'All');
  String get shows => _p('سریال‌ها', 'Shows');
  String get movies => _p('فیلم‌ها', 'Movies');
  String get statusWatching => _p('در حال تماشا', 'Watching');
  String get statusCompleted => _p('تکمیل شده', 'Completed');
  String get statusUpToDate => _p('به‌روز', 'Up to Date');
  String get statusWatchlist => _p('لیست تماشا', 'Watchlist');
  String get statusStopped => _p('متوقف شده', 'Stopped');
  String get markAsCompletedQuestion => _p('علامت‌گذاری به‌عنوان تکمیل شده؟', 'Mark as Completed?');
  String get markAllWatchedQuestion => _p('همه قسمت‌ها هم به‌عنوان تماشا شده علامت بخورد؟', 'Do you also want to mark all episodes as watched?');
  String get noJustChangeStatus => _p('نه، فقط وضعیت تغییر کند', 'No, just change status');
  String get yesMarkAll => _p('بله، همه را علامت بزن', 'Yes, mark all');

  // ---- Favorites ----
  String get removeFromFavorites => _p('حذف از علاقه‌مندی‌ها', 'Remove from Favorites');
  String removeFromFavoritesConfirm(String name) => _p('«$name» از علاقه‌مندی‌ها حذف شود؟', 'Remove "$name" from your favorites?');

  // ---- Profile / social ----
  String get following => _p('دنبال‌شونده‌ها', 'Following');
  String get followers => _p('دنبال‌کننده‌ها', 'Followers');
  String get follow => _p('دنبال کردن', 'Follow');
  String get followBack => _p('دنبال کردن متقابل', 'Follow Back');
  String get unfollow => _p('لغو دنبال کردن', 'Unfollow');
  String get notFollowingAnyone => _p('هنوز کسی را دنبال نمی‌کنید', 'Not following anyone yet');
  String get noFollowers => _p('هنوز دنبال‌کننده‌ای ندارید', 'No followers yet');
  String get couldNotLoadProfile => _p('پروفایل بارگذاری نشد', 'Could not load profile');
  String get checkConnection => _p('اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.', 'Check your internet connection and try again.');
  String get compareStats => _p('مقایسه آمار', 'Compare Stats');
  String get editProfile => _p('ویرایش پروفایل', 'Edit Profile');
  String get privateProfile => _p('این پروفایل خصوصی است', 'This profile is private');
  String get followToSeeContent => _p('برای دیدن محتوا این کاربر را دنبال کنید', 'Follow this user to see their content');
  String get noActivityYet => _p('هنوز فعالیتی نیست', 'No activity yet');
  String get publicLists => _p('لیست‌های عمومی', 'Public Lists');
  String get myLists => _p('لیست‌های من', 'My Lists');
  String get untitled => _p('بدون عنوان', 'Untitled');
  String get noItemsYet => _p('موردی وجود ندارد', 'No items yet');
  String get planToWatch => _p('قصد تماشا', 'Plan to Watch');
  String get failedToLoad => _p('بارگذاری ناموفق بود. دوباره تلاش کنید.', 'Failed to load. Please try again.');
  String get failedToFollow => _p('دنبال کردن ناموفق بود. دوباره تلاش کنید.', 'Failed to follow. Please try again.');
  String get failedToUnfollow => _p('لغو دنبال کردن ناموفق بود. دوباره تلاش کنید.', 'Failed to unfollow. Please try again.');
  String get failedToUpdate => _p('به‌روزرسانی ناموفق بود. دوباره تلاش کنید.', 'Failed to update. Please try again.');
  String get loginToViewProfile => _p('برای دیدن پروفایل خود وارد شوید', 'Please login to view your profile');
  String get noFavoritesYet => _p('هنوز علاقه‌مندی‌ای وجود ندارد', 'No favorites yet');
  String get addShowsToFavorites => _p('سریال و فیلم به علاقه‌مندی‌هایتان اضافه کنید', 'Add shows and movies to your favorites');
  String get noWatchHistory => _p('تاریخچه تماشایی وجود ندارد', 'No watch history yet');
  String get startWatchingToBuildHistory => _p('برای ساخت تاریخچه، تماشا را شروع کنید', 'Start watching to build your history');
  String get myWatchlist => _p('لیست تماشای من', 'My Watchlist');
  String get showsAndMoviesToWatch => _p('سریال و فیلم برای تماشا', 'Shows and movies to watch');
  String get yourFavoriteShowsAndMovies => _p('سریال و فیلم‌های مورد علاقه شما', 'Your favorite shows and movies');
  String get showsAndMoviesYouWatched => _p('سریال و فیلم‌هایی که تماشا کرده‌اید', "Shows and movies you've watched");
  String get customCollections => _p('مجموعه‌های سفارشی', 'Custom collections');
  String get listsWithFriends => _p('لیست‌های مشترک با دوستان', 'Lists with friends');
  String get compareWithFriends => _p('مقایسه با دوستان', 'Compare with friends');
  String get yourWatchingStats => _p('آمار تماشای شما', 'Your watching stats');
  String get yourBadgesAndMilestones => _p('نشان‌ها و دستاوردهای شما', 'Your badges and milestones');
  String get whatFriendsAreWatching => _p('دوستان در حال تماشا', 'What your friends are watching');
  String get themeLanguageNotifications => _p('تم، زبان، اعلان‌ها', 'Theme, language, notifications');
  String get profileUpdatedSuccessfully => _p('پروفایل با موفقیت به‌روزرسانی شد!', 'Profile updated successfully!');
  String get tapToAddHeaderImage => _p('برای افزودن تصویر هدر ضربه بزنید', 'Tap to add header image');
  String get headerImage => _p('تصویر هدر', 'Header Image');
  String get profilePhoto => _p('تصویر پروفایل', 'Profile Photo');
  String get chooseFromGallery => _p('انتخاب از گالری', 'Choose from Gallery');
  String get avatarRemoved => _p('آواتار حذف شد!', 'Avatar removed!');
  String get failedToRemoveAvatar => _p('خطا در حذف آواتار', 'Failed to remove avatar');
  String get headerRemoved => _p('هدر حذف شد!', 'Header removed!');
  String get failedToRemoveHeader => _p('خطا در حذف هدر', 'Failed to remove header');
  String get avatarUpdated => _p('آواتار به‌روزرسانی شد!', 'Avatar updated!');
  String get failedToUploadAvatar => _p('خطا در بارگذاری آواتار', 'Failed to upload avatar');
  String get headerImageUpdated => _p('تصویر هدر به‌روزرسانی شد!', 'Header image updated!');
  String get failedToUploadHeader => _p('خطا در بارگذاری تصویر هدر', 'Failed to upload header image');
  String get usernameLabel => _p('نام کاربری', 'Username');
  String get usernameRequired => _p('نام کاربری الزامی است', 'Username is required');
  String get bio => _p('بیوگرافی', 'Bio');
  String get tellUsAboutYourself => _p('درباره خودت بنویس...', 'Tell us about yourself...');
  String get saving => _p('در حال ذخیره...', 'Saving...');
  String get saveChanges => _p('ذخیره تغییرات', 'Save Changes');
  String checkOutProfile(String username) => _p('پروفایل $username را در NextUp ببین!', "Check out $username's profile on NextUp!");

  // ---- Notifications ----
  String get markAllRead => _p('علامت‌گذاری همه به‌عنوان خوانده', 'Mark all read');
  String get noNotificationsYet => _p('اعلانی وجود ندارد', 'No notifications yet');
  String andOthers(int remaining) => _p('و $remaining نفر دیگر', 'and $remaining others');
  String andOther(int count) => _p('و $count نفر دیگر', 'and $count other');
  String nPeople(int count) => _p('$count نفر', '$count people');
  String get likedYourComment => _p('نظر شما را پسندید', 'liked your comment');
  String get commented => _p('نظر داد', 'commented');
  String get repliedToYourComment => _p('به نظر شما پاسخ داد', 'replied to your comment');
  String get startedFollowingYou => _p('شما را دنبال کرد', 'started following you');
  String get wasActive => _p('فعالیت داشت', 'was active');
  String get on_ => _p(' در ', ' on ');

  // ---- Comments ----
  String get loginToComment => _p('برای ثبت نظر وارد شوید', 'Login to comment');
  String get deleteComment => _p('حذف نظر', 'Delete Comment');
  String get failedToLoadReplies => _p('خطا در بارگذاری پاسخ‌ها', 'Failed to load replies');
  String get spoiler => _p('اسپویل', 'Spoiler');

  // ---- Show / movie detail ----
  String get failedToAddReaction => _p('خطا در ثبت واکنش', 'Failed to add reaction');
  String get failedToSaveRating => _p('خطا در ثبت امتیاز', 'Failed to save rating');
  String get failedToUpdateWatch => _p('خطا در به‌روزرسانی وضعیت تماشا', 'Failed to update watch status');
  String get failedToMarkAll => _p('خطا در علامت‌گذاری همه قسمت‌ها', 'Failed to mark all episodes');
  String get failedToLoadCollection => _p('خطا در بارگذاری مجموعه', 'Failed to load collection');
  String get goToMyLists => _p('رفتن به لیست‌های من', 'Go to My Lists');
  String get rate => _p('امتیاز', 'Rate');
  String get current => _p('فعلی', 'Current');
  String get markAll => _p('علامت‌گذاری همه', 'Mark All');
  String get markAllEpisodes => _p('علامت‌گذاری همه قسمت‌ها', 'Mark All Episodes');
  String get markAllEpisodesConfirm => _p('همه قسمت‌های این فصل به‌عنوان تماشا شده علامت بخورد؟', 'Mark all episodes in this season as watched?');
  String get noEpisodes => _p('قسمتی موجود نیست', 'No episodes available');

  // ---- Lists ----
  String get deleteList => _p('حذف لیست', 'Delete List');
  String get deleteListWarning => _p('این کار لیست و همه موارد آن را برای همیشه حذف می‌کند', 'This will permanently delete the list and all items');
  String get leaveList => _p('ترک لیست', 'Leave List');
  String get leaveListWarning => _p('دیگر به این لیست دسترسی نخواهید داشت', 'You will no longer have access to this list');
  String get members => _p('اعضا', 'Members');
  String get noMembers => _p('هنوز عضوی نیست', 'No members yet');
  String get noSharedLists => _p('هنوز لیست مشترکی نیست', 'No shared lists yet');
  String get createSharedListHint => _p('برای تماشای مشترک با دوستان یک لیست بسازید', 'Create a list to watch together with friends');

  // ---- Filters / discover ----
  String get noContentFound => _p('محتوایی یافت نشد', 'No content found');
  String get reset => _p('بازنشانی', 'Reset');
  String get skipForNow => _p('فعلاً رد شو', 'Skip for now');
  String get failedToSavePreferences => _p('خطا در ذخیره تنظیمات', 'Failed to save preferences');
  String get failedToVote => _p('خطا در ثبت رأی', 'Failed to vote');

  // ---- Settings sections ----
  String get appearance => _p('ظاهر', 'Appearance');
  String get theme => _p('تم', 'Theme');
  String get language => _p('زبان', 'Language');
  String get selectTheme => _p('انتخاب تم', 'Select Theme');
  String get selectLanguage => _p('انتخاب زبان', 'Select Language');
  String get themeDark => _p('تیره', 'Dark');
  String get themeLight => _p('روشن', 'Light');
  String get themeSystem => _p('سیستم', 'System');
  String get pushNotifications => _p('اعلان‌های فشاری', 'Push Notifications');
  String get pushNotificationsSub => _p('اعلان قسمت جدید', 'Get notified for new episodes');
  String get emailNotifications => _p('اعلان‌های ایمیلی', 'Email Notifications');
  String get emailNotificationsSub => _p('خلاصه هفتگی', 'Weekly watch summary');
  String get account => _p('حساب کاربری', 'Account');
  String get changePassword => _p('تغییر رمز عبور', 'Change Password');
  String get deleteAccount => _p('حذف حساب', 'Delete Account');
  String get about => _p('درباره', 'About');
  String get version => _p('نسخه', 'Version');
  String get termsOfService => _p('شرایط استفاده', 'Terms of Service');
  String get termsBody => _p('این برنامه تحت قوانین جمهوری اسلامی ایران فعالیت می‌کند.', 'This application operates under applicable laws.');
  String get privacyPolicy => _p('سیاست حریم خصوصی', 'Privacy Policy');
  String get privacyBody => _p('ما به حریم خصوصی شما احترام می‌گذاریم.', 'We respect your privacy.');
  String get signOut => _p('خروج', 'Sign Out');
  String get signOutAccount => _p('خروج از حساب', 'Sign Out');
  String get areYouSure => _p('آیا مطمئن هستید؟', 'Are you sure?');

  // Change password
  String get currentPassword => _p('رمز عبور فعلی', 'Current Password');
  String get newPassword => _p('رمز عبور جدید', 'New Password');
  String get confirmPassword => _p('تکرار رمز عبور', 'Confirm Password');
  String get enterCurrentPassword => _p('رمز عبور فعلی را وارد کنید', 'Please enter current password');
  String get enterPassword => _p('رمز عبور را وارد کنید', 'Please enter password');
  String get minEightChars => _p('حداقل ۸ کاراکتر', 'Minimum 8 characters');
  String get mustHaveUppercase => _p('باید حرف بزرگ داشته باشد', 'Must contain an uppercase letter');
  String get mustHaveNumber => _p('باید عدد داشته باشد', 'Must contain a number');
  String get confirmPasswordHint => _p('تکرار رمز عبور را وارد کنید', 'Please confirm password');
  String get passwordsNoMatch => _p('رمز عبور مطابقت ندارد', 'Passwords do not match');
  String get passwordChanged => _p('رمز عبور تغییر کرد', 'Password changed');
  String get currentPasswordWrong => _p('رمز عبور فعلی اشتباه است', 'Current password is incorrect');

  // Delete account
  String get deleteAccountConfirm => _p('آیا مطمئن هستید؟ این عمل غیرقابل بازگشت است.', 'Are you sure you want to delete your account? This action cannot be undone.');
  String get enterPasswordToConfirm => _p('رمز عبور فعلی را وارد کنید', 'Enter your password to confirm');
  String get incorrectPassword => _p('رمز عبور اشتباه است', 'Incorrect password');

  // ---- Myket section ----
  String get myket => _p('مایکت', 'Myket');
  String get rateApp => _p('امتیاز به برنامه', 'Rate this app');
  String get sendComment => _p('ارسال نظر', 'Send a comment');
  String get otherApps => _p('سایر برنامه‌های ما', 'Our other apps');
  String get checkForUpdate => _p('بررسی به‌روزرسانی', 'Check for update');
  String get myketNotAvailable => _p('امکان باز کردن مایکت وجود ندارد', 'Could not open Myket');

  // ---- About / publisher ----
  String get aboutApp => _p('درباره برنامه', 'About App');
  String get publisher => _p('عرضه و ویرایش', 'Published & edited by');
  String get support => _p('پشتیبانی', 'Support');
  static const String publisherName = 'Amir Mohammad Shafiei';
  static const String supportTelegram = '@amirs2h';

  // ---- Auth fields ----
  String get email => _p('ایمیل', 'Email');
  String get password => _p('رمز عبور', 'Password');
  String get confirmPasswordField => _p('تکرار رمز عبور', 'Confirm Password');
  String get settingUp => _p('در حال تنظیم...', 'Setting up...');
  String get getStarted => _p('شروع کنید', 'Get Started');
  String get comingSoonSnackBar => _p('به‌زودی!', 'Coming soon!');
  String get passwordResetSent => _p('ایمیل بازنشانی رمز عبور ارسال شد!', 'Password reset email sent!');
  String get failedToSendReset => _p('خطا در ارسال ایمیل بازنشانی. دوباره تلاش کنید.', 'Failed to send reset email. Please try again.');

  // ---- Search / Lists ----
  String get searchShowsOrMovies => _p('جستجوی سریال یا فیلم', 'Search shows or movies');
  String get searchByUsername => _p('جستجو با نام کاربری', 'Search by username');
  String get searchUsers => _p('جستجوی کاربران...', 'Search users...');
  String get listName => _p('نام لیست', 'List name');
  String get descriptionOptional => _p('توضیحات (اختیاری)', 'Description (optional)');
  String get searchFailed => _p('جستجو ناموفق بود. دوباره تلاش کنید.', 'Search failed. Please try again.');

  // ---- Media types ----
  String get tvShow => _p('سریال', 'TV Show');
  String get movie => _p('فیلم', 'Movie');

  // ---- Detail pages ----
  String get compare => _p('مقایسه', 'Compare');
  String get stats => _p('آمار', 'Stats');
  String get overview => _p('خلاصه', 'Overview');
  String get cast => _p('بازیگران', 'Cast');
  String get rating => _p('امتیاز', 'Rating');
  String get watch => _p('تماشا', 'Watch');

  // ---- Season / Episode ----
  String reactedWith(String emoji) => _p('با $emoji واکنش نشان دادید', 'Reacted with $emoji');
  String ratedN(int rating) => _p('امتیاز $rating از ۱۰', 'Rated $rating/10');

  // ---- Comments ----
  String get commentTooLong => _p('نظر خیلی طولانی است (حداکثر ۵۰۰ کاراکتر)', 'Comment is too long (max 500 characters)');

  // ---- Misc ----
  String get refresh => _p('بازخوانی', 'Refresh');
  String get errorPrefix => _p('خطا', 'Error');
  String get list => _p('لیست', 'List');
  String get year => _p('سال', 'Year');
  String get genre => _p('ژانر', 'Genre');
  String get you => _p('شما', 'You');
  String get pageNotFound => _p('صفحه یافت نشد', 'Page not found');
  String replyingTo(String username) => _p('در حال پاسخ به @$username', 'Replying to @$username');
  String errorWithMsg(String msg) => _p('خطا: $msg', 'Error: $msg');

  // ---- Trailer / Watch providers ----
  String get trailers => _p('تیزرها', 'Trailers');
  String get whereToWatch => _p('کجا تماشا کنیم', 'Where to Watch');
  String get stream => _p('استریم', 'Stream');
  String get rent => _p('اجاره', 'Rent');
  String get buy => _p('خرید', 'Buy');

  // ---- Rating / Voting ----
  String get votes => _p('آرا', 'Votes');
  String get vote => _p('رأی', 'Vote');
  String get yourVote => _p('رأی شما', 'Your vote');
  String get changeVote => _p('تغییر رأی', 'Change Vote');
  String get failedToVoteTryAgain => _p('خطا در ثبت رأی. دوباره تلاش کنید.', 'Failed to vote. Please try again.');
  String get whoIsYourFavorite => _p('بازیگر مورد علاقه شما کیست؟', 'Who is your favorite actor?');
  String get voteForFavoriteActor => _p('برای بازیگر مورد علاقه‌تان رأی دهید', 'Vote for your favorite actor');

  // ---- PWA / Update ----
  String get later => _p('بعداً', 'Later');
  String get gotIt => _p('متوجه شدم', 'Got it');
  String get installNextUp => _p('نصب نکست‌آپ', 'Install NextUp');
  String get installNextUpSub => _p('برای دسترسی سریع به صفحه اصلی اضافه کنید', 'Add to your home screen for quick access');

  // ---- Achievement categories ----
  String get catWatching => _p('تماشا', 'Watching');
  String get catCountry => _p('کشور', 'Country');
  String get catTime => _p('زمان', 'Time');
  String get catCollection => _p('مجموعه', 'Collection');
  String get catFunny => _p('طنز', 'Funny');

  // ---- Coming Soon ----
  String get airingToday => _p('امروز پخش می‌شود', 'Airing Today');
  String get airingTodaySub => _p('قسمت‌های جدید امروز', 'New episodes available today');
  String get upcomingMovies => _p('فیلم‌های پیش‌رو', 'Upcoming Movies');
  String get upcomingMoviesSub => _p('به‌زودی در سینما', 'Coming to theaters soon');


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
  String get episode => _p('قسمت', 'Episode');
  String get episodeNotFound => _p('قسمت یافت نشد', 'Episode not found');
  String get watchTogetherWithFriends => _p('با دوستان تماشا کنید', 'Watch together with friends');
  String get addMembers => _p('افزودن اعضا', 'Add Members');
  String selectedN(int n) => _p('انتخاب شده ($n)', 'Selected ($n)');
  String get unlocked => _p('باز شده', 'Unlocked');
  String get dontHaveAccount => _p('حساب کاربری ندارید؟ ', "Don't have an account? ");

  // ---- Achievements ----
  String achievementTitle(String id) {
    final titles = <String, String>{
      'first_episode': _p('اولین قسمت', 'First Episode'),
      'binge_master': _p('استاد ماراتن', 'Binge Master'),
      'marathon_monster': _p('هیولای ماراتن', 'Marathon Monster'),
      'night_owl': _p('جغد شب', 'Night Owl'),
      'early_bird': _p('سحرخیز', 'Early Bird'),
      'daily_streak': _p('رکورد روزانه', 'Daily Streak'),
      'monthly_streak': _p('رکورد ماهانه', 'Monthly Streak'),
      'year_streak': _p('رکورد یک‌ساله', 'One Year Streak'),
      'movie_maniac': _p('دیوانه فیلم', 'Movie Maniac'),
      'series_addict': _p('معتاد سریال', 'Series Addict'),
      'episode_hunter': _p('شکارچی قسمت', 'Episode Hunter'),
      'action_lover': _p('عاشق اکشن', 'Action Lover'),
      'comedy_expert': _p('متخصص کمدی', 'Comedy Expert'),
      'scifi_explorer': _p('کاوشگر علمی‌تخیلی', 'Sci-Fi Explorer'),
      'fantasy_wizard': _p('جادوگر فانتزی', 'Fantasy Wizard'),
      'crime_detective': _p('کارآگاه جنایی', 'Crime Detective'),
      'horror_survivor': _p('بازمانده ترس', 'Horror Survivor'),
      'romance_expert': _p('متخصص عاشقانه', 'Romance Expert'),
      'genre_explorer': _p('کاوشگر ژانر', 'Genre Explorer'),
      'hollywood_tourist': _p('توریست هالیوود', 'Hollywood Tourist'),
      'korean_fan': _p('طرفدار کی‌دراما', 'K-Drama Fan'),
      'anime_world': _p('دنیای انیمه', 'Anime World'),
      'first_save': _p('اولین ذخیره', 'First Save'),
      'collector': _p('کلکسیونر', 'Collector'),
      'wishlist_king': _p('پادشاه لیست', 'Wishlist King'),
      'first_favorite': _p('اولین علاقه‌مندی', 'First Favorite'),
      'favorites_10': _p('کلکسیونر قلب', 'Heart Collector'),
      'favorites_50': _p('طرفدار فوق‌العاده', 'Super Fan'),
      'hours_10': _p('شروع راه', 'Getting Started'),
      'hours_100': _p('بیننده‌ی تعهدی', 'Dedicated Viewer'),
      'hours_500': _p('استاد زمان', 'Time Master'),
      'hours_1000': _p('طرفدار نهایی', 'Ultimate Fan'),
      'unique_50': _p('جستجوگر تنوع', 'Variety Seeker'),
      'unique_100': _p('کاوشگر محتوا', 'Content Explorer'),
      'unique_500': _p('آرشیویست', 'The Archivist'),
      'pizza_movies': _p('پیتزا و فیلم', 'Pizza & Movies'),
      'cry_baby': _p('آب‌دیده', 'Cry Baby'),
      'halloween': _p('ویژه هالووین', 'Halloween Special'),
      'christmas': _p('روح کریسمس', 'Christmas Spirit'),
      'summer_vacation': _p('حال و هوای تابستان', 'Summer Vibes'),
      'hidden_completionist': _p('تکمیل‌کننده', 'Completionist'),
    };
    return titles[id] ?? id;
  }

  String achievementDescription(String id) {
    final descriptions = <String, String>{
      'first_episode': _p('اولین قسمت خود را تماشا کنید', 'Watch your first episode'),
      'binge_master': _p('۵۰ قسمت تماشا کنید', 'Watch 50 episodes'),
      'marathon_monster': _p('۲۰۰ قسمت تماشا کنید', 'Watch 200 episodes'),
      'night_owl': _p('بین ۱۲ شب تا ۴ صبح تماشا کنید', 'Watch between 12AM-4AM'),
      'early_bird': _p('قبل از ۷ صبح تماشا کنید', 'Watch before 7AM'),
      'daily_streak': _p('۷ روز پشت سر هم', '7 days in a row'),
      'monthly_streak': _p('۳۰ روز پشت سر هم', '30 days in a row'),
      'year_streak': _p('۳۶۵ روز پشت سر هم', '365 days in a row'),
      'movie_maniac': _p('۱۰۰ فیلم تماشا کنید', 'Watch 100 movies'),
      'series_addict': _p('۵۰ سریال تماشا کنید', 'Watch 50 shows'),
      'episode_hunter': _p('۱۰۰۰ قسمت تماشا کنید', 'Watch 1000 episodes'),
      'action_lover': _p('۵ عنوان اکشن تماشا کنید', 'Watch 5 action titles'),
      'comedy_expert': _p('۵ عنوان کمدی تماشا کنید', 'Watch 5 comedy titles'),
      'scifi_explorer': _p('۵ عنوان علمی‌تخیلی تماشا کنید', 'Watch 5 sci-fi titles'),
      'fantasy_wizard': _p('۵ عنوان فانتزی تماشا کنید', 'Watch 5 fantasy titles'),
      'crime_detective': _p('۵ عنوان جنایی تماشا کنید', 'Watch 5 crime titles'),
      'horror_survivor': _p('۵ عنوان ترسناک تماشا کنید', 'Watch 5 horror titles'),
      'romance_expert': _p('۵ عنوان عاشقانه تماشا کنید', 'Watch 5 romance titles'),
      'genre_explorer': _p('از ۵ ژانر مختلف تماشا کنید', 'Watch from 5 different genres'),
      'hollywood_tourist': _p('۵ عنوان آمریکایی تماشا کنید', 'Watch 5 US titles'),
      'korean_fan': _p('۵ عنوان کره‌ای تماشا کنید', 'Watch 5 Korean titles'),
      'anime_world': _p('۵ عنوان ژاپنی تماشا کنید', 'Watch 5 Japanese titles'),
      'first_save': _p('اولین مورد را به لیست تماشا اضافه کنید', 'Add first item to watchlist'),
      'collector': _p('۱۰ مورد به لیست تماشا اضافه کنید', 'Add 10 items to watchlist'),
      'wishlist_king': _p('۱۰۰ مورد به لیست تماشا اضافه کنید', 'Add 100 items to watchlist'),
      'first_favorite': _p('اولین علاقه‌مندی خود را اضافه کنید', 'Add your first favorite'),
      'favorites_10': _p('۱۰ علاقه‌مندی اضافه کنید', 'Add 10 favorites'),
      'favorites_50': _p('۵۰ علاقه‌مندی اضافه کنید', 'Add 50 favorites'),
      'hours_10': _p('۱۰ ساعت تماشا کنید', 'Watch 10 hours'),
      'hours_100': _p('۱۰۰ ساعت تماشا کنید', 'Watch 100 hours'),
      'hours_500': _p('۵۰۰ ساعت تماشا کنید', 'Watch 500 hours'),
      'hours_1000': _p('۱۰۰۰ ساعت تماشا کنید', 'Watch 1000 hours'),
      'unique_50': _p('۵۰ عنوان متفاوت تماشا کنید', 'Watch 50 unique titles'),
      'unique_100': _p('۱۰۰ عنوان متفاوت تماشا کنید', 'Watch 100 unique titles'),
      'unique_500': _p('۵۰۰ عنوان متفاوت تماشا کنید', 'Watch 500 unique titles'),
      'pizza_movies': _p('۱۰ فیلم تماشا کنید', 'Watch 10 movies'),
      'cry_baby': _p('۱۰ درام تماشا کنید', 'Watch 10 dramas'),
      'halloween': _p('در اکتبر چیزی تماشا کنید', 'Watch something in October'),
      'christmas': _p('در دسامبر چیزی تماشا کنید', 'Watch something in December'),
      'summer_vacation': _p('در تابستان چیزی تماشا کنید', 'Watch something in summer'),
      'hidden_completionist': _p('۲۰ دستاورد باز کنید', 'Unlock 20 achievements'),
    };
    return descriptions[id] ?? id;
  }
}
