import 'package:flutter/material.dart';

/// Helper class for direction-aware icons and widgets.
/// Provides utilities for correctly handling RTL/LTR icon mirroring.
class DirectionHelper {
  /// Private constructor
  DirectionHelper._();

  /// Icons that should be mirrored in RTL layouts (directional icons)
  /// Using a list of codePoints since IconData can't be in const sets
  static final Set<int> _mirroredIconCodePoints = {
    Icons.arrow_back.codePoint,
    Icons.arrow_back_ios.codePoint,
    Icons.arrow_back_ios_new.codePoint,
    Icons.arrow_forward.codePoint,
    Icons.arrow_forward_ios.codePoint,
    Icons.chevron_left.codePoint,
    Icons.chevron_right.codePoint,
    Icons.keyboard_arrow_left.codePoint,
    Icons.keyboard_arrow_right.codePoint,
    Icons.navigate_before.codePoint,
    Icons.navigate_next.codePoint,
    Icons.first_page.codePoint,
    Icons.last_page.codePoint,
    Icons.reply.codePoint,
    Icons.reply_all.codePoint,
    Icons.forward.codePoint,
    Icons.redo.codePoint,
    Icons.undo.codePoint,
    Icons.trending_up.codePoint,
    Icons.trending_down.codePoint,
    Icons.send.codePoint,
    Icons.exit_to_app.codePoint,
    Icons.open_in_new.codePoint,
    Icons.launch.codePoint,
    Icons.login.codePoint,
    Icons.logout.codePoint,
    Icons.subdirectory_arrow_left.codePoint,
    Icons.subdirectory_arrow_right.codePoint,
    Icons.arrow_right_alt.codePoint,
    Icons.arrow_left.codePoint,
    Icons.arrow_right.codePoint,
  };

  /// Check if an icon should be mirrored in RTL mode
  static bool shouldMirror(IconData icon) {
    return _mirroredIconCodePoints.contains(icon.codePoint);
  }

  /// Get a widget that mirrors the child if in RTL mode and icon should be mirrored
  static Widget maybeFlip(
    BuildContext context,
    Widget child, {
    bool shouldMirror = true,
  }) {
    if (!shouldMirror) return child;

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    if (!isRtl) return child;

    return Transform.scale(scaleX: -1, child: child);
  }

  /// Get a direction-aware icon widget
  /// Automatically mirrors directional icons in RTL layouts
  static Widget directionalIcon(
    BuildContext context,
    IconData icon, {
    double? size,
    Color? color,
    String? semanticLabel,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final shouldFlip = isRtl && shouldMirror(icon);

    final iconWidget = Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );

    return shouldFlip
        ? Transform.scale(scaleX: -1, child: iconWidget)
        : iconWidget;
  }

  /// Get the correct back arrow for the current direction
  static IconData getBackArrow(BuildContext context) {
    return Icons
        .arrow_back; // Flutter handles this automatically via Directionality
  }

  /// Get the correct forward arrow for the current direction
  static IconData getForwardArrow(BuildContext context) {
    return Icons.arrow_forward;
  }

  /// Get the correct chevron for "next" action
  static IconData getNextChevron(BuildContext context) {
    return Icons.chevron_right;
  }

  /// Get the correct chevron for "previous" action
  static IconData getPreviousChevron(BuildContext context) {
    return Icons.chevron_left;
  }

  /// Create direction-aware padding
  static EdgeInsetsDirectional padding({
    double start = 0,
    double end = 0,
    double top = 0,
    double bottom = 0,
  }) {
    return EdgeInsetsDirectional.fromSTEB(start, top, end, bottom);
  }

  /// Create symmetric directional padding
  static EdgeInsetsDirectional symmetricPadding({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsetsDirectional.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  /// Create uniform directional padding
  static EdgeInsetsDirectional allPadding(double value) {
    return EdgeInsetsDirectional.all(value);
  }

  /// Create only-start padding
  static EdgeInsetsDirectional onlyStart(double value) {
    return EdgeInsetsDirectional.only(start: value);
  }

  /// Create only-end padding
  static EdgeInsetsDirectional onlyEnd(double value) {
    return EdgeInsetsDirectional.only(end: value);
  }

  /// Get direction-aware BorderRadius for start-side rounded corners
  static BorderRadiusDirectional borderRadiusStart(double radius) {
    return BorderRadiusDirectional.horizontal(start: Radius.circular(radius));
  }

  /// Get direction-aware BorderRadius for end-side rounded corners
  static BorderRadiusDirectional borderRadiusEnd(double radius) {
    return BorderRadiusDirectional.horizontal(end: Radius.circular(radius));
  }

  /// Get direction-aware BorderRadius for all corners
  static BorderRadiusDirectional borderRadiusAll(double radius) {
    return BorderRadiusDirectional.circular(radius);
  }

  /// Create direction-aware positioned widget
  static PositionedDirectional positioned({
    double? start,
    double? end,
    double? top,
    double? bottom,
    double? width,
    double? height,
    required Widget child,
  }) {
    return PositionedDirectional(
      start: start,
      end: end,
      top: top,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  }
}

/// Extension on BuildContext for direction-related utilities
extension DirectionExtension on BuildContext {
  /// Check if current direction is RTL
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Check if current direction is LTR
  bool get isLtr => Directionality.of(this) == TextDirection.ltr;

  /// Get current text direction
  TextDirection get direction => Directionality.of(this);

  /// Create EdgeInsetsDirectional with start/end
  EdgeInsetsDirectional edgeInsetsSTEB(
    double start,
    double top,
    double end,
    double bottom,
  ) {
    return EdgeInsetsDirectional.fromSTEB(start, top, end, bottom);
  }
}

/// Widget that automatically mirrors its child in RTL layouts
class DirectionalMirror extends StatelessWidget {
  final Widget child;
  final bool mirror;

  const DirectionalMirror({super.key, required this.child, this.mirror = true});

  @override
  Widget build(BuildContext context) {
    if (!mirror) return child;

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    if (!isRtl) return child;

    return Transform.scale(scaleX: -1, child: child);
  }
}

/// A directional icon that automatically handles RTL mirroring
class DirectionalIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final bool autoMirror;

  const DirectionalIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.autoMirror = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!autoMirror || !DirectionHelper.shouldMirror(icon)) {
      return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
    }

    return DirectionHelper.directionalIcon(
      context,
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}
