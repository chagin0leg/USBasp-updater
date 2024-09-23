import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class UploadWidget extends StatefulWidget {
  final bool isReady;
  final String usbasp;
  final String avrdude;
  final String avrgcc;
  const UploadWidget(
      {super.key,
      required this.isReady,
      required this.usbasp,
      required this.avrdude,
      required this.avrgcc});
  @override
  UploadWidgetState createState() => UploadWidgetState();
}

class UploadWidgetState extends State<UploadWidget> {
  final TextEditingController _controller = TextEditingController();
  static String chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  bool _isMaxLengthReached = false;
  double _process = 0;
  bool? _result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          _serialField(),
          const SizedBox(width: 20),
          _isMaxLengthReached
              ? const Icon(Icons.done, color: Colors.green)
              : const Icon(Icons.warning, color: Colors.yellow),
          const SizedBox(width: 40),
          Tooltip(
              message: 'Копировать',
              child: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _isMaxLengthReached ? () => _copySerial() : null)),
          Tooltip(
              message: 'Сгенерировать',
              child: IconButton(
                  icon: const Icon(Icons.new_label),
                  onPressed: _process > 0
                      ? null
                      : () => _formatSerialNumber(_generateSerial()))),
          Tooltip(
              message: 'Скомпилировать и загрузить',
              child: IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: _process > 0
                      ? null
                      : widget.isReady && _isMaxLengthReached
                          ? () => _upload()
                          : null)),
          if (_process > 0) buildProgressIndicator(_process),
          if (_result != null) buildResultIndicator(_result!),
        ],
      ),
    );
  }

  void _copySerial() =>
      Clipboard.setData(ClipboardData(text: _controller.text));

  String _generateSerial() =>
      List.generate(32, (_) => chars[Random().nextInt(chars.length)]).join();

  void _upload() async {
    setState(() => _process = 0);
    setState(() => _result = null);
    await clean(path: widget.usbasp);
    await buildHex(
        path: widget.usbasp,
        toolchain: widget.avrgcc,
        serial: _controller.text);
    await flash(path: widget.usbasp, avrdude: widget.avrdude);
    setState(() => _process = 0);
  }

  Widget buildProgressIndicator(double process) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
            width: 200,
            height: 20,
            child: LinearProgressIndicator(
                value: process, borderRadius: BorderRadius.circular(5))),
        if (process > 0)
          Center(
              child: Text('${(process * 100).toInt()}%',
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)))
      ],
    );
  }

  Widget buildResultIndicator(bool result) => Container(
      width: 200,
      alignment: Alignment.center,
      child: Text(result == true ? "Done!" : "Error",
          style:
              TextStyle(color: _result == true ? Colors.green : Colors.red)));

  Future<void> clean({String? path}) async {
    Logger().i('Running clean...');
    final dir = path != null ? Directory(path) : Directory.current;
    final ext = ['.o', '.lst', '.obj', '.cof', '.list', '.map', '.bin', '.s'];

    List<FileSystemEntity> files = [];
    await for (var e in dir.list(recursive: true, followLinks: false)) {
      if (e is File && ext.any((ext) => e.path.endsWith(ext))) files.add(e);
    }

    int totalFiles = files.length, deletedFiles = 0;

    for (var file in files) {
      try {
        await File(file.path).delete();
        _process = (++deletedFiles) / totalFiles / 4;
        Logger().i('[${(_process * 100).toInt()}%] Deleted: ${file.path}');
        setState(() => _process);
      } catch (e) {
        Logger().e('Failed to delete ${file.path}: $e');
      }
    }

    Logger().i('Clean done.');
  }

  String findFile(String fileName, String path) {
    Directory dir = Directory(path);
    for (var entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.contains(fileName)) {
        return entity.absolute.path;
      }
    }
    return fileName;
  }

  Future<void> buildHex(
      {required String path,
      required String toolchain,
      required String serial}) async {
    Logger().i('Running build firmware...');

    final serialDef = '-DUSB_CFG_SERIAL_NUMBER=${serial.codeUnits.join(',')}';
    final serialLenDefine = '-DUSB_CFG_SERIAL_NUMBER_LEN=${serial.length}';

    List<String> comFlags = ['-Wall', '-Wextra', '-fno-move-loop-invariants'];
    comFlags += ['-fno-tree-scev-cprop', '-fno-inline-small-functions', '-Os'];
    comFlags += ['-mmcu=atmega8', '-DF_CPU=12000000', serialDef];
    comFlags += ['-I$path/usbdrv', '-I$path', serialLenDefine];

    final String avrGcc = findFile("avr-gcc.exe", toolchain);
    final String avrObj = findFile("avr-objcopy.exe", toolchain);

    Logger().i('Step 1: Compiling all project files...');
    List<String> projectFiles = ['isp.c', 'clock.c', 'tpi.S', 'serialnumber.c'];
    projectFiles += ['main.c', 'uart.c', 'usbdrv/oddebug.c'];
    projectFiles += ['usbdrv/usbdrv.c', 'usbdrv/usbdrvasm.S'];
    for (var file in projectFiles) {
      var compile = [avrGcc, ...comFlags, '-c', '$path/$file'];
      compile += ['-o', '$path/${file.split('.').first}.o'];
      if (!await runProcess(compile, "Error compiling $file")) return;
    }
    setState(() => _process += 0.05);

    Logger().i('Step 2: Linking all project files to main.bin...');
    List<String> link = [avrGcc, ...comFlags, '-o'];
    link += ['$path/main.bin', '$path/usbdrv/usbdrv.o'];
    link += ['$path/usbdrv/usbdrvasm.o', '$path/usbdrv/oddebug.o'];
    link += ['$path/isp.o', '$path/clock.o'];
    link += ['$path/tpi.o', '$path/main.o'];
    link += ['$path/uart.o', '$path/serialnumber.o'];
    link += ['-Wl,-Map,main.map'];
    if (!await runProcess(link, "Linking")) return;
    setState(() => _process += 0.05);

    Logger().i('Step 3: Removing old hex files...');
    for (var file in ['$path/main.hex', '$path/main.eep.hex']) {
      if (File(file).existsSync()) File(file).deleteSync();
    }
    setState(() => _process += 0.05);

    Logger().i('Step 4: Generating main.hex...');
    List<String> mainCopy = [avrObj, '-j', '.text', '-j', '.data'];
    mainCopy += ['-O', 'ihex', '$path/main.bin', '$path/main.hex'];
    if (!await runProcess(mainCopy, 'Generating main.hex')) return;
    setState(() => _process += 0.05);

    Logger().i('Step 5: Generating main.eep.hex...');
    List<String> mainEepCopy = [avrObj, '-j', '.eeprom'];
    mainEepCopy += ['--set-section-flags=.eeprom=alloc,load'];
    mainEepCopy += ['--change-section-lma', '.eeprom=0', '-O', 'ihex'];
    mainEepCopy += ['$path/main.bin', '$path/main.eep.hex'];
    if (!await runProcess(mainEepCopy, 'Generating main.eep.hex')) return;

    setState(() => _process += 0.05);
    Logger().i('Build done!');
  }

  Future<bool> runProcess(List<String> command, String action) async {
    var result = await Process.run(command.first, command.skip(1).toList());
    if (result.stderr.isNotEmpty) {
      Logger().e('Error during $action: ${result.stderr}');
    }
    return result.stderr.isEmpty;
  }

  Future<void> flash({required String avrdude, required String path}) async {
    Logger().i('Flashing main.hex...');

    var command = [findFile("avrdude.exe", avrdude)];
    command += ['-c', 'usbasp', '-U', 'flash:w:$path/main.hex:i'];
    command += ['-p', 'm8', '-U', 'eeprom:w:$path/main.eep.hex:i'];

    var process = await Process.start(command.first, command.skip(1).toList());

    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen((data) => stdout.write(data));

    process.stderr.transform(const SystemEncoding().decoder).listen((data) {
      _process = (_process + '#'.allMatches(data).length / 400).clamp(0, 1);
      setState(() => _process);
      stderr.write(data); // негодяи шлют данные не в тот поток
    });

    var exitCode = await process.exitCode;
    if (exitCode == 0) _result = true;
    if (exitCode >= 1) _result = false;
    Logger().i('Flash complete. Exit code $exitCode');
  }

  Widget _serialField() {
    return SizedBox(
      width: 500,
      child: TextField(
        enabled: _process == 0,
        controller: _controller,
        maxLength: 35,
        decoration: InputDecoration(
          labelText: 'Серийный номер (${_controller.text.length}/35)',
          hintText: 'xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
          filled: true,
          fillColor: Colors.white,
          counterText: '',
        ),
        style: const TextStyle(fontFamily: 'RobotoMono'),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^[0-9а-яА-Яa-zA-Z-]*')),
        ],
        onChanged: (text) => _formatSerialNumber(text),
      ),
    );
  }

  static const Map<String, String> _keyMap = {
    'й': 'q', 'ц': 'w', 'у': 'e', 'к': 'r', 'е': 't', 'н': 'y', 'г': 'u',
    'ш': 'i', 'щ': 'o', 'з': 'p', 'х': '[', 'ъ': ']', 'ф': 'a', 'ы': 's',
    'в': 'd', 'а': 'f', 'п': 'g', 'р': 'h', 'о': 'j', 'л': 'k', 'д': 'l',
    'ж': ';', 'э': "'", 'я': 'z', 'ч': 'x', 'с': 'c', 'м': 'v', 'и': 'b',
    'т': 'n', 'ь': 'm', 'б': ',', 'ю': '.', 'ё': '`', ' ': ' ', // RU-EN
  };
  void _formatSerialNumber(String text) {
    String output = text
        .toLowerCase() // Перевод всего в нижний кейс Я->я, Z->z, 1->1
        .replaceAll('-', '') // Удаляются все дефисы
        .split('') // Разделение строки на массив символов
        .map((char) => _keyMap[char] ?? char) // Перевод кириллицы в латиницу
        .join(); // Объединение символов назад в строку

    int cursorPosition = _controller.selection.base.offset;
    int newCursorPosition = min(cursorPosition, output.length);

    for (int pos in [8, 17, 26]) {
      if (output.length > pos && output[pos] != '-') {
        output = '${output.substring(0, pos)}-${output.substring(pos)}';
        if (newCursorPosition >= pos) newCursorPosition++;
      }
    }
    print('$cursorPosition, $newCursorPosition, ${output.length}');

    _controller.value = _controller.value.copyWith(
      text: output,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    _isMaxLengthReached = _controller.text.length == 35;
    _result = null;
    _process = 0;
    setState(() {});
  }
}
