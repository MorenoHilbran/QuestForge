import 'package:flutter/material.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const NeoCard({
    super.key,
    required this.child,
    required this.color,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
