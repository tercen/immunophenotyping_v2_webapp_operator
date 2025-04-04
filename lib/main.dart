import 'dart:async';

import 'dart:io';

import 'package:immunophenotyping_webapp/globals.dart' as globals;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:immunophenotyping_webapp/screens/report_screen.dart';
import 'package:immunophenotyping_webapp/screens/task_manager_screen.dart';
import 'package:json_string/json_string.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:immunophenotyping_webapp/screens/upload_screen.dart';
import 'package:immunophenotyping_webapp/screens/settings_screen.dart';
import 'package:immunophenotyping_webapp/webapp.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';

import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_ui_commons/styles/default_style.dart';
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

        }else{
          print(error);
          print(stackTrace);
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

  late final Widget logo;

  bool initStateFinished = false;
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
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      log("Initializing File Structure",
          dialogTitle: "WebApp");

      Styles().init([DefaultStyle()]);
      
      var img = await rootBundle.load("assets/img/logo.png");
      var bData = img.buffer.asUint8List();
      logo = Padding(padding: const EdgeInsets.fromLTRB(0, 0, 50, 20), child:   Image.memory(bData, width: 228,
            height: 60));

      // BASIC Initialization
      // settingFilterFile
      await appData.init(app.projectId, app.projectName, app.username,
          reposJsonPath: "assets/repos.json",
          settingFilterFile: "assets/settings_screen_filter.json",
          stepMapperJsonFile: "assets/workflow_steps.json");

      app.navMenu.project = app.projectName;
      app.navMenu.user = app.username;
      app.navMenu.team = app.teamname;
      app.navMenu.webApp = "${packageInfo.appName.replaceAll("_", " ")} (${packageInfo.version})";

      //OR Advanced initialization with configuration files
      // await appData.init(app.projectId, app.projectName, app.username,
      //     reposJsonPath: "assets/repos.json",
      //     stepMapperJsonFile: "assets/workflow_steps.json",
      //     settingFiles: workflowSettingsFiles);

      // 

      app.addNavigationPage(
          "Upload Data", UploadScreen(appData, key: app.getKey("Upload")));
      
      app.addNavigationPage(
          "Configuration", SettingsScreen(appData, key: app.getKey("Configuration")));

      app.addNavigationPage(
          "Report", ReportScreen(appData, key: app.getKey("Report")));

      app.addNavigationSpace();

      app.addNavigationPage(
          "Task Manager", ImmunoTaskManagerScreen(appData, key: app.getKey("Task Manager")));

      appData.addListener(refresh);
      app.navMenu.addListener(() => refresh());

      // await app.postInit();
      app.isInitialized = true;
      initStateFinished = true;
      refresh();
      
      closeLog();
    });
  }


  void refresh() {
    setState(() {});
  }


  // Future<void> loadModel(WebAppData modelLayer) async {
  //   if (app.projectId != "") {
  //     var projectId = app.projectId;
  //     var user = app.username;

  //     var folder = await modelLayer.projectService
  //         .getOrCreateFolder(projectId, user, ".tercen", parentId: "");

  //     var viewFile = await modelLayer.projectService.getOrCreateFile(
  //         projectId, user, "${user}_view_05",
  //         parentId: folder.id);

  //     print("FileContent");
  //     var map = (getFileContent(viewFile) );
  //     // print(map);
  //     // print(map.runtimeType);
  //     // ViewState
  //     // ViewState.fromJson( map as Map<String, List<String>> ); 
      
  //   }
  // }


  // dynamic getFileContent(sci.FileDocument fileDoc) {

  //   if (fileDoc.metadata.contentType == "application/json") {
  //     print("A");
  //     print(fileDoc.toJson());
  //     print(fileDoc.getMeta("file.content")!);
  //     print(fileDoc.getMeta("file.content")!.runtimeType);
  //     print("..............");
  //     return  jsonDecode(fileDoc.getMeta("file.content")!);
  //   } else {
  //     print("B");
  //     print(fileDoc.getMeta("file.content")!);
  //     print(fileDoc.getMeta("file.content")!.runtimeType);
  //     print("..............");
  //     return fileDoc.getMeta("file.content")!;
  //   }
  // }

  Widget _buildBanner() {
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: logo,
        ),
        // Align(
        //     alignment: Alignment.topLeft,
        //     child: Text(
        //       appData.project.label != ""
        //           ? "Project Name: ${appData.project.label}"
        //           : "No project associated",
        //       style: Styles()["textGray"],
        //     )),
        Container(
          height: 1,
          color: const Color.fromARGB(255, 230, 230, 230),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (initStateFinished) {
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
      title:  Text(
        "An Unexpected Error Occurred",
        style: Styles()["textH2"],
      ),
      content: SingleChildScrollView(
        child: Text(
          errorString,
          style: Styles()["text"],
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
            child: Center(
                child: Text(
              "Exit",
              style: Styles()["textButton"],
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
