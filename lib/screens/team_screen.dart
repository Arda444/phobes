import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../models/team_model.dart';
import 'team_add_edit_screen.dart';
import '../l10n/app_localizations.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final FirebaseService _service = FirebaseService();

  void _showCreateTeamDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title:
            Text(l10n.createTeam, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
              hintText: l10n.teamName,
              hintStyle: const TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                final String code =
                    await _service.createTeam(controller.text.trim());
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.teamCreated(code)),
                    backgroundColor: Colors.green));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Hata: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: Text(l10n.create),
          )
        ],
      ),
    );
  }

  void _showJoinTeamDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(l10n.joinTeam, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
              hintText: l10n.joinCode,
              hintStyle: const TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                final bool success =
                    await _service.joinTeam(controller.text.trim());
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.teamJoined),
                      backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.invalidCode),
                      backgroundColor: Colors.red));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Hata: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: Text(l10n.join),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Responsive: Genişliğe göre kolon sayısı belirle
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1100 ? 3 : (width > 700 ? 2 : 1);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.navTeams,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: StreamBuilder<List<Team>>(
        stream: _service.getUserTeamsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Hata: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red)));
          }

          final teams = snapshot.data ?? [];

          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off_rounded,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noData,
                      style: GoogleFonts.poppins(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: _showCreateTeamDialog,
                      child: Text(l10n.createTeam)),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: _showJoinTeamDialog,
                      child: Text(l10n.joinTeam)),
                ],
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3.5, // Kartların yatay/dikey oranı
                ),
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return Card(
                    color: Colors.grey.shade900,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05))),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TeamAddEditScreen(team: team)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            CircleAvatar(
                                backgroundColor: Colors.purple,
                                child: Text(
                                    team.name.isNotEmpty
                                        ? team.name[0].toUpperCase()
                                        : "?",
                                    style:
                                        const TextStyle(color: Colors.white))),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(team.name,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(
                                      "${team.memberIds.length} ${l10n.members}",
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.copy, color: Colors.white54),
                              tooltip: l10n.copyCode,
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: team.joinCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "${l10n.joinCode} kopyalandı!")));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'team_create_btn',
        backgroundColor: Colors.purple,
        onPressed: _showCreateTeamDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
