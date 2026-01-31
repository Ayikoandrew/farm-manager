import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double widescreen = 1800;
}

/// Device type enum for responsive layouts
enum DeviceType { mobile, tablet, desktop, widescreen }

/// Get the current device type based on screen width
DeviceType getDeviceType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < Breakpoints.mobile) return DeviceType.mobile;
  if (width < Breakpoints.tablet) return DeviceType.tablet;
  if (width < Breakpoints.desktop) return DeviceType.desktop;
  return DeviceType.widescreen;
}

/// Check if the current device is mobile
bool isMobile(BuildContext context) =>
    MediaQuery.of(context).size.width < Breakpoints.mobile;

/// Check if the current device is tablet or larger
bool isTabletOrLarger(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.mobile;

/// Check if the current device is desktop or larger
bool isDesktopOrLarger(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.tablet;

/// Check if the current device is widescreen
bool isWidescreen(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.desktop;

/// A responsive wrapper that constrains content width and centers it on larger screens
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool centerOnLargeScreens;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
    this.centerOnLargeScreens = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLarge = constraints.maxWidth > maxWidth;

        Widget content = child;

        if (padding != null) {
          content = Padding(padding: padding!, child: content);
        }

        if (isLarge && centerOnLargeScreens) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: content,
            ),
          );
        }

        return content;
      },
    );
  }
}

/// A responsive scaffold body that constrains content width
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isWide = screenWidth > maxWidth;

        // Add extra horizontal padding on wide screens
        final horizontalPadding = isWide
            ? (screenWidth - maxWidth) / 2 + 16
            : padding.horizontal / 2;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: child,
        );
      },
    );
  }
}

/// Extension to help with responsive padding
extension EdgeInsetsExtension on EdgeInsetsGeometry {
  double get horizontal {
    if (this is EdgeInsets) {
      final insets = this as EdgeInsets;
      return insets.left + insets.right;
    }
    return 32; // Default
  }
}

/// A responsive grid that adapts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double mobileColumns;
  final double tabletColumns;
  final double desktopColumns;
  final double widescreenColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.widescreenColumns = 5,
    this.spacing = 12,
    this.runSpacing = 12,
    this.childAspectRatio = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns;

        if (width < Breakpoints.mobile) {
          columns = mobileColumns.toInt();
        } else if (width < Breakpoints.tablet) {
          columns = tabletColumns.toInt();
        } else if (width < Breakpoints.desktop) {
          columns = desktopColumns.toInt();
        } else {
          columns = widescreenColumns.toInt();
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: runSpacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// A responsive card grid specifically for stat/summary cards
class ResponsiveStatGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const ResponsiveStatGrid({
    super.key,
    required this.children,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns;
        double aspectRatio;

        if (width < Breakpoints.mobile) {
          columns = 2;
          aspectRatio = 1.4;
        } else if (width < Breakpoints.tablet) {
          columns = 3;
          aspectRatio = 1.5;
        } else if (width < Breakpoints.desktop) {
          columns = 4;
          aspectRatio = 1.6;
        } else {
          columns = 6;
          aspectRatio = 1.5;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// A responsive list/grid that shows as list on mobile and grid on larger screens
class ResponsiveListGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;

  const ResponsiveListGrid({
    super.key,
    required this.children,
    this.minItemWidth = 300,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // On mobile, show as list
        if (width < Breakpoints.mobile) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: EdgeInsets.only(bottom: runSpacing),
                    child: child,
                  ),
                )
                .toList(),
          );
        }

        // On larger screens, use wrap for flexible grid
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            // Calculate item width based on available space
            final columns = (width / minItemWidth).floor().clamp(1, 4);
            final itemWidth = (width - (spacing * (columns - 1))) / columns;

            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }
}

/// A two-column layout for larger screens, single column on mobile
class ResponsiveTwoColumn extends StatelessWidget {
  final Widget leftColumn;
  final Widget rightColumn;
  final double leftFlex;
  final double rightFlex;
  final double spacing;

  const ResponsiveTwoColumn({
    super.key,
    required this.leftColumn,
    required this.rightColumn,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.spacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Stack vertically on smaller screens
        if (constraints.maxWidth < Breakpoints.tablet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftColumn,
              SizedBox(height: spacing),
              rightColumn,
            ],
          );
        }

        // Side by side on larger screens
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex.toInt(), child: leftColumn),
            SizedBox(width: spacing),
            Expanded(flex: rightFlex.toInt(), child: rightColumn),
          ],
        );
      },
    );
  }
}

/// A widget that shows different content based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? widescreen;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.widescreen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= Breakpoints.desktop && widescreen != null) {
          return widescreen!;
        }
        if (width >= Breakpoints.tablet && desktop != null) {
          return desktop!;
        }
        if (width >= Breakpoints.mobile && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}
