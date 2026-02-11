// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'embedded_data.dart';
import 'package:archive/archive.dart';

const String version = '0.0.0';
const String repo = 'https://github.com/chagin0leg/USBasp-updater/';
const String url = '${repo}releases/latest/download/usbasp_updater_win_x64.exe';

final _appDir = Directory('${Directory.systemTemp.path}/usbasp_updater_app');

bool get _autoUpdateEnabled =>
    File('${_appDir.path}/temporary/usbasp_updater_auto_update').existsSync();

void main() async {
  if (_autoUpdateEnabled && await isNewVersionAvailable()) {
    if (await waitingConfirm()) {
      print('Update confirmed! Program updates has been  started...');
      await downloadLatestVersion();
    }
    print('\nThe update has not been confirmed. Continue execution...');
  }

  final tar = XZDecoder().decodeBytes(base64Decode(applicationData));
  final archive = TarDecoder().decodeBytes(tar);
  if (_appDir.existsSync()) {
    for (final e in _appDir.listSync()) {
      final name = e.path.split(Platform.pathSeparator).last;
      if (e is Directory && name == 'temporary') continue;
      e.deleteSync(recursive: true);
    }
  }
  _appDir.createSync(recursive: true);

  for (final file in archive) {
    final filePath = '${_appDir.path}/${file.name}';
    if (file.isFile) {
      final outFile = File(filePath);
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    }
  }

  final exe = '${_appDir.path}/USBasp-updater.exe';
  Process.start('cmd', ['/c', 'start /b $exe'], workingDirectory: _appDir.path);
}

Future<bool> waitingConfirm({double counter = 9.9}) async {
  final c = Completer<bool>();
  final t = Timer.periodic(const Duration(milliseconds: 100), (timer) {
    stdout.write('\rUpdate is available! Update now? ');
    stdout.write('${counter.toStringAsFixed(1)}s [Y/n] ');
    if ((counter -= 0.1) < 0) c.complete(false);
  });
  final s = stdin.listen(
      (d) => c.complete(String.fromCharCodes(d).trim().toUpperCase() == 'Y'));
  return c.future.whenComplete(() => s.cancel().whenComplete(() => t.cancel()));
}

Future<void> downloadLatestVersion() async {
  final httpClient = HttpClient();

  try {
    final uri = Uri.parse(url);
    final request = await httpClient.getUrl(uri);
    final response = await request.close();

    if (response.statusCode == 200) {
      final oldFile = Platform.resolvedExecutable;
      final tempDir = Directory.systemTemp.path;
      final fileName = url.split('/').last; // Извлекаем имя файла из URL
      final newFile = File('$tempDir\\$fileName');
      final batFile = File('$tempDir\\update_version.bat');
      final String command = '''
        @echo off
        ping 127.0.0.1 -n 5 > nul
        if exist "$oldFile" (
          del "$oldFile"
        )
        move "${newFile.path}" "$oldFile"
        start "" "$oldFile"
      ''';

      print('Save temporary application file');
      final bytes = await consolidateHttpResponse(response);
      await newFile.writeAsBytes(bytes);

      print('Create and launch update script');
      await batFile.writeAsString(command);
      await Process.start(batFile.path, [], runInShell: true);

      print('Restart application! Goodbye.. (っ╥╯﹏╰╥c)');
      exit(0);
    } else {
      throw Exception(
          'Не удалось скачать последнюю версию. Код ошибки: ${response.statusCode}');
    }
  } finally {
    httpClient.close();
  }
}

Future<List<int>> consolidateHttpResponse(HttpClientResponse response) {
  final completer = Completer<List<int>>();
  final contents = <int>[];

  response.listen(
    (data) => contents.addAll(data),
    onDone: () => completer.complete(contents),
    onError: (e) => completer.completeError(e),
    cancelOnError: true,
  );

  return completer.future;
}

const getTag = 'api.github.com/repos/chagin0leg/USBasp-updater/releases/latest';
Future<String> getLatestVersion() async {
  print('Checking for updates...');
  final httpClient = HttpClient();

  try {
    final uri = Uri.parse('https://$getTag');
    final request = await httpClient.getUrl(uri);
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseBody = await response.transform(const Utf8Decoder()).join();

      final tagRegex = RegExp(r'"tag_name"\s*:\s*"([^"]+)"');
      final match = tagRegex.firstMatch(responseBody);

      if (match != null) {
        final tagName = match.group(1);
        print("The latest Application Version is $tagName");
        return tagName ?? '';
      } else {
        throw Exception('Cannot find tag_name in the response.');
      }
    } else {
      throw Exception('Cannot get the last version [${response.statusCode}].');
    }
  } finally {
    httpClient.close();
  }
}

extension VersionParsing on String {
  List<int> toInt() => split('.').map(int.parse).toList();
}

Future<bool> isNewVersionAvailable() async {
  try {
    print("Application Version is $version");
    List<int> current = version.toInt();
    List<int> latest = (await getLatestVersion()).toInt();

    for (int i = 0; i < current.length; i++) {
      if (latest[i] > current[i]) return true;
      if (current[i] > latest[i]) return false;
    }
  } catch (e) {
    print(e);
  }
  return false;
}
