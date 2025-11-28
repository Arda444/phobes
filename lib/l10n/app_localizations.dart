import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'Phobes'**
  String get appTitle;

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Input label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Input label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Input label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Input label
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Select Birth Date'**
  String get birthDateSelect;

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Nav item
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// Nav item
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get navTeams;

  /// Nav item
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStatistics;

  /// Nav item
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Message
  ///
  /// In en, this message translates to:
  /// **'No events found'**
  String get noEvents;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'All Day'**
  String get allDay;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Postpone'**
  String get postpone;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Location (Optional)'**
  String get locationOptional;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Link / URL (Optional)'**
  String get linkOptional;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get tagsHint;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get sectionTiming;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get sectionDetails;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get sectionSettings;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'No Reminder'**
  String get reminderNone;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'At time of event'**
  String get reminderAtTime;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'10 minutes before'**
  String get reminder10Min;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'30 minutes before'**
  String get reminder30Min;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get reminder1Hour;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get reminder1Day;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'No Repeat'**
  String get repeatNone;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Daily Notes'**
  String get dailyNotes;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get allNotes;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// Default
  ///
  /// In en, this message translates to:
  /// **'Untitled Note'**
  String get untitledNote;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Write your notes here...'**
  String get writeYourNotes;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Weekly Notes'**
  String get weeklyNotesTitle;

  /// Message
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// Message
  ///
  /// In en, this message translates to:
  /// **'No notes for today'**
  String get noNotesForToday;

  /// Message
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesAtAll;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNoteTitle;

  /// Dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get deleteNoteWarning;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Statistics Guide'**
  String get statsGuide;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'What do these numbers mean?'**
  String get statsGuideSubtitle;

  /// Metric
  ///
  /// In en, this message translates to:
  /// **'Productivity Score'**
  String get productivityScore;

  /// Desc
  ///
  /// In en, this message translates to:
  /// **'Your daily performance score.'**
  String get productivityScoreDesc;

  /// Metric
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// Desc
  ///
  /// In en, this message translates to:
  /// **'Consecutive days.'**
  String get streakDesc;

  /// Metric
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTasks;

  /// Desc
  ///
  /// In en, this message translates to:
  /// **'Total tasks finished.'**
  String get completedTasksDesc;

  /// Metric
  ///
  /// In en, this message translates to:
  /// **'Best Time'**
  String get mostProductiveTime;

  /// Desc
  ///
  /// In en, this message translates to:
  /// **'Your peak hour.'**
  String get mostProductiveTimeDesc;

  /// Metric
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get focusTime;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Consistency Heatmap'**
  String get activityHeatmapTitle;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Daily Activity'**
  String get dailyActivityTitle;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Weekly Trend'**
  String get weeklyTrendTitle;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Category Analysis'**
  String get categoryAnalysisTitle;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Priority Analysis'**
  String get priorityAnalysisTitle;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Hourly Activity'**
  String get hourlyActivityTitle;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Life Balance'**
  String get lifeBalanceTitle;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Burnout Risk'**
  String get burnoutTitle;

  /// Legend
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get burnoutCreated;

  /// Legend
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get burnoutCompleted;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRateTitle;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Monthly Trend'**
  String get monthlyTrendTitle;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Tag Completion'**
  String get tagCompletionTitle;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Time Spent by Tag'**
  String get tagTimeSpentTitle;

  /// Chart title
  ///
  /// In en, this message translates to:
  /// **'Day Efficiency'**
  String get dayOfWeekEfficiencyTitle;

  /// Widget title
  ///
  /// In en, this message translates to:
  /// **'Projection'**
  String get projectionTitle;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Past 30 Days'**
  String get projectionPast;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Next 30 Days'**
  String get projectionFuture;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Message
  ///
  /// In en, this message translates to:
  /// **'Not enough data'**
  String get tagTimeSpentNoData;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'AI Advice'**
  String get aiAdvice;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// Widget title
  ///
  /// In en, this message translates to:
  /// **'Perfect Days'**
  String get perfectDaysTitle;

  /// Widget desc
  ///
  /// In en, this message translates to:
  /// **'100% completion & 0 postpones'**
  String get perfectDaysDesc;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Account & Settings'**
  String get accountAndSettings;

  /// Metric
  ///
  /// In en, this message translates to:
  /// **'Total Notes'**
  String get totalNotes;

  /// Metric
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get dailyStreak;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Productivity Summary'**
  String get productivitySummary;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Generate Test Data (1 Year)'**
  String get add1YearSimulation;

  /// Desc
  ///
  /// In en, this message translates to:
  /// **'Adds random data'**
  String get add1YearSimulationDesc;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// Desc
  ///
  /// In en, this message translates to:
  /// **'Backup your data'**
  String get exportDataDesc;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// Desc
  ///
  /// In en, this message translates to:
  /// **'Permanently remove all data'**
  String get clearAllDataDesc;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clearAllDataTitle;

  /// Dialog msg
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This cannot be undone.'**
  String get clearAllDataWarning;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get allDataDeleted;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Backup feature coming soon!'**
  String get backupFeatureComingSoon;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Simulation started...'**
  String get simulationStarting;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Simulation complete! Check stats.'**
  String get simulationComplete;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String simulationError(String error);

  /// Desc
  ///
  /// In en, this message translates to:
  /// **'Simulation Data'**
  String get simulationGeneratedTask;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get dataLoadError;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Fetching data from server...'**
  String get fetchingData;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Analyzing {count} records...'**
  String analyzingData(int count);

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Generating charts...'**
  String get generatingCharts;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Edit Info'**
  String get editInfo;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Edit Information'**
  String get editInfoTitle;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Information updated'**
  String get infoUpdated;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get securityPrompt;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get passwordMinLength;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Verification email will be sent.'**
  String get emailChangePrompt;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'New Email'**
  String get newEmail;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get emailVerificationSent;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'30d ago'**
  String get daysAgo30;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'15d ago'**
  String get daysAgo15;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'3w ago'**
  String get weeksAgo3;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'2w ago'**
  String get weeksAgo2;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'1w ago'**
  String get weeksAgo1;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Last 14 Days'**
  String get last14Days;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Last 4 Weeks'**
  String get last4Weeks;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Task Distribution'**
  String get taskDistribution;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Low - Medium - High'**
  String get prioritySubtitle;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Active Hours'**
  String get hourlyActivitySubtitle;

  /// Chart label
  ///
  /// In en, this message translates to:
  /// **'3W Ago'**
  String get week3Ago;

  /// Chart label
  ///
  /// In en, this message translates to:
  /// **'2W Ago'**
  String get week2Ago;

  /// Chart label
  ///
  /// In en, this message translates to:
  /// **'Last W'**
  String get lastWeek;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// Day
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// Advice
  ///
  /// In en, this message translates to:
  /// **'Welcome! Add your first task.'**
  String get adviceWelcome;

  /// Advice
  ///
  /// In en, this message translates to:
  /// **'Great! {count} day streak.'**
  String adviceStreak(int count);

  /// Advice
  ///
  /// In en, this message translates to:
  /// **'Consistency is key.'**
  String get adviceStartStreak;

  /// Advice
  ///
  /// In en, this message translates to:
  /// **'Busy days ahead! ({percent}%)'**
  String adviceUpcomingBusy(String percent);

  /// Advice
  ///
  /// In en, this message translates to:
  /// **'Calm days ahead.'**
  String get adviceUpcomingCalm;

  /// Advice
  ///
  /// In en, this message translates to:
  /// **'Peak hour: {hour}:00.'**
  String adviceBusiestHour(String hour);

  /// Advice
  ///
  /// In en, this message translates to:
  /// **'Avg task: {minutes} mins.'**
  String adviceAvgDuration(String minutes);

  /// Advice
  ///
  /// In en, this message translates to:
  /// **'Busiest day: {day}.'**
  String adviceBusiestDay(String day);

  /// Advice
  ///
  /// In en, this message translates to:
  /// **'Watch out! {percent}% overdue.'**
  String adviceOverdueRate(String percent);

  /// Advice
  ///
  /// In en, this message translates to:
  /// **'Often postponing: {tag}.'**
  String advicePostponedTag(String tag);

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Zombie Task'**
  String get zombieTaskTitle;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'\'{title}\' waiting for {days} days.'**
  String zombieTaskAdvice(String title, int days);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'View All Events'**
  String get viewAllEvents;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Postpone All Day'**
  String get postponeAllDay;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String hiddenItemsCount(int count);

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Move all tasks to later?'**
  String get postponeAllDayWarning;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'15 Min'**
  String get postpone15Min;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'1 Hour'**
  String get postpone1Hour;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'2 Hours'**
  String get postpone2Hour;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get postponeTomorrow;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'1 Week'**
  String get postpone1Week;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Postpone This (1H)'**
  String get postponeThisInstance1Hour;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Postpone All (1H)'**
  String get postponeAllInstances1Hour;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Postpone This (Tmw)'**
  String get postponeThisInstanceTomorrow;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Postpone All (Tmw)'**
  String get postponeAllInstancesTomorrow;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Repeating: {title}'**
  String postponeRepeatingTaskTitle(String title);

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'{label} postponed!'**
  String postponedMessage(String label);

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Link error'**
  String get linkError;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get createTeam;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Join Team'**
  String get joinTeam;

  /// Input
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get teamName;

  /// Input
  ///
  /// In en, this message translates to:
  /// **'Join Code'**
  String get joinCode;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Team created: {code}'**
  String teamCreated(String code);

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Joined!'**
  String get teamJoined;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get taskContext;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @assignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign To'**
  String get assignTo;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {name}'**
  String assignedTo(String name);

  /// No description provided for @kickMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get kickMember;

  /// No description provided for @kickMemberWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this member?'**
  String get kickMemberWarning;

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemoved;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'(Me)'**
  String get me;

  /// No description provided for @tabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get tabActivity;

  /// No description provided for @teamLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get teamLeaderboard;

  /// No description provided for @projectProgress.
  ///
  /// In en, this message translates to:
  /// **'Project Progress'**
  String get projectProgress;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @actTaskCreated.
  ///
  /// In en, this message translates to:
  /// **'created task'**
  String get actTaskCreated;

  /// No description provided for @actTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed task'**
  String get actTaskCompleted;

  /// No description provided for @actMemberJoined.
  ///
  /// In en, this message translates to:
  /// **'joined the team'**
  String get actMemberJoined;

  /// No description provided for @actMemberLeft.
  ///
  /// In en, this message translates to:
  /// **'left the team'**
  String get actMemberLeft;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All Events'**
  String get filterAll;

  /// No description provided for @filterPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal Only'**
  String get filterPersonal;

  /// No description provided for @filterTeam.
  ///
  /// In en, this message translates to:
  /// **'Team Only'**
  String get filterTeam;

  /// No description provided for @assignedToMe.
  ///
  /// In en, this message translates to:
  /// **'Assigned to me'**
  String get assignedToMe;

  /// Calendar View
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get viewWeekly;

  /// Calendar View
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get viewMonthly;

  /// Calendar View
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get viewDaily;

  /// Menu Option
  ///
  /// In en, this message translates to:
  /// **'Smart Add (Nova)'**
  String get addSmart;

  /// Menu Option
  ///
  /// In en, this message translates to:
  /// **'Manual Add'**
  String get addManual;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Nova Assistant'**
  String get novaAssistant;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Type or speak, I will create for you.'**
  String get novaPrompt;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Type here...'**
  String get novaInputHint;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Nova didn\'t understand that.'**
  String get novaUnderstandError;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied.'**
  String get micPermissionError;

  /// Footer
  ///
  /// In en, this message translates to:
  /// **'Powered by'**
  String get poweredBy;

  /// Company Name
  ///
  /// In en, this message translates to:
  /// **'Techluna Software'**
  String get techlunaSoftware;

  /// No description provided for @tabKanban.
  ///
  /// In en, this message translates to:
  /// **'Kanban'**
  String get tabKanban;

  /// No description provided for @tabResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get tabResources;

  /// No description provided for @statusTodo.
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get statusTodo;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @addLink.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLink;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @pinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Pinned Message'**
  String get pinnedMessage;

  /// No description provided for @mvpTitle.
  ///
  /// In en, this message translates to:
  /// **'Star of the Week'**
  String get mvpTitle;

  /// No description provided for @workloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Workload Distribution'**
  String get workloadTitle;

  /// No description provided for @linkUrl.
  ///
  /// In en, this message translates to:
  /// **'Link (https://...)'**
  String get linkUrl;

  /// No description provided for @linkTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get linkTitle;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLink;

  /// No description provided for @noResources.
  ///
  /// In en, this message translates to:
  /// **'No resources added yet.'**
  String get noResources;

  /// No description provided for @moveNext.
  ///
  /// In en, this message translates to:
  /// **'Move Next'**
  String get moveNext;

  /// No description provided for @movePrev.
  ///
  /// In en, this message translates to:
  /// **'Move Back'**
  String get movePrev;

  /// No description provided for @filterMyTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks Only'**
  String get filterMyTasks;

  /// No description provided for @filterAllTeamTasks.
  ///
  /// In en, this message translates to:
  /// **'All Team Tasks'**
  String get filterAllTeamTasks;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @taskStatus.
  ///
  /// In en, this message translates to:
  /// **'Task Status'**
  String get taskStatus;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @noCompletedTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet.'**
  String get noCompletedTasksYet;

  /// No description provided for @taskCount.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskCount;

  /// No description provided for @actMovedToProgress.
  ///
  /// In en, this message translates to:
  /// **'started task'**
  String get actMovedToProgress;

  /// No description provided for @actMovedToTodo.
  ///
  /// In en, this message translates to:
  /// **'moved task back'**
  String get actMovedToTodo;

  /// No description provided for @actFinished.
  ///
  /// In en, this message translates to:
  /// **'finished task'**
  String get actFinished;

  /// No description provided for @addLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLinkTitle;

  /// No description provided for @linkTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get linkTitleHint;

  /// No description provided for @linkUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Link (https://...)'**
  String get linkUrlHint;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @makeAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Make Announcement'**
  String get makeAnnouncement;

  /// No description provided for @announcementHint.
  ///
  /// In en, this message translates to:
  /// **'Your message...'**
  String get announcementHint;

  /// No description provided for @noAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get noAnnouncements;

  /// No description provided for @resourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resourcesTitle;

  /// No description provided for @noResourcesYet.
  ///
  /// In en, this message translates to:
  /// **'No resources added yet.'**
  String get noResourcesYet;

  /// No description provided for @tabKanbanTitle.
  ///
  /// In en, this message translates to:
  /// **'Kanban'**
  String get tabKanbanTitle;

  /// No description provided for @tabDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboardTitle;

  /// No description provided for @tabResourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get tabResourcesTitle;

  /// No description provided for @tabActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get tabActivityTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
