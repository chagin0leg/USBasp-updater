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
      'checkInternetConnection': 'Проверка подключения к интернету...',
      'internetConnectionEstablished': 'Подключение к интернету установлено.',
      'noInternetConnection': 'Ошибка: нет подключения к интернету.',
      'downloadingDependencies': 'Загрузка зависимостей...',
      'unpackingDependencies': 'Распаковка зависимостей...',
      'checkingProgrammerConnection': 'Проверка подключения программатора...',
      'usbaspDriverWarning': 'Предупреждение: возможны проблемы с драйвером!',
      'targetDeviceConnected': 'Всё хорошо! Можно считать или обновить UUID.',
      'programmerNotFound': 'Ошибка: не найден прошивающий программатор!',
      'targetDeviceNotConnected': 'Ошибка: целевое устройство не подключено!',
      'readingUUID': 'Чтение UUID с целевого устройства...',
      'preparingFirmwareImage': 'Подготовка образа прошивки...',
      'uploadingFirmwareImage': 'Загрузка образа прошивки...'
    },
    'en': {
      'checkInternetConnection': 'Checking internet connection...',
      'internetConnectionEstablished': 'Internet connection established.',
      'noInternetConnection': 'Error: no internet connection.',
      'downloadingDependencies': 'Downloading dependencies...',
      'unpackingDependencies': 'Unpacking dependencies...',
      'checkingProgrammerConnection': 'Checking programmer connection...',
      'usbaspDriverWarning': 'Warning: potential driver issues!',
      'targetDeviceConnected': 'All good! You can read or update the UUID.',
      'programmerNotFound': 'Error: programmer not found!',
      'targetDeviceNotConnected': 'Error: target device not connected!',
      'readingUUID': 'Reading UUID from the target device...',
      'preparingFirmwareImage': 'Preparing firmware image...',
      'uploadingFirmwareImage': 'Uploading firmware image...'
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
