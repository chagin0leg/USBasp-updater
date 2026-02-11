/// Class for managing tips in various languages.
///
/// This class contains tips in different languages, which are used
/// to display messages to the user during various operations.
///
/// - 'ru': Tips in Russian.
/// - 'en': Tips in English.
///
/// Each tip corresponds to a specific stage or event in the program's operation.
class TipsManager {
  final Map<String, Map<String, String>> _tipsMap = {
    'ru': {
      'rnu': 'Введите, сгенерируйте или прочитайте серийный номер.',
      'rwu': 'Нажмите «Загрузить прошивку».',
      'cic': 'Проверка подключения к интернету...',
      'ice': 'Подключение к интернету установлено.',
      'nic': 'Ошибка: нет подключения к интернету.',
      'dld': 'Загрузка зависимостей...',
      'upd': 'Распаковка зависимостей...',
      'cpc': 'Проверка подключения программатора...',
      'udw': 'Предупреждение: возможны проблемы с драйвером!',
      'tdc': 'Всё хорошо! Можно считать или обновить UUID.',
      'pnf': 'Ошибка: не найден прошивающий программатор!',
      'tdn': 'Ошибка: целевое устройство не подключено!',
      'ruu': 'Чтение UUID с целевого устройства...',
      'pfi': 'Подготовка образа прошивки...',
      'ufi': 'Загрузка образа прошивки...',
      'ups': 'Прошивка успешно загружена.',
      'ube': 'Ошибка при сборке. Проверьте окружение и логи.',
      'ufe': 'Введённый UUID не соответствует формату. Проверьте и попробуйте снова.',
      'ucp': 'UUID скопирован в буфер обмена.'
    },
    'en': {
      'rnu': 'Enter, generate or read the serial number.',
      'rwu': 'Click «Upload Firmware».',
      'cic': 'Checking internet connection...',
      'ice': 'Internet connection established.',
      'nic': 'Error: no internet connection.',
      'dld': 'Downloading dependencies...',
      'upd': 'Unpacking dependencies...',
      'cpc': 'Checking programmer connection...',
      'udw': 'Warning: potential driver issues!',
      'tdc': 'All good! You can read or update the UUID.',
      'pnf': 'Error: programmer not found!',
      'tdn': 'Error: target device not connected!',
      'ruu': 'Reading UUID from the target device...',
      'pfi': 'Preparing firmware image...',
      'ufi': 'Uploading firmware image...',
      'ups': 'Firmware uploaded successfully.',
      'ube': 'Build error. Check environment and logs.',
      'ufe': 'UUID format is invalid. Check and try again.',
      'ucp': 'UUID copied to clipboard.'
    }
  };

  String _currentLocale;

  /// Constructor, allows setting the locale during initialization.
  ///
  /// Parameters:
  /// - [initialLocale]: The locale to set when creating an instance (e.g., 'ru' or 'en').
  ///
  /// Throws:
  /// - [ArgumentError]: If an unsupported locale is passed.
  ///
  /// Example:
  /// ```dart
  /// // Example with automatic locale detection based on system language
  /// String systemLocale = Platform.localeName.split('_').first;
  /// TipsManager tipsManager = TipsManager(initialLocale: systemLocale);
  /// ```
  TipsManager({String initialLocale = 'ru'}) : _currentLocale = initialLocale {
    if (!_tipsMap.containsKey(initialLocale)) {
      throw ArgumentError('Unsupported locale: $initialLocale');
    }
  }

  /// Sets the current locale for tips.
  ///
  /// Parameters:
  /// - [locale]: The locale to set (e.g., 'ru' or 'en').
  ///
  /// Throws:
  /// - [ArgumentError]: If an unsupported locale is passed.
  void setLocale(String locale) {
    if (_tipsMap.containsKey(locale)) {
      _currentLocale = locale;
    } else {
      throw ArgumentError('Unsupported locale: $locale');
    }
  }

  /// Returns the current locale.
  ///
  /// Returns:
  /// - The current locale as a string.
  ///
  /// Example:
  /// ```dart
  /// TipsManager tipsManager = TipsManager();
  /// print(tipsManager.currentLocale); // 'ru'
  /// ```
  String get currentLocale => _currentLocale;

  /// Returns the map of tips for the current locale.
  ///
  /// Returns:
  /// - The map of tips for the current locale.
  ///
  /// Example:
  /// ```dart
  /// TipsManager tipsManager = TipsManager();
  /// Map<String, String> tips = tipsManager.tips;
  /// print(tips['checkInternetConnection']); // 'Проверка подключения к интернету...'
  /// ```
  Map<String, String> get tips => _tipsMap[_currentLocale] ?? {};
}
