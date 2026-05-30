import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../../models/survey_model.dart';
import '../../services/survey_service.dart';
import '../../widgets/phobes_widgets.dart';

class SurveyScreen extends StatefulWidget {
  final String surveyId;
  const SurveyScreen({super.key, required this.surveyId});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _service = SurveyService();
  SurveyModel? _survey;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final Map<String, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final survey = await _service.fetchSurvey(widget.surveyId);
      if (survey == null || !survey.isActive) {
        setState(() {
          _error = l10n.surveyNotFound;
          _loading = false;
        });
        return;
      }
      final done = await _service.hasResponded(widget.surveyId);
      if (done) {
        setState(() {
          _error = l10n.surveyAlreadyResponded;
          _loading = false;
        });
        return;
      }
      setState(() {
        _survey = survey;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final survey = _survey;
    if (survey == null) return;
    for (final q in survey.questions) {
      final a = _answers[q.id];
      if (a == null || (a is String && a.trim().isEmpty) ||
          (a is List && a.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.surveyAnswerAll(q.text))),
        );
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      await _service.submitResponse(widget.surveyId, _answers);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.surveySubmitFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _survey?.title ?? l10n.surveyDefaultTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_survey!.description.isNotEmpty)
                        Text(
                          _survey!.description,
                          style: GoogleFonts.outfit(
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      const SizedBox(height: 24),
                      ..._survey!.questions.map(_buildQuestion),
                      const SizedBox(height: 32),
                      PhobesButton(
                        text: _submitting
                            ? l10n.surveySubmitting
                            : l10n.surveySubmit,
                        isLoading: _submitting,
                        onPressed: _submitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildQuestion(SurveyQuestion q) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.text,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (q.type == SurveyQuestionType.text)
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.surveyAnswerHint,
              ),
              onChanged: (v) => _answers[q.id] = v.trim(),
            )
          else if (q.type == SurveyQuestionType.single)
            ...q.options.map(
              (opt) => RadioListTile<String>(
                value: opt,
                groupValue: _answers[q.id] as String?,
                title: Text(opt, style: GoogleFonts.outfit()),
                onChanged: (v) => setState(() => _answers[q.id] = v),
              ),
            )
          else
            ...q.options.map(
              (opt) => CheckboxListTile(
                value: ((_answers[q.id] as List<String>?) ?? []).contains(opt),
                title: Text(opt, style: GoogleFonts.outfit()),
                onChanged: (checked) {
                  setState(() {
                    final list =
                        List<String>.from((_answers[q.id] as List<String>?) ?? []);
                    if (checked == true) {
                      list.add(opt);
                    } else {
                      list.remove(opt);
                    }
                    _answers[q.id] = list;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
