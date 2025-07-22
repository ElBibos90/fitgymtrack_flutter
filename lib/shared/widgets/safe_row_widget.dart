import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget helper per creare Row che gestiscono automaticamente l'overflow
class SafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final Clip clipBehavior;
  final double? spacing;
  final bool wrapIfNeeded;

  const SafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.clipBehavior = Clip.hardEdge,
    this.spacing,
    this.wrapIfNeeded = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!wrapIfNeeded) {
      return Row(
        children: _buildChildrenWithSpacing(),
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        clipBehavior: clipBehavior,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildResponsiveRow(constraints.maxWidth);
      },
    );
  }

  Widget _buildResponsiveRow(double maxWidth) {
    // Se c'è abbastanza spazio, usa una Row normale
    if (_canFitInRow(maxWidth)) {
      return Row(
        children: _buildChildrenWithSpacing(),
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        clipBehavior: clipBehavior,
      );
    }

    // Altrimenti, usa Wrap per andare a capo
    return Wrap(
      spacing: spacing ?? 8.w,
      runSpacing: 4.h,
      alignment: _convertMainAxisAlignment(),
      crossAxisAlignment: _convertCrossAxisAlignment(),
      children: children,
    );
  }

  List<Widget> _buildChildrenWithSpacing() {
    if (spacing == null) return children;

    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(width: spacing!));
      }
    }
    return spacedChildren;
  }

  bool _canFitInRow(double maxWidth) {
    // Stima approssimativa se i widget possono stare in una riga
    // Questa è una stima conservativa
    double estimatedWidth = 0;
    for (final child in children) {
      if (child is SizedBox && child.width != null) {
        estimatedWidth += child.width!;
      } else if (child is Container && child.width != null) {
        estimatedWidth += child.width!;
      } else {
        // Stima conservativa per widget di testo e altri
        estimatedWidth += 100.w;
      }
      
      if (spacing != null) {
        estimatedWidth += spacing!;
      }
    }

    return estimatedWidth <= maxWidth;
  }

  WrapAlignment _convertMainAxisAlignment() {
    switch (mainAxisAlignment) {
      case MainAxisAlignment.start:
        return WrapAlignment.start;
      case MainAxisAlignment.end:
        return WrapAlignment.end;
      case MainAxisAlignment.center:
        return WrapAlignment.center;
      case MainAxisAlignment.spaceBetween:
        return WrapAlignment.spaceBetween;
      case MainAxisAlignment.spaceAround:
        return WrapAlignment.spaceAround;
      case MainAxisAlignment.spaceEvenly:
        return WrapAlignment.spaceEvenly;
    }
  }

  WrapCrossAlignment _convertCrossAxisAlignment() {
    switch (crossAxisAlignment) {
      case CrossAxisAlignment.start:
        return WrapCrossAlignment.start;
      case CrossAxisAlignment.end:
        return WrapCrossAlignment.end;
      case CrossAxisAlignment.center:
        return WrapCrossAlignment.center;
      case CrossAxisAlignment.stretch:
        return WrapCrossAlignment.center; // Wrap non supporta stretch
      case CrossAxisAlignment.baseline:
        return WrapCrossAlignment.center; // Wrap non supporta baseline
    }
  }
} 