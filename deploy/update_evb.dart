import 'dart:io';
import 'package:xml/xml.dart';

const String releaseDir = '../build/windows/x64/runner/Release';
const String xmlFilePath = 'USBasp-updater.evb';

XmlNode createFileNode(File file) {
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
  final pathSegments = dir.uri.pathSegments;
  final dirName = name != null
      ? name
      : pathSegments.last.isNotEmpty
          ? pathSegments.last
          : pathSegments[pathSegments.length - 2];

  final files = dir.listSync(recursive: false);

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

void main() {
  final xmlFile = File(xmlFilePath);
  final document = XmlDocument.parse(xmlFile
      .readAsStringSync()
      .replaceAll(r'<>', '<root>')
      .replaceAll(r'</>', '</root>'));

  final mainFilesNode = document.findAllElements('Files').firstWhere((node) {
    final compressFilesElement = node.findElements('CompressFiles').firstOrNull;
    return compressFilesElement != null && compressFilesElement.text == 'True';
  });

  if (mainFilesNode != null) {
    final filesNode = mainFilesNode.findElements('Files').first;
    filesNode.children.clear();

    final release = Directory(releaseDir);
    // filesNode.children.add(createDirNode(release, name: '%DEFAULT FOLDER%'));

    final fileNode = XmlBuilder();
    fileNode.element('File',
        nest: createDirNode(release, name: '%DEFAULT FOLDER%'));
    filesNode.children.add(fileNode.buildFragment());
  }
  xmlFile.writeAsStringSync(document
      .toXmlString(pretty: true)
      .replaceAll('<root>', '<>')
      .replaceAll('</root>', '</>\n')
      .replaceAll('\n', '\r\n'));
}
