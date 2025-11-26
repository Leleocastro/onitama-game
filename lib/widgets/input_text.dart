import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/extensions.dart';
import 'svg_viewer.dart';

class InputText extends StatefulWidget {
  final String labelText;
  final bool isPassword;
  final String icon;
  final String suffixIcon;
  final String hint;
  final double iconSize;
  final double fontSize;
  final double hintFontSize;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String errorText;
  final int? maxLines;
  final Color? backgroundColor;
  final Color? borderColor;
  final ValueChanged<String>? onChanged;
  final bool isLoading;
  final bool isEnabled;
  final Color? iconColor;
  final Color? color;
  final FocusNode? focusNode;
  final bool? autofocus;
  final double? height;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final bool isEnableBorder;
  final int? maxLength;

  const InputText({
    required this.controller,
    super.key,
    this.errorText = '',
    this.hint = '',
    this.icon = '',
    this.suffixIcon = '',
    this.labelText = '',
    this.keyboardType,
    this.inputFormatters,
    this.iconSize = 24,
    this.fontSize = 14,
    this.hintFontSize = 14,
    this.isPassword = false,
    this.maxLines,
    this.isEnableBorder = true,
    this.backgroundColor,
    this.borderColor,
    this.onChanged,
    this.isLoading = false,
    this.isEnabled = true,
    this.iconColor,
    this.color,
    this.focusNode,
    this.autofocus,
    this.height,
    this.onSubmitted,
    this.readOnly = false,
    this.maxLength,
  });

  @override
  State<InputText> createState() => _InputTextState();
}

class _InputTextState extends State<InputText> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.isPassword;
    final bgColor = widget.backgroundColor ?? Colors.grey[200];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.labelText.isNotEmpty) ...[
          Text(widget.labelText, textAlign: TextAlign.start, style: GoogleFonts.onest(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w400)),
          8.0.spaceY,
        ],
        Container(
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          height: widget.height,
          child: TextFormField(
            autofocus: widget.autofocus ?? false,
            cursorColor: widget.color ?? Colors.black,
            controller: widget.controller,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType,
            focusNode: widget.focusNode,
            maxLines: widget.maxLines ?? 1,
            enabled: widget.isEnabled,
            maxLength: widget.maxLength,
            obscureText: isPassword ? _obscureText : false,
            inputFormatters: widget.inputFormatters,
            onFieldSubmitted: widget.onSubmitted,
            readOnly: widget.readOnly,
            style: GoogleFonts.onest(fontSize: widget.fontSize, fontWeight: FontWeight.w700, color: widget.color ?? Colors.black),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.onest(color: widget.color ?? Colors.grey[600], fontWeight: FontWeight.w400, fontSize: widget.hintFontSize),
              prefixIconConstraints: const BoxConstraints(maxWidth: 56, maxHeight: 40),
              prefixIcon: widget.icon.isEmpty
                  ? null
                  : Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: SvgViewer(asset: widget.icon, height: widget.iconSize, color: widget.iconColor),
                    ),
              errorText: widget.errorText.isNotEmpty ? widget.errorText : null,
              labelStyle: GoogleFonts.onest(fontSize: 14, fontWeight: FontWeight.w400),
              floatingLabelStyle: TextStyle(color: Colors.grey[300]),
              enabledBorder: widget.isEnableBorder
                  ? OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.borderColor ?? Colors.grey.shade300))
                  : UnderlineInputBorder(borderSide: BorderSide(color: widget.borderColor ?? Colors.grey.shade300)),
              focusedBorder: widget.isEnableBorder
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.borderColor ?? Colors.grey.shade300, width: 2),
                    )
                  : UnderlineInputBorder(borderSide: BorderSide(color: widget.borderColor ?? Colors.grey.shade300, width: 2)),
              border: widget.isEnableBorder
                  ? OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                  : UnderlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: widget.isLoading
                  ? Container(
                      padding: const EdgeInsets.all(10),
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black),
                    )
                  : isPassword
                      ? IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: widget.iconColor),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        )
                      : widget.suffixIcon.isEmpty
                          ? null
                          : Container(padding: const EdgeInsets.all(10), child: SvgViewer(asset: widget.suffixIcon, height: widget.iconSize)),
            ),
          ),
        ),
      ],
    );
  }
}
