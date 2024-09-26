import 'dart:io';
import 'package:xml/xml.dart';
import 'package:args/args.dart';

const String defaultReleaseDir = '../build/windows/x64/runner/Release';
const String defaultXmlFilePath = '../deploy/USBasp-updater.evb';

XmlNode createFileNode(File file) {
  print('Creating file node for: ${file.absolute.path}');
  final fileNode = XmlBuilder();
  fileNode.element('Type', nest: '2');
  fileNode.element('Name', nest: file.uri.pathSegments.last);
  fileNode.element('File',
      nest: Uri.file(file.absolute.path)
          .normalizePath()
          .toFilePath(windows: true));
  fileNode.element('ActiveX', nest: 'False');
  fileNode.element('ActiveXInstall', nest: 'False');
  fileNode.element('Action', nest: '0');
  fileNode.element('OverwriteDateTime', nest: 'False');
  fileNode.element('OverwriteAttributes', nest: 'False');
  fileNode.element('PassCommandLine', nest: 'False');
  fileNode.element('HideFromDialogs', nest: '0');
  return fileNode.buildFragment();
}

XmlNode createDirNode(Directory dir, {String? name}) {
  print('Creating directory node for: ${dir.absolute.path}');
  final pathSegments = dir.uri.pathSegments;
  final dirName = name != null
      ? name
      : pathSegments.last.isNotEmpty
          ? pathSegments.last
          : pathSegments[pathSegments.length - 2];

  final files = dir.listSync(recursive: false);
  print('Found ${files.length} items in directory: $dirName');

  final fileNode = XmlBuilder();
  fileNode.element('Type', nest: '3');
  fileNode.element('Name', nest: dirName);
  fileNode.element('Action', nest: '0');
  fileNode.element('OverwriteDateTime', nest: 'False');
  fileNode.element('OverwriteAttributes', nest: 'False');
  fileNode.element('HideFromDialogs', nest: '0');
  fileNode.element('Files', nest: () {
    for (var f in files) {
      if (f is File) fileNode.element('File', nest: createFileNode(f));
      if (f is Directory) fileNode.element('File', nest: createDirNode(f));
    }
  });
  return fileNode.buildFragment();
}

void main(List<String> args) {
  final parser = ArgParser();
  parser.addOption('xml', abbr: 'x', defaultsTo: defaultXmlFilePath, help: 'Path to the XML file.');
  parser.addOption('dir', abbr: 'd', defaultsTo: defaultReleaseDir, help: 'Path to the release directory.');

  final results = parser.parse(args);
  final xmlFilePath = results['xml'] as String;
  final releaseDir = results['dir'] as String;

  print('Starting XML processing with XML file: $xmlFilePath and release directory: $releaseDir');

  final xmlFile = File(xmlFilePath);
  
  if (!xmlFile.existsSync()) {
    print('Error: XML file not found at $xmlFilePath');
    return;
  }

  final document = XmlDocument.parse(xmlFile
      .readAsStringSync()
      .replaceAll(r'<>', '<root>')
      .replaceAll(r'</>', '</root>'));

  final mainFilesNode = document.findAllElements('Files').firstWhere((node) {
    final compressFilesElement = node.findElements('CompressFiles').firstOrNull;
    return compressFilesElement != null && compressFilesElement.text == 'True';
  });

  if (mainFilesNode != null) {
    print('Processing main files node...');
    final filesNode = mainFilesNode.findElements('Files').first;
    filesNode.children.clear();

    final release = Directory(releaseDir);
    print('Creating directory node for release directory...');
    
    final fileNode = XmlBuilder();
    fileNode.element('File',
        nest: createDirNode(release, name: '%DEFAULT FOLDER%'));
    filesNode.children.add(fileNode.buildFragment());
  }

  print('Writing updated XML to file...');
  xmlFile.writeAsStringSync(document
      .toXmlString(pretty: true)
      .replaceAll('<root>', '<>')
      .replaceAll('</root>', '</>\n')
      .replaceAll('\n', '\r\n'));
  print('XML processing completed.');
}
