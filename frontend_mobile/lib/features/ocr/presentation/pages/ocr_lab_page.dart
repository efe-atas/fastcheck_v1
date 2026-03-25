import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../cubit/ocr_cubit.dart';

/// OCR ekranı yalnızca hızlı sınav kağıdı tarama akışını sunar.
class OcrLabPage extends StatefulWidget {
  const OcrLabPage({super.key});

  @override
  State<OcrLabPage> createState() => _OcrLabPageState();
}

class _OcrLabPageState extends State<OcrLabPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OcrCubit>().refreshList();
    });
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
      body: MultiBlocListener(
        listeners: [
          BlocListener<OcrCubit, OcrState>(
            listenWhen: (prev, curr) =>
                curr.errorMessage != prev.errorMessage &&
                curr.errorMessage != null,
            listener: (context, state) {
              showAppToast(
                context,
                message: state.errorMessage!,
                destructive: true,
              );
            },
          ),
          BlocListener<OcrCubit, OcrState>(
            listenWhen: (prev, curr) =>
                curr.lastMessage != null &&
                curr.lastMessage != prev.lastMessage &&
                (!curr.isLoading || curr.errorMessage != null),
            listener: (context, state) {
              final msg = state.lastMessage;
              if (msg == null || msg.isEmpty) return;
              showAppToast(context, message: msg);
            },
          ),
        ],
        child: BlocBuilder<OcrCubit, OcrState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Sınav kağıtlarını hızlıca tarayın',
                  style: ShadTheme.of(context).textTheme.h4,
                ),
                const SizedBox(height: 8),
                Text(
                  kIsWeb
                      ? 'Belge tarama yalnızca mobil uygulamada (iOS/Android) kullanılabilir.'
                      : 'Tek dokunuşla tarayın. Çok sayfa varsa sistem hepsini sırayla işler.',
                  style: ShadTheme.of(context).textTheme.muted,
                ),
                const SizedBox(height: 16),
                ShadButton(
                  onPressed: kIsWeb || state.isLoading
                      ? null
                      : () => context.read<OcrCubit>().scanAndExtract(),
                  child: Text(
                      state.isLoading ? 'Taranıyor...' : 'Sınav kağıdını tara'),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.lastMessage ?? 'Tarama bekleniyor',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'İlerleme: ${state.processedCount}/${state.totalCount}',
                        style: ShadTheme.of(context).textTheme.muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Sonuçlarım',
                      style: ShadTheme.of(context).textTheme.h4,
                    ),
                    const Spacer(),
                    ShadButton.ghost(
                      leading: const Icon(Icons.refresh, size: 18),
                      onPressed: state.isLoading
                          ? null
                          : () => context.read<OcrCubit>().refreshList(),
                      child: const Text('Yenile'),
                    ),
                  ],
                ),
                if (state.results == null || state.results!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Kayıt yok',
                      style: ShadTheme.of(context).textTheme.muted,
                    ),
                  )
                else
                  ...state.results!.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.imageUrl ?? e.jobId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ShadTheme.of(context).textTheme.muted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${e.createdAt.day.toString().padLeft(2, '0')}.${e.createdAt.month.toString().padLeft(2, '0')}',
                              style: ShadTheme.of(context).textTheme.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
