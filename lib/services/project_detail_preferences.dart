import 'package:shared_preferences/shared_preferences.dart';

/// Estado de UI do detalhe do projeto (seções recolhidas, concluídas expandidas).
class ProjectDetailPreferences {
  static String collapsedSectionsKey(String projectId) =>
      'proj_detail_collapsed_sections_$projectId';

  static String completedExpandedKey(String projectId) =>
      'proj_detail_completed_expanded_$projectId';

  static Future<Set<String>> collapsedSectionIds(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(collapsedSectionsKey(projectId)) ?? []).toSet();
  }

  static Future<void> setCollapsedSectionIds(
    Set<String> ids,
    String projectId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(collapsedSectionsKey(projectId), ids.toList());
  }

  static Future<bool> completedExpanded(
    String projectId, {
    bool defaultValue = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(completedExpandedKey(projectId)) ?? defaultValue;
  }

  static Future<void> setCompletedExpanded(bool value, String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(completedExpandedKey(projectId), value);
  }
}
