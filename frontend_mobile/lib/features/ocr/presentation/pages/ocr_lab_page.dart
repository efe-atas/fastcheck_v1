import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/ocr_cubit.dart';

/// OCR API yalnızca **http/https** ile erişilebilen görsel URL’leri kabul eder.
/// Cihazdaki ham dosya için önce sunucuya yükleyip public URL üretmeniz gerekir.
class OcrLabPage extends StatefulWidget {
  const OcrLabPage({super.key});

  @override
  State<OcrLabPage> createState() => _OcrLabPageState();
}

class _OcrLabPageState extends State<OcrLabPage> {
  final _urlCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _langCtrl = TextEditingController();
  final _jobIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OcrCubit>().refreshList();
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _sourceCtrl.dispose();
    _langCtrl.dispose();
    _jobIdCtrl.dispose();
    super.dispose();
  }

  String _prettyResult(dynamic result) {
    if (result == null) return '—';
    try {
      return const JsonEncoder.withIndent('  ').convert(result);
    } catch (_) {
      return result.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OCR'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<OcrCubit, OcrState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: const Text(
                  'Bu uç nokta yalnızca herkese açık http(s) görsel adresi kabul eder. '
                  'Yerel fotoğraf göndermek için önce dosyayı bir sunucuya yükleyin.',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Görsel URL (https://...)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _sourceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kaynak ID (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _langCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dil ipucu (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        final u = _urlCtrl.text.trim();
                        if (!u.startsWith('http://') && !u.startsWith('https://')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('URL http veya https ile başlamalı'),
                            ),
                          );
                          return;
                        }
                        final s = _sourceCtrl.text.trim();
                        final l = _langCtrl.text.trim();
                        context.read<OcrCubit>().extract(
                              imageUrl: u,
                              sourceId: s.isEmpty ? null : s,
                              languageHint: l.isEmpty ? null : l,
                            );
                      },
                child: const Text('Metin çıkar (extract)'),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _jobIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Job ID (UUID)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        final id = _jobIdCtrl.text.trim();
                        if (id.isEmpty) return;
                        context.read<OcrCubit>().loadByJobId(id);
                      },
                child: const Text('Job detayı getir'),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              if (state.lastExtract != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Son sonuç',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _prettyResult(state.lastExtract!.result),
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Sonuçlarım',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed:
                        state.isLoading ? null : () => context.read<OcrCubit>().refreshList(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Yenile'),
                  ),
                ],
              ),
              if (state.results == null || state.results!.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Kayıt yok'),
                )
              else
                ...state.results!.map(
                  (e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        e.jobId.length > 12
                            ? '${e.jobId.substring(0, 12)}…'
                            : e.jobId,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      subtitle: Text(
                        e.imageUrl ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _jobIdCtrl.text = e.jobId;
                        context.read<OcrCubit>().loadByJobId(e.jobId);
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
