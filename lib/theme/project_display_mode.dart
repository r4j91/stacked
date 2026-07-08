/// Modos de exibição no detalhe de projeto (`display_mode` em SharedPreferences).
enum ProjectDisplayMode {
  cards,
  cardsRefined,
  list;

  String get storageValue => name;

  String get label => switch (this) {
    ProjectDisplayMode.cards => 'Balões',
    ProjectDisplayMode.cardsRefined => 'Balões+',
    ProjectDisplayMode.list => 'Lista',
  };

  String get subtitle => switch (this) {
    ProjectDisplayMode.cards => 'Cards com painel de subtarefas',
    ProjectDisplayMode.cardsRefined => 'Card sem painel escuro',
    ProjectDisplayMode.list => 'Lista plana com indent',
  };

  bool get usesCardTile => this == cards || this == cardsRefined;

  bool get flatSubtaskPanel => this == cardsRefined;

  static ProjectDisplayMode fromStorage(String? raw) {
    return switch (raw) {
      'list' || 'listRefined' => ProjectDisplayMode.list,
      'cardsRefined' => ProjectDisplayMode.cardsRefined,
      'cards' => ProjectDisplayMode.cards,
      // modos removidos → fallback sensato
      'folders' || 'hybrid' => ProjectDisplayMode.cards,
      _ => ProjectDisplayMode.cards,
    };
  }
}
