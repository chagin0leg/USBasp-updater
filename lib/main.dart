import 'package:flutter/material.dart';
import 'package:usbasp_updater/dependencies.dart';
import 'package:usbasp_updater/update.dart';
import 'package:usbasp_updater/self_update.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (await isNewVersionAvailable()) downloadLatestVersion();
  await windowManager.ensureInitialized();
  final version = await getAppVersion();
  WindowOptions windowOptions = WindowOptions(
    title: 'USBASP Update $version',
    minimumSize: const Size(1024, 512 / 4 * 3),
    center: true,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool allComponentsReady = false;
  String usbasp = '';
  String avrdude = '';
  String avrgcc = '';

  List<Map<String, bool>> componentStates = List.generate(
    components.length,
    (index) => {'isDownloaded': false, 'isUnzipped': false},
  );

  void updateComponentState(int index, bool isDownloaded, bool isUnzipped) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        componentStates[index] = {
          'isDownloaded': isDownloaded,
          'isUnzipped': isUnzipped,
        };

        allComponentsReady = componentStates.every((state) =>
            state['isDownloaded'] == true && state['isUnzipped'] == true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
      ),
    );
  }
}
