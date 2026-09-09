import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Pro-Max Header Component for Zenvi POS
/// Menyediakan geometri presisi di bawah status bar, proteksi font scaling,
/// efek frosted glass modern, serta slot aksi dan tombol kembali yang ergonomis.
class ZenviHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? subtitleWidget;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;
  final double? customContentHeight;
  final bool enableBlur;
  final Color? backgroundColor;
  final bool showBottomBorder;
  final EdgeInsetsGeometry? padding;

  const ZenviHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    this.showBackButton = false,
    this.onBackPressed,
    this.leading,
    this.actions,
    this.bottom,
    this.customContentHeight,
    this.enableBlur = true,
    this.backgroundColor,
    this.showBottomBorder = true,
    this.padding,
  });

  /// Factory untuk membuat SliverPersistentHeader secara instan
  static Widget sliver({
    Key? key,
    String? title,
    Widget? titleWidget,
    String? subtitle,
    Widget? subtitleWidget,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
    Widget? leading,
    List<Widget>? actions,
    Widget? bottom,
    double? customContentHeight,
    bool enableBlur = true,
    Color? backgroundColor,
    bool showBottomBorder = true,
    EdgeInsetsGeometry? padding,
    bool pinned = true,
  }) {
    return _ZenviSliverHeaderWrapper(
      key: key,
      title: title,
      titleWidget: titleWidget,
      subtitle: subtitle,
      subtitleWidget: subtitleWidget,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
      leading: leading,
      actions: actions,
      bottom: bottom,
      customContentHeight: customContentHeight,
      enableBlur: enableBlur,
      backgroundColor: backgroundColor,
      showBottomBorder: showBottomBorder,
      padding: padding,
      pinned: pinned,
    );
  }

  double calculateContentHeight() {
    if (customContentHeight != null) return customContentHeight!;
    if (bottom != null) {
      return (subtitle != null || subtitleWidget != null) ? 128.0 : 120.0;
    }
    return (subtitle != null || subtitleWidget != null) ? 72.0 : 66.0;
  }

  @override
  Size get preferredSize => Size.fromHeight(calculateContentHeight());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBackButton || (showBackButton == false && onBackPressed != null);

    final content = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface.withValues(alpha: enableBlur ? 0.85 : 1.0),
        border: showBottomBorder
            ? Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.08),
                  width: 1,
                ),
              )
            : null,
      ),
      padding: padding ??
          EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: topPadding + 4.0,
            bottom: 6.0,
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading / Back Button
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ] else if (shouldShowBack || (showBackButton && canPop)) ...[
                _buildBackButton(context, theme),
                const SizedBox(width: 10),
              ],

              // Title & Subtitle
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (titleWidget != null)
                      titleWidget!
                    else if (title != null)
                      Text(
                        title!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          fontSize: 18.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: 1.5),
                      subtitleWidget!,
                    ] else if (subtitle != null) ...[
                      const SizedBox(height: 1.5),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Actions Slot
              //
              // Batas tinggi ini menahan aksi yang kelewat tinggi supaya tidak
              // menarik seluruh header ikut memanjang. Angkanya harus tetap
              // muat di dalam calculateContentHeight() - 4px padding atas +
              // 44 + 6px padding bawah = 54, masih di bawah 66.
              //
              // Dulu 38, dan itu memotong aksi berbentuk chip: tombol dengan
              // ikon 16px + padding vertikal 6px + margin vertikal 8px tingginya
              // 44px, jadi 6px terbawahnya terpangkas tanpa peringatan apa pun.
              // 44 juga ukuran minimum sasaran sentuh yang nyaman.
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 44),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: actions!,
                  ),
                ),
              ],
            ],
          ),

          // Bottom Widget (e.g. Filters / Search / Tabs)
          if (bottom != null) ...[
            const SizedBox(height: 6),
            bottom!,
          ],
        ],
      ),
    );

    if (!enableBlur) return content;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: content,
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBackPressed ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Sliver Wrapper untuk ZenviHeader
class _ZenviSliverHeaderWrapper extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? subtitleWidget;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;
  final double? customContentHeight;
  final bool enableBlur;
  final Color? backgroundColor;
  final bool showBottomBorder;
  final EdgeInsetsGeometry? padding;
  final bool pinned;

  const _ZenviSliverHeaderWrapper({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    this.showBackButton = false,
    this.onBackPressed,
    this.leading,
    this.actions,
    this.bottom,
    this.customContentHeight,
    this.enableBlur = true,
    this.backgroundColor,
    this.showBottomBorder = true,
    this.padding,
    this.pinned = true,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    double baseHeight = customContentHeight ??
        (bottom != null
            ? ((subtitle != null || subtitleWidget != null) ? 128.0 : 120.0)
            : ((subtitle != null || subtitleWidget != null) ? 72.0 : 66.0));
    double totalHeight = baseHeight + topPadding;

    return SliverPersistentHeader(
      pinned: pinned,
      delegate: ZenviStickyHeaderDelegate(
        height: totalHeight,
        child: ZenviHeader(
          title: title,
          titleWidget: titleWidget,
          subtitle: subtitle,
          subtitleWidget: subtitleWidget,
          showBackButton: showBackButton,
          onBackPressed: onBackPressed,
          leading: leading,
          actions: actions,
          bottom: bottom,
          customContentHeight: customContentHeight,
          enableBlur: enableBlur,
          backgroundColor: backgroundColor,
          showBottomBorder: showBottomBorder,
          padding: padding,
        ),
      ),
    );
  }
}

/// Standar Delegate Header Lengkap untuk Zenvi
class ZenviStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  ZenviStickyHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant ZenviStickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
