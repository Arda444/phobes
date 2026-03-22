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
  /// **'Full Name'**
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
  /// **'Loading'**
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

  /// No description provided for @resetPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address, we will send a reset link.'**
  String get resetPasswordPrompt;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @resetPasswordEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Reset email sent!'**
  String get resetPasswordEmailSent;

  /// No description provided for @invalidEmailPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email and at least 6-character password.'**
  String get invalidEmailPasswordPrompt;

  /// No description provided for @fillAllFieldsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get fillAllFieldsPrompt;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign in failed: {error}'**
  String googleSignInFailed(Object error);

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @brandPhilosophyTitle.
  ///
  /// In en, this message translates to:
  /// **'Brand Philosophy & Name'**
  String get brandPhilosophyTitle;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @teamAndThanks.
  ///
  /// In en, this message translates to:
  /// **'Our Team & Special Thanks'**
  String get teamAndThanks;

  /// No description provided for @securityPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get securityPrivacy;

  /// No description provided for @brandHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Future Time Management Ecosystem'**
  String get brandHeroTitle;

  /// No description provided for @brandHeroDesc.
  ///
  /// In en, this message translates to:
  /// **'Phobes is a digital life laboratory that transforms chaos into order, synchronizing every moment of life with AI.'**
  String get brandHeroDesc;

  /// No description provided for @productivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get productivity;

  /// No description provided for @harmony.
  ///
  /// In en, this message translates to:
  /// **'Harmony'**
  String get harmony;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @efficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get efficiency;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @aboutPhobesLongDesc.
  ///
  /// In en, this message translates to:
  /// **'Phobes set out to build the digital peace that individuals and teams need in the complex and fast-paced world of the 21st century. We are not just a task manager, we are lifestyle architects. Every line of our code was written to make our users\' time more valuable, reduce their stress, and establish a perfect balance in every area of life (work, health, finance, social).\n\nWith the belief that technology should serve human life, the Phobes ecosystem brings together AI and user-friendly interfaces to transform chaos into a planned structure. For us, success is not just completed tasks, but the peaceful time you gain at the end of those tasks.'**
  String get aboutPhobesLongDesc;

  /// No description provided for @techlunaPartners.
  ///
  /// In en, this message translates to:
  /// **'Techluna Software Partners'**
  String get techlunaPartners;

  /// No description provided for @coFounder.
  ///
  /// In en, this message translates to:
  /// **'Co-Founder'**
  String get coFounder;

  /// No description provided for @specialThanks.
  ///
  /// In en, this message translates to:
  /// **'Special Thanks'**
  String get specialThanks;

  /// No description provided for @specialThanksDesc.
  ///
  /// In en, this message translates to:
  /// **'Phobes is a project nourished not just by lines of code, but by dreams and unwavering belief. On this journey; our esteemed teacher who opened our horizons with her vision and was always by our side'**
  String get specialThanksDesc;

  /// No description provided for @academicTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant Professor'**
  String get academicTitle;

  /// No description provided for @yourDataYourFortress.
  ///
  /// In en, this message translates to:
  /// **'Your Data, Your Fortress'**
  String get yourDataYourFortress;

  /// No description provided for @dataNeverSold.
  ///
  /// In en, this message translates to:
  /// **'Your data is never sold.'**
  String get dataNeverSold;

  /// No description provided for @endToEndTransparency.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Transparency'**
  String get endToEndTransparency;

  /// No description provided for @dataProcessingTransparency.
  ///
  /// In en, this message translates to:
  /// **'You can see which data is processed and why.'**
  String get dataProcessingTransparency;

  /// No description provided for @featureCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Creative Feature Catalog'**
  String get featureCatalogTitle;

  /// No description provided for @featureCatalogDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed breakdown of all modules and capabilities in the Phobes ecosystem.'**
  String get featureCatalogDesc;

  /// No description provided for @featureTreeTitle.
  ///
  /// In en, this message translates to:
  /// **'FEATURE TREE'**
  String get featureTreeTitle;

  /// No description provided for @contactChannels.
  ///
  /// In en, this message translates to:
  /// **'Contact Channels'**
  String get contactChannels;

  /// No description provided for @generalContact.
  ///
  /// In en, this message translates to:
  /// **'General Contact'**
  String get generalContact;

  /// No description provided for @supportHotline.
  ///
  /// In en, this message translates to:
  /// **'Support Hotline'**
  String get supportHotline;

  /// No description provided for @catTaskProject.
  ///
  /// In en, this message translates to:
  /// **'TASKS & PROJECTS'**
  String get catTaskProject;

  /// No description provided for @catTaskProjectDesc.
  ///
  /// In en, this message translates to:
  /// **'Action layer; the main hub that turns ideas into reality and manages time.'**
  String get catTaskProjectDesc;

  /// No description provided for @secActionManagement.
  ///
  /// In en, this message translates to:
  /// **'Action Management'**
  String get secActionManagement;

  /// No description provided for @secViewModes.
  ///
  /// In en, this message translates to:
  /// **'View Modes'**
  String get secViewModes;

  /// No description provided for @secNavDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Nav & Discovery'**
  String get secNavDiscovery;

  /// No description provided for @catNovaAi.
  ///
  /// In en, this message translates to:
  /// **'NOVA AI'**
  String get catNovaAi;

  /// No description provided for @catNovaAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Smart controller; the intelligence that monitors, analyzes, and guides you.'**
  String get catNovaAiDesc;

  /// No description provided for @secAnalysisPlanning.
  ///
  /// In en, this message translates to:
  /// **'Analysis & Planning'**
  String get secAnalysisPlanning;

  /// No description provided for @catFinance.
  ///
  /// In en, this message translates to:
  /// **'FINANCE'**
  String get catFinance;

  /// No description provided for @catFinanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Financial peace; the module that manages your budget and plans your financial future.'**
  String get catFinanceDesc;

  /// No description provided for @secControlPanel.
  ///
  /// In en, this message translates to:
  /// **'Control Panel'**
  String get secControlPanel;

  /// No description provided for @catLifeHealth.
  ///
  /// In en, this message translates to:
  /// **'LIFE & HEALTH'**
  String get catLifeHealth;

  /// No description provided for @catLifeHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Holistic balance; reminders that protect both your physical and mental health.'**
  String get catLifeHealthDesc;

  /// No description provided for @secBalanceTools.
  ///
  /// In en, this message translates to:
  /// **'Balance Tools'**
  String get secBalanceTools;

  /// No description provided for @catPhobesCore.
  ///
  /// In en, this message translates to:
  /// **'PHOBES CORE'**
  String get catPhobesCore;

  /// No description provided for @catPhobesCoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Core infrastructure; the lifeblood that protects your data and keeps it ready everywhere.'**
  String get catPhobesCoreDesc;

  /// No description provided for @secSecuritySpeed.
  ///
  /// In en, this message translates to:
  /// **'Security & Speed'**
  String get secSecuritySpeed;

  /// No description provided for @featAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add New Task'**
  String get featAddTask;

  /// No description provided for @featAddTaskDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick entry with one tap and detailed planning.'**
  String get featAddTaskDesc;

  /// No description provided for @featDynamicSnooze.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Snooze'**
  String get featDynamicSnooze;

  /// No description provided for @featDynamicSnoozeDesc.
  ///
  /// In en, this message translates to:
  /// **'Smartly moving tasks to future dates.'**
  String get featDynamicSnoozeDesc;

  /// No description provided for @featSubtasks.
  ///
  /// In en, this message translates to:
  /// **'Sub-tasks'**
  String get featSubtasks;

  /// No description provided for @featSubtasksDesc.
  ///
  /// In en, this message translates to:
  /// **'Breaking down complex jobs into small pieces.'**
  String get featSubtasksDesc;

  /// No description provided for @featQuickEdit.
  ///
  /// In en, this message translates to:
  /// **'Quick Edit'**
  String get featQuickEdit;

  /// No description provided for @featQuickEditDesc.
  ///
  /// In en, this message translates to:
  /// **'Instant text and date updates via the list.'**
  String get featQuickEditDesc;

  /// No description provided for @featDailyList.
  ///
  /// In en, this message translates to:
  /// **'Daily List'**
  String get featDailyList;

  /// No description provided for @featDailyListDesc.
  ///
  /// In en, this message translates to:
  /// **'A simple and efficient flow focusing on today.'**
  String get featDailyListDesc;

  /// No description provided for @featWeeklyCalendar.
  ///
  /// In en, this message translates to:
  /// **'Weekly Calendar'**
  String get featWeeklyCalendar;

  /// No description provided for @featWeeklyCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'View the 7-day plan at a glance.'**
  String get featWeeklyCalendarDesc;

  /// No description provided for @featMonthlyPlanner.
  ///
  /// In en, this message translates to:
  /// **'Monthly Planner'**
  String get featMonthlyPlanner;

  /// No description provided for @featMonthlyPlannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Long-term strategic calendar view.'**
  String get featMonthlyPlannerDesc;

  /// No description provided for @featKanbanBoard.
  ///
  /// In en, this message translates to:
  /// **'Kanban Board'**
  String get featKanbanBoard;

  /// No description provided for @featKanbanBoardDesc.
  ///
  /// In en, this message translates to:
  /// **'Drag-and-drop cards for process management.'**
  String get featKanbanBoardDesc;

  /// No description provided for @featAdvancedFiltering.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filtering'**
  String get featAdvancedFiltering;

  /// No description provided for @featAdvancedFilteringDesc.
  ///
  /// In en, this message translates to:
  /// **'Filter by importance, team, and category.'**
  String get featAdvancedFilteringDesc;

  /// No description provided for @featSmartTaskSearch.
  ///
  /// In en, this message translates to:
  /// **'Smart Task Search'**
  String get featSmartTaskSearch;

  /// No description provided for @featSmartTaskSearchDesc.
  ///
  /// In en, this message translates to:
  /// **'Instant keyword search across all projects.'**
  String get featSmartTaskSearchDesc;

  /// No description provided for @featPriorityLabels.
  ///
  /// In en, this message translates to:
  /// **'Priority Labels'**
  String get featPriorityLabels;

  /// No description provided for @featPriorityLabelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Mark critical jobs with colored levels.'**
  String get featPriorityLabelsDesc;

  /// No description provided for @featVoiceCommand.
  ///
  /// In en, this message translates to:
  /// **'Voice Command Recognition'**
  String get featVoiceCommand;

  /// No description provided for @featVoiceCommandDesc.
  ///
  /// In en, this message translates to:
  /// **'Creating tasks and managing the system with voice.'**
  String get featVoiceCommandDesc;

  /// No description provided for @featSmartReminders.
  ///
  /// In en, this message translates to:
  /// **'Smart Reminders'**
  String get featSmartReminders;

  /// No description provided for @featSmartRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Context-aware and priority-based notifications.'**
  String get featSmartRemindersDesc;

  /// No description provided for @featUsageAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Usage Analytics'**
  String get featUsageAnalytics;

  /// No description provided for @featUsageAnalyticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Deep insights into your productivity habits.'**
  String get featUsageAnalyticsDesc;

  /// No description provided for @featBudgetManagement.
  ///
  /// In en, this message translates to:
  /// **'Budget Management'**
  String get featBudgetManagement;

  /// No description provided for @featBudgetManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed tracking of income, expenses, and savings.'**
  String get featBudgetManagementDesc;

  /// No description provided for @featFinancialGoals.
  ///
  /// In en, this message translates to:
  /// **'Financial Goals'**
  String get featFinancialGoals;

  /// No description provided for @featFinancialGoalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Set and track goals for future investments.'**
  String get featFinancialGoalsDesc;

  /// No description provided for @featSubscriptionTracking.
  ///
  /// In en, this message translates to:
  /// **'Subscription Tracking'**
  String get featSubscriptionTracking;

  /// No description provided for @featSubscriptionTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep all your monthly payments under control.'**
  String get featSubscriptionTrackingDesc;

  /// No description provided for @featHealthTracking.
  ///
  /// In en, this message translates to:
  /// **'Health Tracking'**
  String get featHealthTracking;

  /// No description provided for @featHealthTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Track water, sleep, and physical activity.'**
  String get featHealthTrackingDesc;

  /// No description provided for @featMindfulnessReminders.
  ///
  /// In en, this message translates to:
  /// **'Mindfulness Reminders'**
  String get featMindfulnessReminders;

  /// No description provided for @featMindfulnessRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Subtle alerts for mental focus and rest.'**
  String get featMindfulnessRemindersDesc;

  /// No description provided for @featMedicationTracking.
  ///
  /// In en, this message translates to:
  /// **'Medication Tracking'**
  String get featMedicationTracking;

  /// No description provided for @featMedicationTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Full management for pills and treatments.'**
  String get featMedicationTrackingDesc;

  /// No description provided for @featCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get featCloudSync;

  /// No description provided for @featCloudSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Your data is always ready on all devices.'**
  String get featCloudSyncDesc;

  /// No description provided for @featBiometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get featBiometricLock;

  /// No description provided for @featBiometricLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Security with Fingerprint or Face ID.'**
  String get featBiometricLockDesc;

  /// No description provided for @featOfflineSupport.
  ///
  /// In en, this message translates to:
  /// **'Offline Support'**
  String get featOfflineSupport;

  /// No description provided for @featOfflineSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Ability to work even without internet.'**
  String get featOfflineSupportDesc;

  /// No description provided for @corpInfo.
  ///
  /// In en, this message translates to:
  /// **'Corporate Information'**
  String get corpInfo;

  /// No description provided for @techlunaDesc.
  ///
  /// In en, this message translates to:
  /// **'A software laboratory that combines technology and design for modern productivity solutions.'**
  String get techlunaDesc;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Techluna Software • Phobes v1.2.5'**
  String get allRightsReserved;

  /// No description provided for @aboutPhobes.
  ///
  /// In en, this message translates to:
  /// **'About Phobes'**
  String get aboutPhobes;

  /// No description provided for @featureTree.
  ///
  /// In en, this message translates to:
  /// **'Feature Tree'**
  String get featureTree;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

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
  /// **'Appointment Code'**
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
  /// **'Invalid code or group not found!'**
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

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Assign To'**
  String get assignTo;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {name}'**
  String assignedTo(String name);

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get kickMember;

  /// Warning message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this member?'**
  String get kickMemberWarning;

  /// Success message
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemoved;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'(Me)'**
  String get me;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get tabActivity;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get teamLeaderboard;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Project Progress'**
  String get projectProgress;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// Activity action
  ///
  /// In en, this message translates to:
  /// **'created task'**
  String get actTaskCreated;

  /// Activity action
  ///
  /// In en, this message translates to:
  /// **'completed task'**
  String get actTaskCompleted;

  /// Activity action
  ///
  /// In en, this message translates to:
  /// **'joined the team'**
  String get actMemberJoined;

  /// Activity action
  ///
  /// In en, this message translates to:
  /// **'left the team'**
  String get actMemberLeft;

  /// Filter option
  ///
  /// In en, this message translates to:
  /// **'All Events'**
  String get filterAll;

  /// Filter option
  ///
  /// In en, this message translates to:
  /// **'Personal Tasks'**
  String get filterPersonal;

  /// Filter option
  ///
  /// In en, this message translates to:
  /// **'Team Only'**
  String get filterTeam;

  /// Filter option
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

  /// Tab title
  ///
  /// In en, this message translates to:
  /// **'Kanban'**
  String get tabKanban;

  /// Tab title
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get tabResources;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get statusTodo;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLink;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Pinned Message'**
  String get pinnedMessage;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Star of the Week'**
  String get mvpTitle;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Workload Distribution'**
  String get workloadTitle;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Link (https://...)'**
  String get linkUrl;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get linkTitle;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLink;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'No resources added yet.'**
  String get noResources;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Move Next'**
  String get moveNext;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Move Back'**
  String get movePrev;

  /// Screen Title
  ///
  /// In en, this message translates to:
  /// **'Appointment Center'**
  String get appointmentCenter;

  /// Button Tooltip
  ///
  /// In en, this message translates to:
  /// **'Service Settings'**
  String get manageServices;

  /// Button Tooltip
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookNewAppointment;

  /// Tab Label
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get managementTab;

  /// Tab Label
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get myAppointmentsTab;

  /// Appointment Status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Appointment Status
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// Appointment Status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Appointment Status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get btnApprove;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get btnReject;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get btnCall;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get btnMap;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get btnWeb;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get btnShare;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get btnCopy;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get btnEdit;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get labelService;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get labelProvider;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get labelDate;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get labelNote;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get labelClient;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'No appointments yet.'**
  String get msgNoAppointments;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'No service groups created yet.'**
  String get msgNoServices;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get msgCodeCopied;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get msgStatusUpdated;

  /// Form Label
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// Form Label
  ///
  /// In en, this message translates to:
  /// **'Service Title'**
  String get serviceTitle;

  /// Form Label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Form Label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Form Label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Form Label
  ///
  /// In en, this message translates to:
  /// **'Cancellation Policy'**
  String get cancellationPolicy;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Cancellation is not allowed within {hours} hours.'**
  String policyWarning(Object hours);

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Client name or phone...'**
  String get searchPlaceholder;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// Kanban filter
  ///
  /// In en, this message translates to:
  /// **'My Tasks Only'**
  String get filterMyTasks;

  /// Kanban filter
  ///
  /// In en, this message translates to:
  /// **'All Team Tasks'**
  String get filterAllTeamTasks;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// User label
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Priority
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Task Status'**
  String get taskStatus;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet.'**
  String get noCompletedTasksYet;

  /// Unit
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskCount;

  /// Activity
  ///
  /// In en, this message translates to:
  /// **'started task'**
  String get actMovedToProgress;

  /// Activity
  ///
  /// In en, this message translates to:
  /// **'moved task back'**
  String get actMovedToTodo;

  /// Activity
  ///
  /// In en, this message translates to:
  /// **'finished task'**
  String get actFinished;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLinkTitle;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get linkTitleHint;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Link (https://...)'**
  String get linkUrlHint;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Make Announcement'**
  String get makeAnnouncement;

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Your message...'**
  String get announcementHint;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get noAnnouncements;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resourcesTitle;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'No resources added yet.'**
  String get noResourcesYet;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Kanban'**
  String get tabKanbanTitle;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboardTitle;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get tabResourcesTitle;

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get tabActivityTitle;

  /// No description provided for @enterServiceCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code you received from your service provider.'**
  String get enterServiceCodeHint;

  /// No description provided for @btnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get btnContinue;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @completeBooking.
  ///
  /// In en, this message translates to:
  /// **'Complete Booking'**
  String get completeBooking;

  /// No description provided for @msgAppointmentSent.
  ///
  /// In en, this message translates to:
  /// **'Appointment request sent! ✅'**
  String get msgAppointmentSent;

  /// No description provided for @msgNoSlots.
  ///
  /// In en, this message translates to:
  /// **'No available slots for today.'**
  String get msgNoSlots;

  /// No description provided for @businessInfo.
  ///
  /// In en, this message translates to:
  /// **'Business Info'**
  String get businessInfo;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointment;

  /// No description provided for @cancelWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this appointment?'**
  String get cancelWarning;

  /// No description provided for @cancellationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Not Allowed'**
  String get cancellationNotAllowed;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status Updated'**
  String get statusUpdated;

  /// No description provided for @navLife.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get navLife;

  /// No description provided for @navHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get navHabits;

  /// No description provided for @navFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get navFocus;

  /// No description provided for @navAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get navAppointments;

  /// No description provided for @descHabits.
  ///
  /// In en, this message translates to:
  /// **'Track daily routines'**
  String get descHabits;

  /// No description provided for @descFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus with Pomodoro'**
  String get descFocus;

  /// No description provided for @descAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointment Management'**
  String get descAppointments;

  /// No description provided for @descStats.
  ///
  /// In en, this message translates to:
  /// **'Productivity analysis'**
  String get descStats;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @filterClient.
  ///
  /// In en, this message translates to:
  /// **'My Appointments (Client)'**
  String get filterClient;

  /// No description provided for @filterProvider.
  ///
  /// In en, this message translates to:
  /// **'Business Appointments'**
  String get filterProvider;

  /// No description provided for @filterTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams & Groups'**
  String get filterTeams;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @navMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get navMedications;

  /// No description provided for @navUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get navUpcomingEvents;

  /// No description provided for @descMedications.
  ///
  /// In en, this message translates to:
  /// **'Track medications & doses'**
  String get descMedications;

  /// No description provided for @descUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming events'**
  String get descUpcomingEvents;

  /// No description provided for @medicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medicationsTitle;

  /// No description provided for @medicationName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// No description provided for @medicationDosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get medicationDosage;

  /// No description provided for @medicationFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get medicationFrequency;

  /// No description provided for @medicationTimes.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get medicationTimes;

  /// No description provided for @medicationColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get medicationColor;

  /// No description provided for @medicationIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get medicationIcon;

  /// No description provided for @medicationActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get medicationActive;

  /// No description provided for @medicationInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get medicationInactive;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// No description provided for @editMedication.
  ///
  /// In en, this message translates to:
  /// **'Edit Medication'**
  String get editMedication;

  /// No description provided for @deleteMedication.
  ///
  /// In en, this message translates to:
  /// **'Delete Medication'**
  String get deleteMedication;

  /// No description provided for @deleteMedicationWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medication?'**
  String get deleteMedicationWarning;

  /// No description provided for @dailyAdherence.
  ///
  /// In en, this message translates to:
  /// **'Daily Adherence'**
  String get dailyAdherence;

  /// No description provided for @weeklyAdherence.
  ///
  /// In en, this message translates to:
  /// **'Weekly Adherence'**
  String get weeklyAdherence;

  /// No description provided for @todayDoses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Doses'**
  String get todayDoses;

  /// No description provided for @allMedications.
  ///
  /// In en, this message translates to:
  /// **'All Medications'**
  String get allMedications;

  /// No description provided for @doseTaken.
  ///
  /// In en, this message translates to:
  /// **'Dose taken'**
  String get doseTaken;

  /// No description provided for @doseSkipped.
  ///
  /// In en, this message translates to:
  /// **'Dose skipped'**
  String get doseSkipped;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @frequencyAsNeeded.
  ///
  /// In en, this message translates to:
  /// **'As Needed'**
  String get frequencyAsNeeded;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @notifFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notifFilterAll;

  /// No description provided for @notifFilterTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get notifFilterTasks;

  /// No description provided for @notifFilterHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get notifFilterHabits;

  /// No description provided for @notifFilterMeds.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get notifFilterMeds;

  /// No description provided for @notifFilterAppts.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get notifFilterAppts;

  /// No description provided for @notifFilterTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get notifFilterTeams;

  /// No description provided for @notifFilterSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notifFilterSystem;

  /// No description provided for @upcomingEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEventsTitle;

  /// No description provided for @upcomingToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get upcomingToday;

  /// No description provided for @upcomingTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get upcomingTomorrow;

  /// No description provided for @upcomingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get upcomingThisWeek;

  /// No description provided for @upcomingNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get upcomingNoEvents;

  /// No description provided for @upcomingFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get upcomingFilterAll;

  /// No description provided for @upcomingFilterTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get upcomingFilterTasks;

  /// No description provided for @upcomingFilterMeds.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get upcomingFilterMeds;

  /// No description provided for @upcomingFilterAppts.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get upcomingFilterAppts;

  /// No description provided for @upcomingFilterHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get upcomingFilterHabits;

  /// No description provided for @prefTaskDeadline.
  ///
  /// In en, this message translates to:
  /// **'Task Deadline'**
  String get prefTaskDeadline;

  /// No description provided for @prefTaskOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue Task'**
  String get prefTaskOverdue;

  /// No description provided for @prefHabitStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak at Risk'**
  String get prefHabitStreak;

  /// No description provided for @prefHabitMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get prefHabitMilestone;

  /// No description provided for @prefMedDose.
  ///
  /// In en, this message translates to:
  /// **'Dose Time'**
  String get prefMedDose;

  /// No description provided for @prefMedMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed Dose'**
  String get prefMedMissed;

  /// No description provided for @prefMedRefill.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get prefMedRefill;

  /// No description provided for @prefApptReminder.
  ///
  /// In en, this message translates to:
  /// **'Appointment Reminder'**
  String get prefApptReminder;

  /// No description provided for @prefApptStatus.
  ///
  /// In en, this message translates to:
  /// **'Status Change'**
  String get prefApptStatus;

  /// No description provided for @prefFocusSession.
  ///
  /// In en, this message translates to:
  /// **'Session End'**
  String get prefFocusSession;

  /// No description provided for @prefFocusBreak.
  ///
  /// In en, this message translates to:
  /// **'Break End'**
  String get prefFocusBreak;

  /// No description provided for @prefTeamAssign.
  ///
  /// In en, this message translates to:
  /// **'Task Assignment'**
  String get prefTeamAssign;

  /// No description provided for @prefTeamAnnounce.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get prefTeamAnnounce;

  /// No description provided for @prefTeamDeadline.
  ///
  /// In en, this message translates to:
  /// **'Team Deadline'**
  String get prefTeamDeadline;

  /// No description provided for @prefMorningBrief.
  ///
  /// In en, this message translates to:
  /// **'Morning Brief'**
  String get prefMorningBrief;

  /// No description provided for @prefWeeklyDigest.
  ///
  /// In en, this message translates to:
  /// **'Weekly Digest'**
  String get prefWeeklyDigest;
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
