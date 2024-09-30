import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:usbasp_updater/dependencies.dart';
import 'package:usbasp_updater/update.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  runApp(const MaterialApp(home: MainAppPage()));
}

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});
  @override
  _MainAppPageState createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  bool allComponentsReady = false;
  String usbasp = '';
  String avrdude = '';
  String avrgcc = '';

  List<Map<String, bool>> componentStates = List.generate(components.length,
      (index) => {'isDownloaded': false, 'isUnzipped': false});

  @override
  void initState() {
    super.initState();
    _initializeWindow(); // Вызов асинхронной инициализации окна
  }

  Future<void> _initializeWindow() async {
    final version = (await PackageInfo.fromPlatform()).version;
    WindowOptions windowOptions = WindowOptions(
        minimumSize: const Size(1024, 512 / 4 * 3),
        title: 'USBASP Update $version');
    await windowManager.waitUntilReadyToShow(windowOptions, () async {});
  }

  void updateComponentState(int index, bool isDownloaded, bool isUnzipped) {
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
          componentStates[index] = {
            'isDownloaded': isDownloaded,
            'isUnzipped': isUnzipped,
          };
          allComponentsReady = componentStates.every((state) =>
              state['isDownloaded'] == true && state['isUnzipped'] == true);
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ...components.asMap().entries.map((entry) {
              int index = entry.key;
              var component = entry.value;
              return ComponentWidget(
                componentName: component['name']!,
                downloadUrl: component['url']!,
                onStateChange: (isDownloaded, isUnzipped, path) {
                  updateComponentState(index, isDownloaded, isUnzipped);
                  if (index == 0) usbasp = path;
                  if (index == 1) avrdude = path;
                  if (index == 2) avrgcc = path;
                },
              );
            }),
            UploadWidget(
                isReady: allComponentsReady,
                usbasp: usbasp,
                avrdude: avrdude,
                avrgcc: avrgcc),
          ],
        ),
      ),
    );
  }
}
