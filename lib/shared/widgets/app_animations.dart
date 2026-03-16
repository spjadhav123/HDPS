// lib/shared/widgets/app_animations.dart
// Central animation utilities for the Humpty Dumpty Preschool app.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Animation Constants (consistent durations – 200-400ms)
// ─────────────────────────────────────────────────────────────
class AppDurations {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const medium = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 400);
  static const stagger = Duration(milliseconds: 50);
}

// ─────────────────────────────────────────────────────────────
// AppButton — Scale-on-press button wrapper
// ─────────────────────────────────────────────────────────────
class AppButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final bool outlined;

  const AppButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.padding,
    this.outlined = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.reverse();
  void _onTapUp(TapUpDetails _) => _ctrl.forward();
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final bg = widget.color ?? AppTheme.primary;
    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading ? _onTapDown : null,
      onTapUp: widget.onPressed != null && !widget.isLoading ? _onTapUp : null,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed != null && !widget.isLoading ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedOpacity(
          duration: AppDurations.fast,
          opacity: (widget.onPressed == null || widget.isLoading) ? 0.65 : 1.0,
          child: Container(
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              color: widget.outlined ? Colors.transparent : bg,
              borderRadius: BorderRadius.circular(12),
              border: widget.outlined
                  ? Border.all(color: bg, width: 1.5)
                  : null,
              boxShadow: widget.outlined
                  ? null
                  : [
                      BoxShadow(
                        color: bg.withAlpha(77),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: widget.isLoading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.outlined ? bg : Colors.white,
                    ),
                  )
                : DefaultTextStyle(
                    style: TextStyle(
                      color: widget.outlined ? bg : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    child: widget.child,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AnimatedListItem — staggered fade+slide for list rows
// ─────────────────────────────────────────────────────────────
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int maxDelay;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.maxDelay = 400,
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: (index * 40).clamp(0, maxDelay));
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.slow)
        .moveY(begin: 12, end: 0, curve: Curves.easeOut, duration: AppDurations.slow);
  }
}

// ─────────────────────────────────────────────────────────────
// AppShimmer — shimmer loading skeleton
// ─────────────────────────────────────────────────────────────
class AppShimmer extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const AppShimmer({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: [
              Colors.grey.shade200,
              Colors.grey.shade100,
              Colors.grey.shade200,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ShimmerListView — full shimmer skeleton for lists
// ─────────────────────────────────────────────────────────────
class ShimmerListView extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerListView({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: itemHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AppShimmer(
                  height: 40,
                  width: 40,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppShimmer(height: 12, width: double.infinity, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 8),
                      AppShimmer(height: 10, width: 140, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                AppShimmer(height: 20, width: 60, borderRadius: BorderRadius.circular(10)),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AppToast — slide-down toast with icon + auto-dismiss
// ─────────────────────────────────────────────────────────────
enum ToastType { success, error, warning, info }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () => entry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _opacity;

  Color get _color {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF22C55E);
      case ToastType.error:
        return AppTheme.secondary;
      case ToastType.warning:
        return AppTheme.warning;
      case ToastType.info:
        return AppTheme.primary;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppDurations.medium);
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _ctrl.forward();

    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _ctrl.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            shadowColor: _color.withAlpha(64),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _color.withAlpha(64)),
                boxShadow: [
                  BoxShadow(
                    color: _color.withAlpha(38),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _color.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, color: _color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await _ctrl.reverse();
                      widget.onDismiss();
                    },
                    child: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AnimatedFocusField — input field with animated focus border
// ─────────────────────────────────────────────────────────────
class AnimatedFocusField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLength;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const AnimatedFocusField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.textInputAction,
  });

  @override
  State<AnimatedFocusField> createState() => _AnimatedFocusFieldState();
}

class _AnimatedFocusFieldState extends State<AnimatedFocusField> {
  late FocusNode _focus;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(() {
      if (mounted) setState(() => _isFocused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.normal,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(38),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onChanged: widget.onChanged,
        maxLength: widget.maxLength,
        maxLines: widget.maxLines,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        textInputAction: widget.textInputAction,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          counterText: '',
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            color: _isFocused ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: _isFocused ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AnimatedValidationText — slide+fade for error messages
// ─────────────────────────────────────────────────────────────
class AnimatedValidationText extends StatelessWidget {
  final String? errorMessage;

  const AnimatedValidationText({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null || errorMessage!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 13, color: AppTheme.secondary),
          const SizedBox(width: 4),
          Text(
            errorMessage!,
            style: const TextStyle(
              color: AppTheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppDurations.normal)
        .moveY(begin: -8, end: 0, duration: AppDurations.normal, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────
// PageFadeTransition — wraps child with fade entrance per page
// ─────────────────────────────────────────────────────────────
class PageFadeTransition extends StatelessWidget {
  final Widget child;

  const PageFadeTransition({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(duration: AppDurations.medium)
        .moveY(begin: 10, end: 0, duration: AppDurations.medium, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────
// AnimatedProgressBar — smooth progress bar for fees/scores
// ─────────────────────────────────────────────────────────────
class AnimatedProgressBar extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor = const Color(0xFFE5E7EB),
    this.height = 6,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 0, end: widget.value.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(begin: _anim.value, end: widget.value.clamp(0.0, 1.0))
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(widget.height / 2);
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => ClipRRect(
        borderRadius: br,
        child: LinearProgressIndicator(
          value: _anim.value,
          backgroundColor: widget.backgroundColor,
          valueColor: AlwaysStoppedAnimation(widget.color),
          minHeight: widget.height,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SpinningLoader — smooth rotating circular loader
// ─────────────────────────────────────────────────────────────
class SpinningLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const SpinningLoader({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation(color ?? AppTheme.primary),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .rotate(duration: const Duration(milliseconds: 800));
  }
}

// ─────────────────────────────────────────────────────────────
// FullPageLoader — centred animated loader for async loads
// ─────────────────────────────────────────────────────────────
class FullPageLoader extends StatelessWidget {
  final String? message;

  const FullPageLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(38),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.95, end: 1.05, duration: 700.ms, curve: Curves.easeInOut),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ],
      ),
    );
  }
}
