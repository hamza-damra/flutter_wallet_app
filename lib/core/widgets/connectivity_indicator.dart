import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_state/connectivity_controller.dart';
import '../../services/connectivity_service.dart';
import '../theme/app_colors.dart';

class ConnectivityIndicator extends ConsumerWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityControllerProvider);

    if (status == ConnectivityStatus.online) {
      // We could show a "Live" badge briefly or nothing.
      // The user wants Offline / Syncing / Live indicators.
      return _buildBadge(
        context,
        label: 'Live',
        color: AppColors.income,
        icon: Icons.wifi,
      );
    } else if (status == ConnectivityStatus.syncing) {
      return _buildBadge(
        context,
        label: 'Syncing...',
        color: AppColors.primary,
        icon: Icons.sync,
        isAnimated: true,
      );
    } else {
      return _buildBadge(
        context,
        label: 'Offline',
        color: AppColors.error,
        icon: Icons.wifi_off,
      );
    }
  }

  Widget _buildBadge(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    bool isAnimated = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(icon, color, isAnimated),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color, bool isAnimated) {
    if (isAnimated) {
      return _RotatingIcon(icon: icon, color: color);
    }
    return Icon(icon, color: color, size: 12);
  }
}

class _RotatingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _RotatingIcon({required this.icon, required this.color});

  @override
  _RotatingIconState createState() => _RotatingIconState();
}

class _RotatingIconState extends State<_RotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, color: widget.color, size: 12),
    );
  }
}
