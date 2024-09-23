import 'dart:io'; // Импортируем пакет для работы с файлами
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

final List<Map<String, String>> components = [
  {
    'name': 'USBasp Firmware',
    'url':
        'https://github.com/chagin0leg/USBasp-updater/releases/download/0.0.0/usbasp-firmware-v1.13.zip'
  },  {
    'name': 'AVRdude',
    'url':
        'https://github.com/avrdudes/avrdude/releases/download/v8.0/avrdude-v8.0-windows-x64.zip'
  },
  {
    'name': 'AVR-GCC 7.3.0 x64 minGW',
    'url':
        'https://github.com/ZakKemble/avr-gcc-build/releases/download/v7.3.0-1/avr-gcc-7.3.0-x64-mingw.zip'
  },
];

class ComponentWidget extends StatefulWidget {
  final String componentName;
  final String downloadUrl;
  final Function(bool, bool, String) onStateChange;

  const ComponentWidget({
    Key? key,
    required this.componentName,
    required this.downloadUrl,
    required this.onStateChange,
  }) : super(key: key);

  @override
  ComponentWidgetState createState() => ComponentWidgetState();
}

class ComponentWidgetState extends State<ComponentWidget> {
  bool _isDownloaded = false;
  bool _isUnzipped = false;
  int _downloadedSize = 0;
  int _folderSize = 0;
  double _process = -1;
  String filename = '';
  Directory path = Directory.current;

  Future<void> downloadFile() async {
    // Проверяем, что downloadUrl не пустой
    if (widget.downloadUrl.isEmpty) {
      Logger().e('downloadUrl не может быть пустым');
      return;
    }

    // Получаем путь к текущему рабочему каталогу
    final currentDirectory = Directory.current;
    final appFolder = Directory('${currentDirectory.path}/temporary');
    if (!await appFolder.exists()) await appFolder.create();
    final savePath = '${appFolder.path}/$filename';

    Dio dio = Dio();
    int lastLogSecond = -1;
    try {
      await dio.download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadedSize = received;
              _process = received / total;
              if (DateTime.now().second != lastLogSecond) {
                lastLogSecond = DateTime.now().second;
                Logger().i('$received / $total');
              }
            });
          }
        },
      );
    } catch (e) {
      Logger().e(e);
    }
    if (await File(savePath).exists()) {
      setState(() {
        _isDownloaded = true;
        _downloadedSize = File(savePath).lengthSync();
        _process = -1;
      });
    }
  }

@override void setState(VoidCallback fn) {
    widget.onStateChange(_isDownloaded, _isUnzipped, path.absolute.path);
    super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
    filename = Uri.parse(widget.downloadUrl).pathSegments.last;
    final file = File('temporary/$filename');
    setState(() => _isDownloaded = file.existsSync());
    setState(() => _isDownloaded ? _downloadedSize = file.lengthSync() : null);

    path = Directory('temporary/${filename.replaceFirst('.zip', '')}');
    setState(() => _isUnzipped = path.existsSync());
    if (_isUnzipped) setState(() => _folderSize = _getFolderSize(path));
  }

  int _getFolderSize(Directory dir) {
    return dir.listSync(recursive: true).fold<int>(
        0, (total, file) => (file is File) ? total + file.lengthSync() : total);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(width: 20),
          SizedBox(width: 200, child: Text(widget.componentName)),
          const SizedBox(width: 20),
          _isDownloaded
              ? const Icon(Icons.done, color: Colors.green)
              : const Icon(Icons.warning, color: Colors.yellow),
          const SizedBox(width: 20),
          _isUnzipped
              ? const Icon(Icons.done, color: Colors.green)
              : const Icon(Icons.warning, color: Colors.yellow),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: _isDownloaded ? null : () => downloadFile(),
            child: const Text('Скачать'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed:
                _isDownloaded && !_isUnzipped ? () => extractZip() : null,
            child: const Text('Распаковать'),
          ),
          const SizedBox(width: 20),
          buildProgressIndicator(_process),
          const SizedBox(width: 20),
          Text(
              '${_downloadedSize ~/ 1024 ~/ 1024} MiB / ${_folderSize ~/ 1024 ~/ 1024} MiB'),
        ],
      ),
    );
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

  Future<void> extractZip() async {
    final folderName = filename.replaceFirst('.zip', '');
    path = Directory('temporary/$folderName');
    final bytes = await File('temporary/$filename').readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    int counter = 0;
    _folderSize = 0;
    for (final file in archive) {
      setState(() => _process = (counter++) / archive.length);
      final filename = file.name;
      if (file.isFile) {
        setState(() => _folderSize += file.size);
        final data = file.content as List<int>;
        await File('temporary/$folderName/$filename').create(recursive: true);
        await File('temporary/$folderName/$filename').writeAsBytes(data);
      } else {
        await Directory('temporary/$folderName/$filename')
            .create(recursive: true);
        Logger().i(filename);
      }
    }
    setState(() => _isUnzipped = path.existsSync());
    if (_isUnzipped) setState(() => _folderSize = _getFolderSize(path));
    _process = -1;
  }
}
