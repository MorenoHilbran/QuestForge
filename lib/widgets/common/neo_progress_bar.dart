import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class NeoProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;

  const NeoProgressBar({
    super.key,
    required this.progress,
    this.color = AppColors.primary,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: Colors.black,
            width: AppConstants.borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius - 2),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: height,
                color: AppColors.background,
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border(
                      right: BorderSide(
                        color: Colors.black,
                        width: progress < 1.0 ? AppConstants.borderWidth : 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
