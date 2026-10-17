import 'package:flutter/widgets.dart';

enum ScreenType { mobile, tablet, desktop }

/// Points de rupture pour l'adaptation mobile / tablette / web.
class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 760;
  static const double desktopBreakpoint = 1180;
  static const double maxContentWidth = 1240;

  static ScreenType of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return ScreenType.desktop;
    if (width >= tabletBreakpoint) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == ScreenType.mobile;

  static bool isTablet(BuildContext context) =>
      of(context) == ScreenType.tablet;

  static bool isDesktop(BuildContext context) =>
      of(context) == ScreenType.desktop;

  /// Vrai dès que l'on quitte la mise en page « téléphone ».
  static bool isWide(BuildContext context) => !isMobile(context);

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (of(context)) {
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.mobile:
        return mobile;
    }
  }

  static int gridColumns(BuildContext context) =>
      value(context, mobile: 1, tablet: 2, desktop: 3);

  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
  );
}

/// Centre et limite la largeur du contenu sur grand écran.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
