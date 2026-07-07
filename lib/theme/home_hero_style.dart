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
