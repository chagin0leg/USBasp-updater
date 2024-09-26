import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

const String url =
    'https://github.com/chagin0leg/USBasp-updater/releases/latest/download/usbasp_updater_win_x64.exe';

Future<void> downloadLatestVersion() async {
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final oldFile = '${Platform.resolvedExecutable}.exe';
    final tempDir = (await getTemporaryDirectory()).path;
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

    await newFile.writeAsBytes(response.bodyBytes);
    await batFile.writeAsString(command);
    await Process.start(batFile.path, [], runInShell: true);

    exit(0);
  } else {
    throw Exception('Не удалось скачать последнюю версию.');
  }
}

Future<String> getLatestVersion() async {
  final response = await http.get(Uri.parse(
      'https://api.github.com/repos/chagin0leg/USBasp-updater/releases/latest'));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    Logger().i("getLatestVersion : ${data['tag_name']}");
    return data['tag_name'];
  } else {
    throw Exception('Не удалось получить последнюю версию.');
  }
}

Future<String> getAppVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String version = packageInfo.version;
  Logger().i("getAppVersion : $version");
  return version;
}

List<int> parseVersion(String version) =>
    version.split('.').map(int.parse).toList();

Future<bool> isNewVersionAvailable() async {
  try {
    List<int> current = parseVersion(await getAppVersion());
    List<int> latest = parseVersion(await getLatestVersion());

    for (int i = 0; i < current.length; i++) {
      if (latest[i] > current[i]) return true;
      if (current[i] > latest[i]) return false;
    }
  } catch (e) {
    Logger().e(e);
  }
  return false;
}
