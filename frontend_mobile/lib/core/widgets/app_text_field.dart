import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int maxLines;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final labelWidget = widget.label != null
        ? Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: theme.textTheme.large.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.foreground,
              ),
            ),
          )
        : null;

    Widget buildInput(void Function(String)? onChangedExtra) {
      return ShadInput(
        controller: widget.controller,
        placeholder: widget.hint != null ? Text(widget.hint!) : null,
        leading: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: 20,
                color: theme.colorScheme.mutedForeground,
              )
            : null,
        trailing: widget.obscureText
            ? ShadIconButton.ghost(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: theme.colorScheme.mutedForeground,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : widget.suffix,
        obscureText: widget.obscureText && _obscured,
        keyboardType: widget.keyboardType,
        enabled: widget.enabled,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        onChanged: (value) {
          widget.onChanged?.call(value);
          onChangedExtra?.call(value);
        },
      );
    }

    if (widget.validator != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelWidget != null) labelWidget,
          FormField<String>(
            initialValue: widget.controller?.text ?? '',
            validator: widget.validator,
            builder: (state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildInput(state.didChange),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        state.errorText!,
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.destructive,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelWidget != null) labelWidget,
        buildInput(null),
      ],
    );
  }
}
