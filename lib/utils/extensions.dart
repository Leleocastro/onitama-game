import 'package:flutter/material.dart';

extension SpaceXY on double {
  SizedBox get spaceX => SizedBox(width: this);
  SizedBox get spaceY => SizedBox(height: this);
}

extension SizeWH on BuildContext {
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  double get safeAreaTopPadding => MediaQuery.of(this).padding.top;
  double get additionalTop => safeAreaTopPadding > 25 ? 25 : safeAreaTopPadding;
  double get insetsBottom => MediaQuery.of(this).viewInsets.bottom;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
}
