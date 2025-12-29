import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

/// Widget for displaying SVG illustrations with fallback handling
class IllustrationWidget extends StatelessWidget {
  final String path;
  final double height;
  final BoxFit fit;
  final Color? color;

  const IllustrationWidget({
    super.key,
    required this.path,
    this.height = 250,
    this.fit = BoxFit.contain,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: SvgPicture.asset(
        path,
        height: height,
        fit: fit,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (context) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 64, color: AppColors.primary.withAlpha(128)),
          const SizedBox(height: 8),
          Text(
            'Illustration',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
