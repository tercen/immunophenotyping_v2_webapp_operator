import 'dart:async';
import 'dart:io';

import 'package:webapp_template/globals.dart' as globals;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_string/json_string.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:webapp_template/screens/project_screen.dart';
import 'package:webapp_template/webapp.dart';
import 'package:webapp_template/webapp_data.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

import 'package:sci_tercen_client/sci_client.dart' as sci;

final navigatorKey = GlobalKey<NavigatorState>();

//Prevents multiple error screens overwriting one another
// bool isShowingGlobalError = false;
void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();




      runApp(MaterialApp(
        home: const KumoAnalysisApp(),
        navigatorKey: navigatorKey,
      ));
    },
    (error, stackTrace) {
      if (navigatorKey.currentContext != null) {
        if (error is sci.ServiceError ) {
          print(error);
          print(stackTrace);
          ErrorScreen errorHandler = ErrorScreen(
            errorDetails: FlutterErrorDetails(exception: error),
          );

          globals.States.hasError = true;
          showDialog(
              barrierDismissible: false,
              context: navigatorKey.currentContext!,
              builder: (context) => errorHandler.build(context));

        }
      } else {
        print("Context or null check error");
        print(stackTrace);
        exit(1);
      }
    },
  );
}

class KumoAnalysisApp extends StatelessWidget {
  const KumoAnalysisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoColumnHome();
  }
}

class TwoColumnHome extends StatefulWidget {
  const TwoColumnHome({super.key});

  @override
  State<TwoColumnHome> createState() => _TwoColumnHomeState();
}

class _TwoColumnHomeState extends State<TwoColumnHome> with ProgressDialog {
  bool doneLoading = false;
  late final WebApp app;
  late final WebAppData appData;

  late final Image logo;


  @override
  initState() {
    

    app = WebApp();
    appData = WebAppData(app);

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      openDialog(context);

      log("Initializing User Session",
          dialogTitle: "WebApp");

      await app.init();


      log("Initializing File Structure",
          dialogTitle: "WebApp");

      // var workflowSettingsFiles = [
      //   "assets/umap_settings.json"
      // ];

      
      var img = await rootBundle.load("assets/img/logo.png");
      var bData = img.buffer.asUint8List();
      logo = Image.memory(bData, width: 380,
            height: 100);

      // BASIC Initialization
      await appData.init(app.projectId, app.projectName, app.username);

      //OR Advanced initialization with configuration files
      // await appData.init(app.projectId, app.projectName, app.username,
      //     reposJsonPath: "assets/repos.json",
      //     stepMapperJsonFile: "assets/workflow_steps.json",
      //     settingFiles: workflowSettingsFiles);

      app.addNavigationPage(
          "Project", ProjectScreen(appData, key: app.getKey("Project")));



      appData.addListener(refresh);
      app.navMenu.addListener(() => refresh());

      // await app.postInit();
      app.isInitialized = true;
      refresh();
      
      closeLog();
    });
  }

  void refresh() {
    setState(() {});
  }


  Widget _buildBanner() {
    return Column(
      children: [
        Center(
          child: logo,
        ),
        Align(
            alignment: Alignment.centerRight,
            child: Text(
              appData.project.label != ""
                  ? "Project Name: ${appData.project.label}"
                  : "No project associated",
              style: Styles.textGray,
            )),
        Container(
          height: 1,
          color: const Color.fromARGB(255, 230, 230, 230),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (app.isInitialized) {
      var bannerWdg = _buildBanner();
      app.banner = bannerWdg;

      return app.buildScaffoldPage();
    } else {
      return Container();
    }
  }
}

class ErrorScreen extends StatelessWidget {
  static const String missingTemplate = "ERR_MISSING_TEMPLATE";
  final FlutterErrorDetails? errorDetails;

  const ErrorScreen({
    super.key,
    this.errorDetails,
  }) : assert(errorDetails != null);

  @override
  Widget build(BuildContext context) {
    return getErrorMessage(errorDetails!.exceptionAsString());
  }

  Widget getErrorMessage(String errorString) {
    switch (errorString.replaceAll("Exception: ", "")) {
      case ErrorScreen.missingTemplate:
        return _buildTemplateErrorScreen(errorString);
      default:
        return _buildDefaultErrorScreen(errorString);
    }
  }

  Widget _buildErrorDialog(String errorString) {
    return AlertDialog(
      icon: const Icon(
        Icons.error,
        size: 70,
        color: Colors.red,
      ),
      backgroundColor: const Color.fromARGB(255, 247, 194, 194),
      title: const Text(
        "An Unexpected Error Occurred",
        style: Styles.textH2,
      ),
      content: SingleChildScrollView(
        child: Text(
          errorString,
          style: Styles.text,
        ),
      ),
      actions: [
        TextButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(
                  Color.fromARGB(255, 20, 20, 20)),
            ),
            onPressed: () {
              print("Loaded project is ${globals.States.loadedProject}");
              Uri tercenLink = Uri(
                  scheme: Uri.base.scheme,
                  host: Uri.base.host,
                  path: globals.States.loadedProject);
              if (Uri.base.hasPort) {
                tercenLink = Uri(
                    scheme: Uri.base.scheme,
                    host: '127.0.0.1',
                    port: 5400,
                    path:
                        "${globals.States.projectUser}/p/${globals.States.loadedProject}");
              }

              launchUrl(tercenLink, webOnlyWindowName: "_self");
            },
            child: const Center(
                child: Text(
              "Exit",
              style: Styles.textButton,
            )))
      ],
    );
  }

  Widget _buildDefaultErrorScreen(String errorString) {
    return _buildErrorDialog(errorString);
  }

  Future<String> _buildWorkflowErrorMessage() async {
    String settingsStr = await rootBundle.loadString("assets/repos.json");
    String msg = "";
    try {
      final jsonString = JsonString(settingsStr);
      final repoInfoMap = jsonString.decodedValueAsMap;

      msg = "${msg}Required Templates are not Installed";
      msg =
          "$msg\nPlease ensure that the following templates are installed:\n\n";

      for (int i = 0; i < repoInfoMap["repos"].length; i++) {
        Map<String, dynamic> jsonEntry = repoInfoMap["repos"][i];
        msg = "$msg\n- ${jsonEntry['url']} - version ${jsonEntry['version']}";
      }
    } on Exception catch (e) {
      throw ('Invalid assets/repos.json: $e');
    }

    msg = "$msg\n\n";

    return msg;
  }

  Widget _buildTemplateErrorScreen(String errorString) {
    return FutureBuilder(
        future: _buildWorkflowErrorMessage(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return _buildErrorDialog(snapshot.data!);
          } else {
            return const Row(
              children: [
                CircularProgressIndicator(),
                Text("Retrieving error information")
              ],
            );
          }
        });
  }
}
