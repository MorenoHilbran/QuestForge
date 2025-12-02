import 'package:flutter/material.dart';

class NeoButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color? textColor;
  final bool isLoading;
  final double? width;

  const NeoButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
    this.textColor,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor ?? Colors.black,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
