import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';

/// Decorative awning trim retained for screens that use the market motif.
class ScallopAwningTrim extends StatelessWidget {
  final double height;
  final Color scallopColor;
  final Color backgroundColor;

  const ScallopAwningTrim({
    super.key,
    this.height = 16.0,
    this.scallopColor = const Color(0xFFFDF8F3),
    this.backgroundColor = KiranaNapseTheme.ledgerDark,
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
    // Fill the top section with brand ink.
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

  const ToranGarland({super.key, this.height = 16, this.opacity = 0.9});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _ToranPainter()),
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

/// Compact app header with a clear back action and optional screen action.
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
      decoration: const BoxDecoration(
        color: KiranaNapseTheme.terracottaDark,
        border: Border(
          bottom: BorderSide(color: KiranaNapseTheme.turmeric, width: 3),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        18,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBack)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Go back',
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            )
          else if (leading != null)
            Padding(padding: const EdgeInsets.only(right: 12), child: leading!),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.baloo2(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hind(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFDDEAE1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
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
    final isReorder = variant == SummaryCardVariant.gold;
    final accent = isReorder
        ? KiranaNapseTheme.terracottaDark
        : KiranaNapseTheme.marigold;
    final surface = isReorder
        ? KiranaNapseTheme.terracottaTint
        : KiranaNapseTheme.marigoldTint;
    return Expanded(
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 126),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      isReorder
                          ? Icons.inventory_2_outlined
                          : Icons.hourglass_bottom_rounded,
                      color: accent,
                      size: 20,
                    ),
                    Icon(Icons.arrow_outward_rounded, color: accent, size: 18),
                  ],
                ),
                Text(
                  count,
                  style: GoogleFonts.baloo2(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  style: GoogleFonts.hind(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KiranaNapseTheme.jute,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clear next step when a list has no data or cannot load.
class KiranaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const KiranaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: KiranaNapseTheme.riceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KiranaNapseTheme.sandstone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: KiranaNapseTheme.terracottaTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: KiranaNapseTheme.terracottaDark, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.baloo2(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: KiranaNapseTheme.jute,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: GoogleFonts.hind(
              fontSize: 13,
              color: KiranaNapseTheme.juteSoft,
              height: 1.4,
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
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
        indicatorColor = KiranaNapseTheme.chili;
        defaultQtyColor = KiranaNapseTheme.chili;
        break;
      case KiranaCardIndicator.watch:
        indicatorColor = KiranaNapseTheme.marigold;
        defaultQtyColor = KiranaNapseTheme.marigold;
        break;
      case KiranaCardIndicator.ok:
        indicatorColor = KiranaNapseTheme.betel;
        defaultQtyColor = KiranaNapseTheme.betel;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: KiranaNapseTheme.riceCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: KiranaNapseTheme.sandstone, width: 1.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 5px left-border indicator strip
                  Container(width: 5.5, color: indicatorColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tag != null) ...[tag!, const SizedBox(height: 6)],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.hind(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: KiranaNapseTheme.jute,
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
                                  color: KiranaNapseTheme.juteSoft,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: urgentPrefix!,
                                    style: GoogleFonts.hind(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: KiranaNapseTheme.chili,
                                    ),
                                  ),
                                  TextSpan(text: ' $reason'),
                                ],
                              ),
                            )
                          else
                            Text(
                              reason,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.hind(
                                fontSize: 13,
                                color: KiranaNapseTheme.juteSoft,
                                height: 1.4,
                              ),
                            ),
                          if (actions != null && actions!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(children: actions!),
                          ],
                        ],
                      ),
                    ),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: filled
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: KiranaNapseTheme.betel,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.hind(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: KiranaNapseTheme.jute,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: const BorderSide(color: KiranaNapseTheme.sandstone),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.hind(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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

  const MiniTag({super.key, required this.label, this.type = MiniTagType.warn});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.hind(
          fontSize: 11,
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
        return MiniTag(label: status, type: MiniTagType.pending);
    }
  }
}

/// Backward compatibility card wrapper
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCard({super.key, required this.child, this.padding, this.onTap});

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
