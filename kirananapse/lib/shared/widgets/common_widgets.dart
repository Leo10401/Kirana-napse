import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';

/// Decorative Scallop Awning Trim beneath the Terracotta Header.
class ScallopAwningTrim extends StatelessWidget {
  final double height;
  final Color scallopColor;
  final Color backgroundColor;

  const ScallopAwningTrim({
    super.key,
    this.height = 16.0,
    this.scallopColor = const Color(0xFFFDF8F3),
    this.backgroundColor = const Color(0xFFB85834),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ScallopAwningPainter(
          scallopColor: scallopColor,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

class _ScallopAwningPainter extends CustomPainter {
  final Color scallopColor;
  final Color backgroundColor;

  _ScallopAwningPainter({
    required this.scallopColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill top section with terracotta
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final double scallopWidth = 24.0;
    final int count = (size.width / scallopWidth).ceil() + 1;

    final scallopPaint = Paint()
      ..color = scallopColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFEAD8CC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 0);

    for (int i = 0; i < count; i++) {
      final double startX = i * scallopWidth;
      final double midX = startX + scallopWidth / 2;
      final double endX = startX + scallopWidth;

      // Downward scallop arch
      path.quadraticBezierTo(midX, size.height * 0.95, endX, 0);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, scallopPaint);

    // Draw the subtle outline along the arches
    final outlinePath = Path();
    outlinePath.moveTo(0, 0);
    for (int i = 0; i < count; i++) {
      final double startX = i * scallopWidth;
      final double midX = startX + scallopWidth / 2;
      final double endX = startX + scallopWidth;
      outlinePath.quadraticBezierTo(midX, size.height * 0.95, endX, 0);
    }
    canvas.drawPath(outlinePath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Decorative Toran Garland motif divider
class ToranGarland extends StatelessWidget {
  final double height;
  final double opacity;

  const ToranGarland({
    super.key,
    this.height = 16,
    this.opacity = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ToranPainter(),
        ),
      ),
    );
  }
}

class _ToranPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double step = 40.0;
    final int count = (size.width / step).ceil() + 1;

    final paintTerracotta = Paint()
      ..color = KiranaNapseTheme.terracotta
      ..style = PaintingStyle.fill;

    final paintTurmeric = Paint()
      ..color = KiranaNapseTheme.turmeric
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final double startX = i * step;
      canvas.drawCircle(Offset(startX + 10, 0), 5.5, paintTerracotta);
      canvas.drawCircle(Offset(startX + 30, 0), 5.5, paintTurmeric);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Terracotta Top App Header with Greeting / Title and circular action button.
class TerracottaAppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool showBack;
  final VoidCallback? onBack;

  const TerracottaAppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFB85834),
      padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBack)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          else if (leading != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: leading!,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.hind(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: GoogleFonts.hind(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFF2DDD4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
        ],
      ),
    );
  }
}

/// Gold/Peach summary KPI metric card.
enum SummaryCardVariant { gold, amber }

class KiranaSummaryCard extends StatelessWidget {
  final String count;
  final String label;
  final SummaryCardVariant variant;
  final VoidCallback? onTap;

  const KiranaSummaryCard({
    super.key,
    required this.count,
    required this.label,
    this.variant = SummaryCardVariant.gold,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF0E7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEED7C8), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: GoogleFonts.hind(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB85834),
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.hind(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4A3A32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status of Item Card left-border indicator.
enum KiranaCardIndicator { urgent, watch, ok }

/// Signature Kirana priority item card with color-coded left bar.
class KiranaItemCard extends StatelessWidget {
  final String name;
  final String? qtyText;
  final Color? qtyColor;
  final String reason;
  final String? urgentPrefix;
  final KiranaCardIndicator indicator;
  final List<Widget>? actions;
  final Widget? tag;
  final VoidCallback? onTap;

  const KiranaItemCard({
    super.key,
    required this.name,
    this.qtyText,
    this.qtyColor,
    required this.reason,
    this.urgentPrefix,
    this.indicator = KiranaCardIndicator.urgent,
    this.actions,
    this.tag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    Color defaultQtyColor;

    switch (indicator) {
      case KiranaCardIndicator.urgent:
        indicatorColor = const Color(0xFFB83226);
        defaultQtyColor = const Color(0xFFB83226);
        break;
      case KiranaCardIndicator.watch:
        indicatorColor = const Color(0xFFC0822B);
        defaultQtyColor = const Color(0xFFB97A21);
        break;
      case KiranaCardIndicator.ok:
        indicatorColor = const Color(0xFF5E8E47);
        defaultQtyColor = const Color(0xFF4C8035);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEBDDD2), width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 5px left-border indicator strip
              Container(
                width: 5.5,
                color: indicatorColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tag != null) ...[
                        tag!,
                        const SizedBox(height: 6),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.hind(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1A17),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (qtyText != null && qtyText!.isNotEmpty)
                            Text(
                              qtyText!,
                              style: GoogleFonts.hind(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: qtyColor ?? defaultQtyColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (urgentPrefix != null && urgentPrefix!.isNotEmpty)
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.hind(
                              fontSize: 13,
                              color: const Color(0xFF4A3A32),
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: urgentPrefix!,
                                style: GoogleFonts.hind(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFB83226),
                                ),
                              ),
                              TextSpan(text: ' $reason'),
                            ],
                          ),
                        )
                      else
                        Text(
                          reason,
                          style: GoogleFonts.hind(
                            fontSize: 13,
                            color: const Color(0xFF4A3A32),
                            height: 1.4,
                          ),
                        ),
                      if (actions != null && actions!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: actions!,
                        ),
                      ],
                    ],
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

/// Mini buttons inside item cards
class MiniButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const MiniButton({
    super.key,
    required this.label,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: filled ? KiranaNapseTheme.betel : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: filled ? KiranaNapseTheme.betel : KiranaNapseTheme.sandstone,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.hind(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: filled ? const Color(0xFFEFF4E7) : KiranaNapseTheme.jute,
          ),
        ),
      ),
    );
  }
}

/// Mini Tag chip for Overstock/Expiry items
enum MiniTagType { danger, warn, success, pending }

class MiniTag extends StatelessWidget {
  final String label;
  final MiniTagType type;

  const MiniTag({
    super.key,
    required this.label,
    this.type = MiniTagType.warn,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case MiniTagType.danger:
        bg = KiranaNapseTheme.chiliTint;
        fg = KiranaNapseTheme.chili;
        break;
      case MiniTagType.warn:
        bg = KiranaNapseTheme.marigoldTint;
        fg = KiranaNapseTheme.marigold;
        break;
      case MiniTagType.success:
        bg = KiranaNapseTheme.betelTint;
        fg = KiranaNapseTheme.betel;
        break;
      case MiniTagType.pending:
        bg = KiranaNapseTheme.sandstoneSoft;
        fg = KiranaNapseTheme.juteSoft;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.hind(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

/// Status chip for generic item recommendation status.
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'low_stock':
      case 'urgent':
        return const MiniTag(label: 'Low stock', type: MiniTagType.danger);
      case 'overstock':
      case 'watch':
        return const MiniTag(label: 'Overstock', type: MiniTagType.warn);
      case 'ordered':
      case 'resolved':
        return const MiniTag(label: 'Ordered', type: MiniTagType.success);
      default:
        return MiniTag(label: status.toUpperCase(), type: MiniTagType.pending);
    }
  }
}

/// Backward compatibility card wrapper
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KiranaNapseTheme.sandstone, width: 1),
        ),
        child: child,
      ),
    );
  }
}

/// Backward compatibility StatCard
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KiranaNapseTheme.sandstone, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.baloo2(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.hind(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: KiranaNapseTheme.juteSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
