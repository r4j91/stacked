import 'package:flutter/material.dart';

/// Respects the platform "Reduce motion" accessibility setting.
class AppMotion {
  AppMotion._();

  static bool enabled(BuildContext context) =>
      !MediaQuery.disableAnimationsOf(context);

  static Duration duration(BuildContext context, Duration normal) =>
      enabled(context) ? normal : Duration.zero;

  static Duration milliseconds(BuildContext context, int ms) =>
      duration(context, Duration(milliseconds: ms));

}
