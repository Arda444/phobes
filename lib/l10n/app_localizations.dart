import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

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
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh')
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

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

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

  /// Label
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get yesterday;

  /// Activity verb
  ///
  /// In en, this message translates to:
  /// **'created'**
  String get activityCreated;

  /// Activity verb
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get activityCompleted;

  /// Activity verb
  ///
  /// In en, this message translates to:
  /// **'started working on'**
  String get activityStarted;

  /// Activity verb
  ///
  /// In en, this message translates to:
  /// **'moved'**
  String get activityMoved;

  /// Activity verb
  ///
  /// In en, this message translates to:
  /// **'joined'**
  String get activityJoined;

  /// Activity verb
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get activityUpdated;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'New Habit'**
  String get habitNew;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Start Chain'**
  String get habitStartChain;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Let\'s Get Started'**
  String get habitGetStarted;

  /// Encouragement
  ///
  /// In en, this message translates to:
  /// **'Great going! 🔥'**
  String get habitGreatGoing;

  /// Encouragement
  ///
  /// In en, this message translates to:
  /// **'Don\'t Break the Chain'**
  String get habitDontBreakChain;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Habit'**
  String get habitDeleteTitle;

  /// Dialog message
  ///
  /// In en, this message translates to:
  /// **'This habit will be permanently deleted.'**
  String get habitDeleteWarning;

  /// Frequency option
  ///
  /// In en, this message translates to:
  /// **'As Needed'**
  String get asNeeded;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

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

  /// No description provided for @noteTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get noteTrash;

  /// No description provided for @noteNotebookNotes.
  ///
  /// In en, this message translates to:
  /// **'Notebook Notes'**
  String get noteNotebookNotes;

  /// No description provided for @notePin.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get notePin;

  /// No description provided for @noteSortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get noteSortDate;

  /// No description provided for @noteSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteSortTitle;

  /// No description provided for @noteSortCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get noteSortCategory;

  /// No description provided for @noteSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes...'**
  String get noteSearchHint;

  /// No description provided for @noteAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get noteAll;

  /// No description provided for @noteTeamNotes.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get noteTeamNotes;

  /// No description provided for @noteProjectNotes.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get noteProjectNotes;

  /// No description provided for @noteFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get noteFavorites;

  /// No description provided for @noteArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get noteArchive;

  /// No description provided for @noteCatGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get noteCatGeneral;

  /// No description provided for @noteCatWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get noteCatWork;

  /// No description provided for @noteCatPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get noteCatPersonal;

  /// No description provided for @noteCatIdeas.
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get noteCatIdeas;

  /// No description provided for @noteCatMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get noteCatMeeting;

  /// No description provided for @noteCatResearch.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get noteCatResearch;

  /// No description provided for @noteCatStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get noteCatStudy;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Share statistics report
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get statsShare;

  /// Download statistics report
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get statsDownload;

  /// Share sheet title
  ///
  /// In en, this message translates to:
  /// **'Share report'**
  String get statsShareReport;

  /// Download sheet title
  ///
  /// In en, this message translates to:
  /// **'Download report'**
  String get statsDownloadReport;

  /// PDF format label
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get statsExportPdf;

  /// Excel format label
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get statsExportExcel;

  /// Share PDF action
  ///
  /// In en, this message translates to:
  /// **'Share as PDF'**
  String get statsSharePdf;

  /// Share Excel action
  ///
  /// In en, this message translates to:
  /// **'Share as Excel'**
  String get statsShareExcel;

  /// Download PDF action
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get statsDownloadPdf;

  /// Download Excel action
  ///
  /// In en, this message translates to:
  /// **'Download Excel'**
  String get statsDownloadExcel;

  /// Export in progress
  ///
  /// In en, this message translates to:
  /// **'Preparing export…'**
  String get statsExporting;

  /// Export error
  ///
  /// In en, this message translates to:
  /// **'Export failed. Try again.'**
  String get statsExportFailed;

  /// Download completed
  ///
  /// In en, this message translates to:
  /// **'File downloaded'**
  String get statsDownloadSuccess;

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

  /// No description provided for @analyzingData.
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

  /// No description provided for @joinTeamPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to join this team.'**
  String get joinTeamPermissionDenied;

  /// No description provided for @joinTeamFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not join the team. Try again later.'**
  String get joinTeamFailed;

  /// No description provided for @joinCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter team join code'**
  String get joinCodeHint;

  /// No description provided for @statsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading data…'**
  String get statsLoading;

  /// No description provided for @statsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load statistics. Pull to refresh.'**
  String get statsLoadFailed;

  /// No description provided for @teamRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get teamRoleOwner;

  /// No description provided for @teamRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get teamRoleAdmin;

  /// No description provided for @teamRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get teamRoleMember;

  /// No description provided for @createTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new team'**
  String get createTeamTitle;

  /// No description provided for @teamWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get teamWorkspace;

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
  /// **'Personal Only'**
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
  /// **'Approve'**
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

  /// No description provided for @appointmentCode.
  ///
  /// In en, this message translates to:
  /// **'Appointment Code'**
  String get appointmentCode;

  /// No description provided for @enterServiceCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code provided by the service provider.'**
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

  /// No description provided for @btnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get btnConfirm;

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

  /// No description provided for @invalidAppointmentCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code or group not found!'**
  String get invalidAppointmentCode;

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

  /// Tab
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get noteMyNotes;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get noteUnpin;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get noteFavorite;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Remove Favorite'**
  String get noteUnfavorite;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get noteArchiveAction;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get noteUnarchive;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get notePermissions;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Link Task'**
  String get noteLinkTask;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Unlink Task'**
  String get noteUnlinkTask;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Coming Soon 🚀'**
  String get noteComingSoon;

  /// Stats
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String noteWords(int count);

  /// Stats
  ///
  /// In en, this message translates to:
  /// **'{count} chars'**
  String noteChars(int count);

  /// Stats
  ///
  /// In en, this message translates to:
  /// **'~{min} min read'**
  String noteReadTime(int min);

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Auto-saved'**
  String get noteAutoSaved;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get noteUnsaved;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'View Permission'**
  String get noteViewPermission;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Edit Permission'**
  String get noteEditPermission;

  /// Permission
  ///
  /// In en, this message translates to:
  /// **'Only Me'**
  String get notePermOwner;

  /// Permission
  ///
  /// In en, this message translates to:
  /// **'Entire Team'**
  String get notePermTeam;

  /// Permission
  ///
  /// In en, this message translates to:
  /// **'Admins Only'**
  String get notePermAdmins;

  /// Permission
  ///
  /// In en, this message translates to:
  /// **'Specific Users'**
  String get notePermSpecific;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Insert Table'**
  String get noteTableInsert;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get noteTableRows;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get noteTableCols;

  /// Header
  ///
  /// In en, this message translates to:
  /// **'Linked Tasks'**
  String get noteLinkedTasks;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'No linked tasks'**
  String get noteNoLinkedTasks;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get noteTemplate;

  /// Template
  ///
  /// In en, this message translates to:
  /// **'Meeting Notes'**
  String get noteTemplateMeeting;

  /// Template
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get noteTemplateDiary;

  /// Template
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get noteTemplateIdea;

  /// Template
  ///
  /// In en, this message translates to:
  /// **'Project Plan'**
  String get noteTemplateProject;

  /// Template
  ///
  /// In en, this message translates to:
  /// **'Blank Note'**
  String get noteTemplateBlank;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'From Template'**
  String get noteFromTemplate;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Quick Note'**
  String get noteQuickNote;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get noteFocusMode;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Your notes will appear here'**
  String get noteEmptyState;

  /// Msg
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first note'**
  String get noteEmptyStateDesc;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get noteGridView;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get noteListView;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Select Team'**
  String get noteSelectTeam;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Select Project'**
  String get noteSelectProject;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get noteDuplicate;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get noteShare;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get noteAddImage;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Add File'**
  String get noteAddFile;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Create Table'**
  String get noteCreateTable;

  /// Generic error with detail
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String errorGeneric(String error);

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission for this action.'**
  String get errorPermissionDenied;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Record not found.'**
  String get errorNotFound;

  /// No description provided for @errorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service temporarily unavailable.'**
  String get errorUnavailable;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait.'**
  String get errorRateLimited;

  /// No description provided for @errorInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input.'**
  String get errorInvalidInput;

  /// No description provided for @errorAuth.
  ///
  /// In en, this message translates to:
  /// **'Authentication error.'**
  String get errorAuth;

  /// No description provided for @adminRoleClaimHint.
  ///
  /// In en, this message translates to:
  /// **'Admin access uses Firebase custom claims. Run: node admin-cli/set-admin.js <uid>'**
  String get adminRoleClaimHint;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Medicine name is required'**
  String get errorMedicineNameRequired;

  /// Note save error
  ///
  /// In en, this message translates to:
  /// **'Save error: {error}'**
  String errorNoteSave(String error);

  /// Habit reminder confirmation
  ///
  /// In en, this message translates to:
  /// **'Daily reminder set for {time}!'**
  String habitReminderSet(String time);

  /// Delete notebook confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the \"{name}\" notebook?'**
  String confirmDeleteNotebook(String name);

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Notebook'**
  String get deleteNotebook;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Medicine?'**
  String get confirmDeleteMedicine;

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get medicineStatusToggleActive;

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get medicineStatusTogglePassive;

  /// Admin header
  ///
  /// In en, this message translates to:
  /// **'ADMIN CONSOLE'**
  String get adminConsole;

  /// Admin menu
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashboard;

  /// Admin menu
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// Admin menu
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get adminEngagement;

  /// Admin menu
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get adminSystemSettings;

  /// Admin footer action
  ///
  /// In en, this message translates to:
  /// **'Exit Panel'**
  String get adminExitPanel;

  /// No description provided for @adminSystemModules.
  ///
  /// In en, this message translates to:
  /// **'System Modules'**
  String get adminSystemModules;

  /// No description provided for @adminModulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick access to all tools'**
  String get adminModulesSubtitle;

  /// No description provided for @adminRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get adminRecentActivity;

  /// No description provided for @adminRecentActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest operations performed on the system'**
  String get adminRecentActivitySubtitle;

  /// No description provided for @adminWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name} 👋'**
  String adminWelcome(String name);

  /// No description provided for @adminSystemStatusStable.
  ///
  /// In en, this message translates to:
  /// **'Overall system status looks stable today.'**
  String get adminSystemStatusStable;

  /// No description provided for @adminTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get adminTotalUsers;

  /// No description provided for @adminOpenFeedback.
  ///
  /// In en, this message translates to:
  /// **'Open Feedback'**
  String get adminOpenFeedback;

  /// No description provided for @adminActiveSurveys.
  ///
  /// In en, this message translates to:
  /// **'Active Surveys'**
  String get adminActiveSurveys;

  /// No description provided for @adminAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get adminAuditLogs;

  /// No description provided for @adminUserDatabase.
  ///
  /// In en, this message translates to:
  /// **'User Database'**
  String get adminUserDatabase;

  /// No description provided for @adminUserDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Card-based ultra-modern user directory'**
  String get adminUserDatabaseSubtitle;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusBanned.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get statusBanned;

  /// No description provided for @adminNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No Users Found'**
  String get adminNoUsersFound;

  /// No description provided for @adminNoUsersFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No records found matching your search criteria.'**
  String get adminNoUsersFoundSubtitle;

  /// No description provided for @adminSearchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users by name, email or ID...'**
  String get adminSearchUsers;

  /// No description provided for @adminUserGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get adminUserGuest;

  /// No description provided for @adminEmailNotSet.
  ///
  /// In en, this message translates to:
  /// **'Email not set'**
  String get adminEmailNotSet;

  /// No description provided for @adminRoleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get adminRoleUser;

  /// No description provided for @adminRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRoleAdmin;

  /// No description provided for @adminUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get adminUnknown;

  /// No description provided for @adminUnbanUser.
  ///
  /// In en, this message translates to:
  /// **'Allow Access'**
  String get adminUnbanUser;

  /// No description provided for @adminBanUser.
  ///
  /// In en, this message translates to:
  /// **'Ban User'**
  String get adminBanUser;

  /// No description provided for @adminDemoteRole.
  ///
  /// In en, this message translates to:
  /// **'Demote Role'**
  String get adminDemoteRole;

  /// No description provided for @adminPromoteRole.
  ///
  /// In en, this message translates to:
  /// **'Make Admin'**
  String get adminPromoteRole;

  /// No description provided for @adminBlacklistManagement.
  ///
  /// In en, this message translates to:
  /// **'Blacklist Management'**
  String get adminBlacklistManagement;

  /// No description provided for @adminBlacklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed audit of blocked identities and addresses'**
  String get adminBlacklistSubtitle;

  /// No description provided for @adminBlacklistAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New Blacklist Entry'**
  String get adminBlacklistAddTitle;

  /// No description provided for @adminCategoryType.
  ///
  /// In en, this message translates to:
  /// **'Category Type'**
  String get adminCategoryType;

  /// No description provided for @adminEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get adminEmailAddress;

  /// No description provided for @adminIpAddress.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get adminIpAddress;

  /// No description provided for @adminDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get adminDeviceId;

  /// No description provided for @adminBlockReason.
  ///
  /// In en, this message translates to:
  /// **'Block Reason'**
  String get adminBlockReason;

  /// No description provided for @adminAddRecord.
  ///
  /// In en, this message translates to:
  /// **'ADD RECORD'**
  String get adminAddRecord;

  /// No description provided for @adminDeleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get adminDeleteRecord;

  /// No description provided for @adminDeleteBlacklistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove \"{value}\" from the blacklist?'**
  String adminDeleteBlacklistConfirm(String value);

  /// No description provided for @adminDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete'**
  String get adminDeleteConfirmAction;

  /// No description provided for @adminNewEntry.
  ///
  /// In en, this message translates to:
  /// **'New Entry'**
  String get adminNewEntry;

  /// No description provided for @adminBlacklistClean.
  ///
  /// In en, this message translates to:
  /// **'Blacklist is Clean'**
  String get adminBlacklistClean;

  /// No description provided for @doseTakenCount.
  ///
  /// In en, this message translates to:
  /// **'{taken} / {total} doses taken'**
  String doseTakenCount(int taken, int total);

  /// No description provided for @medicationCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} Meds'**
  String medicationCountBadge(int count);

  /// No description provided for @showingInactiveMeds.
  ///
  /// In en, this message translates to:
  /// **'Showing Inactive'**
  String get showingInactiveMeds;

  /// No description provided for @showInactiveMeds.
  ///
  /// In en, this message translates to:
  /// **'Show Inactive'**
  String get showInactiveMeds;

  /// No description provided for @medicationWeeklyShort.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get medicationWeeklyShort;

  /// No description provided for @remainingStock.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String remainingStock(int count);

  /// No description provided for @criticalLevel.
  ///
  /// In en, this message translates to:
  /// **'Critical Level'**
  String get criticalLevel;

  /// No description provided for @deleteMedicationConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be deleted. This action cannot be undone.'**
  String deleteMedicationConfirmDesc(String name);

  /// No description provided for @deleteMedicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Medication'**
  String get deleteMedicationTitle;

  /// No description provided for @noMedicationsYet.
  ///
  /// In en, this message translates to:
  /// **'No medications yet'**
  String get noMedicationsYet;

  /// No description provided for @startTrackingMeds.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your medications'**
  String get startTrackingMeds;

  /// No description provided for @teamMemberCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get teamMemberCountLabel;

  /// No description provided for @teamProjectCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get teamProjectCountLabel;

  /// No description provided for @teamOverdueCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get teamOverdueCountLabel;

  /// No description provided for @memberWorkloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Member Workload (Active Tasks)'**
  String get memberWorkloadTitle;

  /// No description provided for @weeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get weeklyActivity;

  /// No description provided for @statusReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get statusReview;

  /// No description provided for @newProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProjectTitle;

  /// No description provided for @projectNameHint.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectNameHint;

  /// No description provided for @projectDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get projectDescriptionHint;

  /// No description provided for @colorSelectionLabel.
  ///
  /// In en, this message translates to:
  /// **'COLOR SELECTION'**
  String get colorSelectionLabel;

  /// No description provided for @deadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'DEADLINE'**
  String get deadlineLabel;

  /// No description provided for @noDateSelected.
  ///
  /// In en, this message translates to:
  /// **'No date selected'**
  String get noDateSelected;

  /// No description provided for @createProjectButton.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get createProjectButton;

  /// No description provided for @selectCharacter.
  ///
  /// In en, this message translates to:
  /// **'Select Character'**
  String get selectCharacter;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated! 😎'**
  String get profilePictureUpdated;

  /// No description provided for @requestVerification.
  ///
  /// In en, this message translates to:
  /// **'Request Verification'**
  String get requestVerification;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete your account and all data? This cannot be undone.'**
  String get deleteAccountConfirmation;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully deleted.'**
  String get accountDeleted;

  /// No description provided for @clearData.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clearData;

  /// No description provided for @clearDataConfirmation.
  ///
  /// In en, this message translates to:
  /// **'All your tasks and settings will be deleted. Are you sure?'**
  String get clearDataConfirmation;

  /// No description provided for @allDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
  String get allDataCleared;

  /// No description provided for @levelXpFormat.
  ///
  /// In en, this message translates to:
  /// **'Level {level} • {xp} XP'**
  String levelXpFormat(int level, int xp);

  /// No description provided for @birthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth Date: {date}'**
  String birthDateLabel(String date);

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @accessAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Access & Security'**
  String get accessAndSecurity;

  /// No description provided for @appearanceAndTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Theme'**
  String get appearanceAndTheme;

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInformation;

  /// No description provided for @appsAndModules.
  ///
  /// In en, this message translates to:
  /// **'Apps & Modules'**
  String get appsAndModules;

  /// No description provided for @languageAndData.
  ///
  /// In en, this message translates to:
  /// **'Language & Data'**
  String get languageAndData;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @taskReminders.
  ///
  /// In en, this message translates to:
  /// **'Task Reminders'**
  String get taskReminders;

  /// No description provided for @teamInvites.
  ///
  /// In en, this message translates to:
  /// **'Team Invites'**
  String get teamInvites;

  /// No description provided for @dailyBriefing.
  ///
  /// In en, this message translates to:
  /// **'Daily Briefing'**
  String get dailyBriefing;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmailTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @securityAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get securityAndPrivacy;

  /// No description provided for @aboutPhobesTitle.
  ///
  /// In en, this message translates to:
  /// **'About Phobes'**
  String get aboutPhobesTitle;

  /// No description provided for @featureTreeTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Feature Tree'**
  String get featureTreeTitleLabel;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact & Support'**
  String get contactSupport;

  /// No description provided for @selectModules.
  ///
  /// In en, this message translates to:
  /// **'Select Modules'**
  String get selectModules;

  /// No description provided for @simulateTestData.
  ///
  /// In en, this message translates to:
  /// **'3-Month Full Test System'**
  String get simulateTestData;

  /// No description provided for @simulateTestDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Synchronizes the whole app'**
  String get simulateTestDataSubtitle;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get tabStatistics;

  /// No description provided for @tabAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get tabAccounts;

  /// No description provided for @tabDebts.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get tabDebts;

  /// No description provided for @tabGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get tabGoals;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @expenseDistribution.
  ///
  /// In en, this message translates to:
  /// **'Expense Distribution'**
  String get expenseDistribution;

  /// No description provided for @budgetLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Budget Limit Exceeded! 🚨 +{amount}'**
  String budgetLimitExceeded(String amount);

  /// No description provided for @levelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Level Up! 🎉'**
  String get levelUpTitle;

  /// No description provided for @levelUpBody.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You reached Level {level}!'**
  String levelUpBody(int level);

  /// No description provided for @aiLabelActiveMeds.
  ///
  /// In en, this message translates to:
  /// **'Active Medications'**
  String get aiLabelActiveMeds;

  /// No description provided for @aiLabelUpcomingTasks7Days.
  ///
  /// In en, this message translates to:
  /// **'Tasks for the Next 7 Days'**
  String get aiLabelUpcomingTasks7Days;

  /// No description provided for @budgetStatus.
  ///
  /// In en, this message translates to:
  /// **'Budget Status for This Month'**
  String get budgetStatus;

  /// No description provided for @financialAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Financial Analysis'**
  String get financialAnalysis;

  /// No description provided for @gaugeBudgetHiz.
  ///
  /// In en, this message translates to:
  /// **'Budget Velocity Gauge'**
  String get gaugeBudgetHiz;

  /// No description provided for @moneyJourney.
  ///
  /// In en, this message translates to:
  /// **'Journey of Money (Sankey)'**
  String get moneyJourney;

  /// No description provided for @incomeVsExpenseTrend.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expense Trend'**
  String get incomeVsExpenseTrend;

  /// No description provided for @anomalyTracking.
  ///
  /// In en, this message translates to:
  /// **'Smart Anomaly Tracking'**
  String get anomalyTracking;

  /// No description provided for @assetTreemap.
  ///
  /// In en, this message translates to:
  /// **'Asset Distribution Tree Map'**
  String get assetTreemap;

  /// No description provided for @dailyHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Spending Activity Heatmap'**
  String get dailyHeatmap;

  /// No description provided for @recurringAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Recurring Expense Analysis'**
  String get recurringAnalysis;

  /// No description provided for @kpiMonthlyExpense.
  ///
  /// In en, this message translates to:
  /// **'Monthly Expense'**
  String get kpiMonthlyExpense;

  /// No description provided for @kpiMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly Income'**
  String get kpiMonthlyIncome;

  /// No description provided for @kpiNetSavings.
  ///
  /// In en, this message translates to:
  /// **'Net Savings'**
  String get kpiNetSavings;

  /// No description provided for @kpiDailyAvg.
  ///
  /// In en, this message translates to:
  /// **'Daily Avg.'**
  String get kpiDailyAvg;

  /// No description provided for @kpiRemainingLimit.
  ///
  /// In en, this message translates to:
  /// **'Remaining Limit'**
  String get kpiRemainingLimit;

  /// No description provided for @kpiEndOfMonthForecast.
  ///
  /// In en, this message translates to:
  /// **'End of Month Forecast'**
  String get kpiEndOfMonthForecast;

  /// No description provided for @budgetLimitApproaching.
  ///
  /// In en, this message translates to:
  /// **'Budget Limit Approaching! ⚠️'**
  String get budgetLimitApproaching;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @clearAccount.
  ///
  /// In en, this message translates to:
  /// **'Clear Account'**
  String get clearAccount;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryIncomes.
  ///
  /// In en, this message translates to:
  /// **'Incomes'**
  String get categoryIncomes;

  /// No description provided for @categoryExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get categoryExpenses;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @deleteTransactionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get deleteTransactionConfirm;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// No description provided for @addNewTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add New Transaction'**
  String get addNewTransaction;

  /// No description provided for @hintTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Title (e.g. Grocery)'**
  String get hintTransactionTitle;

  /// No description provided for @hintAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount ({symbol})'**
  String hintAmount(String symbol);

  /// No description provided for @hintDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get hintDescription;

  /// No description provided for @hintSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Sub-Category (e.g. Food)'**
  String get hintSubCategory;

  /// No description provided for @aiSystemRole.
  ///
  /// In en, this message translates to:
  /// **'You are Nova, the AI life coach and personal assistant of the Phobes app. You are intelligent, friendly, direct, motivating, and slightly witty. Keep responses concise and use bullet points. Always speak in {language}.'**
  String aiSystemRole(String language);

  /// No description provided for @aiContextUser.
  ///
  /// In en, this message translates to:
  /// **'[USER INFO & CONTEXT]'**
  String get aiContextUser;

  /// No description provided for @aiContextCurrentTime.
  ///
  /// In en, this message translates to:
  /// **'Current Time'**
  String get aiContextCurrentTime;

  /// No description provided for @aiLabelTasksToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Pending Tasks'**
  String get aiLabelTasksToday;

  /// No description provided for @aiLabelUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Tasks (Next 7 Days)'**
  String get aiLabelUpcomingTasks;

  /// No description provided for @aiLabelDailyHabits.
  ///
  /// In en, this message translates to:
  /// **'Daily Habits'**
  String get aiLabelDailyHabits;

  /// No description provided for @aiLabelAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointments'**
  String get aiLabelAppointments;

  /// No description provided for @aiLabelRecentNotes.
  ///
  /// In en, this message translates to:
  /// **'Recent Notes (Last 5)'**
  String get aiLabelRecentNotes;

  /// No description provided for @aiLabelBudgetStatus.
  ///
  /// In en, this message translates to:
  /// **'Budget Status (This Month)'**
  String get aiLabelBudgetStatus;

  /// No description provided for @aiLabelActiveTeams.
  ///
  /// In en, this message translates to:
  /// **'Active Teams'**
  String get aiLabelActiveTeams;

  /// No description provided for @aiInstructionToolUsage.
  ///
  /// In en, this message translates to:
  /// **'[TOOL USAGE RULES]'**
  String get aiInstructionToolUsage;

  /// No description provided for @aiInstructionReady.
  ///
  /// In en, this message translates to:
  /// **'I\'ve prepared it, do you approve? 🚀'**
  String get aiInstructionReady;

  /// No description provided for @aiOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get aiOnline;

  /// No description provided for @aiGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Nova User Guide'**
  String get aiGuideTitle;

  /// No description provided for @aiGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What can Nova do?'**
  String get aiGuideSubtitle;

  /// No description provided for @aiStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get aiStatusApproved;

  /// No description provided for @aiStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get aiStatusCancelled;

  /// No description provided for @aiErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection problem, please try again.'**
  String get aiErrorConnection;

  /// No description provided for @aiInitialGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}! I am Nova. How can I help you today?'**
  String aiInitialGreeting(String name);

  /// No description provided for @aiGuideAnladim.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get aiGuideAnladim;

  /// No description provided for @aiGuideItem1Title.
  ///
  /// In en, this message translates to:
  /// **'Task Creation'**
  String get aiGuideItem1Title;

  /// No description provided for @aiGuideItem1Desc.
  ///
  /// In en, this message translates to:
  /// **'\"Add exercise for tomorrow 8am\"'**
  String get aiGuideItem1Desc;

  /// No description provided for @aiGuideItem2Title.
  ///
  /// In en, this message translates to:
  /// **'Full Editing'**
  String get aiGuideItem2Title;

  /// No description provided for @aiGuideItem2Desc.
  ///
  /// In en, this message translates to:
  /// **'\"Reschedule gym to Friday 3pm\", \"Change title to walk\" or \"Add description Buy water\"'**
  String get aiGuideItem2Desc;

  /// No description provided for @aiGuideItem3Title.
  ///
  /// In en, this message translates to:
  /// **'Task Deletion'**
  String get aiGuideItem3Title;

  /// No description provided for @aiGuideItem3Desc.
  ///
  /// In en, this message translates to:
  /// **'\"Delete finish project task, I changed my mind\"'**
  String get aiGuideItem3Desc;

  /// No description provided for @aiGuideItem4Title.
  ///
  /// In en, this message translates to:
  /// **'Search & UI'**
  String get aiGuideItem4Title;

  /// No description provided for @aiGuideItem4Desc.
  ///
  /// In en, this message translates to:
  /// **'\"Find my walk task\" (Draws clickable card)'**
  String get aiGuideItem4Desc;

  /// No description provided for @aiGuideItem5Title.
  ///
  /// In en, this message translates to:
  /// **'Subtask Split'**
  String get aiGuideItem5Title;

  /// No description provided for @aiGuideItem5Desc.
  ///
  /// In en, this message translates to:
  /// **'\"Add write email and make presentation subtasks to my task\"'**
  String get aiGuideItem5Desc;

  /// No description provided for @aiGuideItem6Title.
  ///
  /// In en, this message translates to:
  /// **'Team Announcement'**
  String get aiGuideItem6Title;

  /// No description provided for @aiGuideItem6Desc.
  ///
  /// In en, this message translates to:
  /// **'\"Announce to dev team that there is a meeting tomorrow\"'**
  String get aiGuideItem6Desc;

  /// No description provided for @aiGuideItem7Title.
  ///
  /// In en, this message translates to:
  /// **'Jarvis Mode'**
  String get aiGuideItem7Title;

  /// No description provided for @aiGuideItem7Desc.
  ///
  /// In en, this message translates to:
  /// **'Use the microphone for voice commands.'**
  String get aiGuideItem7Desc;

  /// No description provided for @aiLabelNewTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get aiLabelNewTask;

  /// No description provided for @aiLabelAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get aiLabelAddExpense;

  /// No description provided for @aiLabelMedRecord.
  ///
  /// In en, this message translates to:
  /// **'Medication Record'**
  String get aiLabelMedRecord;

  /// No description provided for @aiLabelSubtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get aiLabelSubtasks;

  /// No description provided for @aiLabelTeamAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Team Announcement'**
  String get aiLabelTeamAnnouncement;

  /// No description provided for @aiFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get aiFieldTitle;

  /// No description provided for @aiFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get aiFieldDate;

  /// No description provided for @aiFieldTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get aiFieldTime;

  /// No description provided for @aiFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get aiFieldAmount;

  /// No description provided for @aiFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get aiFieldCategory;

  /// No description provided for @aiFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get aiFieldDescription;

  /// No description provided for @aiFieldMedName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get aiFieldMedName;

  /// No description provided for @aiBtnApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get aiBtnApprove;

  /// No description provided for @aiBtnReject.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get aiBtnReject;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// No description provided for @btnSuccess.
  ///
  /// In en, this message translates to:
  /// **'Great!'**
  String get btnSuccess;

  /// No description provided for @focusSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Focus Session Ended!'**
  String get focusSessionEnded;

  /// No description provided for @focusSessionDesc.
  ///
  /// In en, this message translates to:
  /// **'Great job! Time for a break. ⭐'**
  String get focusSessionDesc;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @focusMinutesDesc.
  ///
  /// In en, this message translates to:
  /// **'You focused for {minutes} minutes'**
  String focusMinutesDesc(int minutes);

  /// No description provided for @focusDefaultAdvice.
  ///
  /// In en, this message translates to:
  /// **'Now rest your eyes for 5 minutes and drink water.'**
  String get focusDefaultAdvice;

  /// No description provided for @focusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get focusMode;

  /// No description provided for @focusing.
  ///
  /// In en, this message translates to:
  /// **'Focusing...'**
  String get focusing;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @focusXpReward.
  ///
  /// In en, this message translates to:
  /// **'Earn {xp} XP once completed'**
  String focusXpReward(int xp);

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @aiActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Processing failed. Please try again.'**
  String get aiActionFailed;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon! 🚀'**
  String get featureComingSoon;

  /// View mode
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get apptTimeline;

  /// View mode
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get apptWeeklyGrid;

  /// View mode
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get apptListView;

  /// View mode
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get apptMonthView;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get apptToday;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No available time slots for this day.'**
  String get apptNoSlots;

  /// Slot label
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get apptFreeSlot;

  /// Analytics
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get apptOccupancy;

  /// Analytics
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get apptRevenue;

  /// Analytics
  ///
  /// In en, this message translates to:
  /// **'Cancel Rate'**
  String get apptCancelRate;

  /// Analytics
  ///
  /// In en, this message translates to:
  /// **'Popular Hours'**
  String get apptPopularHours;

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get apptAnalytics;

  /// Tab label
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get apptClients;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add Client'**
  String get apptAddClient;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get apptEditClient;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Delete Client'**
  String get apptDeleteClient;

  /// Dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this client?'**
  String get apptDeleteClientConfirm;

  /// Form
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get apptClientEmail;

  /// Form
  ///
  /// In en, this message translates to:
  /// **'Client Note'**
  String get apptClientNote;

  /// Form
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get apptClientTags;

  /// Tag
  ///
  /// In en, this message translates to:
  /// **'VIP'**
  String get apptTagVip;

  /// Tag
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get apptTagRegular;

  /// Tag
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get apptTagNew;

  /// Stat
  ///
  /// In en, this message translates to:
  /// **'Total Visits'**
  String get apptTotalVisits;

  /// Stat
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get apptTotalSpent;

  /// Stat
  ///
  /// In en, this message translates to:
  /// **'Last Visit'**
  String get apptLastVisit;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No clients yet.'**
  String get apptNoClients;

  /// Form label
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get apptServiceColor;

  /// Form label
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get apptServiceIcon;

  /// Form label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get apptServiceCategory;

  /// Toggle
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get apptServiceActive;

  /// Form label
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get apptRecurrence;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get apptRecurrenceNone;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get apptRecurrenceWeekly;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Biweekly'**
  String get apptRecurrenceBiweekly;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get apptRecurrenceMonthly;

  /// Form label
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get apptReminder;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get apptReminderNone;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'At appointment time'**
  String get apptReminderAtTime;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'10 minutes before'**
  String get apptReminder10Min;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'30 minutes before'**
  String get apptReminder30Min;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get apptReminder1Hour;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'2 hours before'**
  String get apptReminder2Hours;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get apptReminder1Day;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get apptWhatsapp;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get apptSendReminder;

  /// Form label
  ///
  /// In en, this message translates to:
  /// **'Select Client'**
  String get apptSelectClient;

  /// Form label
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get apptSelectService;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Quick Appointment'**
  String get apptQuickAdd;

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get apptWorkHours;

  /// Section
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get apptBreaks;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add Break'**
  String get apptAddBreak;

  /// Form label
  ///
  /// In en, this message translates to:
  /// **'Buffer (min)'**
  String get apptBuffer;

  /// Form label
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reason'**
  String get apptCancelReason;

  /// Duration
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String apptMinutes(int count);

  /// Duration
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String apptHours(int count);

  /// Stat
  ///
  /// In en, this message translates to:
  /// **'Total Appointments'**
  String get apptTotalAppointments;

  /// Stat
  ///
  /// In en, this message translates to:
  /// **'{count} confirmed'**
  String apptConfirmedCount(int count);

  /// Stat
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String apptPendingCount(int count);

  /// Stat
  ///
  /// In en, this message translates to:
  /// **'{count} cancelled'**
  String apptCancelledCount(int count);

  /// Hint
  ///
  /// In en, this message translates to:
  /// **'Search clients...'**
  String get apptSearchClients;

  /// Category
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get apptCategoryGeneral;

  /// Cancellation option
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get apptAlwaysAllow;

  /// Cancellation option
  ///
  /// In en, this message translates to:
  /// **'{hours}h before'**
  String apptHoursBefore(int hours);

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Delete Appointment'**
  String get apptDeleteAppointment;

  /// Dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this appointment?'**
  String get apptDeleteAppointmentConfirm;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Appointment deleted'**
  String get apptAppointmentDeleted;

  /// Snackbar
  ///
  /// In en, this message translates to:
  /// **'Appointment saved'**
  String get apptSaved;

  /// Budget settings label
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get baseCurrency;

  /// Budget overview section
  ///
  /// In en, this message translates to:
  /// **'Live Rates'**
  String get liveRates;

  /// Edit transaction sheet title
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransaction;

  /// Budget overview card
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get netWorth;

  /// Net worth chip label
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get totalAssets;

  /// Net worth chip label
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get totalLiabilities;

  /// Goals empty state title
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet'**
  String get noGoalsYet;

  /// Goals empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Set a goal and start saving today'**
  String get noGoalsYetDesc;

  /// Debts empty state title
  ///
  /// In en, this message translates to:
  /// **'No debts recorded'**
  String get noDebtsYet;

  /// Debts empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Track who owes you and who you owe'**
  String get noDebtsYetDesc;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add Goal'**
  String get addGoal;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add Debt'**
  String get addDebt;

  /// Appointment search bar placeholder
  ///
  /// In en, this message translates to:
  /// **'Search appointments...'**
  String get apptSearchHint;

  /// Bulk add button/title
  ///
  /// In en, this message translates to:
  /// **'Bulk Add Tasks'**
  String get bulkAddTasks;

  /// Bulk add text area hint
  ///
  /// In en, this message translates to:
  /// **'Enter one task per line...'**
  String get bulkAddHint;

  /// Bulk add info text
  ///
  /// In en, this message translates to:
  /// **'Each line becomes a separate task with the same date, time and settings.'**
  String get bulkAddInfo;

  /// Preview count
  ///
  /// In en, this message translates to:
  /// **'{count} tasks will be created'**
  String bulkAddCount(int count);

  /// Success message
  ///
  /// In en, this message translates to:
  /// **'Recurring series created ({count} tasks)'**
  String recurringSeriesCreated(int count);

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Series end date'**
  String get repeatSeriesEndDate;

  /// No description provided for @moduleInfoGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get moduleInfoGotIt;

  /// No description provided for @moduleInfoTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get moduleInfoTipsTitle;

  /// No description provided for @moduleInfoCalendarIntro.
  ///
  /// In en, this message translates to:
  /// **'The calendar unifies tasks, appointments, medications, habits, and notes on one timeline.'**
  String get moduleInfoCalendarIntro;

  /// No description provided for @moduleInfoCalendarSection1Title.
  ///
  /// In en, this message translates to:
  /// **'Central tracking'**
  String get moduleInfoCalendarSection1Title;

  /// No description provided for @moduleInfoCalendarSection1B1.
  ///
  /// In en, this message translates to:
  /// **'See every module event in month, week, or day view.'**
  String get moduleInfoCalendarSection1B1;

  /// No description provided for @moduleInfoCalendarSection1B2.
  ///
  /// In en, this message translates to:
  /// **'Jump between dates quickly with the header controls.'**
  String get moduleInfoCalendarSection1B2;

  /// No description provided for @moduleInfoCalendarSection2Title.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get moduleInfoCalendarSection2Title;

  /// No description provided for @moduleInfoCalendarSection2B1.
  ///
  /// In en, this message translates to:
  /// **'Use + to create tasks with smart or manual entry.'**
  String get moduleInfoCalendarSection2B1;

  /// No description provided for @moduleInfoCalendarSection2B2.
  ///
  /// In en, this message translates to:
  /// **'Changes in other modules sync here instantly.'**
  String get moduleInfoCalendarSection2B2;

  /// No description provided for @moduleInfoCalendarTip1.
  ///
  /// In en, this message translates to:
  /// **'Long-press a day to open the detailed timeline.'**
  String get moduleInfoCalendarTip1;

  /// No description provided for @moduleInfoBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get moduleInfoBudgetTitle;

  /// No description provided for @moduleInfoBudgetIntro.
  ///
  /// In en, this message translates to:
  /// **'Track income, expenses, accounts, debts, and savings goals in one place.'**
  String get moduleInfoBudgetIntro;

  /// No description provided for @moduleInfoBudgetSection1Title.
  ///
  /// In en, this message translates to:
  /// **'What you can do'**
  String get moduleInfoBudgetSection1Title;

  /// No description provided for @moduleInfoBudgetSection1B1.
  ///
  /// In en, this message translates to:
  /// **'Categorize transactions and watch account balances update automatically.'**
  String get moduleInfoBudgetSection1B1;

  /// No description provided for @moduleInfoBudgetSection1B2.
  ///
  /// In en, this message translates to:
  /// **'Set limits and goals with visual progress.'**
  String get moduleInfoBudgetSection1B2;

  /// No description provided for @moduleInfoBudgetTip1.
  ///
  /// In en, this message translates to:
  /// **'Use the Overview tab + button for the fastest transaction entry.'**
  String get moduleInfoBudgetTip1;

  /// No description provided for @moduleInfoBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get moduleInfoBooksTitle;

  /// No description provided for @moduleInfoBooksIntro.
  ///
  /// In en, this message translates to:
  /// **'Organize your reading life with shelves, progress, and quotes.'**
  String get moduleInfoBooksIntro;

  /// No description provided for @moduleInfoBooksSection1Title.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get moduleInfoBooksSection1Title;

  /// No description provided for @moduleInfoBooksSection1B1.
  ///
  /// In en, this message translates to:
  /// **'Drag books between shelves and track page progress.'**
  String get moduleInfoBooksSection1B1;

  /// No description provided for @moduleInfoBooksSection1B2.
  ///
  /// In en, this message translates to:
  /// **'Search Google Books or Open Library to auto-fill metadata.'**
  String get moduleInfoBooksSection1B2;

  /// No description provided for @moduleInfoBooksTip1.
  ///
  /// In en, this message translates to:
  /// **'Pin favorite quotes from the book detail screen.'**
  String get moduleInfoBooksTip1;

  /// No description provided for @moduleInfoNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get moduleInfoNotesTitle;

  /// No description provided for @moduleInfoNotesIntro.
  ///
  /// In en, this message translates to:
  /// **'Capture ideas in notebooks with rich text, tags, and team sharing.'**
  String get moduleInfoNotesIntro;

  /// No description provided for @moduleInfoNotesSection1Title.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get moduleInfoNotesSection1Title;

  /// No description provided for @moduleInfoNotesSection1B1.
  ///
  /// In en, this message translates to:
  /// **'Switch list or grid view; filter favorites and team notes.'**
  String get moduleInfoNotesSection1B1;

  /// No description provided for @moduleInfoNotesSection1B2.
  ///
  /// In en, this message translates to:
  /// **'Search and sort by title, date, or category.'**
  String get moduleInfoNotesSection1B2;

  /// No description provided for @moduleInfoNotesTip1.
  ///
  /// In en, this message translates to:
  /// **'On web, the editor opens full screen while sidebars stay visible.'**
  String get moduleInfoNotesTip1;

  /// No description provided for @moduleInfoMedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get moduleInfoMedsTitle;

  /// No description provided for @moduleInfoMedsIntro.
  ///
  /// In en, this message translates to:
  /// **'Never miss a dose with reminders, stock tracking, and history.'**
  String get moduleInfoMedsIntro;

  /// No description provided for @moduleInfoMedsSection1Title.
  ///
  /// In en, this message translates to:
  /// **'Stay on schedule'**
  String get moduleInfoMedsSection1Title;

  /// No description provided for @moduleInfoMedsSection1B1.
  ///
  /// In en, this message translates to:
  /// **'Log taken doses from the daily flow.'**
  String get moduleInfoMedsSection1B1;

  /// No description provided for @moduleInfoMedsSection1B2.
  ///
  /// In en, this message translates to:
  /// **'Get alerts when stock runs low.'**
  String get moduleInfoMedsSection1B2;

  /// No description provided for @moduleInfoMedsTip1.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders per medication for best results.'**
  String get moduleInfoMedsTip1;

  /// No description provided for @moduleInfoApptTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get moduleInfoApptTitle;

  /// No description provided for @moduleInfoApptIntro.
  ///
  /// In en, this message translates to:
  /// **'Manage personal appointments and client booking in one hub.'**
  String get moduleInfoApptIntro;

  /// No description provided for @moduleInfoApptSection1Title.
  ///
  /// In en, this message translates to:
  /// **'Views & workflow'**
  String get moduleInfoApptSection1Title;

  /// No description provided for @moduleInfoApptSection1B1.
  ///
  /// In en, this message translates to:
  /// **'Timeline, weekly grid, or list — filter by status.'**
  String get moduleInfoApptSection1B1;

  /// No description provided for @moduleInfoApptSection1B2.
  ///
  /// In en, this message translates to:
  /// **'Configure service groups and working hours in settings.'**
  String get moduleInfoApptSection1B2;

  /// No description provided for @moduleInfoApptTip1.
  ///
  /// In en, this message translates to:
  /// **'Use the My Appointments tab for your personal calendar.'**
  String get moduleInfoApptTip1;

  /// No description provided for @moduleInfoHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get moduleInfoHabitsTitle;

  /// No description provided for @moduleInfoHabitsIntro.
  ///
  /// In en, this message translates to:
  /// **'Build streaks and track daily routines with reminders.'**
  String get moduleInfoHabitsIntro;

  /// No description provided for @moduleInfoHabitsSection1Title.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get moduleInfoHabitsSection1Title;

  /// No description provided for @moduleInfoHabitsSection1B1.
  ///
  /// In en, this message translates to:
  /// **'Streak counters keep you consistent.'**
  String get moduleInfoHabitsSection1B1;

  /// No description provided for @moduleInfoHabitsSection1B2.
  ///
  /// In en, this message translates to:
  /// **'Weekly stats show your completion rate.'**
  String get moduleInfoHabitsSection1B2;

  /// No description provided for @moduleInfoHabitsTip1.
  ///
  /// In en, this message translates to:
  /// **'Set a reminder time that fits your routine.'**
  String get moduleInfoHabitsTip1;

  /// No description provided for @moduleInfoUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get moduleInfoUpcomingTitle;

  /// No description provided for @moduleInfoUpcomingIntro.
  ///
  /// In en, this message translates to:
  /// **'A smart 30-day feed of everything coming up across modules.'**
  String get moduleInfoUpcomingIntro;

  /// No description provided for @moduleInfoUpcomingSection1Title.
  ///
  /// In en, this message translates to:
  /// **'How to use it'**
  String get moduleInfoUpcomingSection1Title;

  /// No description provided for @moduleInfoUpcomingSection1B1.
  ///
  /// In en, this message translates to:
  /// **'Tasks, appointments, meds, and events in one chronological list.'**
  String get moduleInfoUpcomingSection1B1;

  /// No description provided for @moduleInfoUpcomingSection1B2.
  ///
  /// In en, this message translates to:
  /// **'Tap any item to jump to its module.'**
  String get moduleInfoUpcomingSection1B2;

  /// No description provided for @moduleInfoUpcomingTip1.
  ///
  /// In en, this message translates to:
  /// **'Use category chips to narrow the list.'**
  String get moduleInfoUpcomingTip1;

  /// No description provided for @moduleInfoTeamsIntro.
  ///
  /// In en, this message translates to:
  /// **'Collaborate with projects, tasks, announcements, and shared resources.'**
  String get moduleInfoTeamsIntro;

  /// No description provided for @moduleInfoTeamsSection1Title.
  ///
  /// In en, this message translates to:
  /// **'Team workspace'**
  String get moduleInfoTeamsSection1Title;

  /// No description provided for @moduleInfoTeamsSection1B1.
  ///
  /// In en, this message translates to:
  /// **'Join with a code or create your own team.'**
  String get moduleInfoTeamsSection1B1;

  /// No description provided for @moduleInfoTeamsSection1B2.
  ///
  /// In en, this message translates to:
  /// **'Kanban tasks and activity feed keep everyone aligned.'**
  String get moduleInfoTeamsSection1B2;

  /// No description provided for @moduleInfoTeamsTip1.
  ///
  /// In en, this message translates to:
  /// **'Admins can post announcements from the team header.'**
  String get moduleInfoTeamsTip1;

  /// No description provided for @moduleInfoFocusIntro.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro-style focus sessions to stay productive without distractions.'**
  String get moduleInfoFocusIntro;

  /// No description provided for @moduleInfoFocusTip1.
  ///
  /// In en, this message translates to:
  /// **'Complete a session to log progress in your day.'**
  String get moduleInfoFocusTip1;

  /// No description provided for @moduleInfoStatsIntro.
  ///
  /// In en, this message translates to:
  /// **'Charts and summaries across tasks, habits, budget, and more.'**
  String get moduleInfoStatsIntro;

  /// No description provided for @moduleInfoStatsTip1.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh for the latest aggregates.'**
  String get moduleInfoStatsTip1;

  /// No description provided for @moduleInfoCorkboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Planning board'**
  String get moduleInfoCorkboardTitle;

  /// No description provided for @moduleInfoCorkboardIntro.
  ///
  /// In en, this message translates to:
  /// **'Cards and connections on an infinite canvas.'**
  String get moduleInfoCorkboardIntro;

  /// No description provided for @moduleInfoCorkboardTip1.
  ///
  /// In en, this message translates to:
  /// **'Drag cards to arrange; link related ideas with connections.'**
  String get moduleInfoCorkboardTip1;

  /// No description provided for @corkboardPersonalTitle.
  ///
  /// In en, this message translates to:
  /// **'Planning board'**
  String get corkboardPersonalTitle;

  /// No description provided for @corkboardTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Team planning board'**
  String get corkboardTeamTitle;

  /// No description provided for @corkboardSubtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Place ideas freely and link them with strings'**
  String get corkboardSubtitleDefault;

  /// No description provided for @corkboardBoardNotes.
  ///
  /// In en, this message translates to:
  /// **'{title} · {count} notes'**
  String corkboardBoardNotes(String title, int count);

  /// No description provided for @corkboardAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get corkboardAddNote;

  /// No description provided for @corkboardNewBoard.
  ///
  /// In en, this message translates to:
  /// **'New board'**
  String get corkboardNewBoard;

  /// No description provided for @corkboardRenameBoard.
  ///
  /// In en, this message translates to:
  /// **'Rename board'**
  String get corkboardRenameBoard;

  /// No description provided for @corkboardBoardNameHint.
  ///
  /// In en, this message translates to:
  /// **'Board name'**
  String get corkboardBoardNameHint;

  /// No description provided for @corkboardDefaultBoardName.
  ///
  /// In en, this message translates to:
  /// **'Board {number}'**
  String corkboardDefaultBoardName(int number);

  /// No description provided for @corkboardFirstBoardName.
  ///
  /// In en, this message translates to:
  /// **'Board 1'**
  String get corkboardFirstBoardName;

  /// No description provided for @corkboardDeleteBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String corkboardDeleteBoardTitle(String name);

  /// No description provided for @corkboardDeleteBoardBody.
  ///
  /// In en, this message translates to:
  /// **'All notes and connections on this board will be deleted.'**
  String get corkboardDeleteBoardBody;

  /// No description provided for @corkboardDeleteBoardFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete board: {error}'**
  String corkboardDeleteBoardFailed(String error);

  /// No description provided for @corkboardNoBoardsTitle.
  ///
  /// In en, this message translates to:
  /// **'No planning boards yet'**
  String get corkboardNoBoardsTitle;

  /// No description provided for @corkboardNoBoardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first board to place ideas freely and link notes with strings.'**
  String get corkboardNoBoardsDesc;

  /// No description provided for @corkboardNoBoardsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load boards. Try creating a new board.'**
  String get corkboardNoBoardsError;

  /// No description provided for @corkboardAddBoard.
  ///
  /// In en, this message translates to:
  /// **'Add board'**
  String get corkboardAddBoard;

  /// No description provided for @corkboardBoardTab.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get corkboardBoardTab;

  /// No description provided for @corkboardRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get corkboardRename;

  /// No description provided for @corkboardDeleteBoardMenu.
  ///
  /// In en, this message translates to:
  /// **'Delete board'**
  String get corkboardDeleteBoardMenu;

  /// No description provided for @corkboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your board is empty'**
  String get corkboardEmptyTitle;

  /// No description provided for @corkboardEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add notes and link them with strings'**
  String get corkboardEmptySubtitle;

  /// No description provided for @corkboardConnectSecond.
  ///
  /// In en, this message translates to:
  /// **'Select the second note to link'**
  String get corkboardConnectSecond;

  /// No description provided for @corkboardConnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Select the first note, then tap the second'**
  String get corkboardConnectFirst;

  /// No description provided for @corkboardNewNoteColor.
  ///
  /// In en, this message translates to:
  /// **'New note color'**
  String get corkboardNewNoteColor;

  /// No description provided for @corkboardLinkType.
  ///
  /// In en, this message translates to:
  /// **'Connection type'**
  String get corkboardLinkType;

  /// No description provided for @corkboardEditHint.
  ///
  /// In en, this message translates to:
  /// **'Write your plan or idea…'**
  String get corkboardEditHint;

  /// No description provided for @corkboardCardColor.
  ///
  /// In en, this message translates to:
  /// **'Card color'**
  String get corkboardCardColor;

  /// No description provided for @corkboardConnectLink.
  ///
  /// In en, this message translates to:
  /// **'Create connection'**
  String get corkboardConnectLink;

  /// No description provided for @corkboardManageConnections.
  ///
  /// In en, this message translates to:
  /// **'Manage connections'**
  String get corkboardManageConnections;

  /// No description provided for @corkboardNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write a note…'**
  String get corkboardNotePlaceholder;

  /// No description provided for @corkboardNoConnections.
  ///
  /// In en, this message translates to:
  /// **'No connections on this note'**
  String get corkboardNoConnections;

  /// No description provided for @corkboardDeleteConnection.
  ///
  /// In en, this message translates to:
  /// **'Remove connection'**
  String get corkboardDeleteConnection;

  /// No description provided for @corkboardConnectionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Connection removed'**
  String get corkboardConnectionDeleted;

  /// No description provided for @corkboardTapLinkToDelete.
  ///
  /// In en, this message translates to:
  /// **'Tap a string to remove it'**
  String get corkboardTapLinkToDelete;

  /// No description provided for @corkboardLinkRelated.
  ///
  /// In en, this message translates to:
  /// **'Related'**
  String get corkboardLinkRelated;

  /// No description provided for @corkboardLinkNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get corkboardLinkNext;

  /// No description provided for @corkboardLinkDepends.
  ///
  /// In en, this message translates to:
  /// **'Depends'**
  String get corkboardLinkDepends;

  /// No description provided for @corkboardLinkIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get corkboardLinkIdea;

  /// No description provided for @corkboardLinkImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get corkboardLinkImportant;

  /// No description provided for @corkboardLinkReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get corkboardLinkReference;

  /// No description provided for @corkboardConnectionTo.
  ///
  /// In en, this message translates to:
  /// **'Link to \"{label}\"'**
  String corkboardConnectionTo(String label);

  /// No description provided for @moduleInfoProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get moduleInfoProjectsTitle;

  /// No description provided for @moduleInfoProjectsIntro.
  ///
  /// In en, this message translates to:
  /// **'Organize team work into projects with status filters and deadlines.'**
  String get moduleInfoProjectsIntro;

  /// No description provided for @moduleInfoProjectsTip1.
  ///
  /// In en, this message translates to:
  /// **'Use + to create a project under the selected team.'**
  String get moduleInfoProjectsTip1;

  /// Nova overflow menu
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get novaClearChat;

  /// Nova chat cleared snackbar
  ///
  /// In en, this message translates to:
  /// **'Chat cleared'**
  String get novaChatCleared;

  /// Account backup export
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get backupExportData;

  /// Account backup export subtitle
  ///
  /// In en, this message translates to:
  /// **'Share a JSON backup of your tasks, notes, and more'**
  String get backupExportSubtitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @cookiePolicy.
  ///
  /// In en, this message translates to:
  /// **'Cookie Policy'**
  String get cookiePolicy;

  /// No description provided for @legalLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: May 2026'**
  String get legalLastUpdated;

  /// No description provided for @footerProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get footerProduct;

  /// No description provided for @footerCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get footerCompany;

  /// No description provided for @footerLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get footerLegal;

  /// No description provided for @landingTagline.
  ///
  /// In en, this message translates to:
  /// **'Your time, under your control.'**
  String get landingTagline;

  /// No description provided for @landingAllFeatures.
  ///
  /// In en, this message translates to:
  /// **'ALL FEATURES'**
  String get landingAllFeatures;

  /// No description provided for @landingAllFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'One app for\nevery need'**
  String get landingAllFeaturesTitle;

  /// No description provided for @aboutModulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Phobes modules'**
  String get aboutModulesTitle;

  /// No description provided for @aboutModulesDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable only what you need from Account settings.'**
  String get aboutModulesDesc;

  /// No description provided for @dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily summary'**
  String get dailySummary;

  /// No description provided for @landingFeatCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly, monthly, and daily views'**
  String get landingFeatCalendarSubtitle;

  /// No description provided for @landingFeatTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Priority, recurrence, voice capture'**
  String get landingFeatTasksSubtitle;

  /// No description provided for @landingFeatAppointmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clients, groups, and booking links'**
  String get landingFeatAppointmentsSubtitle;

  /// No description provided for @landingFeatStatisticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Productivity charts and insights'**
  String get landingFeatStatisticsSubtitle;

  /// No description provided for @landingFeatBudgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Income, expenses, goals, and limits'**
  String get landingFeatBudgetSubtitle;

  /// No description provided for @landingFeatNovaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smart assistant with your context'**
  String get landingFeatNovaSubtitle;

  /// No description provided for @landingFeatNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rich editor, pages, tables, and tasks'**
  String get landingFeatNotesSubtitle;

  /// No description provided for @landingFeatProjectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Kanban, resources, and team activity'**
  String get landingFeatProjectsSubtitle;

  /// No description provided for @landingFeatTeamsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboards and shared workspaces'**
  String get landingFeatTeamsSubtitle;

  /// No description provided for @landingFeatFocusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro and deep-work sessions'**
  String get landingFeatFocusSubtitle;

  /// No description provided for @landingFeatHabitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Streaks and daily routines'**
  String get landingFeatHabitsSubtitle;

  /// No description provided for @landingFeatMedicationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Doses, stock, and reminders'**
  String get landingFeatMedicationsSubtitle;

  /// No description provided for @landingFeatUpcomingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unified upcoming timeline'**
  String get landingFeatUpcomingSubtitle;

  /// No description provided for @landingFeatBooksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shelves, goals, quotes, and search'**
  String get landingFeatBooksSubtitle;

  /// No description provided for @landingFeatCorkboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visual cards and idea connections'**
  String get landingFeatCorkboardSubtitle;

  /// No description provided for @landingFeatNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customizable smart reminders'**
  String get landingFeatNotificationsSubtitle;

  /// No description provided for @landingFeatPersonalizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get landingFeatPersonalizationTitle;

  /// No description provided for @landingFeatPersonalizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Themes, accents, and AMOLED mode'**
  String get landingFeatPersonalizationSubtitle;

  /// No description provided for @catNotesKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Notes & knowledge'**
  String get catNotesKnowledge;

  /// No description provided for @catNotesKnowledgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Multi-page notes with embeds and sharing.'**
  String get catNotesKnowledgeDesc;

  /// No description provided for @catBooksReading.
  ///
  /// In en, this message translates to:
  /// **'Books & reading'**
  String get catBooksReading;

  /// No description provided for @catBooksReadingDesc.
  ///
  /// In en, this message translates to:
  /// **'Track reading life, goals, and favorite quotes.'**
  String get catBooksReadingDesc;

  /// No description provided for @catCorkboardPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning board'**
  String get catCorkboardPlanning;

  /// No description provided for @catCorkboardPlanningDesc.
  ///
  /// In en, this message translates to:
  /// **'Infinite canvas with linked idea cards.'**
  String get catCorkboardPlanningDesc;

  /// No description provided for @catProjectsTeams.
  ///
  /// In en, this message translates to:
  /// **'Projects & teams'**
  String get catProjectsTeams;

  /// No description provided for @catProjectsTeamsDesc.
  ///
  /// In en, this message translates to:
  /// **'Kanban, projects, resources, and collaboration.'**
  String get catProjectsTeamsDesc;

  /// No description provided for @catCalendarPlanning.
  ///
  /// In en, this message translates to:
  /// **'Calendar & upcoming'**
  String get catCalendarPlanning;

  /// No description provided for @catCalendarPlanningDesc.
  ///
  /// In en, this message translates to:
  /// **'Tasks, appointments, meds, and habits in one view.'**
  String get catCalendarPlanningDesc;

  /// No description provided for @secRichEditor.
  ///
  /// In en, this message translates to:
  /// **'Rich editor'**
  String get secRichEditor;

  /// No description provided for @featNotePages.
  ///
  /// In en, this message translates to:
  /// **'Multi-page notes'**
  String get featNotePages;

  /// No description provided for @featNotePagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Page breaks, margins, and print-friendly layout.'**
  String get featNotePagesDesc;

  /// No description provided for @featNoteEmbeds.
  ///
  /// In en, this message translates to:
  /// **'Embeds'**
  String get featNoteEmbeds;

  /// No description provided for @featNoteEmbedsDesc.
  ///
  /// In en, this message translates to:
  /// **'Tables, callouts, task cards, and workflows.'**
  String get featNoteEmbedsDesc;

  /// No description provided for @secReadingLife.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get secReadingLife;

  /// No description provided for @featBookShelves.
  ///
  /// In en, this message translates to:
  /// **'Shelves & progress'**
  String get featBookShelves;

  /// No description provided for @featBookShelvesDesc.
  ///
  /// In en, this message translates to:
  /// **'Drag books between shelves and track pages read.'**
  String get featBookShelvesDesc;

  /// No description provided for @featBookQuotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes & goals'**
  String get featBookQuotes;

  /// No description provided for @featBookQuotesDesc.
  ///
  /// In en, this message translates to:
  /// **'Pin quotes and set annual reading goals.'**
  String get featBookQuotesDesc;

  /// No description provided for @secVisualPlanning.
  ///
  /// In en, this message translates to:
  /// **'Visual planning'**
  String get secVisualPlanning;

  /// No description provided for @featCorkboardCards.
  ///
  /// In en, this message translates to:
  /// **'Idea cards'**
  String get featCorkboardCards;

  /// No description provided for @featCorkboardCardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Tasks, notes, and links on a free-form board.'**
  String get featCorkboardCardsDesc;

  /// No description provided for @featCorkboardLinks.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get featCorkboardLinks;

  /// No description provided for @featCorkboardLinksDesc.
  ///
  /// In en, this message translates to:
  /// **'Relate ideas with typed strings between cards.'**
  String get featCorkboardLinksDesc;

  /// No description provided for @secTeamDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get secTeamDelivery;

  /// No description provided for @featTeamProjects.
  ///
  /// In en, this message translates to:
  /// **'Team projects'**
  String get featTeamProjects;

  /// No description provided for @featTeamProjectsDesc.
  ///
  /// In en, this message translates to:
  /// **'Status filters, deadlines, and project tabs.'**
  String get featTeamProjectsDesc;

  /// No description provided for @featTeamKanbanDelivery.
  ///
  /// In en, this message translates to:
  /// **'Team kanban'**
  String get featTeamKanbanDelivery;

  /// No description provided for @featTeamKanbanDeliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Shared boards with assignees and columns.'**
  String get featTeamKanbanDeliveryDesc;

  /// No description provided for @secUnifiedCalendar.
  ///
  /// In en, this message translates to:
  /// **'Unified calendar'**
  String get secUnifiedCalendar;

  /// No description provided for @featCalendarMerge.
  ///
  /// In en, this message translates to:
  /// **'All modules in one place'**
  String get featCalendarMerge;

  /// No description provided for @featCalendarMergeDesc.
  ///
  /// In en, this message translates to:
  /// **'See tasks, notes, appointments, and more together.'**
  String get featCalendarMergeDesc;

  /// No description provided for @featUpcomingTimeline.
  ///
  /// In en, this message translates to:
  /// **'Upcoming timeline'**
  String get featUpcomingTimeline;

  /// No description provided for @featUpcomingTimelineDesc.
  ///
  /// In en, this message translates to:
  /// **'Chronological view of what is next.'**
  String get featUpcomingTimelineDesc;

  /// No description provided for @moduleNameCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get moduleNameCalendar;

  /// No description provided for @moduleNameTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get moduleNameTeams;

  /// No description provided for @moduleNameNova.
  ///
  /// In en, this message translates to:
  /// **'Nova'**
  String get moduleNameNova;

  /// No description provided for @moduleNameHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get moduleNameHabits;

  /// No description provided for @moduleNameFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get moduleNameFocus;

  /// No description provided for @moduleNameBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get moduleNameBudget;

  /// No description provided for @moduleNameAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get moduleNameAppointments;

  /// No description provided for @moduleNameNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get moduleNameNotes;

  /// No description provided for @moduleNameMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get moduleNameMedications;

  /// No description provided for @moduleNameUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get moduleNameUpcoming;

  /// No description provided for @moduleNameStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get moduleNameStatistics;

  /// No description provided for @moduleNameCorkboard.
  ///
  /// In en, this message translates to:
  /// **'Planning board'**
  String get moduleNameCorkboard;

  /// No description provided for @moduleNameBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get moduleNameBooks;

  /// No description provided for @navBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get navBudget;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @navCorkboard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get navCorkboard;

  /// No description provided for @navBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get navBooks;

  /// No description provided for @descNotes.
  ///
  /// In en, this message translates to:
  /// **'Capture your thoughts'**
  String get descNotes;

  /// No description provided for @descTeams.
  ///
  /// In en, this message translates to:
  /// **'Collaborate with your teams'**
  String get descTeams;

  /// No description provided for @descBooks.
  ///
  /// In en, this message translates to:
  /// **'Shelves, goals, and reading quotes'**
  String get descBooks;

  /// No description provided for @habitScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitScreenTitle;

  /// No description provided for @habitAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add habit'**
  String get habitAddTooltip;

  /// No description provided for @habitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t break the chain! 💪'**
  String get habitSubtitle;

  /// No description provided for @habitNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Habit name'**
  String get habitNameLabel;

  /// No description provided for @habitNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Drink 2L water'**
  String get habitNameHint;

  /// No description provided for @habitReminderDaily.
  ///
  /// In en, this message translates to:
  /// **'Remind daily at {time}'**
  String habitReminderDaily(String time);

  /// No description provided for @habitReminderOptional.
  ///
  /// In en, this message translates to:
  /// **'Add daily reminder (optional)'**
  String get habitReminderOptional;

  /// No description provided for @habitReminderTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder time'**
  String get habitReminderTimeHelp;

  /// No description provided for @habitNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'🔥 Habit time!'**
  String get habitNotifTitle;

  /// No description provided for @habitNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget today\'s goals. Keep the chain going!'**
  String get habitNotifBody;

  /// No description provided for @habitEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get habitEmptyTitle;

  /// No description provided for @habitEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Start a new habit and begin your streak.'**
  String get habitEmptyDesc;

  /// No description provided for @habitStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} DAYS'**
  String habitStreakDays(int count);

  /// No description provided for @calendarWeeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary'**
  String get calendarWeeklySummary;

  /// No description provided for @calendarWeeklyRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String calendarWeeklyRange(String start, String end);

  /// No description provided for @calendarTasksLabel.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get calendarTasksLabel;

  /// No description provided for @calendarAppointmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get calendarAppointmentsLabel;

  /// No description provided for @calendarMedsDoses.
  ///
  /// In en, this message translates to:
  /// **'{taken}/{total} doses'**
  String calendarMedsDoses(int taken, int total);

  /// No description provided for @calendarHabitsWeek.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total}'**
  String calendarHabitsWeek(int done, int total);

  /// No description provided for @calendarBusiestDay.
  ///
  /// In en, this message translates to:
  /// **'Busiest: {day}'**
  String calendarBusiestDay(String day);

  /// No description provided for @calendarWeekTotalItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items this week'**
  String calendarWeekTotalItems(int count);

  /// No description provided for @calendarFilterSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get calendarFilterSectionGeneral;

  /// No description provided for @calendarFilterOnlyMyTasks.
  ///
  /// In en, this message translates to:
  /// **'Only my tasks'**
  String get calendarFilterOnlyMyTasks;

  /// No description provided for @calendarFilterOnlyMyTasksDesc.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you or created by you'**
  String get calendarFilterOnlyMyTasksDesc;

  /// No description provided for @calendarFilterSectionTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams & projects'**
  String get calendarFilterSectionTeams;

  /// No description provided for @calendarFilterTeam.
  ///
  /// In en, this message translates to:
  /// **'Team filter'**
  String get calendarFilterTeam;

  /// No description provided for @calendarFilterAllTeams.
  ///
  /// In en, this message translates to:
  /// **'All teams'**
  String get calendarFilterAllTeams;

  /// No description provided for @calendarFilterProject.
  ///
  /// In en, this message translates to:
  /// **'Project filter'**
  String get calendarFilterProject;

  /// No description provided for @calendarFilterAllProjects.
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get calendarFilterAllProjects;

  /// No description provided for @calendarFilterSectionAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get calendarFilterSectionAppointments;

  /// No description provided for @calendarFilterSectionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get calendarFilterSectionOther;

  /// No description provided for @calendarFilterMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get calendarFilterMedications;

  /// No description provided for @calendarFilterHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get calendarFilterHabits;

  /// No description provided for @calendarFilterNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get calendarFilterNotes;

  /// No description provided for @unnamedTeam.
  ///
  /// In en, this message translates to:
  /// **'Unnamed team'**
  String get unnamedTeam;

  /// No description provided for @unnamedGroup.
  ///
  /// In en, this message translates to:
  /// **'Unnamed group'**
  String get unnamedGroup;

  /// No description provided for @upcomingHabitDefault.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get upcomingHabitDefault;

  /// No description provided for @upcomingHabitNotDoneToday.
  ///
  /// In en, this message translates to:
  /// **'Not completed today'**
  String get upcomingHabitNotDoneToday;

  /// No description provided for @upcomingPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'🔴 High priority'**
  String get upcomingPriorityHigh;

  /// No description provided for @upcomingPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'🟡 Medium priority'**
  String get upcomingPriorityMedium;

  /// No description provided for @upcomingPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'🟢 Low priority'**
  String get upcomingPriorityLow;

  /// No description provided for @upcomingClientAppointment.
  ///
  /// In en, this message translates to:
  /// **'Client appointment'**
  String get upcomingClientAppointment;

  /// No description provided for @upcomingAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get upcomingAppointment;

  /// No description provided for @upcomingDoseTime.
  ///
  /// In en, this message translates to:
  /// **'Dose time'**
  String get upcomingDoseTime;

  /// No description provided for @upcomingEventCount.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String upcomingEventCount(int count);

  /// No description provided for @booksMyLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'My library'**
  String get booksMyLibraryTitle;

  /// No description provided for @booksAddBook.
  ///
  /// In en, this message translates to:
  /// **'Add book'**
  String get booksAddBook;

  /// No description provided for @booksLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{total} books · {read} read · {reading} reading'**
  String booksLibrarySubtitle(int total, int read, int reading);

  /// No description provided for @booksTabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get booksTabLibrary;

  /// No description provided for @booksTabStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get booksTabStats;

  /// No description provided for @booksTabQuotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get booksTabQuotes;

  /// No description provided for @booksTabGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get booksTabGoals;

  /// No description provided for @booksFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get booksFilterAll;

  /// No description provided for @booksStatusToRead.
  ///
  /// In en, this message translates to:
  /// **'To read'**
  String get booksStatusToRead;

  /// No description provided for @booksStatusReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get booksStatusReading;

  /// No description provided for @booksStatusRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get booksStatusRead;

  /// No description provided for @booksStatusLent.
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get booksStatusLent;

  /// No description provided for @booksEmptyLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library is empty'**
  String get booksEmptyLibraryTitle;

  /// No description provided for @booksEmptyFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'No books in this category'**
  String get booksEmptyFilterTitle;

  /// No description provided for @booksEmptyLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap + above to add a book'**
  String get booksEmptyLibraryDesc;

  /// No description provided for @modulesPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modulesPanelTitle;

  /// No description provided for @modulesNavShortcutTitle.
  ///
  /// In en, this message translates to:
  /// **'Mobile quick access'**
  String get modulesNavShortcutTitle;

  /// No description provided for @modulesNavShortcutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'4th button on the bottom bar'**
  String get modulesNavShortcutSubtitle;

  /// No description provided for @modulesVisibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Visible modules'**
  String get modulesVisibleTitle;

  /// No description provided for @modulesCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get modulesCollapse;

  /// No description provided for @modulesExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get modulesExpandAll;

  /// No description provided for @modulesStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get modulesStatusActive;

  /// No description provided for @modulesStatusHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get modulesStatusHidden;

  /// No description provided for @booksShelfNameHint.
  ///
  /// In en, this message translates to:
  /// **'Shelf name...'**
  String get booksShelfNameHint;

  /// No description provided for @booksPickDecorationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick decoration'**
  String get booksPickDecorationTitle;

  /// No description provided for @booksRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get booksRemove;

  /// No description provided for @booksDecorationCategoryPlants.
  ///
  /// In en, this message translates to:
  /// **'🪴 Plants'**
  String get booksDecorationCategoryPlants;

  /// No description provided for @booksDecorationCategoryObjects.
  ///
  /// In en, this message translates to:
  /// **'🏺 Objects'**
  String get booksDecorationCategoryObjects;

  /// No description provided for @booksDecorationCategoryDecor.
  ///
  /// In en, this message translates to:
  /// **'🖼️ Decor'**
  String get booksDecorationCategoryDecor;

  /// No description provided for @booksDecorationCategoryFigures.
  ///
  /// In en, this message translates to:
  /// **'🐾 Figures'**
  String get booksDecorationCategoryFigures;

  /// No description provided for @booksStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get booksStatTotal;

  /// No description provided for @booksStatPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get booksStatPages;

  /// No description provided for @booksCategoryDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Category distribution'**
  String get booksCategoryDistributionTitle;

  /// No description provided for @booksReadingSpeedTitle.
  ///
  /// In en, this message translates to:
  /// **'My reading speed'**
  String get booksReadingSpeedTitle;

  /// No description provided for @booksPagesPerDay.
  ///
  /// In en, this message translates to:
  /// **'pages/day'**
  String get booksPagesPerDay;

  /// No description provided for @booksPagesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'pages/week'**
  String get booksPagesPerWeek;

  /// No description provided for @booksBooksPerMonth.
  ///
  /// In en, this message translates to:
  /// **'books/month*'**
  String get booksBooksPerMonth;

  /// No description provided for @booksReadingSpeedFootnote.
  ///
  /// In en, this message translates to:
  /// **'* Assumes 300 pages/book'**
  String get booksReadingSpeedFootnote;

  /// No description provided for @booksRecommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'You might also like'**
  String get booksRecommendationsTitle;

  /// No description provided for @booksRecommendationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based on your reading habits'**
  String get booksRecommendationsSubtitle;

  /// No description provided for @booksQuotesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No quotes yet'**
  String get booksQuotesEmptyTitle;

  /// No description provided for @booksQuotesEmptyDescTab.
  ///
  /// In en, this message translates to:
  /// **'Add beautiful sentences from the book page'**
  String get booksQuotesEmptyDescTab;

  /// No description provided for @booksGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'My reading goals'**
  String get booksGoalsTitle;

  /// No description provided for @booksGoalsEmptyTitleTab.
  ///
  /// In en, this message translates to:
  /// **'No goal set'**
  String get booksGoalsEmptyTitleTab;

  /// No description provided for @booksGoalsEmptyDescTab.
  ///
  /// In en, this message translates to:
  /// **'Add goals like \"20 books a year\"'**
  String get booksGoalsEmptyDescTab;

  /// No description provided for @booksAddGoal.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get booksAddGoal;

  /// No description provided for @booksUnitPages.
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get booksUnitPages;

  /// No description provided for @booksUnitBooks.
  ///
  /// In en, this message translates to:
  /// **'books'**
  String get booksUnitBooks;

  /// No description provided for @booksGoalTypeYearlyBooks.
  ///
  /// In en, this message translates to:
  /// **'Yearly books'**
  String get booksGoalTypeYearlyBooks;

  /// No description provided for @booksGoalTypeMonthlyBooks.
  ///
  /// In en, this message translates to:
  /// **'Monthly books'**
  String get booksGoalTypeMonthlyBooks;

  /// No description provided for @booksGoalTypeYearlyPages.
  ///
  /// In en, this message translates to:
  /// **'Yearly pages'**
  String get booksGoalTypeYearlyPages;

  /// No description provided for @booksGoalTypeMonthlyPages.
  ///
  /// In en, this message translates to:
  /// **'Monthly pages'**
  String get booksGoalTypeMonthlyPages;

  /// No description provided for @booksGoalDefaultYearlyBooks.
  ///
  /// In en, this message translates to:
  /// **'Read {target} books this year'**
  String booksGoalDefaultYearlyBooks(Object target);

  /// No description provided for @booksGoalDefaultMonthlyBooks.
  ///
  /// In en, this message translates to:
  /// **'Read {target} books this month'**
  String booksGoalDefaultMonthlyBooks(Object target);

  /// No description provided for @booksGoalDefaultYearlyPages.
  ///
  /// In en, this message translates to:
  /// **'Read {target} pages this year'**
  String booksGoalDefaultYearlyPages(Object target);

  /// No description provided for @booksGoalDefaultMonthlyPages.
  ///
  /// In en, this message translates to:
  /// **'Read {target} pages this month'**
  String booksGoalDefaultMonthlyPages(Object target);

  /// No description provided for @booksGoalDefaultFallback.
  ///
  /// In en, this message translates to:
  /// **'Reading goal'**
  String get booksGoalDefaultFallback;

  /// No description provided for @booksNewGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'New reading goal'**
  String get booksNewGoalTitle;

  /// No description provided for @booksGoalTargetBooksLabel.
  ///
  /// In en, this message translates to:
  /// **'How many books?'**
  String get booksGoalTargetBooksLabel;

  /// No description provided for @booksGoalTargetPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'How many pages?'**
  String get booksGoalTargetPagesLabel;

  /// No description provided for @booksCreateGoal.
  ///
  /// In en, this message translates to:
  /// **'Create goal'**
  String get booksCreateGoal;

  /// No description provided for @booksPageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String booksPageCount(Object count);

  /// No description provided for @booksReadingStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading status'**
  String get booksReadingStatusTitle;

  /// No description provided for @booksProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get booksProgressTitle;

  /// No description provided for @booksProgressPages.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} pages'**
  String booksProgressPages(Object current, Object total);

  /// No description provided for @booksPagesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} pages left'**
  String booksPagesRemaining(Object count);

  /// No description provided for @booksAvgPagesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Avg. {count} pages/day'**
  String booksAvgPagesPerDay(Object count);

  /// No description provided for @booksCurrentPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Current page'**
  String get booksCurrentPageLabel;

  /// No description provided for @booksDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get booksDatesTitle;

  /// No description provided for @booksAcquisitionDate.
  ///
  /// In en, this message translates to:
  /// **'Acquired on'**
  String get booksAcquisitionDate;

  /// No description provided for @booksStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get booksStartDate;

  /// No description provided for @booksFinishDate.
  ///
  /// In en, this message translates to:
  /// **'Finish date'**
  String get booksFinishDate;

  /// No description provided for @booksMyRatingTitle.
  ///
  /// In en, this message translates to:
  /// **'My rating'**
  String get booksMyRatingTitle;

  /// No description provided for @booksRatingTerrible.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get booksRatingTerrible;

  /// No description provided for @booksRatingMediocre.
  ///
  /// In en, this message translates to:
  /// **'Mediocre'**
  String get booksRatingMediocre;

  /// No description provided for @booksRatingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get booksRatingGood;

  /// No description provided for @booksRatingVeryGood.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get booksRatingVeryGood;

  /// No description provided for @booksRatingExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get booksRatingExcellent;

  /// No description provided for @booksNotesAndQuotesTitle.
  ///
  /// In en, this message translates to:
  /// **'My notes & quotes'**
  String get booksNotesAndQuotesTitle;

  /// No description provided for @booksNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Your thoughts about this book, quotes...'**
  String get booksNotesHint;

  /// No description provided for @booksQuotesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get booksQuotesSectionTitle;

  /// No description provided for @booksAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get booksAdd;

  /// No description provided for @booksQuotesEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'No quotes added yet'**
  String get booksQuotesEmptyDetail;

  /// No description provided for @booksViewAllQuotes.
  ///
  /// In en, this message translates to:
  /// **'View all ({count})'**
  String booksViewAllQuotes(Object count);

  /// No description provided for @booksLendingInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Lending info'**
  String get booksLendingInfoTitle;

  /// No description provided for @booksLentTo.
  ///
  /// In en, this message translates to:
  /// **'Lent to'**
  String get booksLentTo;

  /// No description provided for @booksLentDate.
  ///
  /// In en, this message translates to:
  /// **'Lent on'**
  String get booksLentDate;

  /// No description provided for @booksMarkReturned.
  ///
  /// In en, this message translates to:
  /// **'Mark as returned'**
  String get booksMarkReturned;

  /// No description provided for @booksRemoveFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove book from library'**
  String get booksRemoveFromLibrary;

  /// No description provided for @booksRemoveBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove book'**
  String get booksRemoveBookTitle;

  /// No description provided for @booksRemoveBookConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from your library?'**
  String booksRemoveBookConfirm(Object title);

  /// No description provided for @booksLendBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Lend book'**
  String get booksLendBookTitle;

  /// No description provided for @booksLendToLabel.
  ///
  /// In en, this message translates to:
  /// **'Who are you lending it to?'**
  String get booksLendToLabel;

  /// No description provided for @booksLendBookAction.
  ///
  /// In en, this message translates to:
  /// **'Lend'**
  String get booksLendBookAction;

  /// No description provided for @booksSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get booksSelectDate;

  /// No description provided for @booksBookAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Book added successfully'**
  String get booksBookAddedSuccess;

  /// No description provided for @booksBookAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add book. Try again.'**
  String get booksBookAddFailed;

  /// No description provided for @booksAddBookWhereTitle.
  ///
  /// In en, this message translates to:
  /// **'Where should we add this book?'**
  String get booksAddBookWhereTitle;

  /// No description provided for @booksSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search books'**
  String get booksSearchTitle;

  /// No description provided for @booksSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Book title or author...'**
  String get booksSearchHint;

  /// No description provided for @booksSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get booksSearchNoResults;

  /// No description provided for @booksAddToWantToRead.
  ///
  /// In en, this message translates to:
  /// **'Want to read'**
  String get booksAddToWantToRead;

  /// No description provided for @booksAddToCurrentlyReading.
  ///
  /// In en, this message translates to:
  /// **'Currently reading'**
  String get booksAddToCurrentlyReading;

  /// No description provided for @booksAddToRead.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get booksAddToRead;

  /// No description provided for @booksMyQuotesTitle.
  ///
  /// In en, this message translates to:
  /// **'My quotes'**
  String get booksMyQuotesTitle;

  /// No description provided for @booksQuotesEmptyDescScreen.
  ///
  /// In en, this message translates to:
  /// **'Open a book detail and add your favorite sentences here.'**
  String get booksQuotesEmptyDescScreen;

  /// No description provided for @booksQuotePageAbbrev.
  ///
  /// In en, this message translates to:
  /// **'p. {page}'**
  String booksQuotePageAbbrev(Object page);

  /// No description provided for @booksAddQuoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Add quote'**
  String get booksAddQuoteTitle;

  /// No description provided for @booksAddQuoteHint.
  ///
  /// In en, this message translates to:
  /// **'Write the quote here...'**
  String get booksAddQuoteHint;

  /// No description provided for @booksQuotePageOptional.
  ///
  /// In en, this message translates to:
  /// **'Page (optional)'**
  String get booksQuotePageOptional;

  /// No description provided for @booksEditQuoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit quote'**
  String get booksEditQuoteTitle;

  /// No description provided for @booksDeleteQuoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete quote?'**
  String get booksDeleteQuoteTitle;

  /// No description provided for @booksDeleteQuoteMessage.
  ///
  /// In en, this message translates to:
  /// **'This quote will be permanently deleted.'**
  String get booksDeleteQuoteMessage;

  /// No description provided for @booksSelectBookForQuote.
  ///
  /// In en, this message translates to:
  /// **'Choose a book'**
  String get booksSelectBookForQuote;

  /// No description provided for @booksSelectBookForQuoteHint.
  ///
  /// In en, this message translates to:
  /// **'Which book is this quote from?'**
  String get booksSelectBookForQuoteHint;

  /// No description provided for @booksNoBooksForQuote.
  ///
  /// In en, this message translates to:
  /// **'Add a book to your library first.'**
  String get booksNoBooksForQuote;

  /// No description provided for @booksUnpinQuote.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get booksUnpinQuote;

  /// No description provided for @booksPinQuote.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get booksPinQuote;

  /// No description provided for @booksGoalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get booksGoalsEmptyTitle;

  /// No description provided for @booksGoalsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Set trackable goals like \"20 books a year\"'**
  String get booksGoalsEmptyDesc;

  /// No description provided for @booksAddFirstGoal.
  ///
  /// In en, this message translates to:
  /// **'Add your first goal'**
  String get booksAddFirstGoal;

  /// No description provided for @booksGoalCompleted.
  ///
  /// In en, this message translates to:
  /// **'✓ Completed'**
  String get booksGoalCompleted;

  /// No description provided for @booksGoalProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {target} {unit}'**
  String booksGoalProgress(Object current, Object target, Object unit);

  /// No description provided for @booksGoalRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} {unit} left'**
  String booksGoalRemaining(Object count, Object unit);

  /// No description provided for @booksGoalAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add goal'**
  String get booksGoalAddFailed;

  /// No description provided for @booksGoalTypeSection.
  ///
  /// In en, this message translates to:
  /// **'Goal type'**
  String get booksGoalTypeSection;

  /// No description provided for @booksGoalTargetSection.
  ///
  /// In en, this message translates to:
  /// **'Target number'**
  String get booksGoalTargetSection;

  /// No description provided for @booksTitleOptionalSection.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get booksTitleOptionalSection;

  /// No description provided for @booksIconSection.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get booksIconSection;

  /// No description provided for @booksColorSection.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get booksColorSection;

  /// No description provided for @booksReadingStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading statistics'**
  String get booksReadingStatsTitle;

  /// No description provided for @booksRecommendationsSubtitleLong.
  ///
  /// In en, this message translates to:
  /// **'Recommendations based on your reading habits'**
  String get booksRecommendationsSubtitleLong;

  /// No description provided for @calendarAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get calendarAddTask;

  /// No description provided for @calendarSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type a word to search.'**
  String get calendarSearchPrompt;

  /// No description provided for @calendarSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get calendarSearchNoResults;

  /// No description provided for @calendarSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get calendarSearchTitle;

  /// No description provided for @calendarSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks, notes...'**
  String get calendarSearchHint;

  /// No description provided for @calendarTypeTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get calendarTypeTask;

  /// No description provided for @calendarTypeAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get calendarTypeAppointment;

  /// No description provided for @calendarTypeMedication.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get calendarTypeMedication;

  /// No description provided for @calendarTypeHabit.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get calendarTypeHabit;

  /// No description provided for @calendarTypeNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get calendarTypeNote;

  /// No description provided for @calendarHabitFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get calendarHabitFallbackTitle;

  /// No description provided for @calendarHabitStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String calendarHabitStreakDays(Object days);

  /// No description provided for @calendarSectionAllDay.
  ///
  /// In en, this message translates to:
  /// **'ALL DAY'**
  String get calendarSectionAllDay;

  /// No description provided for @calendarSectionSchedule.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get calendarSectionSchedule;

  /// No description provided for @calendarCompletedBadge.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get calendarCompletedBadge;

  /// No description provided for @calendarDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String calendarDurationMinutes(Object minutes);

  /// No description provided for @calendarDeleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get calendarDeleteTaskTitle;

  /// No description provided for @calendarDeleteTaskConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task?'**
  String get calendarDeleteTaskConfirm;

  /// No description provided for @calendarDismiss.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get calendarDismiss;

  /// No description provided for @calendarPostponeTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Postpone task'**
  String get calendarPostponeTaskTitle;

  /// No description provided for @calendarPostpone15Min.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get calendarPostpone15Min;

  /// No description provided for @calendarPostpone1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get calendarPostpone1Hour;

  /// No description provided for @calendarPostponeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get calendarPostponeTomorrow;

  /// No description provided for @calendarTaskPostponed.
  ///
  /// In en, this message translates to:
  /// **'Task {label} postponed'**
  String calendarTaskPostponed(Object label);

  /// No description provided for @calendarEmptyDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned today ☀️'**
  String get calendarEmptyDayTitle;

  /// No description provided for @calendarEmptyDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to start planning'**
  String get calendarEmptyDaySubtitle;

  /// No description provided for @calendarNoteSingular.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get calendarNoteSingular;

  /// No description provided for @calendarNoteCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Notes'**
  String calendarNoteCount(Object count);

  /// No description provided for @taskMemberNotFound.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get taskMemberNotFound;

  /// No description provided for @taskOverlapTitle.
  ///
  /// In en, this message translates to:
  /// **'Time conflict'**
  String get taskOverlapTitle;

  /// No description provided for @taskOverlapMessage.
  ///
  /// In en, this message translates to:
  /// **'You are busy at the selected time with \"{taskName}\".\n\nFree slots:\n{freeSlots}\n\nSave anyway?'**
  String taskOverlapMessage(Object freeSlots, Object taskName);

  /// No description provided for @taskSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get taskSaveAnyway;

  /// No description provided for @taskGoogleCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar event'**
  String get taskGoogleCalendarEvent;

  /// No description provided for @taskRepeatEndSelect.
  ///
  /// In en, this message translates to:
  /// **'Select end date'**
  String get taskRepeatEndSelect;

  /// No description provided for @taskRepeatEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Series end:'**
  String get taskRepeatEndLabel;

  /// No description provided for @taskLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get taskLinkOpenFailed;

  /// No description provided for @taskErrorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String taskErrorWithDetails(Object error);

  /// No description provided for @taskNovaSuggestionFailed.
  ///
  /// In en, this message translates to:
  /// **'Nova could not generate a suggestion.'**
  String get taskNovaSuggestionFailed;

  /// No description provided for @taskNovaSuggestingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nova suggests'**
  String get taskNovaSuggestingTitle;

  /// No description provided for @taskNovaSplitPrompt.
  ///
  /// In en, this message translates to:
  /// **'Split this task into these steps?'**
  String get taskNovaSplitPrompt;

  /// No description provided for @taskAddSteps.
  ///
  /// In en, this message translates to:
  /// **'Add steps'**
  String get taskAddSteps;

  /// No description provided for @taskStepsAddedAsSubtasks.
  ///
  /// In en, this message translates to:
  /// **'Steps added as subtasks!'**
  String get taskStepsAddedAsSubtasks;

  /// No description provided for @taskNovaFindingSlot.
  ///
  /// In en, this message translates to:
  /// **'Nova is looking for free time… 🕵️'**
  String get taskNovaFindingSlot;

  /// No description provided for @taskTimeFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Time found!'**
  String get taskTimeFoundTitle;

  /// No description provided for @taskTimeFoundConfirm.
  ///
  /// In en, this message translates to:
  /// **'This time slot looks suitable. Confirm?'**
  String get taskTimeFoundConfirm;

  /// No description provided for @taskSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get taskSchedule;

  /// No description provided for @taskScheduledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Task scheduled successfully!'**
  String get taskScheduledSuccess;

  /// No description provided for @taskNoFreeSlotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find a suitable free slot :('**
  String get taskNoFreeSlotFound;

  /// No description provided for @taskPostponeTitle.
  ///
  /// In en, this message translates to:
  /// **'Postpone task'**
  String get taskPostponeTitle;

  /// No description provided for @taskSmartPostponeNova.
  ///
  /// In en, this message translates to:
  /// **'Smart postpone (Nova)'**
  String get taskSmartPostponeNova;

  /// No description provided for @taskCustomTimePick.
  ///
  /// In en, this message translates to:
  /// **'Choose custom time'**
  String get taskCustomTimePick;

  /// No description provided for @taskPostpone15Min.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get taskPostpone15Min;

  /// No description provided for @taskPostpone1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get taskPostpone1Hour;

  /// No description provided for @taskPostponeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get taskPostponeTomorrow;

  /// No description provided for @taskPostpone1Week.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get taskPostpone1Week;

  /// No description provided for @taskPostponedWithLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} postponed!'**
  String taskPostponedWithLabel(Object label);

  /// No description provided for @taskPostponedToDate.
  ///
  /// In en, this message translates to:
  /// **'Task postponed to {date}'**
  String taskPostponedToDate(Object date);

  /// No description provided for @taskDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get taskDeleteTitle;

  /// No description provided for @taskDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This task will be permanently deleted. Are you sure?'**
  String get taskDeleteMessage;

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeleted;

  /// No description provided for @taskSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get taskSectionDescription;

  /// No description provided for @taskSectionSubtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get taskSectionSubtasks;

  /// No description provided for @taskSectionLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get taskSectionLink;

  /// No description provided for @taskSectionTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get taskSectionTags;

  /// No description provided for @taskSectionPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get taskSectionPeople;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed!'**
  String get taskCompleted;

  /// No description provided for @taskUncompleted.
  ///
  /// In en, this message translates to:
  /// **'Task marked incomplete.'**
  String get taskUncompleted;

  /// No description provided for @taskBadgeCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get taskBadgeCompleted;

  /// No description provided for @taskBadgeComplete.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE'**
  String get taskBadgeComplete;

  /// No description provided for @taskPriorityHighBadge.
  ///
  /// In en, this message translates to:
  /// **'HIGH PRIORITY'**
  String get taskPriorityHighBadge;

  /// No description provided for @taskPriorityNormalBadge.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get taskPriorityNormalBadge;

  /// No description provided for @taskPriorityLowBadge.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get taskPriorityLowBadge;

  /// No description provided for @taskStartLabel.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get taskStartLabel;

  /// No description provided for @taskEndLabel.
  ///
  /// In en, this message translates to:
  /// **'END'**
  String get taskEndLabel;

  /// No description provided for @taskNovaAssistant.
  ///
  /// In en, this message translates to:
  /// **'Nova Assistant'**
  String get taskNovaAssistant;

  /// No description provided for @taskNovaSplitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Split into smart steps'**
  String get taskNovaSplitSubtitle;

  /// No description provided for @taskAddSubtaskHint.
  ///
  /// In en, this message translates to:
  /// **'Add a new subtask…'**
  String get taskAddSubtaskHint;

  /// No description provided for @projectTasksLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load tasks. Check your connection.'**
  String get projectTasksLoadError;

  /// No description provided for @projectMakeActive.
  ///
  /// In en, this message translates to:
  /// **'Mark active'**
  String get projectMakeActive;

  /// No description provided for @projectMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get projectMarkComplete;

  /// No description provided for @projectArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get projectArchive;

  /// No description provided for @projectViewKanban.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get projectViewKanban;

  /// No description provided for @projectViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get projectViewList;

  /// No description provided for @projectViewNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get projectViewNotes;

  /// No description provided for @projectViewResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get projectViewResources;

  /// No description provided for @projectViewStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get projectViewStatistics;

  /// No description provided for @projectViewActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get projectViewActivity;

  /// No description provided for @projectSearchTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks…'**
  String get projectSearchTasksHint;

  /// No description provided for @projectNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks in this project.'**
  String get projectNoTasks;

  /// No description provided for @projectStatusTodoUpper.
  ///
  /// In en, this message translates to:
  /// **'TO DO'**
  String get projectStatusTodoUpper;

  /// No description provided for @projectStatusInProgressUpper.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get projectStatusInProgressUpper;

  /// No description provided for @projectStatusReviewUpper.
  ///
  /// In en, this message translates to:
  /// **'REVIEW'**
  String get projectStatusReviewUpper;

  /// No description provided for @projectStatusDoneUpper.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get projectStatusDoneUpper;

  /// No description provided for @projectStatusUnknownUpper.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN'**
  String get projectStatusUnknownUpper;

  /// No description provided for @projectKanbanEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get projectKanbanEmpty;

  /// No description provided for @projectTaskBadge.
  ///
  /// In en, this message translates to:
  /// **'TASK'**
  String get projectTaskBadge;

  /// No description provided for @projectDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get projectDeleteTitle;

  /// No description provided for @projectDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this project?'**
  String get projectDeleteConfirm;

  /// No description provided for @projectStatusActiveUpper.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get projectStatusActiveUpper;

  /// No description provided for @projectStatusArchivedUpper.
  ///
  /// In en, this message translates to:
  /// **'ARCHIVED'**
  String get projectStatusArchivedUpper;

  /// No description provided for @projectNewTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get projectNewTaskTitle;

  /// No description provided for @projectEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get projectEditTitle;

  /// No description provided for @projectDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projectDescriptionLabel;

  /// No description provided for @projectFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get projectFilterAll;

  /// No description provided for @projectFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get projectFilterActive;

  /// No description provided for @projectFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get projectFilterCompleted;

  /// No description provided for @projectFilterArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get projectFilterArchived;

  /// No description provided for @projectEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get projectEmptyTitle;

  /// No description provided for @projectEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create a new project'**
  String get projectEmptySubtitle;

  /// No description provided for @projectStatusCompletedUpper.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get projectStatusCompletedUpper;

  /// No description provided for @projectNewProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectNewProjectTitle;

  /// No description provided for @projectColorSelection.
  ///
  /// In en, this message translates to:
  /// **'COLOR'**
  String get projectColorSelection;

  /// No description provided for @projectDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'DEADLINE'**
  String get projectDeadlineLabel;

  /// No description provided for @projectNoDateSelected.
  ///
  /// In en, this message translates to:
  /// **'No date selected'**
  String get projectNoDateSelected;

  /// No description provided for @projectCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get projectCreateButton;

  /// No description provided for @projectActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Project history'**
  String get projectActivityTitle;

  /// No description provided for @projectActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No project activity yet'**
  String get projectActivityEmpty;

  /// No description provided for @projectNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Project notes'**
  String get projectNotesTitle;

  /// No description provided for @projectNoLinkedNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes linked to this project'**
  String get projectNoLinkedNotes;

  /// No description provided for @projectStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Project statistics'**
  String get projectStatisticsTitle;

  /// No description provided for @projectStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get projectStatTotal;

  /// No description provided for @projectStatCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get projectStatCompleted;

  /// No description provided for @projectStatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get projectStatOpen;

  /// No description provided for @projectStatOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get projectStatOverdue;

  /// No description provided for @projectCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion — {percent}%'**
  String projectCompletionRate(Object percent);

  /// No description provided for @projectNoTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get projectNoTasksYet;

  /// No description provided for @projectEditResource.
  ///
  /// In en, this message translates to:
  /// **'Edit resource'**
  String get projectEditResource;

  /// No description provided for @projectResourceTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get projectResourceTitleLabel;

  /// No description provided for @projectResourceUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get projectResourceUrlLabel;

  /// No description provided for @projectResourceDescHint.
  ///
  /// In en, this message translates to:
  /// **'Add a short note or description…'**
  String get projectResourceDescHint;

  /// No description provided for @projectResourceDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projectResourceDescLabel;

  /// No description provided for @projectColorSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Color selection'**
  String get projectColorSelectionTitle;

  /// No description provided for @projectResourcesHeader.
  ///
  /// In en, this message translates to:
  /// **'RESOURCES'**
  String get projectResourcesHeader;

  /// No description provided for @projectResourcesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No resources added yet'**
  String get projectResourcesEmpty;

  /// No description provided for @projectResourceUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get projectResourceUntitled;

  /// No description provided for @teamTabBoards.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get teamTabBoards;

  /// No description provided for @teamTabProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get teamTabProjects;

  /// No description provided for @teamTabStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get teamTabStats;

  /// No description provided for @teamTabResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get teamTabResources;

  /// No description provided for @teamTabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get teamTabActivity;

  /// No description provided for @teamTabNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get teamTabNotes;

  /// No description provided for @teamTabBookClub.
  ///
  /// In en, this message translates to:
  /// **'Book Club'**
  String get teamTabBookClub;

  /// No description provided for @teamNotFound.
  ///
  /// In en, this message translates to:
  /// **'Team not found'**
  String get teamNotFound;

  /// No description provided for @teamNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter team name'**
  String get teamNameHint;

  /// No description provided for @teamColorLabel.
  ///
  /// In en, this message translates to:
  /// **'TEAM COLOR'**
  String get teamColorLabel;

  /// No description provided for @teamErrorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String teamErrorWithDetail(Object error);

  /// No description provided for @teamWorkspaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your teams and projects'**
  String get teamWorkspaceSubtitle;

  /// No description provided for @teamActiveTeams.
  ///
  /// In en, this message translates to:
  /// **'Active teams'**
  String get teamActiveTeams;

  /// No description provided for @teamPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get teamPerformance;

  /// No description provided for @teamPerformanceGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get teamPerformanceGood;

  /// No description provided for @teamEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have a team yet'**
  String get teamEmptyTitle;

  /// No description provided for @teamEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Boost productivity with teamwork. Create a team or join with an invite code.'**
  String get teamEmptyDescription;

  /// No description provided for @teamTaskProgress.
  ///
  /// In en, this message translates to:
  /// **'Task progress'**
  String get teamTaskProgress;

  /// No description provided for @teamProjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get teamProjectsLabel;

  /// No description provided for @teamTasksLabel.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get teamTasksLabel;

  /// No description provided for @teamPersonalTasks.
  ///
  /// In en, this message translates to:
  /// **'Personal tasks'**
  String get teamPersonalTasks;

  /// No description provided for @teamAllTeamTasks.
  ///
  /// In en, this message translates to:
  /// **'All team tasks'**
  String get teamAllTeamTasks;

  /// No description provided for @teamSearchProjectsHint.
  ///
  /// In en, this message translates to:
  /// **'Search projects...'**
  String get teamSearchProjectsHint;

  /// No description provided for @teamKanbanEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get teamKanbanEmpty;

  /// No description provided for @teamNoDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get teamNoDeadline;

  /// No description provided for @teamProjectBadge.
  ///
  /// In en, this message translates to:
  /// **'PROJECT'**
  String get teamProjectBadge;

  /// No description provided for @teamEditResourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit resource'**
  String get teamEditResourceTitle;

  /// No description provided for @teamResourceTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get teamResourceTitleLabel;

  /// No description provided for @teamResourceUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get teamResourceUrlLabel;

  /// No description provided for @teamResourceDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a short note or description...'**
  String get teamResourceDescriptionHint;

  /// No description provided for @teamResourceDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get teamResourceDescriptionLabel;

  /// No description provided for @teamResourceColorSelection.
  ///
  /// In en, this message translates to:
  /// **'Color selection'**
  String get teamResourceColorSelection;

  /// No description provided for @teamAnnouncementContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Announcement content'**
  String get teamAnnouncementContentLabel;

  /// No description provided for @teamUnnamedResource.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get teamUnnamedResource;

  /// No description provided for @teamRevokeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Revoke admin'**
  String get teamRevokeAdmin;

  /// No description provided for @teamMakeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get teamMakeAdmin;

  /// No description provided for @teamRoleUpdatedRefresh.
  ///
  /// In en, this message translates to:
  /// **'Role updated (refresh the page)'**
  String get teamRoleUpdatedRefresh;

  /// No description provided for @teamRemoveFromTeam.
  ///
  /// In en, this message translates to:
  /// **'Remove from team'**
  String get teamRemoveFromTeam;

  /// No description provided for @teamRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get teamRemoveMemberTitle;

  /// No description provided for @teamRemoveMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this team?'**
  String teamRemoveMemberConfirm(Object name);

  /// No description provided for @teamRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get teamRemoveButton;

  /// No description provided for @teamMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get teamMemberRemoved;

  /// No description provided for @teamLeaveTeam.
  ///
  /// In en, this message translates to:
  /// **'Leave team'**
  String get teamLeaveTeam;

  /// No description provided for @teamLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave this team?'**
  String get teamLeaveConfirm;

  /// No description provided for @teamLeaveButton.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get teamLeaveButton;

  /// No description provided for @teamJoinCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'{joinCode} copied!'**
  String teamJoinCodeCopied(Object joinCode);

  /// No description provided for @teamMemberYouSuffix.
  ///
  /// In en, this message translates to:
  /// **'(Me)'**
  String get teamMemberYouSuffix;

  /// No description provided for @teamRoleFounder.
  ///
  /// In en, this message translates to:
  /// **'Founder'**
  String get teamRoleFounder;

  /// No description provided for @teamRoleAdminShort.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get teamRoleAdminShort;

  /// No description provided for @teamRoleMemberShort.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get teamRoleMemberShort;

  /// No description provided for @teamBookClubEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No book club'**
  String get teamBookClubEmptyTitle;

  /// No description provided for @teamBookClubEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Read a book with your team.\nTrack everyone\'s progress.'**
  String get teamBookClubEmptyDescription;

  /// No description provided for @teamBookClubStart.
  ///
  /// In en, this message translates to:
  /// **'Start book club'**
  String get teamBookClubStart;

  /// No description provided for @teamBookNotSelected.
  ///
  /// In en, this message translates to:
  /// **'No book selected'**
  String get teamBookNotSelected;

  /// No description provided for @teamBookChange.
  ///
  /// In en, this message translates to:
  /// **'Change book'**
  String get teamBookChange;

  /// No description provided for @teamBookClubEnd.
  ///
  /// In en, this message translates to:
  /// **'End club'**
  String get teamBookClubEnd;

  /// No description provided for @teamBookPickPrompt.
  ///
  /// In en, this message translates to:
  /// **'Which book will you read?'**
  String get teamBookPickPrompt;

  /// No description provided for @teamBookSelect.
  ///
  /// In en, this message translates to:
  /// **'Select book'**
  String get teamBookSelect;

  /// No description provided for @teamMemberProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Member progress'**
  String get teamMemberProgressTitle;

  /// No description provided for @teamMemberDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get teamMemberDefaultName;

  /// No description provided for @teamMemberYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (You)'**
  String teamMemberYou(Object name);

  /// No description provided for @teamBookPagesProgress.
  ///
  /// In en, this message translates to:
  /// **'{pages} / {total} p.'**
  String teamBookPagesProgress(Object pages, Object total);

  /// No description provided for @teamUpdateMyProgress.
  ///
  /// In en, this message translates to:
  /// **'Update my progress'**
  String get teamUpdateMyProgress;

  /// No description provided for @teamCurrentPageLabel.
  ///
  /// In en, this message translates to:
  /// **'What page are you on?'**
  String get teamCurrentPageLabel;

  /// No description provided for @teamTargetFinish.
  ///
  /// In en, this message translates to:
  /// **'Target finish'**
  String get teamTargetFinish;

  /// No description provided for @teamNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get teamNotSet;

  /// No description provided for @teamDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String teamDaysLeft(Object days);

  /// No description provided for @teamLastDayToday.
  ///
  /// In en, this message translates to:
  /// **'Last day today!'**
  String get teamLastDayToday;

  /// No description provided for @teamSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get teamSelect;

  /// No description provided for @teamClubNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Club name'**
  String get teamClubNameLabel;

  /// No description provided for @teamCreateClub.
  ///
  /// In en, this message translates to:
  /// **'Create club'**
  String get teamCreateClub;

  /// No description provided for @teamTargetFinishDateHelp.
  ///
  /// In en, this message translates to:
  /// **'Target finish date'**
  String get teamTargetFinishDateHelp;

  /// No description provided for @teamEndClubConfirm.
  ///
  /// In en, this message translates to:
  /// **'End this reading season?'**
  String get teamEndClubConfirm;

  /// No description provided for @teamFinish.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get teamFinish;

  /// No description provided for @budgetModuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget tracker'**
  String get budgetModuleTitle;

  /// No description provided for @budgetAddTransactionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get budgetAddTransactionTooltip;

  /// No description provided for @budgetPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get budgetPeriodMonth;

  /// No description provided for @budgetPeriodQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get budgetPeriodQuarter;

  /// No description provided for @budgetPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get budgetPeriodYear;

  /// No description provided for @budgetPeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get budgetPeriodAll;

  /// No description provided for @budgetNoAnomalies.
  ///
  /// In en, this message translates to:
  /// **'No anomalies detected.'**
  String get budgetNoAnomalies;

  /// No description provided for @budgetFixedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Fixed expenses'**
  String get budgetFixedExpenses;

  /// No description provided for @budgetCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash flow'**
  String get budgetCashFlow;

  /// No description provided for @budgetIncomeLegend.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get budgetIncomeLegend;

  /// No description provided for @budgetExpenseLegend.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get budgetExpenseLegend;

  /// No description provided for @budgetAddLimit.
  ///
  /// In en, this message translates to:
  /// **'Add budget limit'**
  String get budgetAddLimit;

  /// No description provided for @budgetLimitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget limits'**
  String get budgetLimitsTitle;

  /// No description provided for @budgetDeleteLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete limit'**
  String get budgetDeleteLimitTitle;

  /// No description provided for @budgetDeleteLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete the {category} limit?'**
  String budgetDeleteLimitMessage(Object category);

  /// No description provided for @budgetLimitAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Limit amount ({symbol})'**
  String budgetLimitAmountHint(Object symbol);

  /// No description provided for @budgetSaveLimit.
  ///
  /// In en, this message translates to:
  /// **'Save limit'**
  String get budgetSaveLimit;

  /// No description provided for @budgetSearchTransactionsHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get budgetSearchTransactionsHint;

  /// No description provided for @budgetErrorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String budgetErrorWithDetail(Object error);

  /// No description provided for @budgetToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get budgetToday;

  /// No description provided for @budgetYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get budgetYesterday;

  /// No description provided for @budgetTargetAccount.
  ///
  /// In en, this message translates to:
  /// **'Target account'**
  String get budgetTargetAccount;

  /// No description provided for @budgetTransactionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated!'**
  String get budgetTransactionUpdated;

  /// No description provided for @budgetTransactionAdded.
  ///
  /// In en, this message translates to:
  /// **'Transaction added successfully!'**
  String get budgetTransactionAdded;

  /// No description provided for @budgetCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get budgetCurrency;

  /// No description provided for @budgetRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get budgetRecurrence;

  /// No description provided for @budgetPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get budgetPaymentMethod;

  /// No description provided for @budgetCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetCategory;

  /// No description provided for @budgetPaymentAccount.
  ///
  /// In en, this message translates to:
  /// **'Payment account'**
  String get budgetPaymentAccount;

  /// No description provided for @budgetRecurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get budgetRecurrenceNone;

  /// No description provided for @budgetRecurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get budgetRecurrenceDaily;

  /// No description provided for @budgetRecurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budgetRecurrenceWeekly;

  /// No description provided for @budgetRecurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetRecurrenceMonthly;

  /// No description provided for @budgetRecurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get budgetRecurrenceYearly;

  /// No description provided for @budgetMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get budgetMethodCash;

  /// No description provided for @budgetMethodCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get budgetMethodCreditCard;

  /// No description provided for @budgetMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank/EFT'**
  String get budgetMethodBankTransfer;

  /// No description provided for @budgetCatGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get budgetCatGeneral;

  /// No description provided for @budgetCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get budgetCatFood;

  /// No description provided for @budgetCatGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get budgetCatGroceries;

  /// No description provided for @budgetCatTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get budgetCatTransport;

  /// No description provided for @budgetCatEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get budgetCatEntertainment;

  /// No description provided for @budgetCatRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get budgetCatRent;

  /// No description provided for @budgetCatBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get budgetCatBills;

  /// No description provided for @budgetCatHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get budgetCatHealth;

  /// No description provided for @budgetCatSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get budgetCatSalary;

  /// No description provided for @budgetCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get budgetCatOther;

  /// No description provided for @medAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add medication'**
  String get medAddTooltip;

  /// No description provided for @medNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New medication'**
  String get medNewTitle;

  /// No description provided for @medEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit medication'**
  String get medEditTitle;

  /// No description provided for @medDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get medDeactivate;

  /// No description provided for @medActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get medActivate;

  /// No description provided for @medNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Medication name is required'**
  String get medNameRequired;

  /// No description provided for @medUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Medication updated successfully'**
  String get medUpdatedSuccess;

  /// No description provided for @medAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Medication added successfully'**
  String get medAddedSuccess;

  /// No description provided for @medSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save medication. Try again.'**
  String get medSaveFailed;

  /// No description provided for @medNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Medication name'**
  String get medNameLabel;

  /// No description provided for @medDosageHint.
  ///
  /// In en, this message translates to:
  /// **'Dose (e.g. 500mg, 1 tablet)'**
  String get medDosageHint;

  /// No description provided for @medFrequencySection.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get medFrequencySection;

  /// No description provided for @medDoseTimesSection.
  ///
  /// In en, this message translates to:
  /// **'Dose times'**
  String get medDoseTimesSection;

  /// No description provided for @medAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get medAddTime;

  /// No description provided for @medColorSection.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get medColorSection;

  /// No description provided for @medDatesSection.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get medDatesSection;

  /// No description provided for @medStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get medStartDate;

  /// No description provided for @medEndDateOptional.
  ///
  /// In en, this message translates to:
  /// **'End (optional)'**
  String get medEndDateOptional;

  /// No description provided for @medNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get medNotesOptional;

  /// No description provided for @medReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder notification'**
  String get medReminderTitle;

  /// No description provided for @medReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify at each dose time'**
  String get medReminderSubtitle;

  /// No description provided for @medActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get medActiveTitle;

  /// No description provided for @medActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inactive meds are hidden from the daily list'**
  String get medActiveSubtitle;

  /// No description provided for @medStockSection.
  ///
  /// In en, this message translates to:
  /// **'Stock tracking'**
  String get medStockSection;

  /// No description provided for @medEnableStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable stock tracking'**
  String get medEnableStockTitle;

  /// No description provided for @medEnableStockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track remaining quantity automatically'**
  String get medEnableStockSubtitle;

  /// No description provided for @medCurrentStock.
  ///
  /// In en, this message translates to:
  /// **'Current stock'**
  String get medCurrentStock;

  /// No description provided for @medCriticalThreshold.
  ///
  /// In en, this message translates to:
  /// **'Critical threshold'**
  String get medCriticalThreshold;

  /// No description provided for @medSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching medications...'**
  String get medSearching;

  /// No description provided for @medSearchNotFound.
  ///
  /// In en, this message translates to:
  /// **'No medication found'**
  String get medSearchNotFound;

  /// No description provided for @medSearchNotFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Import official data or try a different name.'**
  String get medSearchNotFoundHint;

  /// No description provided for @medMatchedFromDb.
  ///
  /// In en, this message translates to:
  /// **'Matched from database'**
  String get medMatchedFromDb;

  /// No description provided for @medActiveIngredient.
  ///
  /// In en, this message translates to:
  /// **'Active ingredient'**
  String get medActiveIngredient;

  /// No description provided for @medAtcCode.
  ///
  /// In en, this message translates to:
  /// **'ATC code'**
  String get medAtcCode;

  /// No description provided for @medBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get medBarcode;

  /// No description provided for @medNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get medNotSelected;

  /// No description provided for @medPickIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose icon'**
  String get medPickIcon;

  /// No description provided for @medDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete medication'**
  String get medDeleteTitle;

  /// No description provided for @medDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This medication will be permanently deleted. Are you sure?'**
  String get medDeleteConfirm;

  /// No description provided for @medDeleted.
  ///
  /// In en, this message translates to:
  /// **'Medication deleted'**
  String get medDeleted;

  /// No description provided for @medUsageSection.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get medUsageSection;

  /// No description provided for @medDosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get medDosage;

  /// No description provided for @medFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get medFrequency;

  /// No description provided for @medTodayDoses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s doses'**
  String get medTodayDoses;

  /// No description provided for @medNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get medNotes;

  /// No description provided for @medStockStatus.
  ///
  /// In en, this message translates to:
  /// **'Stock status'**
  String get medStockStatus;

  /// No description provided for @medProductInfo.
  ///
  /// In en, this message translates to:
  /// **'Product information'**
  String get medProductInfo;

  /// No description provided for @medClassification.
  ///
  /// In en, this message translates to:
  /// **'Medication classification'**
  String get medClassification;

  /// No description provided for @medViewProspectus.
  ///
  /// In en, this message translates to:
  /// **'View package insert (PDF)'**
  String get medViewProspectus;

  /// No description provided for @medInactiveBadge.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get medInactiveBadge;

  /// No description provided for @medRemainingStock.
  ///
  /// In en, this message translates to:
  /// **'Remaining stock'**
  String get medRemainingStock;

  /// No description provided for @medFreqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get medFreqDaily;

  /// No description provided for @medFreqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get medFreqWeekly;

  /// No description provided for @medFreqAsNeeded.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get medFreqAsNeeded;

  /// No description provided for @apptNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New appointment'**
  String get apptNewTitle;

  /// No description provided for @apptReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get apptReschedule;

  /// No description provided for @apptInactiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get apptInactiveBadge;

  /// No description provided for @apptSlotTaken.
  ///
  /// In en, this message translates to:
  /// **'This slot is full; please choose another time.'**
  String get apptSlotTaken;

  /// No description provided for @adminPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanelTitle;

  /// No description provided for @adminPanelDesc.
  ///
  /// In en, this message translates to:
  /// **'System admin panel'**
  String get adminPanelDesc;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully'**
  String get loginSuccess;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreatedSuccess;

  /// No description provided for @accountAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access to your account is blocked.'**
  String get accountAccessDenied;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect'**
  String get invalidEmailOrPassword;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed: {error}'**
  String appleSignInFailed(Object error);

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get passwordStrengthMedium;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @accountChooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get accountChooseAvatar;

  /// No description provided for @requestConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Request Confirmation'**
  String get requestConfirmation;

  /// No description provided for @backupReady.
  ///
  /// In en, this message translates to:
  /// **'Backup ready'**
  String get backupReady;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @dataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
  String get dataCleared;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @accountHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile · preferences · modules'**
  String get accountHeaderSubtitle;

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserName;

  /// No description provided for @themeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get themeDay;

  /// No description provided for @themeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get themeNight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeAmoledTitle.
  ///
  /// In en, this message translates to:
  /// **'AMOLED black'**
  String get themeAmoledTitle;

  /// No description provided for @themeAmoledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'True black background · battery saving'**
  String get themeAmoledSubtitle;

  /// No description provided for @uiScaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Interface scale'**
  String get uiScaleLabel;

  /// No description provided for @uiScaleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scale the whole interface (layout + text)'**
  String get uiScaleSubtitle;

  /// No description provided for @accentColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColorLabel;

  /// No description provided for @accountSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Access & Security'**
  String get accountSectionSecurity;

  /// No description provided for @accountSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get accountSectionAppearance;

  /// No description provided for @accountSectionWebUi.
  ///
  /// In en, this message translates to:
  /// **'Web interface'**
  String get accountSectionWebUi;

  /// No description provided for @accountSectionWebUiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Right panel and shell'**
  String get accountSectionWebUiSubtitle;

  /// No description provided for @weatherPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather panel'**
  String get weatherPanelTitle;

  /// No description provided for @weatherPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When off, open only from here'**
  String get weatherPanelSubtitle;

  /// No description provided for @accountSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data & backup'**
  String get accountSectionData;

  /// No description provided for @testData.
  ///
  /// In en, this message translates to:
  /// **'Test data'**
  String get testData;

  /// No description provided for @sidebarExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get sidebarExpand;

  /// No description provided for @sidebarCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get sidebarCollapse;

  /// No description provided for @modulesPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{enabled} active · menu and sidebar'**
  String modulesPanelSubtitle(Object enabled);

  /// No description provided for @novaPreparing.
  ///
  /// In en, this message translates to:
  /// **'Nova is getting ready…'**
  String get novaPreparing;

  /// No description provided for @novaListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get novaListening;

  /// No description provided for @aiActionCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Action could not be created. Please try again.'**
  String get aiActionCreateFailed;

  /// No description provided for @aiStatusAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get aiStatusAnswered;

  /// No description provided for @aiTasksAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks added ✅'**
  String aiTasksAddedCount(Object count);

  /// No description provided for @aiApproveAllTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} Tasks — Approve All'**
  String aiApproveAllTasksTitle(Object count);

  /// No description provided for @aiAddAllTasks.
  ///
  /// In en, this message translates to:
  /// **'Add All ✓'**
  String get aiAddAllTasks;

  /// No description provided for @aiLabelDeleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get aiLabelDeleteTask;

  /// No description provided for @aiLabelUpdateTask.
  ///
  /// In en, this message translates to:
  /// **'Update Task'**
  String get aiLabelUpdateTask;

  /// No description provided for @aiLabelRescheduleTask.
  ///
  /// In en, this message translates to:
  /// **'Reschedule Task'**
  String get aiLabelRescheduleTask;

  /// No description provided for @aiLabelCompleteTask.
  ///
  /// In en, this message translates to:
  /// **'Complete Task'**
  String get aiLabelCompleteTask;

  /// No description provided for @aiLabelCreateAppointment.
  ///
  /// In en, this message translates to:
  /// **'Create Appointment'**
  String get aiLabelCreateAppointment;

  /// No description provided for @aiLabelCancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get aiLabelCancelAppointment;

  /// No description provided for @aiLabelRescheduleAppointment.
  ///
  /// In en, this message translates to:
  /// **'Reschedule Appointment'**
  String get aiLabelRescheduleAppointment;

  /// No description provided for @aiLabelCreateNote.
  ///
  /// In en, this message translates to:
  /// **'Create Note'**
  String get aiLabelCreateNote;

  /// No description provided for @aiLabelAddHabit.
  ///
  /// In en, this message translates to:
  /// **'Add Habit'**
  String get aiLabelAddHabit;

  /// No description provided for @aiLabelAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get aiLabelAddIncome;

  /// No description provided for @aiLabelSavingsGoal.
  ///
  /// In en, this message translates to:
  /// **'Savings Goal'**
  String get aiLabelSavingsGoal;

  /// No description provided for @aiTaskDeletePermanentWarning.
  ///
  /// In en, this message translates to:
  /// **'This task will be permanently deleted!'**
  String get aiTaskDeletePermanentWarning;

  /// No description provided for @aiAppointmentCancelPermanentWarning.
  ///
  /// In en, this message translates to:
  /// **'The appointment will be permanently cancelled.'**
  String get aiAppointmentCancelPermanentWarning;

  /// No description provided for @aiFieldClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get aiFieldClient;

  /// No description provided for @aiFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get aiFieldPhone;

  /// No description provided for @aiFieldDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get aiFieldDuration;

  /// No description provided for @aiFieldNotebook.
  ///
  /// In en, this message translates to:
  /// **'Notebook'**
  String get aiFieldNotebook;

  /// No description provided for @aiFieldReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get aiFieldReminder;

  /// No description provided for @aiFieldGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get aiFieldGoal;

  /// No description provided for @aiFieldDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get aiFieldDeadline;

  /// No description provided for @aiFieldNewDate.
  ///
  /// In en, this message translates to:
  /// **'New date'**
  String get aiFieldNewDate;

  /// No description provided for @aiFieldNewTime.
  ///
  /// In en, this message translates to:
  /// **'New time'**
  String get aiFieldNewTime;

  /// No description provided for @aiFieldTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get aiFieldTask;

  /// No description provided for @aiCreatedByNova.
  ///
  /// In en, this message translates to:
  /// **'Created by Nova.'**
  String get aiCreatedByNova;

  /// No description provided for @defaultTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get defaultTask;

  /// No description provided for @defaultExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get defaultExpense;

  /// No description provided for @defaultCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get defaultCategoryOther;

  /// No description provided for @defaultAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get defaultAppointment;

  /// No description provided for @defaultNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get defaultNote;

  /// No description provided for @defaultHabit.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get defaultHabit;

  /// No description provided for @defaultIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get defaultIncome;

  /// No description provided for @defaultGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get defaultGoal;

  /// No description provided for @noteTaskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found or deleted.'**
  String get noteTaskNotFound;

  /// No description provided for @noteAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get noteAddTask;

  /// No description provided for @noteNoOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'No open tasks.'**
  String get noteNoOpenTasks;

  /// No description provided for @noteLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This note is locked — editing disabled.'**
  String get noteLockedMessage;

  /// No description provided for @noteUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get noteUnlock;

  /// No description provided for @noteLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get noteLock;

  /// No description provided for @notePageLayout.
  ///
  /// In en, this message translates to:
  /// **'Page Layout'**
  String get notePageLayout;

  /// No description provided for @noteAddLink.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get noteAddLink;

  /// No description provided for @noteLinkUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://'**
  String get noteLinkUrlHint;

  /// No description provided for @notebookNew.
  ///
  /// In en, this message translates to:
  /// **'New Notebook'**
  String get notebookNew;

  /// No description provided for @notebookNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Notebook name'**
  String get notebookNameLabel;

  /// No description provided for @notebookNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Work, Personal...'**
  String get notebookNameHint;

  /// No description provided for @notebookEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any notebooks yet.'**
  String get notebookEmpty;

  /// No description provided for @noteEmbedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Content could not be loaded'**
  String get noteEmbedLoadFailed;

  /// No description provided for @noteSelectMembers.
  ///
  /// In en, this message translates to:
  /// **'Select Members'**
  String get noteSelectMembers;

  /// No description provided for @notesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Notes could not be loaded'**
  String get notesLoadFailed;

  /// No description provided for @noteCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create Your First Note'**
  String get noteCreateFirst;

  /// No description provided for @noteRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get noteRestore;

  /// No description provided for @noteDeletePermanent.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get noteDeletePermanent;

  /// No description provided for @noteMoveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to Trash'**
  String get noteMoveToTrash;

  /// No description provided for @noteCalloutTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get noteCalloutTip;

  /// No description provided for @noteCalloutInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get noteCalloutInfo;

  /// No description provided for @noteCalloutWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get noteCalloutWarning;

  /// No description provided for @noteCalloutDanger.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get noteCalloutDanger;

  /// No description provided for @noteCalloutPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write here…'**
  String get noteCalloutPlaceholder;

  /// No description provided for @noteCalloutAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Callout'**
  String get noteCalloutAdd;

  /// No description provided for @noteDividerLine.
  ///
  /// In en, this message translates to:
  /// **'Thin Line'**
  String get noteDividerLine;

  /// No description provided for @noteDividerThick.
  ///
  /// In en, this message translates to:
  /// **'Thick Line'**
  String get noteDividerThick;

  /// No description provided for @noteDividerDots.
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get noteDividerDots;

  /// No description provided for @noteTableDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Table'**
  String get noteTableDeleteTitle;

  /// No description provided for @noteTableDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get noteTableDeleteBody;

  /// No description provided for @noteTableCellHint.
  ///
  /// In en, this message translates to:
  /// **'Cell content…'**
  String get noteTableCellHint;

  /// No description provided for @noteTableCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Table'**
  String get noteTableCreate;

  /// No description provided for @noteWorkflowDone.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get noteWorkflowDone;

  /// No description provided for @noteWorkflowNewStep.
  ///
  /// In en, this message translates to:
  /// **'New Step'**
  String get noteWorkflowNewStep;

  /// No description provided for @noteWorkflowCompletedCelebration.
  ///
  /// In en, this message translates to:
  /// **'🎉 Completed!'**
  String get noteWorkflowCompletedCelebration;

  /// No description provided for @notePageSettings.
  ///
  /// In en, this message translates to:
  /// **'Page Settings'**
  String get notePageSettings;

  /// No description provided for @notePageOrientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get notePageOrientation;

  /// No description provided for @notePageMargins.
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get notePageMargins;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @wide.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get wide;

  /// No description provided for @notePageBreakLabel.
  ///
  /// In en, this message translates to:
  /// **'PAGE BREAK'**
  String get notePageBreakLabel;

  /// No description provided for @quoteOfDay.
  ///
  /// In en, this message translates to:
  /// **'Quote of the Day'**
  String get quoteOfDay;

  /// No description provided for @quickNote.
  ///
  /// In en, this message translates to:
  /// **'Quick Note'**
  String get quickNote;

  /// No description provided for @quickNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Jot something down…'**
  String get quickNoteHint;

  /// No description provided for @quickNoteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved successfully'**
  String get quickNoteSaved;

  /// No description provided for @weatherWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get weatherWind;

  /// No description provided for @weatherSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City/District'**
  String get weatherSelectCity;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @focusXpBonus.
  ///
  /// In en, this message translates to:
  /// **'+100 XP'**
  String get focusXpBonus;

  /// No description provided for @focusBreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get focusBreakLabel;

  /// No description provided for @corkboardPaperYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get corkboardPaperYellow;

  /// No description provided for @corkboardPaperWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get corkboardPaperWhite;

  /// No description provided for @corkboardPaperBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get corkboardPaperBlue;

  /// No description provided for @corkboardPaperPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get corkboardPaperPink;

  /// No description provided for @corkboardPaperGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get corkboardPaperGreen;

  /// No description provided for @notifChannelTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get notifChannelTasks;

  /// No description provided for @notifChannelMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get notifChannelMedications;

  /// No description provided for @notifChannelAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get notifChannelAppointments;

  /// No description provided for @notifChannelHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get notifChannelHabits;

  /// No description provided for @notifChannelFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get notifChannelFocus;

  /// No description provided for @notifChannelTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get notifChannelTeams;

  /// No description provided for @notifChannelGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notifChannelGeneral;

  /// No description provided for @notifChannelInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant Notifications'**
  String get notifChannelInstant;

  /// No description provided for @notifChannelDailyBriefing.
  ///
  /// In en, this message translates to:
  /// **'Daily Briefing'**
  String get notifChannelDailyBriefing;

  /// No description provided for @notifChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'{name} reminders'**
  String notifChannelDescription(Object name);

  /// No description provided for @notifHabitReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'🔥 Habit Reminder'**
  String get notifHabitReminderTitle;

  /// No description provided for @notifHabitReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to complete \"{name}\"!'**
  String notifHabitReminderBody(Object name);

  /// No description provided for @notifMedicationTitle.
  ///
  /// In en, this message translates to:
  /// **'💊 Medication Time'**
  String get notifMedicationTitle;

  /// No description provided for @notifMedicationBody.
  ///
  /// In en, this message translates to:
  /// **'Time to take \"{name}\".'**
  String notifMedicationBody(Object name);

  /// No description provided for @aiToolErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get aiToolErrorGeneric;

  /// No description provided for @aiToolErrorTaskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found.'**
  String get aiToolErrorTaskNotFound;

  /// No description provided for @aiPromptApproveAllTasks.
  ///
  /// In en, this message translates to:
  /// **'Do you approve all of them? 🗓️'**
  String get aiPromptApproveAllTasks;

  /// No description provided for @aiPromptApproveDayPlan.
  ///
  /// In en, this message translates to:
  /// **'Do you approve? 📅'**
  String get aiPromptApproveDayPlan;

  /// No description provided for @aiPromptWhatWouldYouLike.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get aiPromptWhatWouldYouLike;

  /// No description provided for @aiTaskOverlapWarning.
  ///
  /// In en, this message translates to:
  /// **'Attention! You have \"{title}\" at that time. Free slots:\n{slots}'**
  String aiTaskOverlapWarning(Object slots, Object title);

  /// No description provided for @aiPromptDeleteTask.
  ///
  /// In en, this message translates to:
  /// **'You are about to delete \"{title}\". Approve?'**
  String aiPromptDeleteTask(Object title);

  /// No description provided for @aiPromptUpdateTask.
  ///
  /// In en, this message translates to:
  /// **'Update task \"{title}\". Approve?'**
  String aiPromptUpdateTask(Object title);

  /// No description provided for @aiPromptCreateAppointment.
  ///
  /// In en, this message translates to:
  /// **'Create appointment. Approve?'**
  String get aiPromptCreateAppointment;

  /// No description provided for @aiPromptMarkMedication.
  ///
  /// In en, this message translates to:
  /// **'Mark medication taken. Approve?'**
  String get aiPromptMarkMedication;

  /// No description provided for @aiPromptAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense. Approve?'**
  String get aiPromptAddExpense;

  /// No description provided for @aiPromptTeamAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Post team announcement. Approve?'**
  String get aiPromptTeamAnnouncement;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'General app notifications'**
  String get pushNotificationsSubtitle;

  /// No description provided for @taskRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts for starting tasks'**
  String get taskRemindersSubtitle;

  /// No description provided for @teamInvitesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New memberships and projects'**
  String get teamInvitesSubtitle;

  /// No description provided for @dailyBriefingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Morning briefing from Nova'**
  String get dailyBriefingSubtitle;

  /// No description provided for @emailNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t miss important updates'**
  String get emailNotificationsSubtitle;

  /// No description provided for @passwordSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get passwordSecuritySubtitle;

  /// No description provided for @aboutPhobesVisionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vision and story'**
  String get aboutPhobesVisionSubtitle;

  /// No description provided for @featureTreeAllModulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All modules'**
  String get featureTreeAllModulesSubtitle;

  /// No description provided for @contactGetHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help'**
  String get contactGetHelpSubtitle;

  /// No description provided for @clearLocalDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear local data'**
  String get clearLocalDataSubtitle;

  /// No description provided for @permanentActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanent action'**
  String get permanentActionSubtitle;

  /// No description provided for @accountSectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get accountSectionApp;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @simulateStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Full Simulation'**
  String get simulateStartTitle;

  /// No description provided for @simulateStartMessage.
  ///
  /// In en, this message translates to:
  /// **'A comprehensive 3-month (90-day) test environment will be created.\n\n• All existing data will be deleted.\n• Teams, projects, and resources\n• 90 days of tasks and notes history\n• Habits, medications, and appointments\n• Budget, accounts, and savings goals\n\nDo you want to continue?'**
  String get simulateStartMessage;

  /// No description provided for @simulatePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing simulation...'**
  String get simulatePreparing;

  /// No description provided for @allSystemsSynced.
  ///
  /// In en, this message translates to:
  /// **'All systems synchronized! 🚀'**
  String get allSystemsSynced;

  /// No description provided for @noteWorkflowTodo.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get noteWorkflowTodo;

  /// No description provided for @noteWorkflowPending.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get noteWorkflowPending;

  /// No description provided for @notebooksHeader.
  ///
  /// In en, this message translates to:
  /// **'NOTEBOOKS'**
  String get notebooksHeader;

  /// No description provided for @noteAllNotes.
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get noteAllNotes;

  /// No description provided for @editNotebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Notebook'**
  String get editNotebookTitle;

  /// No description provided for @durationMinutesFormat.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutesFormat(Object minutes);

  /// No description provided for @aiFieldAppointmentId.
  ///
  /// In en, this message translates to:
  /// **'Appointment ID'**
  String get aiFieldAppointmentId;

  /// No description provided for @aiFieldContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get aiFieldContent;

  /// No description provided for @aiFieldHabit.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get aiFieldHabit;

  /// No description provided for @pagePortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get pagePortrait;

  /// No description provided for @pageLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get pageLandscape;

  /// No description provided for @marginNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get marginNormal;

  /// No description provided for @marginNarrow.
  ///
  /// In en, this message translates to:
  /// **'Narrow'**
  String get marginNarrow;

  /// No description provided for @marginMirror.
  ///
  /// In en, this message translates to:
  /// **'Mirror'**
  String get marginMirror;

  /// No description provided for @marginTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get marginTop;

  /// No description provided for @marginBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get marginBottom;

  /// No description provided for @marginLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get marginLeft;

  /// No description provided for @marginRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get marginRight;

  /// No description provided for @notePageSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Page Size'**
  String get notePageSizeLabel;

  /// No description provided for @statsModuleTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get statsModuleTasks;

  /// No description provided for @statsModuleHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get statsModuleHabits;

  /// No description provided for @statsModuleBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get statsModuleBudget;

  /// No description provided for @statsModuleNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get statsModuleNotes;

  /// No description provided for @statsModuleAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get statsModuleAppointments;

  /// No description provided for @statsModuleMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get statsModuleMedications;

  /// No description provided for @statsModuleBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get statsModuleBooks;

  /// No description provided for @statsModuleCorkboard.
  ///
  /// In en, this message translates to:
  /// **'Planning board'**
  String get statsModuleCorkboard;

  /// No description provided for @statsModuleFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get statsModuleFocus;

  /// No description provided for @statsModuleTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get statsModuleTeams;

  /// No description provided for @statsGeneralActivity.
  ///
  /// In en, this message translates to:
  /// **'Overall activity'**
  String get statsGeneralActivity;

  /// No description provided for @statsModulePerformance.
  ///
  /// In en, this message translates to:
  /// **'Module performance'**
  String get statsModulePerformance;

  /// No description provided for @statsModulePerformanceHint.
  ///
  /// In en, this message translates to:
  /// **'Bar height is a 0–100 normalized score; each module uses different metrics.'**
  String get statsModulePerformanceHint;

  /// No description provided for @statsHabitLabel.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get statsHabitLabel;

  /// No description provided for @statsCorkboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Planning board'**
  String get statsCorkboardLabel;

  /// No description provided for @statsSummaryMetrics.
  ///
  /// In en, this message translates to:
  /// **'Summary metrics'**
  String get statsSummaryMetrics;

  /// No description provided for @statsStatusDistribution.
  ///
  /// In en, this message translates to:
  /// **'Status distribution'**
  String get statsStatusDistribution;

  /// No description provided for @statsPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get statsPriority;

  /// No description provided for @statsDailyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Daily completed'**
  String get statsDailyCompleted;

  /// No description provided for @statsPeriodTrend.
  ///
  /// In en, this message translates to:
  /// **'Period trend'**
  String get statsPeriodTrend;

  /// No description provided for @statsActivityHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Activity heatmap'**
  String get statsActivityHeatmap;

  /// No description provided for @statsTagDistribution.
  ///
  /// In en, this message translates to:
  /// **'Tag distribution'**
  String get statsTagDistribution;

  /// No description provided for @statsHourlyDensity.
  ///
  /// In en, this message translates to:
  /// **'Hourly density'**
  String get statsHourlyDensity;

  /// No description provided for @statsIntradayDistribution.
  ///
  /// In en, this message translates to:
  /// **'Intraday distribution'**
  String get statsIntradayDistribution;

  /// No description provided for @statsWeekdayDistribution.
  ///
  /// In en, this message translates to:
  /// **'By weekday'**
  String get statsWeekdayDistribution;

  /// No description provided for @statsComplianceRate.
  ///
  /// In en, this message translates to:
  /// **'Compliance rate'**
  String get statsComplianceRate;

  /// No description provided for @statsPeriodCompliance.
  ///
  /// In en, this message translates to:
  /// **'Period compliance'**
  String get statsPeriodCompliance;

  /// No description provided for @statsActivitySummary.
  ///
  /// In en, this message translates to:
  /// **'Activity summary'**
  String get statsActivitySummary;

  /// No description provided for @statsIncomeExpense.
  ///
  /// In en, this message translates to:
  /// **'Income / Expense'**
  String get statsIncomeExpense;

  /// No description provided for @statsExpenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get statsExpenseCategories;

  /// No description provided for @statsTransactionCount.
  ///
  /// In en, this message translates to:
  /// **'Transaction count'**
  String get statsTransactionCount;

  /// No description provided for @statsCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash flow'**
  String get statsCashFlow;

  /// No description provided for @statsDailyExpense.
  ///
  /// In en, this message translates to:
  /// **'Daily expense'**
  String get statsDailyExpense;

  /// No description provided for @statsDailyIncome.
  ///
  /// In en, this message translates to:
  /// **'Daily income'**
  String get statsDailyIncome;

  /// No description provided for @statsCategoryDistribution.
  ///
  /// In en, this message translates to:
  /// **'Category distribution'**
  String get statsCategoryDistribution;

  /// No description provided for @statsNoteActivity.
  ///
  /// In en, this message translates to:
  /// **'Note activity'**
  String get statsNoteActivity;

  /// No description provided for @statsEngagementDistribution.
  ///
  /// In en, this message translates to:
  /// **'Engagement distribution'**
  String get statsEngagementDistribution;

  /// No description provided for @statsAppointmentStatuses.
  ///
  /// In en, this message translates to:
  /// **'Appointment statuses'**
  String get statsAppointmentStatuses;

  /// No description provided for @statsAppointmentCounts.
  ///
  /// In en, this message translates to:
  /// **'Appointment counts'**
  String get statsAppointmentCounts;

  /// No description provided for @statsRevenueSummary.
  ///
  /// In en, this message translates to:
  /// **'Revenue summary'**
  String get statsRevenueSummary;

  /// No description provided for @statsFromCompletedAppointments.
  ///
  /// In en, this message translates to:
  /// **'from completed appointments'**
  String get statsFromCompletedAppointments;

  /// No description provided for @statsDoseCompliance.
  ///
  /// In en, this message translates to:
  /// **'Dose compliance'**
  String get statsDoseCompliance;

  /// No description provided for @statsCompliancePercent.
  ///
  /// In en, this message translates to:
  /// **'Compliance %'**
  String get statsCompliancePercent;

  /// No description provided for @statsModuleSummary.
  ///
  /// In en, this message translates to:
  /// **'Module summary'**
  String get statsModuleSummary;

  /// No description provided for @statsDetailedStats.
  ///
  /// In en, this message translates to:
  /// **'Detailed statistics'**
  String get statsDetailedStats;

  /// No description provided for @statsNoDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get statsNoDataForPeriod;

  /// No description provided for @statsBookReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get statsBookReading;

  /// No description provided for @statsBookFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get statsBookFinished;

  /// No description provided for @statsBookNew.
  ///
  /// In en, this message translates to:
  /// **'Just started'**
  String get statsBookNew;

  /// No description provided for @statsPeriodDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get statsPeriodDay;

  /// No description provided for @statsPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get statsPeriodWeek;

  /// No description provided for @statsPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get statsPeriodMonth;

  /// No description provided for @statsPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get statsPeriodYear;

  /// No description provided for @landingHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get landingHome;

  /// No description provided for @landingAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get landingAbout;

  /// No description provided for @landingFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get landingFeatures;

  /// No description provided for @landingContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get landingContact;

  /// No description provided for @landingThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get landingThemeLight;

  /// No description provided for @landingThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get landingThemeDark;

  /// No description provided for @landingAiProductivity.
  ///
  /// In en, this message translates to:
  /// **'AI-POWERED PRODUCTIVITY'**
  String get landingAiProductivity;

  /// No description provided for @landingHeroHeadline.
  ///
  /// In en, this message translates to:
  /// **'Don\'t just live.\nManage your time.'**
  String get landingHeroHeadline;

  /// No description provided for @landingHeroSub.
  ///
  /// In en, this message translates to:
  /// **'Tasks, calendar, teams, budget, and Nova AI in one app.'**
  String get landingHeroSub;

  /// No description provided for @landingCtaStart.
  ///
  /// In en, this message translates to:
  /// **'GET STARTED'**
  String get landingCtaStart;

  /// No description provided for @landingCtaFree.
  ///
  /// In en, this message translates to:
  /// **'START FREE'**
  String get landingCtaFree;

  /// No description provided for @landingFeatCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Master of Time'**
  String get landingFeatCalendarTitle;

  /// No description provided for @landingFeatCalendarBadge.
  ///
  /// In en, this message translates to:
  /// **'SMART CALENDAR'**
  String get landingFeatCalendarBadge;

  /// No description provided for @landingFeatCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'See your whole plan in weekly, monthly, and daily views. Tasks, appointments, and notes in one calendar.'**
  String get landingFeatCalendarDesc;

  /// No description provided for @landingFeatTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Power'**
  String get landingFeatTeamsTitle;

  /// No description provided for @landingFeatTeamsBadge.
  ///
  /// In en, this message translates to:
  /// **'PROJECT MANAGEMENT'**
  String get landingFeatTeamsBadge;

  /// No description provided for @landingFeatTeamsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your team with kanban, projects, and leaderboards.'**
  String get landingFeatTeamsDesc;

  /// No description provided for @landingFeatNovaTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get landingFeatNovaTitle;

  /// No description provided for @landingFeatNovaBadge.
  ///
  /// In en, this message translates to:
  /// **'PHOBES NOVA'**
  String get landingFeatNovaBadge;

  /// No description provided for @landingFeatNovaDesc.
  ///
  /// In en, this message translates to:
  /// **'Nova analyzes productivity, prioritizes tasks, and suggests what to do next.'**
  String get landingFeatNovaDesc;

  /// No description provided for @landingFeatBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Control'**
  String get landingFeatBudgetTitle;

  /// No description provided for @landingFeatBudgetBadge.
  ///
  /// In en, this message translates to:
  /// **'SMART BUDGET'**
  String get landingFeatBudgetBadge;

  /// No description provided for @landingFeatBudgetDesc.
  ///
  /// In en, this message translates to:
  /// **'Categorize spending, set limits, and see where your money goes.'**
  String get landingFeatBudgetDesc;

  /// No description provided for @noteSlashCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get noteSlashCommands;

  /// No description provided for @noteSlashHeading1Label.
  ///
  /// In en, this message translates to:
  /// **'Heading 1'**
  String get noteSlashHeading1Label;

  /// No description provided for @noteSlashHeading1Desc.
  ///
  /// In en, this message translates to:
  /// **'Large heading'**
  String get noteSlashHeading1Desc;

  /// No description provided for @noteSlashHeading2Label.
  ///
  /// In en, this message translates to:
  /// **'Heading 2'**
  String get noteSlashHeading2Label;

  /// No description provided for @noteSlashHeading2Desc.
  ///
  /// In en, this message translates to:
  /// **'Medium heading'**
  String get noteSlashHeading2Desc;

  /// No description provided for @noteSlashHeading3Label.
  ///
  /// In en, this message translates to:
  /// **'Heading 3'**
  String get noteSlashHeading3Label;

  /// No description provided for @noteSlashHeading3Desc.
  ///
  /// In en, this message translates to:
  /// **'Small heading'**
  String get noteSlashHeading3Desc;

  /// No description provided for @noteSlashBulletLabel.
  ///
  /// In en, this message translates to:
  /// **'Bullet List'**
  String get noteSlashBulletLabel;

  /// No description provided for @noteSlashBulletDesc.
  ///
  /// In en, this message translates to:
  /// **'Unordered list'**
  String get noteSlashBulletDesc;

  /// No description provided for @noteSlashNumberedLabel.
  ///
  /// In en, this message translates to:
  /// **'Numbered List'**
  String get noteSlashNumberedLabel;

  /// No description provided for @noteSlashNumberedDesc.
  ///
  /// In en, this message translates to:
  /// **'Ordered list'**
  String get noteSlashNumberedDesc;

  /// No description provided for @noteSlashChecklistLabel.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get noteSlashChecklistLabel;

  /// No description provided for @noteSlashChecklistDesc.
  ///
  /// In en, this message translates to:
  /// **'To-do items'**
  String get noteSlashChecklistDesc;

  /// No description provided for @noteSlashTableLabel.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get noteSlashTableLabel;

  /// No description provided for @noteSlashTableDesc.
  ///
  /// In en, this message translates to:
  /// **'Insert a table'**
  String get noteSlashTableDesc;

  /// No description provided for @noteSlashCalloutLabel.
  ///
  /// In en, this message translates to:
  /// **'Callout'**
  String get noteSlashCalloutLabel;

  /// No description provided for @noteSlashCalloutDesc.
  ///
  /// In en, this message translates to:
  /// **'Info / warning box'**
  String get noteSlashCalloutDesc;

  /// No description provided for @noteSlashDividerLabel.
  ///
  /// In en, this message translates to:
  /// **'Divider'**
  String get noteSlashDividerLabel;

  /// No description provided for @noteSlashDividerDesc.
  ///
  /// In en, this message translates to:
  /// **'Horizontal separator'**
  String get noteSlashDividerDesc;

  /// No description provided for @noteSlashQuoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get noteSlashQuoteLabel;

  /// No description provided for @noteSlashQuoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Block quote'**
  String get noteSlashQuoteDesc;

  /// No description provided for @noteSlashCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code Block'**
  String get noteSlashCodeLabel;

  /// No description provided for @noteSlashCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Code snippet'**
  String get noteSlashCodeDesc;

  /// No description provided for @noteSlashTaskCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Task Card'**
  String get noteSlashTaskCardLabel;

  /// No description provided for @noteSlashTaskCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Embed a task'**
  String get noteSlashTaskCardDesc;

  /// No description provided for @noteSlashWorkflowLabel.
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get noteSlashWorkflowLabel;

  /// No description provided for @noteSlashWorkflowDesc.
  ///
  /// In en, this message translates to:
  /// **'Process pipeline'**
  String get noteSlashWorkflowDesc;

  /// No description provided for @noteSlashTable2Label.
  ///
  /// In en, this message translates to:
  /// **'2×3 Table'**
  String get noteSlashTable2Label;

  /// No description provided for @noteSlashTable2Desc.
  ///
  /// In en, this message translates to:
  /// **'Quick 2-column table'**
  String get noteSlashTable2Desc;

  /// No description provided for @noteSlashTable3Label.
  ///
  /// In en, this message translates to:
  /// **'3×3 Table'**
  String get noteSlashTable3Label;

  /// No description provided for @noteSlashTable3Desc.
  ///
  /// In en, this message translates to:
  /// **'Quick 3-column table'**
  String get noteSlashTable3Desc;

  /// No description provided for @noteSlashPageBreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Page Break'**
  String get noteSlashPageBreakLabel;

  /// No description provided for @noteSlashPageBreakDesc.
  ///
  /// In en, this message translates to:
  /// **'Start a new page'**
  String get noteSlashPageBreakDesc;

  /// No description provided for @noteSlashInsertHint.
  ///
  /// In en, this message translates to:
  /// **'Type / to insert a block'**
  String get noteSlashInsertHint;

  /// No description provided for @notePageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String notePageNumber(Object number);

  /// No description provided for @noteTableThemeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get noteTableThemeClassic;

  /// No description provided for @noteTableThemeOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get noteTableThemeOcean;

  /// No description provided for @noteTableThemeForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get noteTableThemeForest;

  /// No description provided for @noteTableThemeRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get noteTableThemeRose;

  /// No description provided for @noteTableThemeSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get noteTableThemeSunset;

  /// No description provided for @noteTableThemeMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get noteTableThemeMidnight;

  /// No description provided for @noteTableThemeCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get noteTableThemeCoffee;

  /// No description provided for @noteTableThemeSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get noteTableThemeSlate;

  /// No description provided for @noteTableAlignLeft.
  ///
  /// In en, this message translates to:
  /// **'Align left'**
  String get noteTableAlignLeft;

  /// No description provided for @noteTableAlignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get noteTableAlignCenter;

  /// No description provided for @noteTableAlignFullWidth.
  ///
  /// In en, this message translates to:
  /// **'Full width'**
  String get noteTableAlignFullWidth;

  /// No description provided for @noteTableDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get noteTableDensityCompact;

  /// No description provided for @noteTableDensityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get noteTableDensityNormal;

  /// No description provided for @noteTableDensityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get noteTableDensityComfortable;

  /// No description provided for @noteTableHeaderRowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Header row'**
  String get noteTableHeaderRowTooltip;

  /// No description provided for @noteTableHeaderColTooltip.
  ///
  /// In en, this message translates to:
  /// **'Header column'**
  String get noteTableHeaderColTooltip;

  /// No description provided for @noteTableHeaderRowShort.
  ///
  /// In en, this message translates to:
  /// **'H.Row'**
  String get noteTableHeaderRowShort;

  /// No description provided for @noteTableHeaderColShort.
  ///
  /// In en, this message translates to:
  /// **'H.Col'**
  String get noteTableHeaderColShort;

  /// No description provided for @noteTableAddRow.
  ///
  /// In en, this message translates to:
  /// **'+Row'**
  String get noteTableAddRow;

  /// No description provided for @noteTableAddColumn.
  ///
  /// In en, this message translates to:
  /// **'+Col'**
  String get noteTableAddColumn;

  /// No description provided for @noteTableHeaderPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get noteTableHeaderPlaceholder;

  /// No description provided for @noteTableHeaderPlaceholderN.
  ///
  /// In en, this message translates to:
  /// **'Header {n}'**
  String noteTableHeaderPlaceholderN(Object n);

  /// No description provided for @noteTableCellPosition.
  ///
  /// In en, this message translates to:
  /// **'Row {row} · Col {col}'**
  String noteTableCellPosition(Object col, Object row);

  /// No description provided for @noteTableCellBackground.
  ///
  /// In en, this message translates to:
  /// **'CELL BACKGROUND'**
  String get noteTableCellBackground;

  /// No description provided for @noteTableChooseThemeSize.
  ///
  /// In en, this message translates to:
  /// **'Choose theme and size'**
  String get noteTableChooseThemeSize;

  /// No description provided for @noteTableSectionTheme.
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get noteTableSectionTheme;

  /// No description provided for @noteTableSectionSize.
  ///
  /// In en, this message translates to:
  /// **'SIZE'**
  String get noteTableSectionSize;

  /// No description provided for @noteTableSectionPreview.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get noteTableSectionPreview;

  /// No description provided for @noteTableRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get noteTableRowLabel;

  /// No description provided for @noteTableColLabel.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get noteTableColLabel;

  /// No description provided for @notifPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notifPrefsTitle;

  /// No description provided for @notifPrefsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage which notifications you receive'**
  String get notifPrefsSubtitle;

  /// No description provided for @notifPrefsSectionGeneralMaster.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notifPrefsSectionGeneralMaster;

  /// No description provided for @notifPrefsAllOn.
  ///
  /// In en, this message translates to:
  /// **'All on'**
  String get notifPrefsAllOn;

  /// No description provided for @notifPrefsAllOff.
  ///
  /// In en, this message translates to:
  /// **'All off'**
  String get notifPrefsAllOff;

  /// No description provided for @accountNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get accountNotificationSettings;

  /// No description provided for @accountNotificationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage push, email and per-module alerts'**
  String get accountNotificationSettingsSubtitle;

  /// No description provided for @notifPrefsSectionTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get notifPrefsSectionTasks;

  /// No description provided for @notifPrefsTaskDeadline.
  ///
  /// In en, this message translates to:
  /// **'Task deadline'**
  String get notifPrefsTaskDeadline;

  /// No description provided for @notifPrefsTaskDeadlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind when a due date is approaching'**
  String get notifPrefsTaskDeadlineDesc;

  /// No description provided for @notifPrefsTaskOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue tasks'**
  String get notifPrefsTaskOverdue;

  /// No description provided for @notifPrefsTaskOverdueDesc.
  ///
  /// In en, this message translates to:
  /// **'Tasks past their due date'**
  String get notifPrefsTaskOverdueDesc;

  /// No description provided for @notifPrefsSectionHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get notifPrefsSectionHabits;

  /// No description provided for @notifPrefsHabitStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak at risk'**
  String get notifPrefsHabitStreak;

  /// No description provided for @notifPrefsHabitStreakDesc.
  ///
  /// In en, this message translates to:
  /// **'Evening alert at 8 PM for habits not completed today'**
  String get notifPrefsHabitStreakDesc;

  /// No description provided for @notifPrefsHabitMilestone.
  ///
  /// In en, this message translates to:
  /// **'Streak celebration'**
  String get notifPrefsHabitMilestone;

  /// No description provided for @notifPrefsHabitMilestoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Celebrate 7, 30, and 100-day streaks'**
  String get notifPrefsHabitMilestoneDesc;

  /// No description provided for @notifPrefsSectionMeds.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get notifPrefsSectionMeds;

  /// No description provided for @notifPrefsMedDose.
  ///
  /// In en, this message translates to:
  /// **'Dose time'**
  String get notifPrefsMedDose;

  /// No description provided for @notifPrefsMedDoseDesc.
  ///
  /// In en, this message translates to:
  /// **'Notify at medication time'**
  String get notifPrefsMedDoseDesc;

  /// No description provided for @notifPrefsMedMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed dose'**
  String get notifPrefsMedMissed;

  /// No description provided for @notifPrefsMedMissedDesc.
  ///
  /// In en, this message translates to:
  /// **'Alert for doses not taken'**
  String get notifPrefsMedMissedDesc;

  /// No description provided for @notifPrefsMedRefill.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get notifPrefsMedRefill;

  /// No description provided for @notifPrefsMedRefillDesc.
  ///
  /// In en, this message translates to:
  /// **'Medication refill reminder'**
  String get notifPrefsMedRefillDesc;

  /// No description provided for @notifPrefsSectionAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get notifPrefsSectionAppointments;

  /// No description provided for @notifPrefsApptReminder.
  ///
  /// In en, this message translates to:
  /// **'Appointment reminder'**
  String get notifPrefsApptReminder;

  /// No description provided for @notifPrefsApptReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind before appointments'**
  String get notifPrefsApptReminderDesc;

  /// No description provided for @notifPrefsApptStatus.
  ///
  /// In en, this message translates to:
  /// **'Status changes'**
  String get notifPrefsApptStatus;

  /// No description provided for @notifPrefsApptStatusDesc.
  ///
  /// In en, this message translates to:
  /// **'Confirmations, cancellations, and updates'**
  String get notifPrefsApptStatusDesc;

  /// No description provided for @notifPrefsSectionFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get notifPrefsSectionFocus;

  /// No description provided for @notifPrefsFocusBreak.
  ///
  /// In en, this message translates to:
  /// **'Break ended'**
  String get notifPrefsFocusBreak;

  /// No description provided for @notifPrefsFocusBreakDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind when a break timer ends'**
  String get notifPrefsFocusBreakDesc;

  /// No description provided for @notifPrefsSectionBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get notifPrefsSectionBudget;

  /// No description provided for @notifPrefsBudgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit alert'**
  String get notifPrefsBudgetLimit;

  /// No description provided for @notifPrefsBudgetLimitDesc.
  ///
  /// In en, this message translates to:
  /// **'When a budget limit is exceeded'**
  String get notifPrefsBudgetLimitDesc;

  /// No description provided for @notifPrefsBudgetGoal.
  ///
  /// In en, this message translates to:
  /// **'Savings goal'**
  String get notifPrefsBudgetGoal;

  /// No description provided for @notifPrefsBudgetGoalDesc.
  ///
  /// In en, this message translates to:
  /// **'Celebrate when a goal is reached'**
  String get notifPrefsBudgetGoalDesc;

  /// No description provided for @notifPrefsBudgetInsight.
  ///
  /// In en, this message translates to:
  /// **'Budget insights'**
  String get notifPrefsBudgetInsight;

  /// No description provided for @notifPrefsBudgetInsightDesc.
  ///
  /// In en, this message translates to:
  /// **'Weekly spending analysis (off by default)'**
  String get notifPrefsBudgetInsightDesc;

  /// No description provided for @notifPrefsSectionTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get notifPrefsSectionTeams;

  /// No description provided for @notifPrefsTeamAssign.
  ///
  /// In en, this message translates to:
  /// **'Task assignment'**
  String get notifPrefsTeamAssign;

  /// No description provided for @notifPrefsTeamAssignDesc.
  ///
  /// In en, this message translates to:
  /// **'When a task is assigned to you'**
  String get notifPrefsTeamAssignDesc;

  /// No description provided for @notifPrefsTeamAnnounce.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get notifPrefsTeamAnnounce;

  /// No description provided for @notifPrefsTeamAnnounceDesc.
  ///
  /// In en, this message translates to:
  /// **'Team announcements'**
  String get notifPrefsTeamAnnounceDesc;

  /// No description provided for @notifPrefsTeamDeadline.
  ///
  /// In en, this message translates to:
  /// **'Team deadlines'**
  String get notifPrefsTeamDeadline;

  /// No description provided for @notifPrefsTeamDeadlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Due dates for team tasks'**
  String get notifPrefsTeamDeadlineDesc;

  /// No description provided for @notifPrefsSectionXp.
  ///
  /// In en, this message translates to:
  /// **'XP & Level'**
  String get notifPrefsSectionXp;

  /// No description provided for @notifPrefsLevelUp.
  ///
  /// In en, this message translates to:
  /// **'Level up'**
  String get notifPrefsLevelUp;

  /// No description provided for @notifPrefsLevelUpDesc.
  ///
  /// In en, this message translates to:
  /// **'Celebrate reaching a new level'**
  String get notifPrefsLevelUpDesc;

  /// No description provided for @notifPrefsMilestones.
  ///
  /// In en, this message translates to:
  /// **'Special celebrations'**
  String get notifPrefsMilestones;

  /// No description provided for @notifPrefsMilestonesDesc.
  ///
  /// In en, this message translates to:
  /// **'Birthdays, app anniversaries, and more'**
  String get notifPrefsMilestonesDesc;

  /// No description provided for @notifPrefsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notifPrefsSectionGeneral;

  /// No description provided for @notifPrefsMorningBrief.
  ///
  /// In en, this message translates to:
  /// **'Morning brief'**
  String get notifPrefsMorningBrief;

  /// No description provided for @notifPrefsMorningBriefDesc.
  ///
  /// In en, this message translates to:
  /// **'Start the day with pending task count (9:00 AM)'**
  String get notifPrefsMorningBriefDesc;

  /// No description provided for @notifPrefsWeeklyDigest.
  ///
  /// In en, this message translates to:
  /// **'Weekly digest'**
  String get notifPrefsWeeklyDigest;

  /// No description provided for @notifPrefsWeeklyDigestDesc.
  ///
  /// In en, this message translates to:
  /// **'Sunday morning performance report (10:00 AM)'**
  String get notifPrefsWeeklyDigestDesc;

  /// No description provided for @accountBannedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get accountBannedTitle;

  /// No description provided for @accountBannedReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason:'**
  String get accountBannedReasonLabel;

  /// No description provided for @accountBannedDefaultReason.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended due to a policy violation.'**
  String get accountBannedDefaultReason;

  /// No description provided for @accountBannedSupportMessage.
  ///
  /// In en, this message translates to:
  /// **'If you believe this suspension is a mistake, please contact our support team.'**
  String get accountBannedSupportMessage;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'The system is under maintenance. Please try again later.'**
  String get maintenanceDefaultMessage;

  /// No description provided for @surveyDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Survey'**
  String get surveyDefaultTitle;

  /// No description provided for @surveyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Survey not found or has ended.'**
  String get surveyNotFound;

  /// No description provided for @surveyAlreadyResponded.
  ///
  /// In en, this message translates to:
  /// **'You have already completed this survey.'**
  String get surveyAlreadyResponded;

  /// No description provided for @surveyAnswerAll.
  ///
  /// In en, this message translates to:
  /// **'Please answer all questions: {question}'**
  String surveyAnswerAll(Object question);

  /// No description provided for @surveySubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit: {error}'**
  String surveySubmitFailed(Object error);

  /// No description provided for @surveySubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get surveySubmitting;

  /// No description provided for @surveySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get surveySubmit;

  /// No description provided for @surveyAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get surveyAnswerHint;

  /// No description provided for @broadcastDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get broadcastDefaultTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications about tasks, medications, and other activity will appear here.'**
  String get notificationsEmptyDesc;

  /// No description provided for @notificationsTimeNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get notificationsTimeNow;

  /// No description provided for @notificationsTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String notificationsTimeMinutes(Object n);

  /// No description provided for @notificationsTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String notificationsTimeHours(Object n);

  /// No description provided for @notificationsTimeDays.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String notificationsTimeDays(Object n);

  /// No description provided for @notePermissionSelectMembers.
  ///
  /// In en, this message translates to:
  /// **'Select members'**
  String get notePermissionSelectMembers;

  /// No description provided for @landingTrustFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get landingTrustFast;

  /// No description provided for @landingTrustSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get landingTrustSecure;

  /// No description provided for @landingTrustSync.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get landingTrustSync;

  /// No description provided for @landingTrustPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get landingTrustPremium;

  /// No description provided for @landingMockWeeklyView.
  ///
  /// In en, this message translates to:
  /// **'Weekly view'**
  String get landingMockWeeklyView;

  /// No description provided for @landingMockTasksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks'**
  String landingMockTasksCount(Object count);

  /// No description provided for @landingMockAppointmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} appointments'**
  String landingMockAppointmentsCount(Object count);

  /// No description provided for @landingMockNotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} notes'**
  String landingMockNotesCount(Object count);

  /// No description provided for @landingMockTaskPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get landingMockTaskPlan;

  /// No description provided for @landingMockTaskSport.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get landingMockTaskSport;

  /// No description provided for @landingMockTaskPresentation.
  ///
  /// In en, this message translates to:
  /// **'Presentation'**
  String get landingMockTaskPresentation;

  /// No description provided for @landingMockAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get landingMockAppointment;

  /// No description provided for @landingMockNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get landingMockNoteTitle;

  /// No description provided for @landingMockNoteContent.
  ///
  /// In en, this message translates to:
  /// **'Notes for new features'**
  String get landingMockNoteContent;

  /// No description provided for @landingMockTeamBoard.
  ///
  /// In en, this message translates to:
  /// **'Team board'**
  String get landingMockTeamBoard;

  /// No description provided for @landingMockOverallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall progress'**
  String get landingMockOverallProgress;

  /// No description provided for @landingMockMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get landingMockMembers;

  /// No description provided for @landingMockProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get landingMockProjects;

  /// No description provided for @landingMockWeeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly activity'**
  String get landingMockWeeklyActivity;

  /// No description provided for @landingMockBudgetSummary.
  ///
  /// In en, this message translates to:
  /// **'Budget summary'**
  String get landingMockBudgetSummary;

  /// No description provided for @landingMockAvailableBudget.
  ///
  /// In en, this message translates to:
  /// **'Available budget'**
  String get landingMockAvailableBudget;

  /// No description provided for @landingMockIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get landingMockIncome;

  /// No description provided for @landingMockExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get landingMockExpense;

  /// No description provided for @landingMockCategoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get landingMockCategoryGroceries;

  /// No description provided for @landingMockCategoryTech.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get landingMockCategoryTech;

  /// No description provided for @landingMockCategoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get landingMockCategoryEntertainment;

  /// No description provided for @landingMockNovaSender.
  ///
  /// In en, this message translates to:
  /// **'Nova'**
  String get landingMockNovaSender;

  /// No description provided for @landingMockYouSender.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get landingMockYouSender;

  /// No description provided for @landingMockNovaMessage.
  ///
  /// In en, this message translates to:
  /// **'Your calendar looks busy next week. Would you like to review the summary I prepared for Monday morning?'**
  String get landingMockNovaMessage;

  /// No description provided for @landingMockYouMessage.
  ///
  /// In en, this message translates to:
  /// **'Yes please — especially highlight any meeting conflicts.'**
  String get landingMockYouMessage;

  /// No description provided for @landingMockProductivityInsight.
  ///
  /// In en, this message translates to:
  /// **'Productivity insight: You\'re up 15% compared to yesterday!'**
  String get landingMockProductivityInsight;

  /// No description provided for @budgetDeleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get budgetDeleteGoalTitle;

  /// No description provided for @budgetDeleteGoalMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete the goal \"{title}\"?'**
  String budgetDeleteGoalMessage(Object title);

  /// No description provided for @statsPeriodDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get statsPeriodDaily;

  /// No description provided for @statsPeriodQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get statsPeriodQuarter;

  /// No description provided for @statsPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsPeriodToday;

  /// No description provided for @statsPeriod7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get statsPeriod7Days;

  /// No description provided for @statsPeriod30Days.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get statsPeriod30Days;

  /// No description provided for @statsPeriod90Days.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get statsPeriod90Days;

  /// No description provided for @statsPeriodSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{period} summary · {count} actions'**
  String statsPeriodSummarySubtitle(Object count, Object period);

  /// No description provided for @statsAllModulesPeriod.
  ///
  /// In en, this message translates to:
  /// **'All modules · {period} period'**
  String statsAllModulesPeriod(Object period);

  /// No description provided for @statsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statsCompleted;

  /// No description provided for @statsPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statsPendingLabel;

  /// No description provided for @statsOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statsOverdue;

  /// No description provided for @statsCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get statsCompletionRate;

  /// No description provided for @statsStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get statsStreak;

  /// No description provided for @statsFocusDuration.
  ///
  /// In en, this message translates to:
  /// **'Focus time'**
  String get statsFocusDuration;

  /// No description provided for @statsProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get statsProductivity;

  /// No description provided for @statsCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get statsCreatedLabel;

  /// No description provided for @statsPostponed.
  ///
  /// In en, this message translates to:
  /// **'Postponed'**
  String get statsPostponed;

  /// No description provided for @statsAvgDuration.
  ///
  /// In en, this message translates to:
  /// **'Avg. duration'**
  String get statsAvgDuration;

  /// No description provided for @statsBusiestDay.
  ///
  /// In en, this message translates to:
  /// **'Busiest day'**
  String get statsBusiestDay;

  /// No description provided for @statsPeakHour.
  ///
  /// In en, this message translates to:
  /// **'Peak hour'**
  String get statsPeakHour;

  /// No description provided for @statsWithSubtasks.
  ///
  /// In en, this message translates to:
  /// **'With subtasks'**
  String get statsWithSubtasks;

  /// No description provided for @statsRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get statsRecurring;

  /// No description provided for @statsPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get statsPriorityHigh;

  /// No description provided for @statsPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get statsPriorityMedium;

  /// No description provided for @statsPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get statsPriorityLow;

  /// No description provided for @statsMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String statsMinutesShort(Object n);

  /// No description provided for @statsHoursMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String statsHoursMinutesShort(Object hours, Object minutes);

  /// No description provided for @statsDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String statsDaysUnit(Object n);

  /// No description provided for @statsWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get statsWeekdayMon;

  /// No description provided for @statsWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get statsWeekdayTue;

  /// No description provided for @statsWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get statsWeekdayWed;

  /// No description provided for @statsWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get statsWeekdayThu;

  /// No description provided for @statsWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get statsWeekdayFri;

  /// No description provided for @statsWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get statsWeekdaySat;

  /// No description provided for @statsWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get statsWeekdaySun;

  /// No description provided for @statsTotalHabits.
  ///
  /// In en, this message translates to:
  /// **'Total habits'**
  String get statsTotalHabits;

  /// No description provided for @statsCompletedInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Completed in period'**
  String get statsCompletedInPeriod;

  /// No description provided for @statsPeriodAdherence.
  ///
  /// In en, this message translates to:
  /// **'Period adherence'**
  String get statsPeriodAdherence;

  /// No description provided for @statsLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get statsLongestStreak;

  /// No description provided for @statsActiveToday.
  ///
  /// In en, this message translates to:
  /// **'Active today'**
  String get statsActiveToday;

  /// No description provided for @statsMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get statsMissing;

  /// No description provided for @statsIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get statsIncomeLabel;

  /// No description provided for @statsExpenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get statsExpenseLabel;

  /// No description provided for @statsNetLabel.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get statsNetLabel;

  /// No description provided for @statsTxnCount.
  ///
  /// In en, this message translates to:
  /// **'Transaction count'**
  String get statsTxnCount;

  /// No description provided for @statsIncomeTxn.
  ///
  /// In en, this message translates to:
  /// **'Income transactions'**
  String get statsIncomeTxn;

  /// No description provided for @statsExpenseTxn.
  ///
  /// In en, this message translates to:
  /// **'Expense transactions'**
  String get statsExpenseTxn;

  /// No description provided for @statsTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get statsTotalBalance;

  /// No description provided for @statsAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get statsAccountLabel;

  /// No description provided for @statsTopSpending.
  ///
  /// In en, this message translates to:
  /// **'Top spending'**
  String get statsTopSpending;

  /// No description provided for @statsCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get statsCategoryGeneral;

  /// No description provided for @statsNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statsNewLabel;

  /// No description provided for @statsUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get statsUpdatedLabel;

  /// No description provided for @statsFavoriteLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get statsFavoriteLabel;

  /// No description provided for @statsPinnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get statsPinnedLabel;

  /// No description provided for @statsArchivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statsArchivedLabel;

  /// No description provided for @statsTaskLinked.
  ///
  /// In en, this message translates to:
  /// **'Task linked'**
  String get statsTaskLinked;

  /// No description provided for @statsTeamNote.
  ///
  /// In en, this message translates to:
  /// **'Team note'**
  String get statsTeamNote;

  /// No description provided for @statsScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statsScheduled;

  /// No description provided for @statsCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statsCancelled;

  /// No description provided for @statsActiveMeds.
  ///
  /// In en, this message translates to:
  /// **'Active medications'**
  String get statsActiveMeds;

  /// No description provided for @statsDosesScheduled.
  ///
  /// In en, this message translates to:
  /// **'Doses scheduled'**
  String get statsDosesScheduled;

  /// No description provided for @statsDosesTaken.
  ///
  /// In en, this message translates to:
  /// **'Doses taken'**
  String get statsDosesTaken;

  /// No description provided for @statsAdherence.
  ///
  /// In en, this message translates to:
  /// **'Adherence'**
  String get statsAdherence;

  /// No description provided for @statsLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get statsLowStock;

  /// No description provided for @statsSufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Sufficient stock'**
  String get statsSufficientStock;

  /// No description provided for @statsTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get statsTaken;

  /// No description provided for @statsMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get statsMissed;

  /// No description provided for @statsInLibrary.
  ///
  /// In en, this message translates to:
  /// **'In library'**
  String get statsInLibrary;

  /// No description provided for @statsFinishedInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Finished in period'**
  String get statsFinishedInPeriod;

  /// No description provided for @statsStartedInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Started in period'**
  String get statsStartedInPeriod;

  /// No description provided for @statsPagesRead.
  ///
  /// In en, this message translates to:
  /// **'Pages read'**
  String get statsPagesRead;

  /// No description provided for @statsAvgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg. rating'**
  String get statsAvgRating;

  /// No description provided for @statsTeamCount.
  ///
  /// In en, this message translates to:
  /// **'Team count'**
  String get statsTeamCount;

  /// No description provided for @statsTotalMembers.
  ///
  /// In en, this message translates to:
  /// **'Total members'**
  String get statsTotalMembers;

  /// No description provided for @statsOwnedTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams you manage'**
  String get statsOwnedTeams;

  /// No description provided for @statsTotalCards.
  ///
  /// In en, this message translates to:
  /// **'Total cards'**
  String get statsTotalCards;

  /// No description provided for @statsConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get statsConnections;

  /// No description provided for @statsAddedInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Added in period'**
  String get statsAddedInPeriod;

  /// No description provided for @statsCardsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get statsCardsLabel;

  /// No description provided for @statsLinksLabel.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get statsLinksLabel;

  /// No description provided for @statsModuleTaskHint.
  ///
  /// In en, this message translates to:
  /// **'Completion + streak + volume'**
  String get statsModuleTaskHint;

  /// No description provided for @statsModuleHabitHint.
  ///
  /// In en, this message translates to:
  /// **'Daily adherence rate'**
  String get statsModuleHabitHint;

  /// No description provided for @statsNetPositive.
  ///
  /// In en, this message translates to:
  /// **'Net positive'**
  String get statsNetPositive;

  /// No description provided for @statsNetNegative.
  ///
  /// In en, this message translates to:
  /// **'Net negative'**
  String get statsNetNegative;

  /// No description provided for @statsModuleNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Created in period'**
  String get statsModuleNotesHint;

  /// No description provided for @statsModuleApptHint.
  ///
  /// In en, this message translates to:
  /// **'Completed / scheduled'**
  String get statsModuleApptHint;

  /// No description provided for @statsModuleMedHint.
  ///
  /// In en, this message translates to:
  /// **'Dose adherence'**
  String get statsModuleMedHint;

  /// No description provided for @statsModuleBookHint.
  ///
  /// In en, this message translates to:
  /// **'Finished / library'**
  String get statsModuleBookHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'it',
        'ja',
        'pt',
        'ru',
        'tr',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
