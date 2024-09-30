import 'dart:io';
import 'package:archive/archive.dart';

void packFiles(String dir, String outputZip) {
  final archive = Archive();
  for (var f in Directory(dir).listSync(recursive: true)) {
    if (f is File) {
      final b = f.readAsBytesSync();
      archive.addFile(ArchiveFile(f.path.replaceFirst(dir, ''), b.length, b));
    }
  }
  File(outputZip).writeAsBytesSync(ZipEncoder().encode(archive)!);
}

void generateByteArray(String zipFilePath, String outputDartFile) {
  final buffer = StringBuffer();
  buffer.writeln('const List<int> embeddedZipData = [');
  for (var byte in File(zipFilePath).readAsBytesSync()) buffer.write('$byte,');
  buffer.writeln('];');
  File(outputDartFile).writeAsStringSync(buffer.toString());
}

void generateExecutable(String dart, String out) {
  final result = Process.runSync('dart', ['compile', 'exe', dart, '-o', out]);
  result.exitCode == 0
      ? print('Executable generated at: $out')
      : print('Error generating executable: ${result.stderr}');
}

String findExe(String dirPath) {
  for (var file in Directory(dirPath).listSync())
    if (file is File && file.path.endsWith('.exe')) return file.path;
  throw Exception('No .exe file found in the specified directory');
}

Future<void> main(List<String> args) async {
  if (args.length != 1) throw Exception('Usage: dart deploy.dart <input_dir>');

  try {
    final outputExe = findExe(args[0]).split(Platform.pathSeparator).last;
    final outputZip = outputExe.replaceAll('.exe', '.zip');

    packFiles(args[0], outputZip);
    print('Packed files into: $outputZip');

    final embeddedDartFile = 'embedded_data.dart';
    generateByteArray(outputZip, embeddedDartFile);
    print('Generated embedded data file: $embeddedDartFile');

    final mainDir = Directory.current.absolute.path;
    final mainDartFile = '$mainDir\\run_app.dart';
    generateExecutable(mainDartFile, outputExe);

    File(embeddedDartFile).deleteSync();
    print('Cleanup embedded data file: $embeddedDartFile');
  } catch (e) {
    print('Error: $e');
  }
}
