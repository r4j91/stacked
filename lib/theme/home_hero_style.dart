import 'package:shared_preferences/shared_preferences.dart';

enum HomeHeroStyle {
  classic,
  orbital,
  orbitalOpen,
  horizon,
  capsule,
  openType,
  focus;

  String get storageValue => name;

  String get displayName => switch (this) {
    HomeHeroStyle.classic => 'Clássico',
    HomeHeroStyle.orbital => 'Orbital',
    HomeHeroStyle.orbitalOpen => 'Orbital aberto',
    HomeHeroStyle.horizon => 'Horizonte',
    HomeHeroStyle.capsule => 'Cápsula',
    HomeHeroStyle.openType => 'Aberto',
    HomeHeroStyle.focus => 'Foco',
  };

  String get subtitle => switch (this) {
    HomeHeroStyle.classic => 'Saudação e status como hoje',
    HomeHeroStyle.orbital => 'Stack com halo animado',
    HomeHeroStyle.orbitalOpen => 'Mesma arte, sem o card',
    HomeHeroStyle.horizon => 'Mini horizonte por hora do dia',
    HomeHeroStyle.capsule => 'Status em cápsula no topo',
    HomeHeroStyle.openType => 'Tipografia direta no fundo',
    HomeHeroStyle.focus => 'Status direto com bandeja',
  };

  static HomeHeroStyle fromStorage(String? raw) {
    return HomeHeroStyle.values.firstWhere(
      (s) => s.storageValue == raw,
      orElse: () => HomeHeroStyle.classic,
    );
  }
}

/// Escala tipográfica e de arte do hero — clássico não usa (mantém tokens próprios).
class HomeHeroMetrics {
  final double phraseSize;
  final double nameSize;
  final double statusSize;
  final double orbitalArtSize;
  final double cardPaddingH;
  final double cardPaddingV;
  final double rowSpacing;
  final double focusTitleSize;
  final double focusSubtitleSize;
  final double capsuleStatusSize;
  final double openVerticalPadding;
  final double dividerTopPadding;

  const HomeHeroMetrics({
    required this.phraseSize,
    required this.nameSize,
    required this.statusSize,
    required this.orbitalArtSize,
    required this.cardPaddingH,
    required this.cardPaddingV,
    required this.rowSpacing,
    required this.focusTitleSize,
    required this.focusSubtitleSize,
    required this.capsuleStatusSize,
    required this.openVerticalPadding,
    required this.dividerTopPadding,
  });

  static HomeHeroMetrics forStyle(HomeHeroStyle style) {
    return switch (style) {
      HomeHeroStyle.orbitalOpen => const HomeHeroMetrics(
        phraseSize: 14,
        nameSize: 26,
        statusSize: 14,
        orbitalArtSize: 56,
        cardPaddingH: 14,
        cardPaddingV: 12,
        rowSpacing: 14,
        focusTitleSize: 16,
        focusSubtitleSize: 13,
        capsuleStatusSize: 11,
        openVerticalPadding: 6,
        dividerTopPadding: 12,
      ),
      HomeHeroStyle.orbital || HomeHeroStyle.horizon => const HomeHeroMetrics(
        phraseSize: 13,
        nameSize: 22,
        statusSize: 13.5,
        orbitalArtSize: 52,
        cardPaddingH: 14,
        cardPaddingV: 12,
        rowSpacing: 14,
        focusTitleSize: 16,
        focusSubtitleSize: 13,
        capsuleStatusSize: 11,
        openVerticalPadding: 4,
        dividerTopPadding: 10,
      ),
      HomeHeroStyle.capsule => const HomeHeroMetrics(
        phraseSize: 13,
        nameSize: 25,
        statusSize: 13.5,
        orbitalArtSize: 48,
        cardPaddingH: 15,
        cardPaddingV: 13,
        rowSpacing: 14,
        focusTitleSize: 16,
        focusSubtitleSize: 13,
        capsuleStatusSize: 11,
        openVerticalPadding: 4,
        dividerTopPadding: 10,
      ),
      HomeHeroStyle.openType => const HomeHeroMetrics(
        phraseSize: 13,
        nameSize: 26,
        statusSize: 13.5,
        orbitalArtSize: 48,
        cardPaddingH: 14,
        cardPaddingV: 12,
        rowSpacing: 14,
        focusTitleSize: 16,
        focusSubtitleSize: 13,
        capsuleStatusSize: 11,
        openVerticalPadding: 6,
        dividerTopPadding: 10,
      ),
      HomeHeroStyle.focus => const HomeHeroMetrics(
        phraseSize: 13,
        nameSize: 22,
        statusSize: 13.5,
        orbitalArtSize: 48,
        cardPaddingH: 13,
        cardPaddingV: 11,
        rowSpacing: 12,
        focusTitleSize: 16,
        focusSubtitleSize: 13,
        capsuleStatusSize: 11,
        openVerticalPadding: 4,
        dividerTopPadding: 10,
      ),
      HomeHeroStyle.classic => const HomeHeroMetrics(
        phraseSize: 12,
        nameSize: 20,
        statusSize: 12.5,
        orbitalArtSize: 48,
        cardPaddingH: 13,
        cardPaddingV: 11,
        rowSpacing: 12,
        focusTitleSize: 15,
        focusSubtitleSize: 12,
        capsuleStatusSize: 10,
        openVerticalPadding: 4,
        dividerTopPadding: 10,
      ),
    };
  }
}

enum HomeTimeOfDay { morning, afternoon, night }

HomeTimeOfDay homeTimeOfDayNow() {
  final hour = DateTime.now().hour;
  if (hour < 12) return HomeTimeOfDay.morning;
  if (hour < 18) return HomeTimeOfDay.afternoon;
  return HomeTimeOfDay.night;
}

String homeGreetingPhrase() {
  return switch (homeTimeOfDayNow()) {
    HomeTimeOfDay.morning => 'Bom dia,',
    HomeTimeOfDay.afternoon => 'Boa tarde,',
    HomeTimeOfDay.night => 'Boa noite,',
  };
}

String homeGreetingLine(String firstName) {
  final phrase = homeGreetingPhrase();
  final base = phrase.substring(0, phrase.length - 1);
  return firstName.isNotEmpty ? '$base, $firstName' : base;
}

String homeStatusLabel(int overdueCount) {
  if (overdueCount == 1) return '1 tarefa atrasada';
  if (overdueCount > 1) return '$overdueCount tarefas atrasadas';
  return 'Tudo em dia';
}

String homeFocusHeroTitle(int overdueCount) {
  return overdueCount > 0 ? 'Você tem pendências' : 'Tudo certo!';
}

String homeFocusHeroSubtitle(int overdueCount) {
  if (overdueCount == 1) return '1 tarefa atrasada precisa da sua atenção.';
  if (overdueCount > 1) return '$overdueCount tarefas atrasadas precisam da sua atenção.';
  return 'Você está em dia com tudo.';
}

class HomeHeroStyleStorage {
  static const key = 'homeHeroStyle';

  static Future<HomeHeroStyle> load() async {
    final prefs = await SharedPreferences.getInstance();
    return HomeHeroStyle.fromStorage(prefs.getString(key));
  }

  static Future<void> save(HomeHeroStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, style.storageValue);
  }
}
