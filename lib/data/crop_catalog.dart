// 🌱 Каталог культур «СадовникPRO».
// Агрономические факты (глубина, схема, пороги почвы, сроки) не охраняются
// авторским правом; тексты написаны нами. Данные требуют сверки с местными
// рекомендациями перед публикацией. Нормы полива считает irrigation.dart.
//
// Сроки задаются СМЕЩЕНИЕМ от даты последних весенних заморозков —
// это позволяет работать в любом регионе без переписывания календаря.
//
// ВАЖНО О ПОРОГАХ ТЕМПЕРАТУРЫ:
// - germinationTemp: минимум почвы для ПРОРАСТАНИЯ семян (для рассады)
// - plantingTemp: минимум почвы для ВЫСАДКИ рассады или ПОСЕВА в грунт
// Это два разных значения! Например, томаты прорастают при +23 °C,
// но рассаду высаживают когда почва прогреется до +14 °C.

enum CropCategory { vegetable, root, green, legume, cucurbit, perennial, spice }

enum CropFamily {
  solanaceae,
  cucurbitaceae,
  brassicaceae,
  apiaceae,
  amaryllidaceae,
  fabaceae,
  asteraceae,
  amaranthaceae,
  poaceae,
  polygonaceae,
  lamiaceae,
  rosaceae,
}

enum FrostTolerance { tender, halfHardy, hardy, veryHardy }

class ProblemSpec {
  final String name;
  final bool disease;
  final int danger;
  final String symptoms;
  final List<String> treatment;
  final List<String> prevention;
  const ProblemSpec(this.name, this.disease, this.danger, this.symptoms,
      this.treatment, this.prevention);
}

class RegionClimate {
  final String name;
  final int lastFrostMonth, lastFrostDay;
  final int firstFrostMonth, firstFrostDay;
  const RegionClimate(this.name, this.lastFrostMonth, this.lastFrostDay,
      this.firstFrostMonth, this.firstFrostDay);

  DateTime lastFrost(int y) => DateTime(y, lastFrostMonth, lastFrostDay);
  DateTime firstFrost(int y) => DateTime(y, firstFrostMonth, firstFrostDay);
  String get lastFrostText => '$lastFrostDay.$lastFrostMonth';
}

class CropRecord {
  final String id;
  final String name;
  final String emoji;
  final CropCategory category;
  final CropFamily family;
  final String desc;
  final List<String> aliases;

  final double sowDepth; // см
  final int spacing; // см между растениями
  final int rows; // см между рядами
  final int germinationTemp; // °C, минимум для прорастания семян
  final int plantingTemp; // °C, минимум почвы для посадки/высадки в грунт
  final int
      maturity; // дней до уборки (от высадки для рассадных, от посева для грунтовых)
  final int waterDays; // НЕ ИСПОЛЬЗУЕТСЯ: полив считает irrigation.dart
  final String waterAmount; // НЕ ИСПОЛЬЗУЕТСЯ: полив считает irrigation.dart
  final FrostTolerance frost;
  final int
      sowOffset; // дней от последних заморозков (первое окно посева/посадки)
  final int?
      secondSowOffset; // дней от последних заморозков (второе окно посева, если есть)
  final int transplantOffset; // дней от заморозков (высадка рассады)
  final int seedlingDays; // возраст рассады, 0 = без рассады
  final bool greenhouse;
  final bool winterSow;
  final String light;
  final String soil;
  final List<String> tips;
  final String? careKey;
  final List<ProblemSpec> extra;

  const CropRecord({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.family,
    required this.desc,
    required this.sowDepth,
    required this.spacing,
    required this.rows,
    required this.germinationTemp,
    required this.plantingTemp,
    required this.maturity,
    required this.waterDays,
    required this.waterAmount,
    required this.frost,
    required this.sowOffset,
    required this.soil,
    required this.tips,
    this.secondSowOffset,
    this.aliases = const [],
    this.transplantOffset = 0,
    this.seedlingDays = 0,
    this.greenhouse = false,
    this.winterSow = false,
    this.light = 'Солнце 6+ часов',
    this.careKey,
    this.extra = const [],
  });

  bool get isRoot =>
      category == CropCategory.root ||
      category == CropCategory.perennial && family == CropFamily.polygonaceae;

  bool get hasSeedling => seedlingDays > 0;

  String get scheme => '$spacing × $rows см';

  String get frostText {
    switch (frost) {
      case FrostTolerance.tender:
        return 'Не переносит заморозков (погибает при 0…−1 °C)';
      case FrostTolerance.halfHardy:
        return 'Выдерживает лёгкие заморозки до −2…−3 °C';
      case FrostTolerance.hardy:
        return 'Холодостойкая: до −4…−6 °C';
      case FrostTolerance.veryHardy:
        return 'Зимостойкая: переносит морозы под снегом';
    }
  }

  bool matches(String query) {
    final q = query.toLowerCase().replaceAll('ё', 'е');
    if (name.toLowerCase().replaceAll('ё', 'е').contains(q)) return true;
    for (final a in aliases) {
      if (a.toLowerCase().replaceAll('ё', 'е').contains(q)) return true;
    }
    return false;
  }
}

class CropCatalog {
  static RegionClimate climate = kSamaraClimate;
  static const RegionClimate kSamaraClimate =
      RegionClimate('Самарская область', 5, 15, 9, 28);

  // ДОБАВЬТЕ ЭТОТ МЕТОД:
  static CropRecord? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static CropRecord? byName(String name) {
    final n = name.toLowerCase().replaceAll('ё', 'е').trim();
    for (final r in all) {
      if (r.name.toLowerCase().replaceAll('ё', 'е') == n) return r;
    }
    for (final r in all) {
      if (r.matches(n)) return r;
    }
    return null;
  }

  static List<CropRecord> byCategory(CropCategory c) =>
      all.where((r) => r.category == c).toList();

  static String categoryTitle(CropCategory c) {
    switch (c) {
      case CropCategory.vegetable:
        return 'Овощные';
      case CropCategory.root:
        return 'Корнеплоды';
      case CropCategory.green:
        return 'Зелень и листовые';
      case CropCategory.legume:
        return 'Бобовые';
      case CropCategory.cucurbit:
        return 'Тыквенные';
      case CropCategory.perennial:
        return 'Многолетние';
      case CropCategory.spice:
        return 'Пряные травы';
    }
  }

  static String familyTitle(CropFamily f) {
    switch (f) {
      case CropFamily.solanaceae:
        return 'Паслёновые';
      case CropFamily.cucurbitaceae:
        return 'Тыквенные';
      case CropFamily.brassicaceae:
        return 'Капустные';
      case CropFamily.apiaceae:
        return 'Зонтичные';
      case CropFamily.amaryllidaceae:
        return 'Луковые';
      case CropFamily.fabaceae:
        return 'Бобовые';
      case CropFamily.asteraceae:
        return 'Астровые';
      case CropFamily.amaranthaceae:
        return 'Амарантовые';
      case CropFamily.poaceae:
        return 'Злаки';
      case CropFamily.polygonaceae:
        return 'Гречишные';
      case CropFamily.lamiaceae:
        return 'Яснотковые';
      case CropFamily.rosaceae:
        return 'Розоцветные';
    }
  }

  static List<String> rotationAdvice(CropFamily f) => [
        'Не возвращайте ${familyTitle(f).toLowerCase()} на эту грядку 3–4 года.',
        'Хорошие предшественники: бобовые, лук, огурцы, ранняя капуста.',
        'После уборки посейте сидерат: горчицу, овёс или фацелию.',
      ];

  static const List<CropRecord> all = [
    // ================= ПАСЛЁНОВЫЕ =================
    CropRecord(
      id: 'tomato',
      name: 'Помидоры',
      emoji: '🍅',
      category: CropCategory.vegetable,
      family: CropFamily.solanaceae,
      desc:
          'Главная культура теплиц и открытого грунта. Требует формирования и защиты от фитофтороза.',
      aliases: ['томат', 'томаты', 'черри'],
      sowDepth: 1.0,
      spacing: 45,
      rows: 65,
      germinationTemp: 23,
      plantingTemp: 14,
      maturity: 110,
      waterDays: 4,
      waterAmount: '3–5 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 18,
      transplantOffset: 14,
      seedlingDays: 55,
      greenhouse: true,
      careKey: 'помидор',
      soil: 'Рыхлая, плодородная, pH 6,0–6,8. Свежий навоз запрещён.',
      tips: [
        'Пасынкуйте раз в неделю.',
        'Подвязывайте сразу после высадки.',
        'Мульча 5–7 см держит влажность стабильной.',
        'Проветривайте теплицу ежедневно.'
      ],
    ),
    CropRecord(
      id: 'pepper',
      name: 'Перец',
      emoji: '🫑',
      category: CropCategory.vegetable,
      family: CropFamily.solanaceae,
      desc:
          'Теплолюбивый, с поверхностными корнями. Не терпит пересыхания и жары выше +32 °C.',
      aliases: ['перец сладкий', 'болгарский'],
      sowDepth: 1.0,
      spacing: 35,
      rows: 60,
      germinationTemp: 26,
      plantingTemp: 15,
      maturity: 120,
      waterDays: 3,
      waterAmount: '2–3 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 21,
      transplantOffset: 18,
      seedlingDays: 65,
      greenhouse: true,
      careKey: 'перц',
      soil: 'Лёгкая, плодородная, нейтральная. Рыхлить не глубже 3–5 см.',
      tips: [
        'Удалите первый коронный бутон.',
        'Подвяжите — ветки хрупкие.',
        'В жару притеняйте: пыльца стерильна.'
      ],
    ),
    CropRecord(
      id: 'hotpepper',
      name: 'Перец острый',
      emoji: '🌶️',
      category: CropCategory.spice,
      family: CropFamily.solanaceae,
      desc:
          'Жгучий перец. Выращивается через рассаду, отлично растёт в горшке на балконе.',
      aliases: ['чили', 'горький перец'],
      sowDepth: 1.0,
      spacing: 30,
      rows: 50,
      germinationTemp: 26,
      plantingTemp: 16,
      maturity: 130,
      waterDays: 3,
      waterAmount: '1,5–2 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 24,
      transplantOffset: 21,
      seedlingDays: 70,
      greenhouse: true,
      soil: 'Лёгкая, дренированная, нейтральная. Не любит переувлажнения.',
      tips: [
        'Не сажайте рядом со сладким перцем — переопыление даст горечь.',
        'Собирайте в перчатках.',
        'Осенью куст можно перенести в дом на зиму.'
      ],
    ),
    CropRecord(
      id: 'eggplant',
      name: 'Баклажаны',
      emoji: '🍆',
      category: CropCategory.vegetable,
      family: CropFamily.solanaceae,
      desc:
          'Самый теплолюбивый из паслёновых. Ниже +15 °C останавливается в росте.',
      aliases: ['баклажан'],
      sowDepth: 1.5,
      spacing: 40,
      rows: 65,
      germinationTemp: 26,
      plantingTemp: 16,
      maturity: 125,
      waterDays: 3,
      waterAmount: '3–4 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 24,
      transplantOffset: 20,
      seedlingDays: 65,
      greenhouse: true,
      careKey: 'баклажан',
      soil: 'Плодородная, лёгкая, нейтральная. Любит перепревшую органику.',
      tips: [
        'Формируйте в 2–3 стебля.',
        'Оставляйте 5–7 плодов на куст.',
        'Снимайте, пока кожица глянцевая.'
      ],
    ),
    CropRecord(
      id: 'potato',
      name: 'Картофель',
      emoji: '🥔',
      category: CropCategory.root,
      family: CropFamily.solanaceae,
      desc:
          'Клубневая культура. Критичны полив в бутонизацию и высокое окучивание.',
      aliases: ['картошка'],
      sowDepth: 8.0,
      spacing: 35,
      rows: 70,
      germinationTemp: 10,
      plantingTemp: 8,
      maturity: 95,
      waterDays: 7,
      waterAmount: '30–40 л на м² в засуху',
      frost: FrostTolerance.halfHardy,
      sowOffset: -5,
      careKey: 'картоф',
      soil: 'Рыхлая, воздухопроницаемая, слабокислая. Любит перегной и золу.',
      tips: [
        'Окучивайте дважды.',
        'Проращивайте клубни 2–3 недели на свету.',
        'Скосите ботву за неделю до копки.'
      ],
    ),
    CropRecord(
      id: 'physalis',
      name: 'Физалис',
      emoji: '🏮',
      category: CropCategory.vegetable,
      family: CropFamily.solanaceae,
      desc:
          'Овощной физалис в фонарике. Неприхотлив, урожай стабилен даже в прохладное лето.',
      aliases: ['мексиканский томат'],
      sowDepth: 1.0,
      spacing: 40,
      rows: 60,
      germinationTemp: 21,
      plantingTemp: 14,
      maturity: 115,
      waterDays: 5,
      waterAmount: '2–3 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 14,
      transplantOffset: 12,
      seedlingDays: 45,
      soil: 'Неприхотлив, но лучше рыхлая нейтральная почва без застоя воды.',
      tips: [
        'Опоры обычно не нужны — куст полегающий.',
        'Плоды готовы, когда фонарик подсох и порвался.',
        'Хранится в сухом месте до 2 месяцев.'
      ],
    ),

    // ================= ТЫКВЕННЫЕ =================
    CropRecord(
      id: 'cucumber',
      name: 'Огурцы',
      emoji: '🥒',
      category: CropCategory.cucurbit,
      family: CropFamily.cucurbitaceae,
      desc:
          'Водолюбивая культура. Только тёплый полив, иначе гнили и горечь плодов.',
      aliases: ['огурец'],
      sowDepth: 2.0,
      spacing: 30,
      rows: 60,
      germinationTemp: 19,
      plantingTemp: 16,
      maturity: 50,
      waterDays: 2,
      waterAmount: '5–10 л на м²',
      frost: FrostTolerance.tender,
      sowOffset: 16,
      transplantOffset: 12,
      seedlingDays: 25,
      greenhouse: true,
      careKey: 'огурц',
      soil: 'Лёгкая, богатая органикой, воздухопроницаемая. Любит компост.',
      tips: [
        'Ведите на шпалере вертикально.',
        'Снимайте плоды каждые 1–2 дня.',
        'Полив только водой +22…25 °C.'
      ],
    ),
    CropRecord(
      id: 'zucchini',
      name: 'Кабачки',
      emoji: '🥬',
      category: CropCategory.cucurbit,
      family: CropFamily.cucurbitaceae,
      desc: 'Самая урожайная тыквенная культура. Снимать плоды нужно молодыми.',
      aliases: ['цукини'],
      sowDepth: 3.0,
      spacing: 70,
      rows: 90,
      germinationTemp: 16,
      plantingTemp: 14,
      maturity: 50,
      waterDays: 4,
      waterAmount: '10 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 16,
      transplantOffset: 12,
      seedlingDays: 25,
      careKey: 'кабачк',
      soil: 'Лёгкая, плодородная. Отлично растёт на компостной куче.',
      tips: [
        'Снимайте при длине 15–25 см.',
        'Один куст на м².',
        'В холодное лето опыляйте вручную.'
      ],
    ),
    CropRecord(
      id: 'patisson',
      name: 'Патиссоны',
      emoji: '🛸',
      category: CropCategory.cucurbit,
      family: CropFamily.cucurbitaceae,
      desc:
          'Тарельчатая тыква. Компактный куст, плоды идеальны для консервации.',
      aliases: ['тарельчатая тыква'],
      sowDepth: 3.0,
      spacing: 60,
      rows: 80,
      germinationTemp: 16,
      plantingTemp: 14,
      maturity: 55,
      waterDays: 4,
      waterAmount: '8–10 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 16,
      transplantOffset: 12,
      seedlingDays: 25,
      soil: 'Плодородная, рыхлая, нейтральная. Отзывчив на органику.',
      tips: [
        'Снимайте при диаметре 5–8 см — самые нежные.',
        'Мульчируйте, чтобы плоды не лежали на земле.',
        'Хранятся до 2 месяцев в прохладе.'
      ],
    ),
    CropRecord(
      id: 'pumpkin',
      name: 'Тыква',
      emoji: '🎃',
      category: CropCategory.cucurbit,
      family: CropFamily.cucurbitaceae,
      desc:
          'Мощные плети, крупные плоды. Требует площади и калийных подкормок.',
      aliases: ['тыкву'],
      sowDepth: 4.0,
      spacing: 100,
      rows: 150,
      germinationTemp: 15,
      plantingTemp: 14,
      maturity: 120,
      waterDays: 5,
      waterAmount: '10–20 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 16,
      transplantOffset: 12,
      seedlingDays: 25,
      careKey: 'тыкв',
      soil: 'Очень плодородная, рыхлая. Идеально — компостная куча.',
      tips: [
        'Прищипните плеть после 2–3 плодов.',
        'Подложите дощечку под плод.',
        'Дозаривайте 2 недели в тепле — станет слаще.'
      ],
    ),
    CropRecord(
      id: 'melon',
      name: 'Дыня',
      emoji: '🍈',
      category: CropCategory.cucurbit,
      family: CropFamily.cucurbitaceae,
      desc:
          'Требует тепла и сухого воздуха в период налива. В средней полосе — через теплицу.',
      aliases: ['дыню'],
      sowDepth: 3.0,
      spacing: 70,
      rows: 100,
      germinationTemp: 17,
      plantingTemp: 16,
      maturity: 100,
      waterDays: 4,
      waterAmount: '8–10 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 22,
      transplantOffset: 18,
      seedlingDays: 30,
      greenhouse: true,
      soil: 'Лёгкая, песчаная, нейтральная, хорошо прогреваемая.',
      tips: [
        'За 2 недели до уборки полив прекратите — иначе несладкая.',
        'Подвешивайте плоды в сетку в теплице.',
        'Оставляйте 2–3 плода на растение.'
      ],
    ),
    CropRecord(
      id: 'watermelon',
      name: 'Арбуз',
      emoji: '🍉',
      category: CropCategory.cucurbit,
      family: CropFamily.cucurbitaceae,
      desc:
          'Самая теплолюбивая тыквенная. Нужны ранние сорта и прививка на лагенарию в холодных регионах.',
      aliases: ['арбузы'],
      sowDepth: 3.0,
      spacing: 80,
      rows: 120,
      germinationTemp: 19,
      plantingTemp: 18,
      maturity: 95,
      waterDays: 4,
      waterAmount: '10–15 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 25,
      transplantOffset: 20,
      seedlingDays: 30,
      greenhouse: true,
      soil: 'Песчаная, лёгкая, нейтральная. Не переносит кислых и сырых почв.',
      tips: [
        'Только ранние сорта в средней полосе.',
        'Полив прекратите за 3 недели до уборки.',
        'Оставляйте 1–2 плода на плеть.'
      ],
    ),
    CropRecord(
      id: 'luffa',
      name: 'Лагенария',
      emoji: '🍐',
      category: CropCategory.cucurbit,
      family: CropFamily.cucurbitaceae,
      desc:
          'Бутылочная тыква / горлянка. Молодые плоды съедобны, зрелые идут на поделки.',
      aliases: ['горлянку', 'бутылочную тыкву', 'кабачок-бутылку'],
      sowDepth: 3.0,
      spacing: 80,
      rows: 120,
      germinationTemp: 19,
      plantingTemp: 16,
      maturity: 130,
      waterDays: 4,
      waterAmount: '10–15 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 22,
      transplantOffset: 18,
      seedlingDays: 35,
      greenhouse: true,
      soil: 'Очень плодородная, рыхлая. Любит компостную кучу.',
      tips: [
        'Молодые плоды едят как кабачки.',
        'Для поделок оставляйте до полного созревания.',
        'Нужна опора — плети длинные.',
        'Опыляйте вручную в холодное лето.'
      ],
    ),

    // ================= КАПУСТНЫЕ =================
    CropRecord(
      id: 'cabbage',
      name: 'Капуста',
      emoji: '🥬',
      category: CropCategory.vegetable,
      family: CropFamily.brassicaceae,
      desc:
          'Белокочанная. Водохлёб, требует нейтральной почвы — на кислой поражается килой.',
      aliases: ['белокочанная', 'капусту'],
      sowDepth: 1.0,
      spacing: 50,
      rows: 70,
      germinationTemp: 7,
      plantingTemp: 6,
      maturity: 130,
      waterDays: 4,
      waterAmount: '10–15 л под растение',
      frost: FrostTolerance.hardy,
      sowOffset: -12,
      transplantOffset: -8,
      seedlingDays: 45,
      careKey: 'капуст',
      soil: 'Плодородная, влагоёмкая, нейтральная. Кислые почвы = кила.',
      tips: [
        'Окучивайте для дополнительных корней.',
        'Удаляйте нижние желтеющие листья.',
        'Известкуйте почву с осени.'
      ],
    ),
    CropRecord(
      id: 'cauliflower',
      name: 'Капуста цветная',
      emoji: '🥦',
      category: CropCategory.vegetable,
      family: CropFamily.brassicaceae,
      desc:
          'Головка-соцветие. Требует притенения головки и стабильного полива.',
      aliases: ['цветная капуста'],
      sowDepth: 1.0,
      spacing: 45,
      rows: 65,
      germinationTemp: 7,
      plantingTemp: 6,
      maturity: 100,
      waterDays: 3,
      waterAmount: '8–10 л под растение',
      frost: FrostTolerance.halfHardy,
      sowOffset: -10,
      transplantOffset: -6,
      seedlingDays: 45,
      soil: 'Очень плодородная, нейтральная, влагоёмкая.',
      tips: [
        'Притеняйте головку надломленным листом — иначе пожелтеет.',
        'Не допускайте пересыхания: головка рассыпется.',
        'Срезайте, пока соцветие плотное.'
      ],
    ),
    CropRecord(
      id: 'broccoli',
      name: 'Брокколи',
      emoji: '🥦',
      category: CropCategory.vegetable,
      family: CropFamily.brassicaceae,
      desc: 'Спаржевая капуста. После срезки центральной головки даёт боковые.',
      aliases: ['спаржевая капуста'],
      sowDepth: 1.0,
      spacing: 40,
      rows: 60,
      germinationTemp: 7,
      plantingTemp: 6,
      maturity: 85,
      waterDays: 3,
      waterAmount: '8–10 л под растение',
      frost: FrostTolerance.halfHardy,
      sowOffset: -10,
      transplantOffset: -6,
      seedlingDays: 40,
      soil: 'Плодородная, нейтральная, с хорошим дренажом.',
      tips: [
        'Срезайте головку до распускания бутонов.',
        'После срезки оставьте куст — даст 3–5 боковых головок.',
        'Осенний урожай вкуснее летнего.'
      ],
    ),
    CropRecord(
      id: 'brusselsprouts',
      name: 'Брюссельская капуста',
      emoji: '🥬',
      category: CropCategory.vegetable,
      family: CropFamily.brassicaceae,
      desc:
          'Морозостойкая капуста с мелкими кочанчиками на высоком стебле. Вкуснее после первых заморозков.',
      aliases: ['брюссельская'],
      sowDepth: 1.0,
      spacing: 60,
      rows: 70,
      germinationTemp: 7,
      plantingTemp: 6,
      maturity: 130,
      waterDays: 4,
      waterAmount: '10–15 л под растение',
      frost: FrostTolerance.veryHardy,
      sowOffset: -14,
      transplantOffset: -10,
      seedlingDays: 45,
      soil: 'Плодородная, влагоёмкая, нейтральная. Кислые почвы = кила.',
      tips: [
        'Окучивайте стебель для дополнительных корней.',
        'Прищипните верхушку за месяц до уборки.',
        'Убирайте после первых заморозков — кочанчики слаще.',
        'Подвяжите высокий стебель к опоре.',
        'Не сажайте после редиса и редьки.'
      ],
    ),
    CropRecord(
      id: 'peking',
      name: 'Капуста пекинская',
      emoji: '🥬',
      category: CropCategory.green,
      family: CropFamily.brassicaceae,
      desc:
          'Скороспелая листовая. Стрелкуется при длинном дне — основное окно летом.',
      aliases: ['петсай', 'пекинка'],
      sowDepth: 1.0,
      spacing: 30,
      rows: 45,
      germinationTemp: 7,
      plantingTemp: 6,
      maturity: 60,
      waterDays: 3,
      waterAmount: '6–8 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -14,
      secondSowOffset: 65,
      transplantOffset: -10,
      seedlingDays: 40,
      soil: 'Рыхлая, плодородная, нейтральная.',
      tips: [
        'Весной выращивайте через рассаду.',
        'Основной посев в грунт — после 20 июля, иначе уйдёт в стрелку.',
        'Притеняйте от жары.',
        'Убирайте, когда кочан сомкнут.'
      ],
    ),
    CropRecord(
      id: 'kohlrabi',
      name: 'Кольраби',
      emoji: '🥬',
      category: CropCategory.vegetable,
      family: CropFamily.brassicaceae,
      desc:
          'Стеблеплод. Самая скороспелая капуста, не боится пересадки и засухи.',
      aliases: ['капустная репа'],
      sowDepth: 1.0,
      spacing: 25,
      rows: 40,
      germinationTemp: 7,
      plantingTemp: 6,
      maturity: 65,
      waterDays: 4,
      waterAmount: '6–8 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -14,
      transplantOffset: -8,
      seedlingDays: 35,
      soil: 'Рыхлая, плодородная, нейтральная.',
      tips: [
        'Не заглубляйте стеблеплод при посадке.',
        'Снимайте при диаметре 6–8 см — крупный деревянистый.',
        'Сейте каждые 2 недели до августа.'
      ],
    ),
    CropRecord(
      id: 'radish',
      name: 'Редис',
      emoji: '🔴',
      category: CropCategory.root,
      family: CropFamily.brassicaceae,
      desc:
          'Самый быстрый корнеплод: 20–30 дней. Пересыхание даёт горечь и древесность.',
      aliases: ['редиска'],
      sowDepth: 1.5,
      spacing: 5,
      rows: 15,
      germinationTemp: 5,
      plantingTemp: 5,
      maturity: 25,
      waterDays: 2,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -22,
      secondSowOffset: 85,
      careKey: 'редис',
      soil: 'Рыхлая, нейтральная, богатая перегноем. Без свежего навоза.',
      tips: [
        'Весенний посев — как только сойдёт снег.',
        'Летний посев — в начале августа.',
        'Прореживайте до 3–5 см.',
        'Летом стрелкуется — притеняйте.'
      ],
    ),
    CropRecord(
      id: 'daikon',
      name: 'Дайкон',
      emoji: '🥕',
      category: CropCategory.root,
      family: CropFamily.brassicaceae,
      desc:
          'Японская редька. Крупный корнеплод, посев только во второй половине лета.',
      aliases: ['японская редька', 'лобо'],
      sowDepth: 2.0,
      spacing: 25,
      rows: 45,
      germinationTemp: 6,
      plantingTemp: 6,
      maturity: 70,
      waterDays: 4,
      waterAmount: '10–12 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: 70,
      soil:
          'Глубокая, рыхлая, нейтральная. На плотной почве корнеплод уродливый.',
      tips: [
        'Посев с 20 июля по 10 августа — иначе стрелкуется.',
        'Не прореживайте с повреждением соседних корней.',
        'Хранится в песке до весны.'
      ],
    ),
    CropRecord(
      id: 'turnip',
      name: 'Репа',
      emoji: '🥔',
      category: CropCategory.root,
      family: CropFamily.brassicaceae,
      desc:
          'Скороспелый корнеплод, холодостойкий. Возвращается на грядки как осенняя культура.',
      aliases: ['репка'],
      sowDepth: 1.5,
      spacing: 10,
      rows: 25,
      germinationTemp: 6,
      plantingTemp: 5,
      maturity: 60,
      waterDays: 4,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -18,
      winterSow: true,
      soil: 'Рыхлая, нейтральная, без свежего навоза.',
      tips: [
        'Весенний посев ранний, осенний — в июле.',
        'Прореживайте до 8–10 см.',
        'Убирайте до сильных морозов.'
      ],
    ),

    // ================= ЗОНТИЧНЫЕ =================
    CropRecord(
      id: 'carrot',
      name: 'Морковь',
      emoji: '🥕',
      category: CropCategory.root,
      family: CropFamily.apiaceae,
      desc:
          'Требует глубокой рыхлой почвы. Свежий навоз даёт ветвистые корнеплоды.',
      aliases: ['морковка'],
      sowDepth: 1.0,
      spacing: 5,
      rows: 20,
      germinationTemp: 5,
      plantingTemp: 6,
      maturity: 110,
      waterDays: 6,
      waterAmount: '10–15 л на м²',
      frost: FrostTolerance.halfHardy,
      sowOffset: -18,
      winterSow: true,
      careKey: 'морков',
      soil: 'Глубокая, рыхлая, песчаная или супесчаная. Без свежего навоза.',
      tips: [
        'Прореживайте дважды.',
        'Прореживайте вечером и поливайте — запах привлекает морковную муху.',
        'Окучивайте плечики, чтобы не зеленели.'
      ],
    ),
    CropRecord(
      id: 'parsley',
      name: 'Петрушка',
      emoji: '🌿',
      category: CropCategory.green,
      family: CropFamily.apiaceae,
      desc:
          'Листовая и корневая. Всходит медленно (до 3 недель) из-за эфирных масел.',
      aliases: ['петрушку'],
      sowDepth: 1.0,
      spacing: 8,
      rows: 20,
      germinationTemp: 5,
      plantingTemp: 5,
      maturity: 70,
      waterDays: 3,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -20,
      winterSow: true,
      soil: 'Рыхлая, плодородная, нейтральная. Корневой форме нужна глубокая.',
      tips: [
        'Замочите семена на 2 суток — ускорит всходы.',
        'Срезайте наружные листья, оставляя центр.',
        'Корневую не срезайте на зелень.'
      ],
    ),
    CropRecord(
      id: 'dill',
      name: 'Укроп',
      emoji: '🌿',
      category: CropCategory.green,
      family: CropFamily.apiaceae,
      desc:
          'Самая неприхотливая зелень. Для непрерывного урожая сейте каждые 2 недели.',
      aliases: ['укропа'],
      sowDepth: 1.5,
      spacing: 5,
      rows: 15,
      germinationTemp: 5,
      plantingTemp: 5,
      maturity: 40,
      waterDays: 3,
      waterAmount: '6–8 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -20,
      winterSow: true,
      soil: 'Рыхлая, нейтральная, умеренно плодородная.',
      tips: [
        'Для зелени прореживайте до 5 см, для зонтиков — до 15 см.',
        'Не перекармливайте азотом — накапливает нитраты.',
        'Самосев даёт всходы следующей весной.'
      ],
    ),
    CropRecord(
      id: 'celery',
      name: 'Сельдерей',
      emoji: '🌿',
      category: CropCategory.green,
      family: CropFamily.apiaceae,
      desc:
          'Листовой, черешковый и корневой. Длинный период рассады — до 70 дней.',
      aliases: ['сельдерея'],
      sowDepth: 0.5,
      spacing: 30,
      rows: 45,
      germinationTemp: 11,
      plantingTemp: 10,
      maturity: 140,
      waterDays: 3,
      waterAmount: '8–10 л под растение',
      frost: FrostTolerance.halfHardy,
      sowOffset: 10,
      transplantOffset: 8,
      seedlingDays: 70,
      soil: 'Очень плодородная, влагоёмкая, нейтральная.',
      tips: [
        'Семена не заглубляйте — только прижмите к почве.',
        'Черешковый окучивайте или обертывайте для отбелки.',
        'Корневой не окучивайте — иначе обрастёт боковыми корнями.'
      ],
    ),
    CropRecord(
      id: 'parsnip',
      name: 'Пастернак',
      emoji: '🥕',
      category: CropCategory.root,
      family: CropFamily.apiaceae,
      desc:
          'Белый корнеплод со сладковатым вкусом. Зимует в грунте, вкуснее после морозов.',
      aliases: ['пастернака'],
      sowDepth: 1.5,
      spacing: 10,
      rows: 30,
      germinationTemp: 5,
      plantingTemp: 5,
      maturity: 130,
      waterDays: 6,
      waterAmount: '10–12 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -18,
      winterSow: true,
      soil: 'Глубокая, рыхлая, без камней и свежего навоза.',
      tips: [
        'Семена всходят 2–3 недели, замочите заранее.',
        'Можно оставить в грунте на зиму.',
        'Листья содержат фурокумарины — работайте в перчатках.'
      ],
    ),
    CropRecord(
      id: 'coriander',
      name: 'Кориандр',
      emoji: '🌿',
      category: CropCategory.spice,
      family: CropFamily.apiaceae,
      desc: 'Кинза. Быстро уходит в стрелку в жару — сейте каждые 2–3 недели.',
      aliases: ['кинза', 'кинзу'],
      sowDepth: 1.5,
      spacing: 8,
      rows: 20,
      germinationTemp: 9,
      plantingTemp: 8,
      maturity: 45,
      waterDays: 3,
      waterAmount: '6–8 л на м²',
      frost: FrostTolerance.halfHardy,
      sowOffset: -10,
      soil: 'Лёгкая, плодородная, нейтральная.',
      tips: [
        'Сейте каждые 2–3 недели для непрерывной зелени.',
        'В жару притеняйте.',
        'Для семян оставьте до зонтиков.'
      ],
    ),
    CropRecord(
      id: 'fennel',
      name: 'Фенхель',
      emoji: '🌿',
      category: CropCategory.vegetable,
      family: CropFamily.apiaceae,
      desc:
          'Овощной фенхель со сладковатым укропно-анисовым вкусом. Кочанчик и зелень съедобны.',
      aliases: ['фенхель', 'сладкий укроп', 'аптечный укроп'],
      sowDepth: 1.5,
      spacing: 25,
      rows: 45,
      germinationTemp: 9,
      plantingTemp: 8,
      maturity: 80,
      waterDays: 3,
      waterAmount: '8–10 л под растение',
      frost: FrostTolerance.halfHardy,
      sowOffset: -10,
      transplantOffset: -6,
      seedlingDays: 40,
      soil: 'Плодородная, рыхлая, нейтральная, влагоёмкая.',
      tips: [
        'Окучивайте кочанчик для отбелки.',
        'Не сажайте рядом с укропом — переопыление.',
        'Снимайте, когда кочанчик 8–10 см.',
        'Листья срезайте как зелень.'
      ],
    ),

    // ================= ЛУКОВЫЕ =================
    CropRecord(
      id: 'onion',
      name: 'Лук',
      emoji: '🧅',
      category: CropCategory.root,
      family: CropFamily.amaryllidaceae,
      desc:
          'Репчатый. Полив прекращают за 2–3 недели до уборки, иначе шейка не вызреет.',
      aliases: ['лук репчатый', 'севок', 'чернушка'],
      sowDepth: 3.0,
      spacing: 10,
      rows: 25,
      germinationTemp: 6,
      plantingTemp: 8,
      maturity: 100,
      waterDays: 5,
      waterAmount: '10–12 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -18,
      careKey: 'лук',
      soil: 'Рыхлая, нейтральная, богатая перегноем. Не любит кислых и сырых.',
      tips: [
        'Не окучивайте — луковица сидит на поверхности.',
        'Перо срезайте не более 30% за раз.',
        'Сушите 2 недели под навесом.'
      ],
    ),
    CropRecord(
      id: 'garlic',
      name: 'Чеснок',
      emoji: '🧄',
      category: CropCategory.root,
      family: CropFamily.amaryllidaceae,
      desc: 'Озимый и яровой. Выламывание стрелок даёт +30% к урожаю.',
      aliases: ['чеснока'],
      sowDepth: 5.0,
      spacing: 12,
      rows: 25,
      germinationTemp: 5,
      plantingTemp: 5,
      maturity: 100,
      waterDays: 6,
      waterAmount: '10–12 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -20,
      careKey: 'чеснок',
      soil: 'Рыхлая, нейтральная, без застоя воды. Грядка приподнятая.',
      tips: [
        'Выламывайте стрелки после первого витка.',
        'Озимый сажайте за 3–4 недели до морозов.',
        'Мульчируйте торфом на зиму.'
      ],
    ),
    CropRecord(
      id: 'leek',
      name: 'Лук-порей',
      emoji: '🥬',
      category: CropCategory.vegetable,
      family: CropFamily.amaryllidaceae,
      desc:
          'Жемчужный лук. Отбелка окучиванием даёт длинную нежную белую часть.',
      aliases: ['порей', 'жемчужный лук'],
      sowDepth: 1.0,
      spacing: 15,
      rows: 40,
      germinationTemp: 9,
      plantingTemp: 8,
      maturity: 150,
      waterDays: 4,
      waterAmount: '10–12 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -8,
      transplantOffset: -4,
      seedlingDays: 60,
      soil: 'Очень плодородная, рыхлая, нейтральная, влагоёмкая.',
      tips: [
        'Окучивайте 3–4 раза за сезон для отбелки.',
        'Не срезайте листья — они питают стебель.',
        'Убирайте до устойчивых морозов.'
      ],
    ),
    CropRecord(
      id: 'batun',
      name: 'Лук-батун',
      emoji: '🌿',
      category: CropCategory.perennial,
      family: CropFamily.amaryllidaceae,
      desc:
          'Многолетний лук на перо. Растёт на одном месте 4–5 лет, даёт раннюю зелень.',
      aliases: ['батун', 'дудчатый лук'],
      sowDepth: 1.5,
      spacing: 20,
      rows: 30,
      germinationTemp: 5,
      plantingTemp: 5,
      maturity: 60,
      waterDays: 4,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -20,
      winterSow: true,
      soil: 'Рыхлая, плодородная, нейтральная.',
      tips: [
        'Раз в 3–4 года делите куст и пересаживайте.',
        'Срезайте не более 2–3 раз за сезон.',
        'Ранней весной подкормите азотом.'
      ],
    ),
    CropRecord(
      id: 'chives',
      name: 'Шнитт-лук',
      emoji: '🌿',
      category: CropCategory.perennial,
      family: CropFamily.amaryllidaceae,
      desc: 'Лук-резанец. Тонкое нежное перо, декоративные съедобные цветы.',
      aliases: ['шнитт', 'лук-резанец', 'скорода'],
      sowDepth: 1.0,
      spacing: 25,
      rows: 30,
      germinationTemp: 6,
      plantingTemp: 5,
      maturity: 60,
      waterDays: 4,
      waterAmount: '6–8 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -20,
      soil: 'Рыхлая, влажная, плодородная. Терпит полутень.',
      tips: [
        'Делите куст каждые 3 года — иначе загущается.',
        'Цветы съедобны, украшают салат.',
        'Можно выгонять в горшке зимой.'
      ],
      light: 'Солнце или полутень',
    ),

    // ================= БОБОВЫЕ =================
    CropRecord(
      id: 'pea',
      name: 'Горох',
      emoji: '🫛',
      category: CropCategory.legume,
      family: CropFamily.fabaceae,
      desc:
          'Сам фиксирует азот. Нужна опора и умеренный полив, перелив даёт гнили.',
      aliases: ['горошек'],
      sowDepth: 4.0,
      spacing: 6,
      rows: 30,
      germinationTemp: 5,
      plantingTemp: 6,
      maturity: 70,
      waterDays: 5,
      waterAmount: '10–15 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -20,
      careKey: 'горох',
      soil: 'Рыхлая, нейтральная. Азотные удобрения не нужны.',
      tips: [
        'Опора нужна сразу — иначе плети полегут.',
        'Снимайте бобы каждые 2 дня.',
        'Корни оставьте в почве — это азот.'
      ],
    ),
    CropRecord(
      id: 'bean',
      name: 'Фасоль овощная',
      emoji: '🫘',
      category: CropCategory.legume,
      family: CropFamily.fabaceae,
      desc: 'Кустовая и вьющаяся. Теплолюбива, сейте только в прогретую почву.',
      aliases: ['фасоль', 'спаржевая фасоль'],
      sowDepth: 4.0,
      spacing: 15,
      rows: 45,
      germinationTemp: 11,
      plantingTemp: 12,
      maturity: 60,
      waterDays: 4,
      waterAmount: '10–12 л на м²',
      frost: FrostTolerance.tender,
      sowOffset: 14,
      soil: 'Лёгкая, нейтральная. Азот не нужен — фиксирует сама.',
      tips: [
        'Вьющейся нужна опора 2 м.',
        'Снимайте лопатки, пока семена не выпирают.',
        'Не работайте с мокрыми растениями — разносится антракноз.'
      ],
    ),
    CropRecord(
      id: 'broadbean',
      name: 'Бобы',
      emoji: '🫘',
      category: CropCategory.legume,
      family: CropFamily.fabaceae,
      desc:
          'Самые холодостойкие бобовые. Прищипка верхушки отпугивает тлю и ускоряет налив.',
      aliases: ['бобов', 'русские бобы', 'фава'],
      sowDepth: 6.0,
      spacing: 20,
      rows: 45,
      germinationTemp: 5,
      plantingTemp: 5,
      maturity: 90,
      waterDays: 5,
      waterAmount: '10–15 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -22,
      soil: 'Рыхлая, нейтральная, влагоёмкая. Терпит лёгкую кислотность.',
      tips: [
        'Прищипните верхушку при первых бобах — тля не заселит.',
        'Снимайте, пока шов на бобе зелёный.',
        'Самый ранний посев из всех бобовых.'
      ],
    ),

    // ================= АСТРОВЫЕ =================
    CropRecord(
      id: 'lettuce',
      name: 'Салат листовой',
      emoji: '🥬',
      category: CropCategory.green,
      family: CropFamily.asteraceae,
      desc:
          'Скороспелая зелень. В жару и при длинном дне уходит в стрелку и горчит.',
      aliases: ['салат', 'латук'],
      sowDepth: 0.5,
      spacing: 15,
      rows: 25,
      germinationTemp: 5,
      plantingTemp: 5,
      maturity: 45,
      waterDays: 3,
      waterAmount: '6–8 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -20,
      soil: 'Рыхлая, плодородная, нейтральная, влагоёмкая.',
      tips: [
        'Сейте каждые 2 недели.',
        'В жару притеняйте.',
        'Срезайте наружные листья — куст даст новые.'
      ],
      light: 'Солнце или полутень',
    ),
    CropRecord(
      id: 'headlettuce',
      name: 'Салат кочанный',
      emoji: '🥬',
      category: CropCategory.green,
      family: CropFamily.asteraceae,
      desc:
          'Айсберг и маслянистые сорта. Требует стабильного полива для плотного кочана.',
      aliases: ['айсберг', 'кочанный салат'],
      sowDepth: 0.5,
      spacing: 25,
      rows: 35,
      germinationTemp: 7,
      plantingTemp: 6,
      maturity: 70,
      waterDays: 3,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -16,
      transplantOffset: -10,
      seedlingDays: 30,
      soil: 'Плодородная, влагоёмкая, нейтральная.',
      tips: [
        'Не заглубляйте точку роста при высадке.',
        'Полив под корень — иначе гниль внутри кочана.',
        'Убирайте утром, пока кочан тургорный.'
      ],
    ),
    CropRecord(
      id: 'endive',
      name: 'Эндивий',
      emoji: '🥬',
      category: CropCategory.green,
      family: CropFamily.asteraceae,
      desc: 'Салат цикорий с лёгкой горчинкой. Отбелка убирает горечь.',
      aliases: ['эндивия', 'эскариоль'],
      sowDepth: 1.0,
      spacing: 25,
      rows: 35,
      germinationTemp: 9,
      plantingTemp: 8,
      maturity: 75,
      waterDays: 3,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: 40,
      soil: 'Рыхлая, плодородная, нейтральная.',
      tips: [
        'Основной посев в июле — осенний урожай нежнее.',
        'За 2 недели до уборки накройте куст для отбелки.',
        'Горечь уходит после первых заморозков.'
      ],
    ),
    CropRecord(
      id: 'jerusalem',
      name: 'Топинамбур',
      emoji: '🌻',
      category: CropCategory.perennial,
      family: CropFamily.asteraceae,
      desc: 'Земляная груша. Зимует в грунте, урожай клубней до 3 кг с куста.',
      aliases: ['земляная груша', 'иерусалимский артишок'],
      sowDepth: 8.0,
      spacing: 50,
      rows: 70,
      germinationTemp: 7,
      plantingTemp: 6,
      maturity: 130,
      waterDays: 8,
      waterAmount: '15–20 л под куст',
      frost: FrostTolerance.veryHardy,
      sowOffset: -20,
      soil: 'Неприхотлив, но лучше рыхлая плодородная. Не любит застоя воды.',
      tips: [
        'Сажайте с северной стороны — кусты затеняют грядки.',
        'Убирайте после заморозков — слаще.',
        'Оставьте 2–3 клубня в земле на следующий год.'
      ],
    ),
    CropRecord(
      id: 'arugula',
      name: 'Руккола',
      emoji: '🥬',
      category: CropCategory.green,
      family: CropFamily.brassicaceae,
      desc:
          'Скороспелая пряная зелень с орехово-горчичным вкусом. Готова через 3–4 недели.',
      aliases: ['рукколу', 'индау'],
      sowDepth: 1.0,
      spacing: 10,
      rows: 20,
      germinationTemp: 6,
      plantingTemp: 6,
      maturity: 30,
      waterDays: 3,
      waterAmount: '6–8 л на м²',
      frost: FrostTolerance.halfHardy,
      sowOffset: -18,
      secondSowOffset: 90,
      winterSow: true,
      soil: 'Рыхлая, нейтральная, умеренно плодородная.',
      tips: [
        'Сейте каждые 2 недели для непрерывной зелени.',
        'В жару стрелкуется — притеняйте.',
        'Срезайте наружные листья, оставляя центр.',
        'Осенний посев даёт нежные листья.'
      ],
      light: 'Солнце или полутень',
    ),
    CropRecord(
      id: 'kale',
      name: 'Кале',
      emoji: '🥬',
      category: CropCategory.green,
      family: CropFamily.brassicaceae,
      desc:
          'Листовая капуста без кочана. Морозостойкая, даёт зелень до глубокой осени.',
      aliases: ['кале', 'кудрявая капуста', 'грюнколь'],
      sowDepth: 1.0,
      spacing: 30,
      rows: 45,
      germinationTemp: 6,
      plantingTemp: 6,
      maturity: 70,
      waterDays: 3,
      waterAmount: '8–10 л под растение',
      frost: FrostTolerance.veryHardy,
      sowOffset: -16,
      transplantOffset: -10,
      seedlingDays: 35,
      winterSow: true,
      soil: 'Плодородная, влагоёмкая, нейтральная.',
      tips: [
        'Срезайте нижние листья, верхушка даст новые.',
        'После заморозков листья слаще.',
        'Мульчируйте на зиму для перезимовки.',
        'Убирайте листья, пока они нежные.'
      ],
    ),

    // ================= АМАРАНТОВЫЕ =================
    CropRecord(
      id: 'beet',
      name: 'Свёкла',
      emoji: '🍠',
      category: CropCategory.root,
      family: CropFamily.amaranthaceae,
      desc: 'Скачки влажности дают волокнистые и растрескавшиеся корнеплоды.',
      aliases: ['свекла', 'столовая свёкла'],
      sowDepth: 2.5,
      spacing: 10,
      rows: 30,
      germinationTemp: 9,
      plantingTemp: 10,
      maturity: 110,
      waterDays: 5,
      waterAmount: '10–15 л на м²',
      frost: FrostTolerance.halfHardy,
      sowOffset: -4,
      careKey: 'свекл',
      soil:
          'Рыхлая, нейтральная. На кислой почве листья краснеют, рост тормозится.',
      tips: [
        'Прореживайте до 8–10 см.',
        'Не окучивайте — корнеплод выступает над землёй.',
        'Убирайте до заморозков.'
      ],
    ),
    CropRecord(
      id: 'spinach',
      name: 'Шпинат',
      emoji: '🥬',
      category: CropCategory.green,
      family: CropFamily.amaranthaceae,
      desc:
          'Самая ранняя зелень. Длинный день вызывает стрелкование — сейте весной и осенью.',
      aliases: ['шпината'],
      sowDepth: 2.0,
      spacing: 8,
      rows: 20,
      germinationTemp: 5,
      plantingTemp: 4,
      maturity: 40,
      waterDays: 3,
      waterAmount: '6–8 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -24,
      secondSowOffset: 90,
      winterSow: true,
      soil: 'Рыхлая, плодородная, нейтральная, влагоёмкая.',
      tips: [
        'Сейте как только сойдёт снег.',
        'Осенний посев под зиму даёт раннюю зелень.',
        'Срезайте, пока листья не загрубели.'
      ],
      light: 'Солнце или полутень',
    ),
    CropRecord(
      id: 'chard',
      name: 'Мангольд',
      emoji: '🥬',
      category: CropCategory.green,
      family: CropFamily.amaranthaceae,
      desc:
          'Листовая свёкла с цветными черешками. Срезка даёт новые листья всё лето.',
      aliases: ['листовая свёкла', 'свекла листовая'],
      sowDepth: 2.5,
      spacing: 25,
      rows: 35,
      germinationTemp: 9,
      plantingTemp: 8,
      maturity: 60,
      waterDays: 4,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -14,
      soil: 'Плодородная, рыхлая, нейтральная.',
      tips: [
        'Срезайте наружные листья, центр не трогайте.',
        'Черешки готовьте как спаржу.',
        'Декоративен — можно в цветнике.'
      ],
    ),

    // ================= ЗЛАКИ =================
    CropRecord(
      id: 'corn',
      name: 'Кукуруза сахарная',
      emoji: '🌽',
      category: CropCategory.vegetable,
      family: CropFamily.poaceae,
      desc:
          'Опыляется ветром — сажайте блоком, а не в один ряд, иначе пустые початки.',
      aliases: ['кукуруза', 'маис'],
      sowDepth: 5.0,
      spacing: 30,
      rows: 60,
      germinationTemp: 11,
      plantingTemp: 12,
      maturity: 85,
      waterDays: 4,
      waterAmount: '15–20 л на м²',
      frost: FrostTolerance.tender,
      sowOffset: 14,
      transplantOffset: 10,
      seedlingDays: 25,
      soil: 'Плодородная, рыхлая, нейтральная. Любит азот и органику.',
      tips: [
        'Сажайте квадратом минимум 4×4 растения.',
        'В цветение потрясите метёлки для опыления.',
        'Снимайте, когда нити подсохли, а зерно даёт молочко.'
      ],
    ),

    // ================= ГРЕЧИШНЫЕ =================
    CropRecord(
      id: 'sorrel',
      name: 'Щавель',
      emoji: '🌿',
      category: CropCategory.perennial,
      family: CropFamily.polygonaceae,
      desc:
          'Многолетняя кислая зелень. На одном месте 4–5 лет, первая срезка очень ранняя.',
      aliases: ['щавеля'],
      sowDepth: 1.5,
      spacing: 20,
      rows: 30,
      germinationTemp: 5,
      plantingTemp: 5,
      maturity: 60,
      waterDays: 4,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -22,
      winterSow: true,
      soil: 'Рыхлая, влажная, слабокислая. Терпит полутень.',
      tips: [
        'Удаляйте цветоносы — иначе лист загрубеет.',
        'Делите куст каждые 4 года.',
        'Не срезайте больше 2–3 раз за сезон.'
      ],
      light: 'Солнце или полутень',
    ),
    CropRecord(
      id: 'rhubarb',
      name: 'Ревень',
      emoji: '🌿',
      category: CropCategory.perennial,
      family: CropFamily.polygonaceae,
      desc: 'Многолетник: едят только черешки. Листья ядовиты — оксалаты.',
      aliases: ['ревеня'],
      sowDepth: 2.0,
      spacing: 70,
      rows: 90,
      germinationTemp: 11,
      plantingTemp: 10,
      maturity: 365,
      waterDays: 6,
      waterAmount: '15–20 л под куст',
      frost: FrostTolerance.veryHardy,
      sowOffset: -18,
      transplantOffset: -10,
      seedlingDays: 90,
      soil: 'Очень плодородная, влагоёмкая, нейтральная.',
      tips: [
        'В первый год черешки не срезайте.',
        'Листья ядовиты — едят только черешки.',
        'Обламывайте, не срезайте — меньше гнили.'
      ],
    ),

    // ================= ЯСНОТКОВЫЕ =================
    CropRecord(
      id: 'basil',
      name: 'Базилик',
      emoji: '🌿',
      category: CropCategory.spice,
      family: CropFamily.lamiaceae,
      desc:
          'Теплолюбивая пряность. Прищипка даёт ветвистый куст и много листа.',
      aliases: ['базилика', 'рейхан'],
      sowDepth: 0.5,
      spacing: 25,
      rows: 35,
      germinationTemp: 16,
      plantingTemp: 15,
      maturity: 60,
      waterDays: 3,
      waterAmount: '2–3 л под куст',
      frost: FrostTolerance.tender,
      sowOffset: 20,
      transplantOffset: 16,
      seedlingDays: 50,
      greenhouse: true,
      soil: 'Лёгкая, плодородная, дренированная, нейтральная.',
      tips: [
        'Прищипните над 4-м листом — куст ветвится.',
        'Удаляйте бутоны, иначе лист горчит.',
        'Отлично растёт в горшке на солнечном окне.'
      ],
    ),
    CropRecord(
      id: 'mint',
      name: 'Мята',
      emoji: '🌿',
      category: CropCategory.perennial,
      family: CropFamily.lamiaceae,
      desc:
          'Агрессивный многолетник. Сажайте с ограничителем корней, иначе захватит грядку.',
      aliases: ['мяту', 'перечная мята'],
      sowDepth: 0.5,
      spacing: 30,
      rows: 40,
      germinationTemp: 11,
      plantingTemp: 8,
      maturity: 90,
      waterDays: 4,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -10,
      soil: 'Влажная, плодородная, слабокислая. Терпит полутень.',
      tips: [
        'Вкопайте бордюр или ведро без дна на 30 см.',
        'Срезайте до цветения — максимум аромата.',
        'Обновляйте куст каждые 3–4 года.'
      ],
      light: 'Солнце или полутень',
    ),
    CropRecord(
      id: 'lemonbalm',
      name: 'Мелисса',
      emoji: '🌿',
      category: CropCategory.perennial,
      family: CropFamily.lamiaceae,
      desc: 'Лимонная мята. Неприхотлива, зимует без укрытия, привлекает пчёл.',
      aliases: ['мелиссу', 'лимонная мята'],
      sowDepth: 0.5,
      spacing: 35,
      rows: 45,
      germinationTemp: 11,
      plantingTemp: 8,
      maturity: 80,
      waterDays: 5,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -12,
      soil: 'Рыхлая, умеренно плодородная. Не любит застоя воды.',
      tips: [
        'Срезайте до цветения для чая.',
        'Разрастается самосевом — контролируйте.',
        'Сушите в тени, не на солнце.'
      ],
      light: 'Солнце или полутень',
    ),
    CropRecord(
      id: 'thyme',
      name: 'Тимьян',
      emoji: '🌿',
      category: CropCategory.perennial,
      family: CropFamily.lamiaceae,
      desc:
          'Чабрец. Засухоустойчивый почвопокровный многолетник, отличный медонос.',
      aliases: ['чабрец', 'тимьяна'],
      sowDepth: 0.3,
      spacing: 25,
      rows: 30,
      germinationTemp: 13,
      plantingTemp: 10,
      maturity: 90,
      waterDays: 8,
      waterAmount: '3–5 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -8,
      transplantOffset: 0,
      seedlingDays: 60,
      soil: 'Песчаная, бедная, дренированная, нейтральная или щелочная.',
      tips: [
        'Не переливайте — корневая гниль.',
        'Стригите после цветения для компактности.',
        'Идеален для каменистых горок и бордюров.'
      ],
    ),
    CropRecord(
      id: 'tarragon',
      name: 'Эстрагон',
      emoji: '🌿',
      category: CropCategory.perennial,
      family: CropFamily.asteraceae,
      desc:
          'Тархун. Многолетняя пряная трава с анисовым ароматом. Для напитков и соусов.',
      aliases: ['тархун', 'эстрагоновую полынь'],
      sowDepth: 0.3,
      spacing: 40,
      rows: 60,
      germinationTemp: 11,
      plantingTemp: 10,
      maturity: 90,
      waterDays: 5,
      waterAmount: '6–8 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -10,
      transplantOffset: -5,
      seedlingDays: 60,
      soil:
          'Дренированная, нейтральная или слабощелочная. Не любит застоя воды.',
      tips: [
        'Делите куст каждые 3 года.',
        'Срезайте до цветения для максимального аромата.',
        'Укрывайте в бесснежные зимы.',
        'Сушите в тени для сохранения аромата.'
      ],
    ),
    CropRecord(
      id: 'oregano',
      name: 'Душица',
      emoji: '🌿',
      category: CropCategory.perennial,
      family: CropFamily.lamiaceae,
      desc: 'Орегано. Многолетняя пряная трава. Для пиццы, соусов и чая.',
      aliases: ['орегано', 'душицу'],
      sowDepth: 0.3,
      spacing: 30,
      rows: 45,
      germinationTemp: 11,
      plantingTemp: 10,
      maturity: 80,
      waterDays: 5,
      waterAmount: '6–8 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -10,
      transplantOffset: -5,
      seedlingDays: 50,
      soil: 'Лёгкая, дренированная, нейтральная или слабощелочная.',
      tips: [
        'Не переливайте — корневая гниль.',
        'Срезайте до цветения.',
        'Делите куст каждые 3–4 года.',
        'Сушите в пучках в тени.'
      ],
    ),

    // ================= ПРОЧИЕ =================
    CropRecord(
      id: 'horseradish',
      name: 'Хрен',
      emoji: '🌱',
      category: CropCategory.perennial,
      family: CropFamily.brassicaceae,
      desc:
          'Многолетний корнеплод с острым вкусом. Агрессивно разрастается — сажайте с ограничителем.',
      aliases: ['хрен'],
      sowDepth: 10.0,
      spacing: 40,
      rows: 70,
      germinationTemp: 7,
      plantingTemp: 6,
      maturity: 180,
      waterDays: 6,
      waterAmount: '10–12 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -20,
      soil: 'Рыхлая, глубокая, без камней. На плотной почве корни ветвятся.',
      tips: [
        'Вкопайте бордюр на 40 см — иначе захватит участок.',
        'Выкапывайте корни осенью второго года.',
        'Не оставляйте мелкие корни в почве — прорастут.',
        'Сажайте на краю участка.'
      ],
    ),
    CropRecord(
      id: 'asparagus',
      name: 'Спаржа',
      emoji: '🌿',
      category: CropCategory.perennial,
      family: CropFamily.asteraceae,
      desc:
          'Многолетний деликатес. Первый урожай только на третий год, но потом до 20 лет.',
      aliases: ['спаржу', 'аспарагус'],
      sowDepth: 2.0,
      spacing: 50,
      rows: 100,
      germinationTemp: 13,
      plantingTemp: 12,
      maturity: 365,
      waterDays: 4,
      waterAmount: '10–12 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -8,
      transplantOffset: -4,
      seedlingDays: 365,
      soil: 'Очень плодородная, глубокая, дренированная, нейтральная.',
      tips: [
        'Не срезайте побеги в первые 2 года.',
        'Урожай собирайте 6–8 недель в год.',
        'Осенью подкормите компостом.',
        'Мульчируйте на зиму.'
      ],
    ),
    CropRecord(
      id: 'okra',
      name: 'Бамия',
      emoji: '🌿',
      category: CropCategory.vegetable,
      family: CropFamily.asteraceae,
      desc:
          'Теплолюбивый овощ для южных регионов. Стручки используют в супах и рагу.',
      aliases: ['бамию', 'окра', 'гомо'],
      sowDepth: 2.5,
      spacing: 35,
      rows: 60,
      germinationTemp: 16,
      plantingTemp: 16,
      maturity: 75,
      waterDays: 3,
      waterAmount: '8–10 л под растение',
      frost: FrostTolerance.tender,
      sowOffset: 24,
      transplantOffset: 20,
      seedlingDays: 45,
      greenhouse: true,
      soil: 'Плодородная, дренированная, нейтральная. Хорошо прогреваемая.',
      tips: [
        'Только для южных регионов (Краснодар, Казахстан юг, Узбекистан).',
        'Снимайте стручки, пока они нежные, 5–8 см.',
        'Собирайте в перчатках — волоски колются.',
        'В средней полосе растёт только в теплице.'
      ],
    ),

    // ================= РОЗОЦВЕТНЫЕ =================
    CropRecord(
      id: 'strawberry',
      name: 'Земляника садовая',
      emoji: '🍓',
      category: CropCategory.perennial,
      family: CropFamily.rosaceae,
      desc:
          'Клубника. Обновляйте посадки каждые 3–4 года, удаляйте усы для урожая.',
      aliases: ['клубника', 'клубнику', 'земляника'],
      sowDepth: 0.0,
      spacing: 30,
      rows: 60,
      germinationTemp: 10,
      plantingTemp: 8,
      maturity: 365,
      waterDays: 4,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.veryHardy,
      sowOffset: -14,
      soil: 'Рыхлая, плодородная, слабокислая pH 5,5–6,5. Мульча обязательна.',
      tips: [
        'Сердечко не заглубляйте и не оголяйте.',
        'Удаляйте усы, если не нужен посадочный материал.',
        'Мульчируйте соломой — ягода чистая и не гниёт.',
        'После плодоношения скосите лист и подкормите.'
      ],
      extra: [
        ProblemSpec(
            'Серая гниль ягод',
            true,
            3,
            'Ягоды покрываются серым пушистым налётом, размягчаются и мумифицируются.',
            [
              'Уберите и уничтожьте все больные ягоды.',
              'Подложите солому или агроволокно под кисти.',
              'Фитоспорин до цветения и после сбора.'
            ],
            [
              'Мульча — ягода не касается земли.',
              'Не загущайте посадки.',
              'Полив под корень утром.'
            ]),
        ProblemSpec(
            'Земляничный клещ',
            false,
            3,
            'Молодые листья сморщенные, маслянистые, куст карликовый, урожай резко падает.',
            [
              'Удалите сильно поражённые кусты.',
              'Обработайте акарицидом после сбора урожая.',
              'Омоложение посадок каждые 3 года.'
            ],
            [
              'Покупайте здоровые усы.',
              'Термообработка усов +45 °C 15 минут.',
              'Не сажайте после малины.'
            ]),
      ],
    ),

    // ================= СМЕСЬ (совместимость со старым садом) =================
    CropRecord(
      id: 'greens',
      name: 'Зелень',
      emoji: '🌿',
      category: CropCategory.green,
      family: CropFamily.apiaceae,
      desc:
          'Смесь зелени: укроп, петрушка, салат. Непрерывная срезка всё лето.',
      aliases: ['зелень смесь', 'микс зелени'],
      sowDepth: 1.0,
      spacing: 8,
      rows: 20,
      germinationTemp: 5,
      plantingTemp: 5,
      maturity: 45,
      waterDays: 3,
      waterAmount: '8–10 л на м²',
      frost: FrostTolerance.hardy,
      sowOffset: -20,
      secondSowOffset: 110,
      winterSow: true,
      careKey: 'зелен',
      soil: 'Рыхлая, плодородная, нейтральная. Умеренная органика.',
      tips: [
        'Срезайте наружные листья, оставляя точку роста.',
        'Сейте каждые 2 недели.',
        'Не перекармливайте азотом.'
      ],
    ),
  ];
}

/// Болезни и вредители, общие для семейства.
/// Наследование по семейству даёт покрытие всех культур без ручного
/// написания сотен карточек.
class FamilyProblems {
  static List<ProblemSpec> of(CropFamily f) {
    switch (f) {
      case CropFamily.solanaceae:
        return _solanaceae;
      case CropFamily.cucurbitaceae:
        return _cucurbitaceae;
      case CropFamily.brassicaceae:
        return _brassicaceae;
      case CropFamily.apiaceae:
        return _apiaceae;
      case CropFamily.amaryllidaceae:
        return _amaryllidaceae;
      case CropFamily.fabaceae:
        return _fabaceae;
      case CropFamily.asteraceae:
        return _asteraceae;
      case CropFamily.amaranthaceae:
        return _amaranthaceae;
      case CropFamily.poaceae:
        return _poaceae;
      case CropFamily.polygonaceae:
        return _polygonaceae;
      case CropFamily.lamiaceae:
        return _lamiaceae;
      case CropFamily.rosaceae:
        return _rosaceae;
    }
  }

  static const _solanaceae = [
    ProblemSpec(
        'Фитофтороз',
        true,
        3,
        'Бурые расплывчатые пятна на листьях и стеблях, белый налёт снизу во влажную погоду, плоды с твёрдыми бурыми пятнами.',
        [
          'Удалите и сожгите поражённые части.',
          'Фитоспорин или 1% бордоская жидкость (медь — не позднее 20 дней до сбора).',
          'Прекратите полив по листу, усильте проветривание.'
        ],
        [
          'Устойчивые сорта и мульча.',
          'Не загущайте посадки.',
          'Профилактика биопрепаратами каждые 2 недели с июня.'
        ]),
    ProblemSpec(
        'Колорадский жук',
        false,
        3,
        'Полосатые жуки и оранжевые личинки объедают листья до жилок, куст стоит голый.',
        [
          'Ручной сбор каждые 2–3 дня.',
          'Битоксибациллин по инструкции.',
          'При массовом нашествии — разрешённый инсектицид.'
        ],
        [
          'Осмотр нижней стороны листьев.',
          'Севооборот.',
          'Уборка сорняков паслёновых.'
        ]),
    ProblemSpec(
        'Тля',
        false,
        2,
        'Скрученные верхушки побегов, колонии насекомых снизу листа, липкая падь, рядом муравьи.',
        [
          'Смойте мыльно-зольным раствором.',
          'Фитоверм при массовом заселении.',
          'Контроль муравьёв — они разносят тлю.'
        ],
        [
          'Еженедельный осмотр верхушек.',
          'Удаление сорняков.',
          'Привлечение божьих коровок.'
        ]),
  ];

  static const _cucurbitaceae = [
    ProblemSpec(
        'Мучнистая роса',
        true,
        3,
        'Белый мучнистый налёт на верхней стороне листьев, затем листья буреют и засыхают. Особенно в августе.',
        [
          'Удалите сильно поражённые листья.',
          'Фитоспорин или Топаз по инструкции.',
          'Настой золы с мылом как мягкая мера.'
        ],
        [
          'Полив только под корень тёплой водой.',
          'Не загущайте, проветривайте.',
          'Профилактика с июля.'
        ]),
    ProblemSpec(
        'Пероноспороз',
        true,
        3,
        'Жёлтые угловатые маслянистые пятна сверху листа, серо-фиолетовый налёт снизу. Развивается в прохладные росистые ночи.',
        [
          'Удалите больные листья.',
          'Медьсодержащий препарат с учётом срока ожидания.',
          'Сократите полив, усильте проветривание.'
        ],
        [
          'Полив только утром.',
          'Борьба с конденсатом в теплице.',
          'Севооборот и уборка остатков.'
        ]),
    ProblemSpec(
        'Бахчевая тля',
        false,
        2,
        'Скрученные верхушки плетей, липкая падь, колонии тли снизу листьев, муравьи рядом.',
        [
          'Мыльно-зольный раствор по колониям.',
          'Фитоверм при массовом заселении.',
          'Уничтожьте муравейники рядом.'
        ],
        [
          'Осмотр верхушек плетей.',
          'Ловчие пояса от муравьёв.',
          'Удаление сорняков вокруг.'
        ]),
  ];

  static const _brassicaceae = [
    ProblemSpec(
        'Кила',
        true,
        3,
        'Наросты и вздутия на корнях, растение вянет в жару и отстаёт в росте. Возбудитель живёт в почве до 7 лет.',
        [
          'Удалите больные растения с корнями.',
          'Известкование: доломитовая мука 500 г на м².',
          'Не сажайте капустные на этом месте 5–6 лет.'
        ],
        [
          'Нейтральная почва — главная защита.',
          'Севооборот 5 лет.',
          'Только здоровая рассада.'
        ]),
    ProblemSpec(
        'Крестоцветная блошка',
        false,
        3,
        'Мелкие дырочки-язвочки на молодых листьях, мелкие прыгающие жучки. Всходы могут быть изъедены полностью.',
        [
          'Опудрите золой с табачной пылью по росе.',
          'Укройте спанбондом до укрепления растений.',
          'Полив дождеванием отпугивает.'
        ],
        [
          'Ранняя высадка крепкой рассады.',
          'Укрытие сразу после посева.',
          'Уборка сорняков капустных.'
        ]),
    ProblemSpec(
        'Капустная белянка',
        false,
        2,
        'Жёлтые яйца снизу листа, жёлто-зелёные гусеницы объедают листья до крупных жилок.',
        [
          'Ручной сбор гусениц и яиц каждые 3 дня.',
          'Битоксибациллин по инструкции.',
          'Настой полыни как отпугивание.'
        ],
        [
          'Укрытие спанбондом от лёта бабочек.',
          'Осмотр нижней стороны листьев.',
          'Привлечение насекомоядных птиц.'
        ]),
  ];

  static const _apiaceae = [
    ProblemSpec(
        'Альтернариоз',
        true,
        2,
        'Бурые сухие пятна с концентрическими кругами на листьях, ботва чернеет и засыхает.',
        [
          'Удалите сильно поражённую ботву.',
          'Обработайте Фитоспорином.',
          'Убирайте урожай в сухую погоду.'
        ],
        [
          'Севооборот 3–4 года.',
          'Уборка ботвы осенью.',
          'Здоровые семена, протравливание.'
        ]),
    ProblemSpec(
        'Морковная муха',
        false,
        3,
        'Ржавые ходы в корнеплоде, ботва краснеет и вянет, корнеплод горчит и гниёт.',
        [
          'Укройте грядку спанбондом сразу после посева.',
          'Удалите повреждённые корнеплоды.',
          'Настой табака или золы в междурядьях как отпугивание.'
        ],
        [
          'Посев рядом с луком — взаимное отпугивание.',
          'Прореживание вечером с поливом.',
          'Глубокая осенняя перекопка.'
        ]),
    ProblemSpec(
        'Проволочник',
        false,
        2,
        'Узкие глубокие ходы в корнеплоде, в почве жёсткие жёлто-коричневые личинки-проволочки.',
        [
          'Ловушки: кусочки картофеля закопать на 5–10 см, проверять каждые 2 дня.',
          'Известкование кислых почв.',
          'Горчица как сидерат после уборки.'
        ],
        [
          'Борьба с пыреем.',
          'Севооборот.',
          'Ловушки ранней весной.'
        ]),
  ];

  static const _amaryllidaceae = [
    ProblemSpec(
        'Пероноспороз',
        true,
        3,
        'Бледные вытянутые пятна на пере, серо-фиолетовый налёт во влажную погоду, перо желтеет и падает.',
        [
          'Прекратите полив по листу.',
          'Медьсодержащие препараты не позднее 20 дней до уборки.',
          'Удалите сильно больные растения.'
        ],
        [
          'Солнечное продуваемое место.',
          'Прогрев посадочного материала.',
          'Севооборот 3–4 года.'
        ]),
    ProblemSpec(
        'Луковая муха',
        false,
        3,
        'Перо желтеет с верхушки, луковица мягкая и гниёт, внутри белые личинки.',
        [
          'Удалите и уничтожьте больные луковицы.',
          'Полив солёной водой (стакан на 10 л) ранней весной.',
          'Укройте спанбондом на период лёта.'
        ],
        [
          'Посадка рядом с морковью.',
          'Ранняя посадка до лёта мухи.',
          'Осенняя перекопка.'
        ]),
    ProblemSpec(
        'Шейковая гниль',
        true,
        2,
        'Шейка луковицы мягкая, серая гниль под чешуями. Проявляется в хранении.',
        [
          'Переберите хранилище, удалите больные.',
          'Просушите и понизьте влажность.',
          'Не храните недозревший лук.'
        ],
        [
          'Прекращение полива за 3 недели до уборки.',
          'Полная просушка перед закладкой.',
          'Уборка только в сухую погоду.'
        ]),
  ];

  static const _fabaceae = [
    ProblemSpec(
        'Корневые гнили',
        true,
        2,
        'Пожелтение и увядание снизу, корни бурые, растение легко выдёргивается из почвы.',
        [
          'Удалите больные растения.',
          'Подсушите почву и рыхлите.',
          'Пролейте Фитоспорином.'
        ],
        [
          'Не переливайте.',
          'Севооборот 4 года.',
          'Известкование кислых почв.'
        ]),
    ProblemSpec(
        'Бобовая тля',
        false,
        2,
        'Чёрные колонии на верхушках и цветоносах, липкая падь, деформированные бобы.',
        [
          'Прищипните верхушки — тля заселяет их первыми.',
          'Мыльный раствор.',
          'Фитоверм до налива бобов.'
        ],
        [
          'Осмотр верхушек.',
          'Уборка сорняков.',
          'Привлечение божьих коровок.'
        ]),
    ProblemSpec('Плодожорка', false, 3,
        'Гусеницы внутри бобов, дырочки в створках, изъеденные зёрна.', [
      'Собирайте бобы своевременно, не давая перерастать.',
      'Ранние сорта уходят от лёта.',
      'Уберите растительные остатки.'
    ], [
      'Ранний посев.',
      'Глубокая осенняя перекопка.',
      'Севооборот.'
    ]),
  ];

  static const _asteraceae = [
    ProblemSpec(
        'Ложная мучнистая роса',
        true,
        2,
        'Жёлтые пятна сверху листа, серый налёт снизу, листья отмирают.',
        ['Удалите больные листья.', 'Сократите полив по листу.', 'Фитоспорин.'],
        ['Не загущайте.', 'Полив под корень утром.', 'Уборка остатков.']),
    ProblemSpec('Слизни', false, 2,
        'Дыры в листьях и плодах у земли, серебристые следы слизи.', [
      'Ловушки: доски на ночь, утром собрать.',
      'Барьер из золы или суперфосфата.',
      'Уберите мульчу-убежище от стеблей.'
    ], [
      'Прополка и сухая мульча.',
      'Осенняя перекопка междурядий.',
      'Ловушки в междурядьях.'
    ]),
    ProblemSpec(
        'Тля',
        false,
        2,
        'Колонии на молодых побегах и нижней стороне листьев, скручивание верхушек.',
        [
          'Смойте сильной струёй воды.',
          'Фитоверм с учётом срока ожидания.',
          'Срежьте сильно заселённые верхушки.'
        ],
        [
          'Еженедельный осмотр.',
          'Уборка сорняков.',
          'Божьи коровки рядом.'
        ]),
  ];

  static const _amaranthaceae = [
    ProblemSpec(
        'Церкоспороз',
        true,
        2,
        'Круглые бурые пятна с красной каймой на листьях, листья постепенно отмирают.',
        [
          'Фитоспорин или 1% бордоская жидкость.',
          'Удалите сильно больные листья.',
          'Не загущайте посадки.'
        ],
        [
          'Севооборот 3 года.',
          'Уборка ботвы.',
          'Протравливание семян.'
        ]),
    ProblemSpec('Корнеед всходов', true, 2,
        'Стебелёк всхода темнеет и истончается, всходы падают и гибнут.', [
      'Удалите больные всходы.',
      'Подсушите почву, присыпьте золой.',
      'Пролейте Фитоспорином.'
    ], [
      'Не загущайте посев.',
      'Умеренный полив.',
      'Рыхление и проветривание.'
    ]),
    ProblemSpec('Свекольная муха', false, 2,
        'Вздутия и ходы в листьях, листья буреют и сохнут.', [
      'Удалите минированные листья.',
      'Укройте спанбондом.',
      'Фитоверм при массовом лёте.'
    ], [
      'Ранний посев.',
      'Уборка сорняков.',
      'Перекопка осенью.'
    ]),
  ];

  static const _poaceae = [
    ProblemSpec(
        'Пузырчатая головня',
        true,
        2,
        'Вздутия на зёрнах и листьях, заполненные серой пылью спор; початок деформирован.',
        [
          'Удалите и сожгите поражённые початки.',
          'Не оставляйте их на грядке.',
          'Протравливайте семена перед посевом.'
        ],
        [
          'Устойчивые гибриды.',
          'Севооборот.',
          'Не загущайте посев.'
        ]),
    ProblemSpec(
        'Проволочник',
        false,
        2,
        'Личинки повреждают всходы и подземный стебель, растения выпадают из ряда.',
        [
          'Ловушки с картофелем ранней весной.',
          'Известкование кислых почв.',
          'Горчица как сидерат.'
        ],
        [
          'Борьба с пыреем.',
          'Осенняя перекопка.',
          'Севооборот.'
        ]),
    ProblemSpec('Шведская муха', false, 2,
        'Центральный лист всхода желтеет и засыхает, куст не развивается.', [
      'Удалите повреждённые всходы.',
      'Подсейте резервные растения.',
      'Ранний посев уходит от лёта.'
    ], [
      'Протравленные семена.',
      'Ранние сроки посева.',
      'Уборка растительных остатков.'
    ]),
  ];

  static const _polygonaceae = [
    ProblemSpec(
        'Ржавчина',
        true,
        2,
        'Оранжевые подушечки-пустулы на нижней стороне листьев, листья желтеют и сохнут.',
        [
          'Удалите поражённые листья.',
          'Фитоспорин после срезки.',
          'Не оставляйте старую листву зимовать.'
        ],
        [
          'Не загущайте куст.',
          'Полив под корень.',
          'Обновление посадок каждые 4 года.'
        ]),
    ProblemSpec('Щавелевый листоед', false, 2,
        'Мелкие дырочки и скелетированные листья, мелкие тёмные личинки.', [
      'Ручной сбор личинок.',
      'Срезка всей листвы с последующим отрастанием.',
      'Фитоверм при массовом появлении.'
    ], [
      'Осмотр весной.',
      'Уборка растительных остатков.',
      'Рыхление под кустами.'
    ]),
    ProblemSpec('Корневая гниль', true, 2,
        'Куст вянет при влажной почве, корни бурые и мягкие.', [
      'Удалите больной куст.',
      'Улучшите дренаж, сократите полив.',
      'Пролейте биофунгицидом.'
    ], [
      'Не сажайте в низине.',
      'Дренаж и умеренный полив.',
      'Деление и пересадка каждые 4 года.'
    ]),
  ];

  static const _lamiaceae = [
    ProblemSpec('Мучнистая роса', true, 2,
        'Белый налёт на листьях, лист теряет аромат и засыхает.', [
      'Удалите больные побеги.',
      'Фитоспорин (можно перед срезкой).',
      'Проредите куст для проветривания.'
    ], [
      'Не загущайте.',
      'Полив под корень утром.',
      'Солнечное место.'
    ]),
    ProblemSpec(
        'Корневая гниль от перелива',
        true,
        3,
        'Побеги вянут при мокрой почве, основание стебля буреет, корни мягкие.',
        [
          'Прекратите полив, просушите почву.',
          'Удалите больные побеги.',
          'Пересадите в дренированный грунт.'
        ],
        [
          'Дренаж обязателен.',
          'Полив по подсыханию.',
          'Не сажайте в низине.'
        ]),
    ProblemSpec(
        'Тля и паутинный клещ',
        false,
        2,
        'Скрученные верхушки, липкая падь или тонкая паутинка и светлые точки на листьях.',
        [
          'Смойте сильной струёй воды.',
          'Фитоверм с учётом срока ожидания.',
          'Срежьте сильно заселённые верхушки.'
        ],
        [
          'Осмотр раз в неделю.',
          'Не пересушивайте воздух в теплице.',
          'Уборка сорняков.'
        ]),
  ];

  static const _rosaceae = [
    ProblemSpec(
        'Серая гниль',
        true,
        3,
        'Ягоды и плоды покрываются серым пушистым налётом, размягчаются и мумифицируются.',
        [
          'Уберите и уничтожьте больные плоды.',
          'Подложите мульчу под кисти.',
          'Фитоспорин до цветения и после сбора.'
        ],
        [
          'Мульча — плоды не касаются земли.',
          'Не загущайте.',
          'Полив под корень утром.'
        ]),
    ProblemSpec(
        'Пятнистости листьев',
        true,
        2,
        'Бурые или пурпурные пятна на листьях, преждевременное опадение листвы.',
        [
          'Уберите и сожгите больные листья.',
          'Обработка после сбора урожая.',
          'Омоложение посадок.'
        ],
        [
          'Не загущайте кусты.',
          'Уборка листвы осенью.',
          'Устойчивые сорта.'
        ]),
    ProblemSpec(
        'Тля и клещ',
        false,
        2,
        'Сморщенные молодые листья, колонии насекомых, тонкая паутинка в жару.',
        [
          'Фитоверм после сбора урожая.',
          'Мыльный раствор по колониям.',
          'Удалите сильно поражённые побеги.'
        ],
        [
          'Осмотр молодых листьев.',
          'Здоровый посадочный материал.',
          'Уборка сорняков.'
        ]),
  ];
}
