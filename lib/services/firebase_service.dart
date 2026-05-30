import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../models/team_model.dart';
import '../models/activity_log_model.dart';
import '../models/appointment_model.dart';
import '../models/appointment_group_model.dart';
import '../models/project_model.dart';
import '../models/notebook_model.dart';
import '../models/note_comment_model.dart';
import '../models/note_history_model.dart';
import '../models/medication_model.dart';
import '../models/app_notification_model.dart';
import 'base_firebase_service.dart';
import 'auth_service.dart';
import 'task_service.dart';
import 'note_service.dart';
import 'team_service.dart';
import 'team_join_result.dart';
import 'habit_service.dart';
import 'medication_service.dart';
import 'appointment_service.dart';
import 'notification_service.dart';
import 'dev_data_service.dart';
import 'budget_service.dart';
import 'corkboard_service.dart';
import '../screens/calendar/calendar_controller.dart';

/// App-wide Firebase facade. Budget, corkboard, books, and Nova use their
/// singleton services directly when only one domain is needed.
class FirebaseService extends BaseFirebaseService implements CalendarStreams {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _authService = AuthService();
  final _taskService = TaskService();
  final _noteService = NoteService();
  final _teamService = TeamService();
  final _habitService = HabitService();
  final _medicationService = MedicationService();
  final _appointmentService = AppointmentService();
  final _notifService = NotificationService();
  final _devService = DevDataService();
  final _budgetService = BudgetService();
  final _corkboardService = CorkboardService();

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String surname,
    required DateTime birthDate,
  }) =>
      _authService.signUp(
        email: email,
        password: password,
        name: name,
        surname: surname,
        birthDate: birthDate,
      );

  Future<UserCredential> signIn(String email, String password) =>
      _authService.signIn(email, password);

  Future<UserCredential?> signInWithGoogle() => _authService.signInWithGoogle();

  Future<UserCredential?> signInWithApple() => _authService.signInWithApple();

  Future<void> signOut() => _authService.signOut();

  Future<void> sendPasswordResetEmail(String email) =>
      _authService.sendPasswordResetEmail(email);

  Stream<DocumentSnapshot> getUserDataStream() =>
      _authService.getUserDataStream();

  Future<DocumentSnapshot> getUserDoc(String uid) =>
      _authService.getUserDoc(uid);

  Future<void> updateUserName(String name, String surname) =>
      _authService.updateUserName(name, surname);

  Future<void> updateAvatar(String avatarSeed) =>
      _authService.updateAvatar(avatarSeed);

  Future<List<Map<String, dynamic>>> getUsersByIds(
    List<String> userIds, {
    String? teamId,
  }) =>
      _authService.getUsersByIds(userIds, teamId: teamId);

  // ─── Tasks ────────────────────────────────────────────────────────────────

  Future<String?> addTask(Task task) => _taskService.addTask(task);
  Future<void> addRecurringTaskInstances(List<Task> instances) =>
      _taskService.addRecurringTaskInstances(instances);
  Future<void> setTaskCompleted(String taskId, bool isCompleted) =>
      _taskService.setTaskCompleted(taskId, isCompleted);

  Future<String?> resolveTeamIdForTaskScope({
    String? teamId,
    String? groupId,
  }) =>
      _taskService.resolveTeamIdForScope(teamId: teamId, groupId: groupId);

  Stream<Task?> getTaskStream(String taskId) =>
      _taskService.getTaskStream(taskId);

  Future<List<Task>> getTasksForStats() => _taskService.getTasksForStats();

  Stream<List<Task>> getAllUserTasksStream() =>
      _taskService.getAllUserTasksStream();

  Stream<List<Task>> getCalendarRelevantTasksStream() =>
      _taskService.getCalendarRelevantTasksStream();

  @override
  Stream<List<Task>> getTasksStreamForDateRange(DateTime start, DateTime end) =>
      _taskService.getTasksStreamForDateRange(start, end);

  @override
  Stream<List<Task>> getCalendarTasksStream(DateTime start, DateTime end) =>
      _taskService.getCalendarTasksStream(start, end);

  Stream<List<Task>> getTasksForDateRange(DateTime start, DateTime end) =>
      _taskService.getTasksForDateRange(start, end);

  Future<void> updateTask(Task task) => _taskService.updateTask(task);

  Future<void> updateTaskStatus(String taskId, String status) =>
      _taskService.updateTaskStatus(taskId, status);

  Future<void> deleteTask(String taskId) => _taskService.deleteTask(taskId);

  Stream<List<Task>> getTeamTasksStream(String teamId) =>
      _taskService.getTeamTasksStream(teamId);

  Stream<List<Task>> getProjectTasksStream(String teamId, String projectId) =>
      _taskService.getProjectTasksStream(teamId, projectId);

  Future<void> backfillProjectTaskTeamIds(String teamId) =>
      _teamService.backfillProjectTaskTeamIds(teamId);

  // ─── Notes ────────────────────────────────────────────────────────────────

  Future<String?> addNote(Note note) => _noteService.addNote(note);

  Future<String?> duplicateNote(Note note) => _noteService.duplicateNote(note);

  @override
  Stream<List<Note>> getNotesStream() => _noteService.getNotesStream();

  Stream<List<Note>> getTeamNotesStream(String teamId) =>
      _noteService.getTeamNotesStream(teamId);

  Future<void> updateNote(Note note) => _noteService.updateNote(note);

  Future<void> deleteNote(String noteId) => _noteService.deleteNote(noteId);

  Future<void> archiveNote(String noteId) => _noteService.archiveNote(noteId);

  Future<void> unarchiveNote(String noteId) =>
      _noteService.unarchiveNote(noteId);

  Future<void> toggleNoteFavorite(String noteId, bool isFavorite) =>
      _noteService.toggleNoteFavorite(noteId, isFavorite);

  Future<void> toggleNoteLock(String noteId, bool isLocked) =>
      _noteService.toggleNoteLock(noteId, isLocked);

  Future<void> moveToTrash(String noteId) => _noteService.moveToTrash(noteId);

  Future<void> restoreNote(String noteId) => _noteService.restoreNote(noteId);

  Stream<List<Note>> getTrashStream() => _noteService.getTrashStream();

  Future<void> updateNotePermissions(
    String noteId, {
    required String viewPermission,
    required String editPermission,
    List<String>? allowedUserIds,
  }) =>
      _noteService.updateNotePermissions(
        noteId,
        viewPermission: viewPermission,
        editPermission: editPermission,
        allowedUserIds: allowedUserIds,
      );

  Stream<List<Note>> getArchivedNotesStream() =>
      _noteService.getArchivedNotesStream();

  Stream<List<Note>> getProjectNotesStream(String projectId) =>
      _noteService.getProjectNotesStream(projectId);

  Future<void> linkTaskToNote(String noteId, String taskId) =>
      _noteService.linkTaskToNote(noteId, taskId);

  Future<void> unlinkTaskFromNote(String noteId, String taskId) =>
      _noteService.unlinkTaskFromNote(noteId, taskId);

  Future<void> addNoteComment(String noteId, NoteComment comment) =>
      _noteService.addNoteComment(noteId, comment);

  Stream<List<NoteComment>> getNoteCommentsStream(String noteId) =>
      _noteService.getNoteCommentsStream(noteId);

  Future<void> saveNoteVersion(String noteId, NoteHistory history) =>
      _noteService.saveNoteVersion(noteId, history);

  Stream<List<NoteHistory>> getNoteHistoryStream(String noteId) =>
      _noteService.getNoteHistoryStream(noteId);

  Future<void> addNotebook(Notebook notebook) =>
      _noteService.addNotebook(notebook);

  Stream<List<Notebook>> getNotebooksStream() =>
      _noteService.getNotebooksStream();

  Future<void> updateNotebook(Notebook notebook) =>
      _noteService.updateNotebook(notebook);

  Future<void> deleteNotebook(String notebookId) =>
      _noteService.deleteNotebook(notebookId);

  Stream<List<Note>> getNotesByNotebookStream(String notebookId) =>
      _noteService.getNotesByNotebookStream(notebookId);

  // ─── Teams ────────────────────────────────────────────────────────────────

  Future<String> createTeam(String teamName, {int color = 0xFF6366F1}) =>
      _teamService.createTeam(teamName, color: color);

  Future<JoinTeamResult> joinTeam(String code) => _teamService.joinTeam(code);

  Stream<List<Team>> getUserTeamsStream() => _teamService.getUserTeamsStream();

  Future<void> addTeamLink(String teamId, String title, String url,
          {String? description, int? color,}) =>
      _teamService.addTeamLink(teamId, title, url,
          description: description, color: color,);

  Future<void> updateTeamResource(
          String teamId, String resourceId, Map<String, dynamic> updates,) =>
      _teamService.updateTeamResource(teamId, resourceId, updates);

  Stream<QuerySnapshot> getTeamResources(String teamId) =>
      _teamService.getTeamResources(teamId);

  Future<void> deleteTeamResource(String teamId, String resourceId) =>
      _teamService.deleteTeamResource(teamId, resourceId);

  Future<void> updateTeamAnnouncement(String teamId, String message) =>
      _teamService.updateTeamAnnouncement(teamId, message);

  Future<void> updateTeam(Team team) => _teamService.updateTeam(team);

  Future<void> leaveTeam(String teamId) => _teamService.leaveTeam(teamId);

  Future<void> deleteTeam(String teamId) => _teamService.deleteTeam(teamId);

  Future<void> kickMember(String teamId, String memberId) =>
      _teamService.kickMember(teamId, memberId);

  Future<void> promoteToAdmin(String teamId, String memberId) =>
      _teamService.promoteToAdmin(teamId, memberId);

  Future<void> demoteFromAdmin(String teamId, String memberId) =>
      _teamService.demoteFromAdmin(teamId, memberId);

  Stream<List<ActivityLog>> getTeamActivityLogs(String teamId) =>
      _teamService.getTeamActivityLogs(teamId);

  Future<String> createProject(String teamId, Project project) =>
      _teamService.createProject(teamId, project);

  Stream<List<Project>> getProjectsStream(String teamId) =>
      _teamService.getProjectsStream(teamId);

  Stream<Project> getProjectStream(String teamId, String projectId) =>
      _teamService.getProjectStream(teamId, projectId);

  Future<void> addProjectResource(
          String teamId, String projectId, String title, String url,
          {String? description, int? color,}) =>
      _teamService.addProjectResource(teamId, projectId, title, url,
          description: description, color: color,);

  Future<void> updateProjectResource(String teamId, String projectId,
          String resourceId, Map<String, dynamic> updates,) =>
      _teamService.updateProjectResource(
          teamId, projectId, resourceId, updates,);

  Stream<QuerySnapshot> getProjectResources(String teamId, String projectId) =>
      _teamService.getProjectResources(teamId, projectId);

  Future<void> deleteProjectResource(
          String teamId, String projectId, String resourceId,) =>
      _teamService.deleteProjectResource(teamId, projectId, resourceId);

  Future<void> updateProject(
          String teamId, String projectId, Map<String, dynamic> data,) =>
      _teamService.updateProject(teamId, projectId, data);

  Future<void> deleteProject(String teamId, String projectId) =>
      _teamService.deleteProject(teamId, projectId);

  // ─── Habits ────────────────────────────────────────────────────────────────

  @override
  Stream<QuerySnapshot> getHabitsStream() => _habitService.getHabitsStream();
  Future<String?> addHabit(String title) => _habitService.addHabit(title);
  Future<void> toggleHabit(String habitId, bool isCompleted) =>
      _habitService.toggleHabit(habitId, isCompleted);
  Future<void> deleteHabit(String habitId) =>
      _habitService.deleteHabit(habitId);

  // ─── Appointments ──────────────────────────────────────────────────────────

  Future<String> createAppointmentGroup(AppointmentGroup group) =>
      _appointmentService.createService(group);
  Future<void> updateAppointmentGroup(AppointmentGroup group) =>
      _appointmentService.updateService(group);
  Future<void> deleteAppointmentGroup(String groupId) =>
      _appointmentService.deleteService(groupId);
  Stream<List<AppointmentGroup>> getMyAppointmentGroups() =>
      _appointmentService.getMyServicesStream();
  Future<AppointmentGroup?> getGroupById(String groupId) =>
      _appointmentService.getServiceById(groupId);
  Stream<List<Appointment>> getAppointmentsStream() =>
      _appointmentService.getAppointmentsStream();
  Stream<List<Appointment>> getMyAppointmentsAsClientStream() =>
      _appointmentService.getMyAppointmentsAsClientStream();
  @override
  Stream<List<Appointment>> getAppointmentsStreamForDateRange(
          DateTime start, DateTime end,) =>
      _appointmentService.getAppointmentsForDateRange(start, end);
  @override
  Stream<List<Appointment>> getMyAppointmentsAsClientStreamForDateRange(
          DateTime start, DateTime end,) =>
      _appointmentService.getMyAppointmentsAsClientStreamForDateRange(
          start, end,);
  Future<AppointmentGroup?> getGroupByCode(String code) =>
      _appointmentService.getServiceByCode(code);
  Future<List<DateTime>> getAvailableSlots(
          AppointmentGroup group, DateTime date,) =>
      _appointmentService.getAvailableSlots(group, date);
  Future<String> addAppointment(Appointment appt) =>
      _appointmentService.addAppointment(appt);
  Future<void> updateAppointment(Appointment appt) =>
      _appointmentService.updateAppointment(appt);
  Future<void> deleteAppointment(String id) =>
      _appointmentService.deleteAppointment(id);

  // ─── Medications ───────────────────────────────────────────────────────────

  Future<void> addMedication(Medication med) =>
      _medicationService.addMedication(med);
  Future<void> updateMedication(Medication med) =>
      _medicationService.updateMedication(med);
  Future<void> deleteMedication(String medId) =>
      _medicationService.deleteMedication(medId);
  @override
  Stream<List<Medication>> getMedicationsStream() =>
      _medicationService.getMedicationsStream();
  Future<Medication?> getMedicationById(String medId) =>
      _medicationService.getMedicationById(medId);
  Future<void> markMedicationTaken(String medId, String dateKey, String time) =>
      _medicationService.markMedicationTaken(medId, dateKey, time);
  Future<void> unmarkMedicationTaken(
          String medId, String dateKey, String time,) =>
      _medicationService.unmarkMedicationTaken(medId, dateKey, time);

  // ─── App Notifications ─────────────────────────────────────────────────────

  Future<void> addAppNotification(AppNotification notif) =>
      _notifService.addAppNotification(notif);
  Stream<List<AppNotification>> getNotificationsStream() =>
      _notifService.getNotificationsStream();
  Stream<int> getUnreadNotificationCount() =>
      _notifService.getUnreadNotificationCount();
  Future<void> markNotificationRead(String notifId) =>
      _notifService.markNotificationRead(notifId);
  Future<void> markAllNotificationsRead() =>
      _notifService.markAllNotificationsRead();
  Future<void> deleteOldNotifications({int daysOld = 30}) =>
      _notifService.deleteOldNotifications(daysOld: daysOld);

  // ─── Medicine Search ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchMedicines(String query) =>
      _medicationService.searchMedicines(query);

  // ─── Budget (facade) ───────────────────────────────────────────────────────

  BudgetService get budget => _budgetService;

  // ─── Corkboard (facade) ────────────────────────────────────────────────────

  CorkboardService get corkboard => _corkboardService;

  // ─── Dev Tools ─────────────────────────────────────────────────────────────

  Future<void> deleteAllData() => _devService.deleteAllData();

  Future<void> generateFullTestEnvironment({Function(double)? onProgress}) =>
      _devService.generateFullTestEnvironment(onProgress: onProgress);
}
