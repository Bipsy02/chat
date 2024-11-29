import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final FocusNode? focusNode;
  final String fieldName;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final bool? enabled;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const TextFieldInput({
    super.key,
    required this.textEditingController,
    required this.fieldName,
    required this.hintText,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.enabled,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fieldName,
          style: const TextStyle(
            color: Color(0xFF747474),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          obscureText: obscureText,
          enabled: enabled ?? true,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            border: _buildOutlineBorder(Colors.grey[300]!),
            enabledBorder: _buildOutlineBorder(Colors.grey[300]!),
            focusedBorder: _buildOutlineBorder(Colors.blue),
            disabledBorder: _buildOutlineBorder(Colors.grey[200]!),
            errorBorder: _buildOutlineBorder(Colors.red),
            focusedErrorBorder: _buildOutlineBorder(Colors.red),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Helper method to create consistent OutlineInputBorder
  OutlineInputBorder _buildOutlineBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: color,
        width: 1,
      ),
    );
  }
}