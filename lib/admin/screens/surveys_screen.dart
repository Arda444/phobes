import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_service.dart';
import '../utils/admin_ui_system.dart';
import '../../models/survey_model.dart';

class SurveysScreen extends StatelessWidget {
  const SurveysScreen({super.key});

  void _showCreateDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final questions = <SurveyQuestion>[];

    void addQuestion(SurveyQuestionType type) {
      questions.add(SurveyQuestion(
        id: 'q${questions.length + 1}',
        text: '',
        type: type,
        options: type == SurveyQuestionType.text ? [] : ['Seçenek 1', 'Seçenek 2'],
      ));
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Yeni Anket', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => addQuestion(SurveyQuestionType.single)),
                        child: const Text('+ Tek seçim'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => addQuestion(SurveyQuestionType.multi)),
                        child: const Text('+ Çoklu seçim'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => addQuestion(SurveyQuestionType.text)),
                        child: const Text('+ Metin'),
                      ),
                    ],
                  ),
                  ...questions.asMap().entries.map((e) {
                    final q = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Soru ${e.key + 1} (${q.type.name})',
                        ),
                        onChanged: (v) => questions[e.key] = SurveyQuestion(
                          id: q.id,
                          text: v,
                          type: q.type,
                          options: q.options,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || questions.isEmpty) return;
                final valid = questions.every((q) => q.text.trim().isNotEmpty);
                if (!valid) return;
                Navigator.pop(ctx);
                await AdminService.createSurvey(
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  questions: questions,
                );
              },
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStats(BuildContext context, String surveyId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          width: 480,
          height: 400,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('$title — İstatistik',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: AdminService.surveyResponsesStream(surveyId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data?.docs ?? [];
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('Toplam yanıt: ${docs.length}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        ...docs.take(20).map((d) {
                          final answers = d.data()['answers'] as Map<String, dynamic>? ?? {};
                          return ListTile(
                            dense: true,
                            title: Text('UID: ${d.id.substring(0, 8)}...'),
                            subtitle: Text(answers.toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pad = AdminUISystem.horizontalPadding(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 20, pad, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('Anket Yönetimi',
                    style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface, fontSize: 22)),
              ),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Yeni'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AdminService.surveysStream(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Hata: ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('Henüz anket yok'));
              }
              return ListView.builder(
                padding: EdgeInsets.all(pad),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data();
                  final status = d['status'] as String? ?? 'draft';
                  final title = d['title'] as String? ?? '';
                  final responses = (d['responseCount'] as num?)?.toInt() ?? 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                      subtitle: Text('$status · $responses yanıt'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'publish') {
                            await AdminService.publishSurvey(doc.id, title);
                          } else if (v == 'stop') {
                            await AdminService.stopSurvey(doc.id, title);
                          } else if (v == 'stats') {
                            _showStats(context, doc.id, title);
                          } else if (v == 'delete') {
                            await AdminService.deleteSurvey(doc.id, title);
                          }
                        },
                        itemBuilder: (_) => [
                          if (status != 'active')
                            const PopupMenuItem(value: 'publish', child: Text('Yayınla + Push')),
                          if (status == 'active')
                            const PopupMenuItem(value: 'stop', child: Text('Durdur')),
                          const PopupMenuItem(value: 'stats', child: Text('İstatistik')),
                          const PopupMenuItem(value: 'delete', child: Text('Sil')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
