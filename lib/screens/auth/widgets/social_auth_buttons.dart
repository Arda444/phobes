import 'package:flutter/material.dart';
import '../../../widgets/phobes_widgets.dart';
import '../../../l10n/app_localizations.dart';

class SocialAuthButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;

  const SocialAuthButtons({
    super.key,
    required this.isLoading,
    required this.onGoogleTap,
    required this.onAppleTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      children: [
        PhobesButton(
          width: double.infinity,
          text: l10n.continueWithGoogle,
          isOutlined: true,
          icon: Icons.g_mobiledata_rounded,
          isLoading: isLoading,
          onPressed: onGoogleTap,
        ),
        const SizedBox(height: 12),
        PhobesButton(
          width: double.infinity,
          text: l10n.continueWithApple,
          isOutlined: true,
          icon: Icons.apple_rounded,
          isLoading: isLoading,
          onPressed: onAppleTap,
        ),
      ],
    );
  }
}
