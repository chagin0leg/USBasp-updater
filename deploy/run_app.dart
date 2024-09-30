import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'embedded_data.dart';

const String version = '0.0.0';
const String repo = 'https://github.com/chagin0leg/USBasp-updater/';
const String url = repo + 'releases/latest/download/usbasp_updater_win_x64.exe';

void main() async {
  if (await isNewVersionAvailable()) {
    if (await waitingConfirm()) {
      print('Update confirmed! Program updates has been  started...');
      await downloadLatestVersion();
    }
    print('\nThe update has not been confirmed. Continue execution...');
  }

  final zipData = Uint8List.fromList(embeddedZipData);
  final archive = ZipDecoder().decodeBytes(zipData);
  final tempDir = Directory.systemTemp.createTempSync('flutter_app_');

  for (final file in archive) {
    final filePath = tempDir.path + '/' + file.name;
    if (file.isFile) {
      final outFile = File(filePath);
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    }
  }

  final exe = '${tempDir.path}/USBasp-updater.exe';
  Process.start('cmd', ['/c', 'start /b $exe'], workingDirectory: tempDir.path);
}

Future<bool> waitingConfirm({double counter = 9.9}) async {
  final c = Completer<bool>();
  final t = Timer.periodic(Duration(milliseconds: 100), (timer) {
    stdout.write('\rUpdate is available! Update now? ');
    stdout.write('${counter.toStringAsFixed(1)}s [Y/n] ');
    if ((counter -= 0.1) < 0) c.complete(false);
  });
  final s = stdin.listen(
      (d) => c.complete(String.fromCharCodes(d).trim().toUpperCase() == 'Y'));
  return c.future.whenComplete(() => s.cancel().whenComplete(() => t.cancel()));
}

Future<void> downloadLatestVersion() async {
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final oldFile = Platform.resolvedExecutable;
    final tempDir = (Directory.systemTemp).path;
    final newFile = File('$tempDir\\${path.basename(url)}');
    final batFile = File('${tempDir}\\update_version.bat');
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
    await newFile.writeAsBytes(response.bodyBytes);
    print('Create and launch update script');
    await batFile.writeAsString(command);
    await Process.start(batFile.path, [], runInShell: true);
    print('Restart application! Goodbye.. (っ╥╯﹏╰╥c)');

    exit(0);
  } else {
    throw Exception('Не удалось скачать последнюю версию.');
  }
}

const getTag = 'api.github.com/repos/chagin0leg/USBasp-updater/releases/latest';
Future<String> getLatestVersion() async {
  print('Checking for updates...');
  final response = await http.get(Uri.parse('https://' + getTag));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print("The latest Application Version is ${data['tag_name']}");
    return data['tag_name'];
  } else {
    throw Exception('Cannot get the last version [${response.statusCode}].');
  }
}

extension VersionParsing on String {
  List<int> toInt() => this.split('.').map(int.parse).toList();
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
