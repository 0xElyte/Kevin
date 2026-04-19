import 'package:flutter/material.dart';
import 'package:project_kevin/theme/scifi_theme.dart';

/// A sci-fi styled button that consumes SciFi theme tokens.
class SciFiButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool outlined;
  final IconData? icon;

  const SciFiButton({
    super.key,
    required this.text,
    this.onPressed,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: SciFiTheme.colorAccent, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          ),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(text),
                ],
              )
            : Text(text),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: SciFiTheme.colorAccent,
        foregroundColor: SciFiTheme.colorTextPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
        ),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(text),
              ],
            )
          : Text(text),
    );
  }
}

/// A sci-fi styled text field that consumes SciFi theme tokens.
class SciFiTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final String? errorText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const SciFiTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onEditingComplete,
    this.errorText,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: SciFiTheme.colorSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          borderSide: const BorderSide(color: SciFiTheme.colorAccent, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          borderSide: const BorderSide(
            color: SciFiTheme.colorAccentDim,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          borderSide: const BorderSide(color: SciFiTheme.colorAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          borderSide: const BorderSide(color: SciFiTheme.colorAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          borderSide: const BorderSide(color: SciFiTheme.colorAccent, width: 2),
        ),
      ),
    );
  }
}

/// A sci-fi styled card that consumes SciFi theme tokens.
class SciFiCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double? borderWidth;

  const SciFiCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? SciFiTheme.bubblePadding,
      decoration: BoxDecoration(
        color: SciFiTheme.colorSurface,
        borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
        border: Border.all(
          color: borderColor ?? SciFiTheme.colorAccent,
          width: borderWidth ?? 1,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
        child: card,
      );
    }

    return card;
  }
}
