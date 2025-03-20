import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:immunophenotyping_webapp/screens/components/upload_table_team_component.dart';

import 'package:webapp_components/action_components/button_component.dart';
import 'package:webapp_components/components/input_text_component.dart';
import 'package:webapp_components/components/select_from_list.dart';
import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_components/validators/null_validator.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/screens/components/upload_file_team_component.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_workflow/runners/workflow_runner.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;


class UploadScreen extends StatefulWidget {
  final WebAppData modelLayer;
  const UploadScreen(this.modelLayer, {super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with ScreenBase, ProgressDialog {
  @override
  String getScreenId() {
    return "UploadScreen";
  }

  @override
  void dispose() {
    super.dispose();
    disposeScreen();
  }

  @override
  void refresh() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    var projectInputComponent = InputTextComponent(
        "project", getScreenId(), "Project Name",
        saveState: false);
    projectInputComponent.setComponentValue(widget.modelLayer.app.projectName);
    projectInputComponent.onChange(refresh);
    projectInputComponent.addValidator(
        NullValidator(invalidMessage: "Project Name cannot be empty"));

    var selectTeamComponent = SelectFromListComponent(
        "team", getScreenId(), "Select Team",
        user: widget.modelLayer.app.teamname, saveState: false);
    selectTeamComponent.setComponentValue(widget.modelLayer.app.teamname);
    selectTeamComponent
        .addValidator(NullValidator(invalidMessage: "Team cannot be empty"));

    var fcsComponent = UploadFileTeamComponent(
        "uploadFcs", getScreenId(), "FCS File", "", "",
        maxHeight: 150,
        maxWidth: 350,
        allowedMime: ["application/zip", "application/vnd.isac.fcs"],
        showUploadButton: false,
        fetchProjectFiles: fetchFcsFiles);
    fcsComponent.setProjectOwnerCallback(getProjectId, getFileOwner);

    var annotationComponent = UploadTableTeamComponent(
        "uploadAnnotation",
        getScreenId(),
        "Sample Annotation File",
        widget.modelLayer.app.projectId,
        "",
        maxHeight: 150,
        maxWidth: 350,
        allowedMime: ["text/csv", "text/tsv"],
        showUploadButton: false,
        fetchProjectFiles: fetchAnnotationFiles);
    annotationComponent.setProjectOwnerCallback(getProjectId, getFileOwner);

    addComponent("default", projectInputComponent);
    addComponent("default", selectTeamComponent);
    addHorizontalBar("default");
    addComponent("default", fcsComponent);
    addComponent("default", annotationComponent);

    var createProjectBtn = ButtonActionComponent(
        "createProject", "Upload Files", _doCreateProjectUpload,
        blocking: false,
        parents: [
          projectInputComponent,
          selectTeamComponent,
          fcsComponent,
          annotationComponent
        ]);
    addActionComponent(createProjectBtn);
    initScreen(widget.modelLayer as WebAppDataBase);
  }

  Future<List<sci.ProjectDocument>> fetchFcsFiles() async {
    var docs = widget.modelLayer.projectService.getProjectFiles();

    return docs
        .whereType<sci.ProjectDocument>()
        .where((doc) =>
            doc.name.toLowerCase().endsWith(".zip") ||
            doc.name.toLowerCase().endsWith(".fcs"))
        .toList();
  }

  Future<List<sci.ProjectDocument>> fetchAnnotationFiles() async {
    var docs = widget.modelLayer.projectService.getProjectFiles();

    return docs
        .whereType<sci.ProjectDocument>()
        .where((doc) => doc.subKind == "TableSchema")
        .where((doc) =>
            doc.name.toLowerCase().endsWith(".csv") ||
            doc.name.toLowerCase().endsWith(".tsv"))
        .toList();
  }

  String getProjectId() {
    return widget.modelLayer.app.projectId;
  }

  String getFileOwner() {
    var teamComponent = getComponent("team") as SelectFromListComponent;
    return teamComponent.getComponentValue();
  }

  Future<void> _doCreateProjectUpload() async {
    openDialog(context);

    await _createLoadProject();

    await _uploadData();

    await _readFcsFiles();

    closeLog();

    widget.modelLayer.app.navMenu.selectScreen("Configuration");
  }

  Future<void> _createLoadProject() async {
    log("Creating/Loading Project", dialogTitle: "Create Project");
    var teamComponent = getComponent("team") as SelectFromListComponent;
    var selectedTeam = teamComponent.getComponentValue();

    var projectComponent = getComponent("project") as InputTextComponent;
    var projectName = projectComponent.getComponentValue();

    if (projectName != widget.modelLayer.app.projectName) {
      await widget.modelLayer
          .createOrLoadProject("", projectName, selectedTeam);
      await modelLayer.reloadProjectFiles();
    }
  }

  String removeSuffix(String name) {
    var parts = name.split(".");
    parts.removeLast();
    return parts.join(".");
  }

  Future<void> _uploadData() async {
    log("Uploading FCS Files", dialogTitle: "Create Project");
    var upFcsComp = getComponent("uploadFcs") as UploadFileTeamComponent;
    await upFcsComp.doUpload(context);

    log("Uploading Annotation Files", dialogTitle: "Create Project");
    var upAnnotComp =
        getComponent("uploadAnnotation") as UploadTableTeamComponent;
    await upAnnotComp.doUpload(context);
  }

  Future<void> _readFcsFiles() async {
    var upFcsComp = getComponent("uploadFcs") as UploadFileTeamComponent;
    var upAnnotComp =
        getComponent("uploadAnnotation") as UploadTableTeamComponent;

    log("Reading FCS", dialogTitle: "Create Project");
    WorkflowRunner runner = WorkflowRunner(
        widget.modelLayer.app.projectId,
        widget.modelLayer.app.teamname,
        widget.modelLayer.workflowService.getWorkflow("immuno"));

    runner.addDocument(
        widget.modelLayer.settingsService.getStepId("immuno", "fcsTable"),
        upFcsComp.getComponentValue().first);
    runner.addTableDocument(
        widget.modelLayer.settingsService
            .getStepId("immuno", "annotationTable"),
        upAnnotComp.getComponentValue().first);

    var folderName =
        "${removeSuffix(upFcsComp.uploadedFilenames.first)}_${removeSuffix(upAnnotComp.uploadedFilenames.first)}";
    var folder = widget.modelLayer.projectService.getFolder(folderName);

    //If folder exists, pair of file has been run
    if (folder == null) {
      runner.setFolderName(folderName);

      runner.addPostRun(widget.modelLayer.reloadProjectFiles);
      runner.addPostRun(removeTestsFolder);

      runner.addFolderMeta("immuno.data.folder", "true");
      runner.addWorkflowMeta("immuno.readFcs.run", "true");

      runner.addTimestampToName(false);

      runner.setNewWorkflowName("FcsLoaded_Template");

      widget.modelLayer.workflow = await runner.doRunStep(context,
          widget.modelLayer.settingsService.getStepId("immuno", "readFcs"));
    } else {
      Fluttertoast.showToast(
          msg: "Files successfully loaded",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          webPosition: "center",
          webBgColor: "linear-gradient(to bottom, #ffffff, #eeeeaff)",
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.lightBlue[100],
          textColor: Styles()["black"],
          fontSize: 16.0);
    }
  }

  Future<void> removeTestsFolder() async {
    var folder = widget.modelLayer.projectService.getFolder("workflow_tests");
    if (folder != null) {
      var factory = tercen.ServiceFactory();
      await factory.folderService.delete(folder.id, folder.rev);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget.modelLayer.userService
            .fetchUserList(widget.modelLayer.app.username),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            (getComponent("team")! as SelectFromListComponent)
                .setOptions(snapshot.data!);
            return buildComponents(context);
          } else {
            (getComponent("team")! as SelectFromListComponent)
                .setOptions(["Loading user list..."]);
            return buildComponents(context);
          }
        });
  }
}
