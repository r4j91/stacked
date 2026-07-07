import 'package:flutter/material.dart';
import '../theme/home_hero_style.dart';

class HomeHeroStyleProvider extends ChangeNotifier {
  HomeHeroStyleProvider._();
  static final HomeHeroStyleProvider instance = HomeHeroStyleProvider._();

  HomeHeroStyle _style = HomeHeroStyle.classic;
  HomeHeroStyle get style => _style;

  Future<void> loadSaved() async {
    _style = await HomeHeroStyleStorage.load();
  }

  Future<void> setStyle(HomeHeroStyle style) async {
    if (_style == style) return;
    _style = style;
    notifyListeners();
    await HomeHeroStyleStorage.save(style);
  }
}
