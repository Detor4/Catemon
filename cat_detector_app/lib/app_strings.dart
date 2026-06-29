import 'profile_store.dart';

enum AppLang { uz, ru, en }

extension AppLangX on AppLang {
  String get code => switch (this) {
        AppLang.uz => 'uz',
        AppLang.ru => 'ru',
        AppLang.en => 'en',
      };

  String get label => switch (this) {
        AppLang.uz => 'O\'zbekcha',
        AppLang.ru => 'Русский',
        AppLang.en => 'English',
      };

  String get flag => switch (this) {
        AppLang.uz => '🇺🇿',
        AppLang.ru => '🇷🇺',
        AppLang.en => '🇬🇧',
      };

  static AppLang fromCode(String? code) => switch (code) {
        'ru' => AppLang.ru,
        'en' => AppLang.en,
        _ => AppLang.uz,
      };
}

/// Lokalizatsiya. Joriy til [ProfileStore] dan olinadi.
class S {
  const S(this.lang);

  final AppLang lang;

  static S get current => S(ProfileStore.instance.lang);

  String _p(String uz, String ru, String en) => switch (lang) {
        AppLang.uz => uz,
        AppLang.ru => ru,
        AppLang.en => en,
      };

  // ── Umumiy ──
  String get appName => 'Catemon';
  String get cancel => _p('Bekor', 'Отмена', 'Cancel');
  String get delete => _p('O\'chirish', 'Удалить', 'Delete');
  String get save => _p('Saqlash', 'Сохранить', 'Save');
  String get done => _p('Tayyor', 'Готово', 'Done');
  String get share => _p('Ulashish', 'Поделиться', 'Share');
  String get comingSoon =>
      _p('Tez orada qo\'shiladi', 'Скоро будет добавлено', 'Coming soon');

  // ── Navigatsiya ──
  String get collection => _p('Kolleksiya', 'Коллекция', 'Collection');
  String get upgrade => _p('Upgrade', 'Апгрейд', 'Upgrade');
  String get camera => _p('Kamera', 'Камера', 'Camera');

  // ── Home / Profil ──
  String get tagline => _p('Real mushuklar, haqiqiy kolleksiya',
      'Настоящие коты, реальная коллекция', 'Real cats, real collection');
  String get profile => _p('Profil', 'Профиль', 'Profile');
  String get player => _p('O\'yinchi', 'Игрок', 'Player');
  String get cats => _p('mushuk', 'котов', 'cats');
  String get catsCount => _p('Mushuklar', 'Котов', 'Cats');
  String get level => _p('Daraja', 'Уровень', 'Level');
  String get power => _p('Kuch', 'Сила', 'Power');
  String get achievements => _p('Yutuqlar', 'Достижения', 'Achievements');
  String get settings => _p('Sozlamalar', 'Настройки', 'Settings');
  String get showcase => _p('Vitrina mushuk', 'Витрина', 'Showcase cat');
  String get chooseShowcase =>
      _p('Vitrina uchun mushuk tanlang', 'Выберите кота для витрины',
          'Choose a showcase cat');
  String get editName => _p('Ismni o\'zgartirish', 'Изменить имя', 'Edit name');
  String get changeAvatar =>
      _p('Avatarni o\'zgartirish', 'Сменить аватар', 'Change avatar');
  String get noCatsYet =>
      _p('Hali mushuk yo\'q', 'Пока нет котов', 'No cats yet');
  String levelLabel(int n) => _p('Daraja $n', 'Уровень $n', 'Level $n');
  String get toNextLevel =>
      _p('keyingi darajagacha', 'до следующего уровня', 'to next level');

  // ── Settings ──
  String get language => _p('Til', 'Язык', 'Language');
  String get selectLanguage =>
      _p('Tilni tanlang', 'Выберите язык', 'Select language');
  String get about => _p('Ilova haqida', 'О приложении', 'About');
  String get version => _p('Versiya', 'Версия', 'Version');

  // ── Achievements ──
  String get achievementsTitle =>
      _p('Yutuqlar', 'Достижения', 'Achievements');
  String get achievementsSubtitle => _p('Titullar va mukofotlar',
      'Титулы и награды', 'Titles and rewards');
  String get earned => _p('Qo\'lga kiritildi', 'Получено', 'Earned');
  String get locked => _p('Yopiq', 'Закрыто', 'Locked');
  String get activeTitle =>
      _p('Faol titul', 'Активный титул', 'Active title');
  String get setAsTitle =>
      _p('Titul qilib qo\'yish', 'Сделать титулом', 'Set as title');
  String get noTitle => _p('Titul yo\'q', 'Без титула', 'No title');
  String progressOf(int a, int b) => '$a / $b';

  // Achievement nomlari
  String get achFirstCatTitle =>
      _p('Yangi boshlovchi', 'Новичок', 'Beginner');
  String get achFirstCatDesc => _p('Birinchi mushukni to\'pla',
      'Поймай первого кота', 'Collect your first cat');
  String get achCollectorTitle =>
      _p('Kolleksioner', 'Коллекционер', 'Collector');
  String get achCollectorDesc => _p('30 ta mushukka ega bo\'l',
      'Собери 30 котов', 'Own 30 cats');
  String get achLegendTitle =>
      _p('Afsonalar ustasi', 'Мастер легенд', 'Legend Master');
  String get achLegendDesc => _p('3 ta Legendary mushuk to\'pla',
      'Собери 3 легендарных кота', 'Collect 3 Legendary cats');
  String get achMythicTitle =>
      _p('Mifik egasi', 'Владелец мифа', 'Mythic Owner');
  String get achMythicDesc => _p('1 ta Mythic mushuk to\'pla',
      'Собери 1 мифического кота', 'Collect 1 Mythic cat');
  String get achLevelTitle => _p('Tajribali', 'Опытный', 'Veteran');
  String get achLevelDesc => _p('10-darajaga yet',
      'Достигни 10 уровня', 'Reach level 10');
  String get achStreakTitle =>
      _p('Sodiq o\'yinchi', 'Преданный игрок', 'Loyal Player');
  String get achStreakDesc => _p('7 kun ketma-ket o\'yinga kir',
      'Заходи 7 дней подряд', 'Log in 7 days in a row');

  // ── Cat play view ──
  String get accuracy => _p('Aniqlik', 'Точность', 'Accuracy');
  String get color => _p('Rang', 'Цвет', 'Color');
  String get quality => _p('Sifat', 'Качество', 'Quality');
  String get date => _p('Sana', 'Дата', 'Date');
  String get colorQuality =>
      _p('Rang sifati', 'Качество цвета', 'Color quality');
  String get deleteCatTitle =>
      _p('O\'chirish', 'Удалить', 'Delete');
  String get deleteCatBody => _p('Bu mushukni o\'chirmoqchimisiz?',
      'Удалить этого кота?', 'Delete this cat?');
  String get swipeHint => _p('Panelni torting',
      'Потяните панель', 'Drag the panel');
  String get info => _p('Ma\'lumot', 'Информация', 'Info');

  // ── Gallery ──
  String get myCollection =>
      _p('Kolleksiyam', 'Моя коллекция', 'My Collection');
  String catsFound(int n) => _p('$n ta mushuk topilgan',
      'Найдено котов: $n', '$n cats found');
  String get emptyGalleryTitle =>
      _p('Hali mushuk yo\'q', 'Пока нет котов', 'No cats yet');
  String get emptyGalleryBody => _p(
      'Kameraga o\'ting va birinchi mushukni toping!',
      'Откройте камеру и найдите первого кота!',
      'Open the camera and find your first cat!');
  String get goToCamera =>
      _p('Kameraga o\'tish', 'Открыть камеру', 'Open camera');

  // ── Time ──
  String daysAgo(int n) => _p('$n kun oldin', '$n дн. назад', '$n days ago');
  String hoursAgo(int n) =>
      _p('$n soat oldin', '$n ч. назад', '$n hours ago');
  String minutesAgo(int n) =>
      _p('$n daqiqa oldin', '$n мин. назад', '$n minutes ago');
  String get justNow => _p('hozirgina', 'только что', 'just now');
}
