import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const NeoCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Container(
        margin: const EdgeInsets.only(
          left: AppConstants.shadowOffset,
          top: AppConstants.shadowOffset,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: Colors.black,
            width: AppConstants.borderWidth,
          ),
        ),
        child: onTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                  child: Padding(
                    padding: padding ??
                        const EdgeInsets.all(AppConstants.spacingM),
                    child: child,
                  ),
                ),
              )
            : Padding(
                padding:
                    padding ?? const EdgeInsets.all(AppConstants.spacingM),
                child: child,
              ),
      ),
    );
  }
}
