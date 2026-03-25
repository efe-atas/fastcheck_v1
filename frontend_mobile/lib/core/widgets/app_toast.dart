import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void showAppToast(
  BuildContext context, {
  required String message,
  bool destructive = false,
  Duration duration = const Duration(seconds: 4),
}) {
  final toast = destructive
      ? ShadToast.destructive(
          title: Text(message),
          duration: duration,
        )
      : ShadToast(
          title: Text(message),
          duration: duration,
        );
  ShadToaster.maybeOf(context)?.show(toast);
}
