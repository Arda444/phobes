/// Result of attempting to join a team with a join code.
enum JoinTeamResult {
  success,
  invalidCode,
  permissionDenied,
  error,
}
