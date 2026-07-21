import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:she_secure/shared/theme/app_colors.dart';
import 'package:she_secure/shared/theme/app_text_styles.dart';

class SosHeroButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;

  const SosHeroButton({
    super.key,
    required this.onPressed,
    this.size = 160,
  });

  @override
  State<SosHeroButton> createState() => _SosHeroButtonState();
}

class _SosHeroButtonState extends State<SosHeroButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2750),
    );

    _rippleScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut),
    );

    _rippleOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut),
    );

    _rippleController.repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        widget.onPressed();
      },
      child: SizedBox(
        width: widget.size + 40,
        height: widget.size + 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _rippleScale.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: AppColors.gradientHeroColors
                            .map((c) => c.withValues(alpha: _rippleOpacity.value))
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.gradientHeroColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentAlert.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'SOS',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: widget.size * 0.28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
