// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';

Future<void> packFiles(String dir, String output) async {
  final archive = Archive();
  for (var f in Directory(dir).listSync(recursive: true)) {
    if (f is File) {
      final b = f.readAsBytesSync();
      archive.addFile(ArchiveFile(f.path.replaceFirst(dir, ''), b.length, b));
    }
  }

  File(output).writeAsBytesSync(TarEncoder().encode(archive));
  final result = Process.runSync('xz', ['-z', '-9', '-e', output]);
  result.exitCode == 0
      ? print('XZ generated at: $output.xz')
      : print('Error generating XZ: ${result.stderr}');
}

void generateByteArray(String archiveFilePath, String outputDartFile) {
  final buffer = StringBuffer();
  buffer.write('const String applicationData = "');
  buffer.write(base64Encode(File(archiveFilePath).readAsBytesSync()));
  buffer.writeln('";');
  File(outputDartFile).writeAsStringSync(buffer.toString());
  print('Generated embedded data file: $outputDartFile');
}

void generateExecutable(String dart, String out) {
  const f = '--save-debugging-info=info';
  final res = Process.runSync('dart', ['compile', 'exe', dart, '-o', out, f]);
  res.exitCode == 0
      ? print('Executable generated at: $out')
      : print('Error generating executable: ${res.stderr}');
}

String findExe(String dirPath) {
  for (var file in Directory(dirPath).listSync()) {
    if (file is File && file.path.endsWith('.exe')) return file.path;
  }
  throw Exception('No .exe file found in the specified directory');
}

Future<void> main(List<String> args) async {
  if (args.length != 1) throw Exception('Usage: dart deploy.dart <input_dir>');

  final outputExe = findExe(args[0]).split(Platform.pathSeparator).last;
  final mainDartFile = '${Directory.current.absolute.path}\\run_app.dart';
  final outputTar = outputExe.replaceAll('.exe', '.tar');
  const embeddedDartFile = 'embedded_data.dart';

  try {
    await packFiles(args[0], outputTar);
    generateByteArray('$outputTar.xz', embeddedDartFile);
    generateExecutable(mainDartFile, outputExe);
  } catch (e) {
    print('Error: $e');
  } finally {
    print('Cleanup file: $embeddedDartFile');
    File(embeddedDartFile).deleteSync();
    print('Cleanup file: $outputTar.xz');
    File('$outputTar.xz').deleteSync();
  }
}
