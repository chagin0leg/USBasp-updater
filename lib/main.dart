import 'dart:async';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_svg/flutter_svg.dart';

String path = "";
String version = "";
final uuidFieldKey = GlobalKey<_UuidFieldState>();
final uuidField = UuidField(key: uuidFieldKey);
final toolBarFieldKey = GlobalKey<_ToolBarFieldState>();
final toolBarField = ToolBarField(key: toolBarFieldKey);

const List<String> components = [
  'https://github.com/chagin0leg/USBasp-updater/releases/download/0.0.0/usbasp-firmware-v1.13.zip',
  'https://github.com/avrdudes/avrdude/releases/download/v8.0/avrdude-v8.0-windows-x64.zip',
  'https://github.com/ZakKemble/avr-gcc-build/releases/download/v7.3.0-1/avr-gcc-7.3.0-x64-mingw.zip',
];

void main(List<String> arguments) async {
  if (arguments.length == 2 && arguments[1] == "--path") path = arguments[1];
  checkDeviceDriverWindows(vid: '16C0', pid: '05DC', driver: 'libusbK');
  for (var component in components) {
    downloadFile(url: component);
  }
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    // await checkProgrammerConnection(avrdude: Directory.current);
  });
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await Window.initialize();
  await Window.setEffect(
      effect: WindowEffect.transparent, color: Colors.white24);

  runApp(const MainAppPage());

  doWhenWindowReady(() {
    const initialSize = Size(800, 320);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});
  @override
  MainAppPageState createState() => MainAppPageState();
}

class MainAppPageState extends State<MainAppPage> {
  @override
  void initState() {
    super.initState();
    _initializeWindow();
  }

  Future<void> _initializeWindow() async {
    // version = (await PackageInfo.fromPlatform()).version;
    WindowOptions windowOptions = const WindowOptions(
        skipTaskbar: true,
        alwaysOnTop: true,
        size: Size(800, 320),
        minimumSize: Size(800, 320),
        maximumSize: Size(800, 320),
        titleBarStyle: TitleBarStyle.hidden);
    await windowManager.waitUntilReadyToShow(windowOptions, () async {});
  }

  bool light = true;
  final _ctrl = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    const String fontFamily = 'Courier New';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16.0, fontFamily: fontFamily),
          bodyMedium: TextStyle(fontSize: 14.0, fontFamily: fontFamily),
          bodySmall: TextStyle(fontSize: 12.0, fontFamily: fontFamily),
          displayLarge: TextStyle(fontSize: 16.0, fontFamily: fontFamily),
          displayMedium: TextStyle(fontSize: 14.0, fontFamily: fontFamily),
          displaySmall: TextStyle(fontSize: 12.0, fontFamily: fontFamily),
          titleLarge: TextStyle(fontSize: 16.0, fontFamily: fontFamily),
          titleMedium: TextStyle(fontSize: 14.0, fontFamily: fontFamily),
          titleSmall: TextStyle(fontSize: 12.0, fontFamily: fontFamily),
          labelLarge: TextStyle(fontSize: 16.0, fontFamily: fontFamily),
          labelMedium: TextStyle(fontSize: 14.0, fontFamily: fontFamily),
          labelSmall: TextStyle(fontSize: 12.0, fontFamily: fontFamily),
        ),
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned(
              bottom: -20,
              right: 20,
              child: SvgPicture.asset(
                width: 360,
                'assets/usbasp_isometric.drawio.svg',
                alignment: Alignment.bottomRight,
              ),
            ),
            MoveWindow(
              onDoubleTap: () {},
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WorkSpace(),
                    SettingsSpace(ctrl: _ctrl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _boxShadow = [
  BoxShadow(
      color: Colors.black38,
      blurRadius: 2,
      offset: Offset(0, 0),
      blurStyle: BlurStyle.solid)
];

class SettingsSpace extends StatelessWidget {
  const SettingsSpace({
    super.key,
    required ValueNotifier<bool> ctrl,
  }) : _ctrl = ctrl;

  final ValueNotifier<bool> _ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 140,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(222, 255, 255, 255),
          boxShadow: _boxShadow),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CacheSetting(ctrl: _ctrl),
          UpdateSetting(ctrl: _ctrl),
          const TipsField()
        ],
      ),
    );
  }
}

/// Верхняя часть окна с основным функционалом приложения
class WorkSpace extends StatelessWidget {
  const WorkSpace({super.key});
  @override
  Widget build(BuildContext context) => Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(222, 255, 255, 255),
          boxShadow: _boxShadow),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [uuidField, toolBarField]));
}

class TipsField extends StatelessWidget {
  const TipsField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), color: Colors.white),
        child:
            SelectableText(onTap: () {}, 'Здесь будут отображаться подсказки'),
      ),
    );
  }
}

class UpdateSetting extends StatelessWidget {
  const UpdateSetting({
    super.key,
    required ValueNotifier<bool> ctrl,
  }) : _ctrl = ctrl;

  final ValueNotifier<bool> _ctrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          const SizedBox(width: 5),
          AdvancedSwitch(
            controller: _ctrl,
            width: 30.0,
            height: 15.0,
          ),
          const SizedBox(width: 10),
          const Text('Включить авто-обновление'),
        ],
      ),
    );
  }
}

class CacheSetting extends StatelessWidget {
  const CacheSetting({
    super.key,
    required ValueNotifier<bool> ctrl,
  }) : _ctrl = ctrl;

  final ValueNotifier<bool> _ctrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          const SizedBox(width: 5),
          AdvancedSwitch(
            controller: _ctrl,
            width: 30.0,
            height: 15.0,
          ),
          const SizedBox(width: 10),
          const Text('Ускорить первый запуск'),
        ],
      ),
    );
  }
}

class ToolBarField extends StatefulWidget {
  const ToolBarField({super.key});
  @override
  State<ToolBarField> createState() => _ToolBarFieldState();
}

class _ToolBarFieldState extends State<ToolBarField> {
  var _progress = 0, _visibleProgress = 0, _updateStarted = false;
  addProgress({required int value}) => setProgress(value: _progress + value);

  void setProgress({required int value}) => setState(() {
        if ((_progress = max(min(value, 100), 0)) == 0) _visibleProgress = 0;
        if (!_updateStarted && (_updateStarted = true)) _update();
      });

  void _update() async => setState(() {
        if (_visibleProgress == _progress && !(_updateStarted = false)) return;
        _visibleProgress += (_visibleProgress < _progress) ? 1 : -1;
        Future.delayed(const Duration(milliseconds: 1), () => _update());
      });

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox.fromSize(
            size: const Size(400, 25),
            child: LinearProgressIndicator(
                value: _visibleProgress / 100.0,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue))),
        _iconButton(
            icon: Icons.local_cafe_outlined,
            tooltip: 'Read from EEPROM',
            onPressed: () async {
              final uuid = await readEeprom(avrdude: Directory.current);
              if (uuid != null) uuidFieldKey.currentState?.fillUuid(uuid);
            }),
        _iconButton(
            icon: Icons.ramen_dining,
            tooltip: 'Generate & Copy',
            onPressed: () {
              final uuid = uuidFieldKey.currentState?.generateUuid();
              if (uuid != null) uuidFieldKey.currentState?.fillUuid(uuid);
              setProgress(value: 0);
            }),
        _iconButton(
            icon: Icons.local_fire_department,
            tooltip: 'Upload Firmware',
            onPressed: () {
              final uuid = uuidFieldKey.currentState?.getUuid();
              if (uuid != null) upload(uuid: uuid);
            }),
        Expanded(child: Container()),
        _iconButton(
            icon: Icons.exit_to_app,
            tooltip: 'Abort & Quit',
            onPressed: () {
              exit(0);
            }),
      ]);

  Widget _iconButton({IconData? icon, String? tooltip, Function()? onPressed}) {
    return Row(children: [
      const SizedBox(height: 25, width: 10),
      SizedBox.fromSize(
          size: const Size(25, 25),
          child: IconButton(
              tooltip: tooltip ?? '',
              icon: Icon(icon),
              onPressed: onPressed,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tight(const Size(25, 25))))
    ]);
  }
}

class UuidField extends StatefulWidget {
  const UuidField({super.key});
  static const Map<String, String> _keyMap = {
    'й': 'q', 'ц': 'w', 'у': 'e', 'к': 'r', 'е': 't', 'н': 'y', 'г': 'u',
    'ш': 'i', 'щ': 'o', 'з': 'p', 'х': '[', 'ъ': ']', 'ф': 'a', 'ы': 's',
    'в': 'd', 'а': 'f', 'п': 'g', 'р': 'h', 'о': 'j', 'л': 'k', 'д': 'l',
    'ж': ';', 'э': "'", 'я': 'z', 'ч': 'x', 'с': 'c', 'м': 'v', 'и': 'b',
    'т': 'n', 'ь': 'm', 'б': ',', 'ю': '.', 'ё': '`', ' ': ' ', // RU-EN
  };
  @override
  State<UuidField> createState() => _UuidFieldState();
}

class _UuidFieldState extends State<UuidField> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        if (index % 2 == 1) return const Text("-");
        const hints = ['XXXXXXXX', 'XXXXXXXX', 'XXXXXXXX', 'XXXXXXXX'];
        int fieldIndex = index ~/ 2;
        return SizedBox.fromSize(
            size: const Size(150, 25),
            child: TextField(
                controller: _controllers[fieldIndex],
                focusNode: _focusNodes[fieldIndex],
                showCursor: true,
                cursorHeight: 20,
                textAlign: TextAlign.center,
                textAlignVertical: const TextAlignVertical(y: 0.75),
                style: const TextStyle(fontSize: 20),
                maxLength: 8,
                decoration: InputDecoration(
                  counterText: '',
                  border: const OutlineInputBorder(),
                  hintText: hints[fieldIndex],
                ),
                onChanged: (text) => _uuidFormatter(text, fieldIndex)));
      }),
    );
  }

  void fillUuid(String uuid, {int i = 0}) {
    if (uuid.length != 32) throw ArgumentError('UUID менее 32 символов');
    for (i = 0; i < 4; _controllers[i].text = '', i++) {}
    for (i = 0; i < 4; _uuidFormatter(uuid.substring(8 * i, 8 * i + 8), i++)) {}
  }

  String? getUuid() {
    String uuid = _controllers.map((controller) => controller.text).join('-');
    if (RegExp(r'^([0-9a-fA-F]{8}-?){4}$').hasMatch(uuid)) return uuid;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Введенный UUID не соответствует формату. Пожалуйста, проверьте и попробуйте снова.')),
    );
    return null;
  }

  String generateUuid({String chars = '0123456789abcdeffedcba'}) =>
      List.generate(32, (i) => chars[Random().nextInt(chars.length)]).join();

  void _uuidFormatter(String text, int fieldIndex) {
    final output = text
        .replaceAll(RegExp(r'[^фФaAиИbBсСcCвВdDуУeEаАfF0-9]'), '')
        .toLowerCase()
        .split('')
        .map((char) => UuidField._keyMap[char] ?? char)
        .join();
    final int cursorPosition = _controllers[fieldIndex].selection.base.offset;
    final int newCursorPosition = min(cursorPosition, output.length);
    _controllers[fieldIndex].value = _controllers[fieldIndex].value.copyWith(
        text: output,
        selection: TextSelection.collapsed(offset: newCursorPosition));
    if (output.length == 8 && fieldIndex < _controllers.length - 1) {
      FocusScope.of(context).requestFocus(_focusNodes[fieldIndex + 1]);
    } else if (output.isEmpty && fieldIndex > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[fieldIndex - 1]);
    }
    if (_controllers.every((ctrl) => ctrl.text.length == 8)) {
      final uuid = _controllers.map((controller) => controller.text).join('-');
      Clipboard.setData(ClipboardData(text: uuid));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UUID скопирован в буфер обмена')),
      );
    }
    setState(() {});
  }
}

// ========================================================================== //

Future<String> findFile({required String file, required Directory dir}) async {
  for (var f in await dir.list(recursive: true, followLinks: false).toList()) {
    if (f is File && f.path.contains(file)) return f.absolute.path;
  }
  return file;
}

Future<int> checkProgrammerConnection({required Directory avrdude}) async {
  int result = -1;
  var command = [await findFile(file: "avrdude.exe", dir: avrdude)];
  command += ['-c', 'usbasp', '-p', 'm16', '-P', 'usb'];
  command += ['-U', 'hfuse:r:-:h', '-U', 'lfuse:r:-:h'];

  var process = await Process.start(command.first, command.skip(1).toList());

  process.stdout
      .transform(const SystemEncoding().decoder)
      .listen((data) => stdout.write(data));

  process.stderr.transform(const SystemEncoding().decoder).listen((data) {
    if (data.contains('Device signature')) {
      Logger().i('Всё хорошо: целевое устройство подключено. ${result = 0}');
    } else if (data.contains('could not find USB device')) {
      Logger().e('Ошибка: не найден прошивающий программатор. ${result = 1}');
    } else if (data.contains('target doesn\'t answer')) {
      Logger().e('Ошибка: целевое устройство не подключено.  ${result = 2}');
    }
    // stderr.write(data); // негодяи шлют данные не в тот поток
  });

  var exitCode = await process.exitCode;
  Logger().i('Проверка подключения завершена. Код завершения $exitCode');
  return result;
}

Future<bool> checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      Logger().i('Подключение к интернету установлено.');
      return true;
    }
  } on SocketException catch (_) {
    Logger().e('Ошибка: нет подключения к интернету.');
    return false;
  }
  return false;
}

Future<bool> checkDeviceDriverWindows(
    {required String vid, required String pid, required String driver}) async {
  var ls = (await Process.run('pnputil', ['/enum-drivers'])).stdout.split('\n');
  for (int i = 0; i < ls.length; i++) {
    if (ls[i].contains(vid) && ls[i].contains(pid)) {
      for (int j = max(0, i - 7); j <= i; j++) {
        if (ls[j].trim().contains(driver)) return true;
      }
    }
  }
  return false;
}

Future<void> downloadFile({required String url}) async {
  final appFolder = Directory('${Directory.current.path}/temporary');
  if (!await appFolder.exists()) await appFolder.create();
  final savePath = '${appFolder.path}/${url.split('/').last}';

  try {
    final headers = (await Dio().head(url)).headers;
    final contentLength = int.tryParse(headers.value('content-length') ?? '');

    final existingFile = File(savePath);
    if (await existingFile.exists()) {
      final fileSize = await existingFile.length();
      if (contentLength != null && fileSize == contentLength) {
        Logger().i('Файл уже существует и цел: $savePath');
        extractZip(url: url);
        return;
      }
    }

    int lastLogSecond = -1;
    await Dio().download(url, savePath, onReceiveProgress: (received, total) {
      if (total != -1 && DateTime.now().second != lastLogSecond) {
        lastLogSecond = DateTime.now().second;
        Logger().i('$received / $total');
      }
    });
    Logger().i('Файл успешно скачан по пути: $savePath');
    extractZip(url: url);
  } catch (error) {
    Logger().e(error);
  }
}

Future<void> extractZip({required String url}) async {
  final f = url.split('/').last, tmp = '${Directory.current.path}/temporary';
  final zip = File('$tmp/$f'), path = '$tmp/${f.replaceFirst('.zip', '')}';
  if (!await zip.exists()) throw FileSystemException('ZIP не найден', zip.path);
  final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());

  for (ArchiveFile file in archive) {
    final filePath = '$path/${file.name}';
    if (file.isFile) {
      final data = file.content as List<int>;
      await File(filePath).create(recursive: true);
      await File(filePath).writeAsBytes(data);
    } else {
      await Directory(filePath).create(recursive: true);
      Logger().i(file.name);
    }
  }

  Logger().i('Архив успешно распакован: $path');
}

// === Firmware ============================================================= //

Future<String?> readEeprom({required Directory avrdude}) async {
  var command = [await findFile(file: "avrdude.exe", dir: avrdude)];
  command += ['-c', 'usbasp', '-p', 'm8', '-P', 'usb', '-U', 'eeprom:r:-:r'];
  toolBarFieldKey.currentState?.setProgress(value: 0);

  try {
    List<int> eeprom = [];
    var process = await Process.start(command.first, command.skip(1).toList());
    await process.stdout.listen((data) => eeprom.addAll(data)).asFuture();
    var exitCode = await process.exitCode;
    if (exitCode != 0) {
      Logger().e('Ошибка при чтении EEPROM. Код завершения: $exitCode');
      return null;
    }
    toolBarFieldKey.currentState?.setProgress(value: 25);

    eeprom = eeprom.sublist(0, eeprom.first);
    var out = eeprom.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    Logger().i('Прочитано из EEPROM (первые ${eeprom.first} байт): $out');
    if (eeprom.every((value) => value == 0xFF)) {
      Logger().e('EEPROM пока чист. Серийный номер не найден');
      return null;
    }
    toolBarFieldKey.currentState?.setProgress(value: 50);

    eeprom = eeprom.where((e) => e != 0).toList().sublist(2);
    if (eeprom.every((value) => value >= 0x20 && value <= 0x7A)) {
      toolBarFieldKey.currentState?.setProgress(value: 75);
      String eepromString = String.fromCharCodes(eeprom);
      Logger().i('ASCII представление EEPROM (обработанные): $eepromString');
      if (RegExp(r'^([0-9a-fA-F]{8}-?){4}$').hasMatch(eepromString)) {
        Logger().i('Серийный номер найден в EEPROM');
        toolBarFieldKey.currentState?.setProgress(value: 100);
        return eepromString.replaceAll('-', '');
      }
    }
    Logger().e('Серийный номер найден, но не соответствует формату');
    return null;
  } catch (e) {
    Logger().e('Ошибка при выполнении команды: $e');
    return null;
  }
}

Future<void> clean({required Directory buildPath}) async {
  Logger().i('Running clean...');

  toolBarFieldKey.currentState?.setProgress(value: 0);
  final ext = ['.o', '.lst', '.obj', '.cof', '.list', '.map', '.bin', '.s'];
  var files = List.empty(growable: true), deletedFiles = 0;
  await for (var e in buildPath.list(recursive: true, followLinks: false)) {
    if (e is File && ext.any((ext) => e.path.endsWith(ext))) files.add(e);
  }

  for (FileSystemEntity file in files) {
    try {
      await File(file.path).delete();
      double process = (++deletedFiles) / files.length / 4 * 100;
      Logger().i('[${(process).toInt()}%] Deleted: ${file.path}');
      toolBarFieldKey.currentState?.setProgress(value: (process).toInt());
    } catch (e) {
      Logger().e('Failed to delete ${file.path}: $e');
    }
  }
  Logger().i('Clean done.');
}

Future<void> build(
    {required Directory buildPath,
    required Directory toolchain,
    required String uuid}) async {
  Logger().i('Running build firmware...');

  final path = buildPath.path;
  final uuidDef = '-DUSB_CFG_SERIAL_NUMBER=${uuid.codeUnits.join(',')}';
  final uuidLenDefine = '-DUSB_CFG_SERIAL_NUMBER_LEN=${uuid.length}';

  List<String> comFlags = ['-Wall', '-Wextra', '-fno-move-loop-invariants'];
  comFlags += ['-fno-tree-scev-cprop', '-fno-inline-small-functions', '-Os'];
  comFlags += ['-mmcu=atmega8', '-DF_CPU=12000000', uuidDef];
  comFlags += ['-I$path/usbdrv', '-I$path', uuidLenDefine];

  final avrGcc = await findFile(file: "avr-gcc.exe", dir: toolchain);
  final avrObj = await findFile(file: "avr-objcopy.exe", dir: toolchain);

  Logger().i('Step 1: Compiling all project files...');
  List<String> projectFiles = ['isp.c', 'clock.c', 'tpi.S', 'serialnumber.c'];
  projectFiles += ['main.c', 'uart.c', 'usbdrv/oddebug.c'];
  projectFiles += ['usbdrv/usbdrv.c', 'usbdrv/usbdrvasm.S'];
  for (var file in projectFiles) {
    var compile = [avrGcc, ...comFlags, '-c', '$path/$file'];
    compile += ['-o', '$path/${file.split('.').first}.o'];
    if (!await runProcess(compile, "Error compiling $file")) return;
  }
  toolBarFieldKey.currentState?.addProgress(value: 5);

  Logger().i('Step 2: Linking all project files to main.bin...');
  List<String> link = [avrGcc, ...comFlags, '-o'];
  link += ['$path/main.bin', '$path/usbdrv/usbdrv.o'];
  link += ['$path/usbdrv/usbdrvasm.o', '$path/usbdrv/oddebug.o'];
  link += ['$path/isp.o', '$path/clock.o'];
  link += ['$path/tpi.o', '$path/main.o'];
  link += ['$path/uart.o', '$path/serialnumber.o'];
  link += ['-Wl,-Map,main.map'];
  if (!await runProcess(link, "Linking")) return;
  toolBarFieldKey.currentState?.addProgress(value: 5);

  Logger().i('Step 3: Removing old hex files...');
  for (var file in ['$path/main.hex', '$path/main.eep.hex']) {
    if (File(file).existsSync()) File(file).deleteSync();
  }
  toolBarFieldKey.currentState?.addProgress(value: 5);

  Logger().i('Step 4: Generating main.hex...');
  List<String> mainCopy = [avrObj, '-j', '.text', '-j', '.data'];
  mainCopy += ['-O', 'ihex', '$path/main.bin', '$path/main.hex'];
  if (!await runProcess(mainCopy, 'Generating main.hex')) return;
  toolBarFieldKey.currentState?.addProgress(value: 5);

  Logger().i('Step 5: Generating main.eep.hex...');
  List<String> mainEepCopy = [avrObj, '-j', '.eeprom'];
  mainEepCopy += ['--set-section-flags=.eeprom=alloc,load'];
  mainEepCopy += ['--change-section-lma', '.eeprom=0', '-O', 'ihex'];
  mainEepCopy += ['$path/main.bin', '$path/main.eep.hex'];
  if (!await runProcess(mainEepCopy, 'Generating main.eep.hex')) return;

  toolBarFieldKey.currentState?.addProgress(value: 5);
  Logger().i('Build done!');
}

Future<bool> runProcess(List<String> command, String action) async {
  var result = await Process.run(command.first, command.skip(1).toList());
  if (!result.stderr.isEmpty) Logger().e('Error in $action: ${result.stderr}');
  return result.stderr.isEmpty;
}

Future<void> flash(
    {required Directory avrdude, required Directory buildPath}) async {
  Logger().i('Flashing main.hex...');

  var command = [await findFile(file: "avrdude.exe", dir: avrdude)];
  command += ['-c', 'usbasp', '-U', 'flash:w:${buildPath.path}/main.hex:i'];
  command += ['-p', 'm8', '-U', 'eeprom:w:${buildPath.path}/main.eep.hex:i'];

  // var process = await Process.start(command.first, command.sublist(1)), add = 0;
  // process.stderr.transform(const SystemEncoding().decoder).listen((data) {
  //   // stderr.write(data); // негодяи шлют данные не в тот поток
  //   if ((add += '#'.allMatches(data).length) >= 5 && (add -= 5) >= 0) {
  //     toolBarFieldKey.currentState?.addProgress(value: 1);
  //   }
  // });
  var process = await Process.start(command[0], command.sublist(1)), add = 0;
  process.stderr.transform(const SystemEncoding().decoder).listen((data) {
    bool v = ((add += '#'.allMatches(data).length) >= 5 && (add -= 5) >= 0);
    toolBarFieldKey.currentState?.addProgress(value: v ? 1 : 0);
  });

  var exitCode = await process.exitCode;
  Logger().i('Flash complete. Exit code $exitCode');
}

void upload({required String uuid}) async {
  Directory dirFromUrl(String url) => Directory(
      '${Directory.current.path}/temporary/${url.split('/').last.replaceAll('.zip', '')}');
  final usbasp = dirFromUrl(components[0]);
  final avrgcc = dirFromUrl(components[1]);
  final avrdude = dirFromUrl(components[2]);
  await clean(buildPath: usbasp);
  await build(buildPath: usbasp, toolchain: avrgcc, uuid: uuid);
  await flash(buildPath: usbasp, avrdude: avrdude);
}
