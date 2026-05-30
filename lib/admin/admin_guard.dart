import 'package:flutter/material.dart';
import '../../services/admin_access_service.dart';
import 'screens/not_authorized_screen.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminAccessService.instance.isCurrentUserAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return child;
        }
        return const NotAuthorizedScreen();
      },
    );
  }
}
