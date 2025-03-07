import 'dart:async';

import 'package:flutter/material.dart';
import 'package:immunophenotyping_webapp/screens/components/upload_table_team_component.dart';

import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_components/action_components/button_component.dart';
import 'package:webapp_components/components/input_text_component.dart';
import 'package:webapp_components/components/select_from_list.dart';
import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_components/validators/null_validator.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/screens/components/upload_file_team_component.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';

import 'package:webapp_workflow/runners/workflow_runner.dart';

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

    var project = widget.modelLayer.project;

    var projectInputComponent =
        InputTextComponent("project", getScreenId(), "Project Name");
    projectInputComponent.setData(project.label);
    projectInputComponent.onChange(refresh);
    projectInputComponent.addValidator(
        NullValidator(invalidMessage: "Project Name cannot be empty"));

    var selectTeamComponent = SelectFromListComponent(
        "team", getScreenId(), "Select Team",
        user: widget.modelLayer.app.teamname);

    var fcsComponent = UploadFileTeamComponent(
        "uploadFcs", getScreenId(), "FCS File", "", "",
        maxHeight: 150,
        maxWidth: 350,
        allowedMime: ["application/zip", "application/vnd.isac.fcs"],
        showUploadButton: false);
    fcsComponent.setProjectOwnerCallback(getProjectId, getFileOwner);

    var annotationComponent = UploadTableTeamComponent(
        "uploadAnnotation",
        getScreenId(),
        "Marker Annotation File",
        widget.modelLayer.app.projectId,
        "",
        maxHeight: 150,
        maxWidth: 350,
        allowedMime: ["text/csv"],
        showUploadButton: false);
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

  String getProjectId() {
    return widget.modelLayer.app.projectId;
  }

  String getFileOwner() {
    return widget.modelLayer.app.teamname;
  }

  Future<void> _doCreateProjectUpload() async {
    openDialog(context);

    await _createLoadProject();

    await _uploadData();

    await _readFcsFiles();

    closeLog();

    setState(() {
      
    });
  }

  Future<void> _createLoadProject() async {
    log("Creating/Loading Project", dialogTitle: "Create Project");
    SingleValueComponent teamComponent =
        getComponent("team") as SingleValueComponent;
    var selectedTeam = teamComponent.getValue().label;

    SingleValueComponent projectComponent =
        getComponent("project") as SingleValueComponent;
    var projectName = projectComponent.getValue().label;

    await widget.modelLayer
        .createOrLoadProject(IdElement("", projectName), selectedTeam);

    await modelLayer.reloadProjectFiles();
    // modelLayer.app.projectName = widget.modelLayer.app.projectName;
    print("New project is ${widget.modelLayer.app.projectName}");
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
    WorkflowRunner runner = WorkflowRunner(widget.modelLayer.project.id,
        widget.modelLayer.teamname.id, widget.modelLayer.getWorkflow("immuno"));

    runner.addDocument(
        widget.modelLayer.stepsMapper.getStepId("immuno", "fcsTable"),
        upFcsComp.getValue().first.id);
    runner.addTableDocument(
        widget.modelLayer.stepsMapper.getStepId("immuno", "annotationTable"),
        upAnnotComp.getValue().first.id);

    widget.modelLayer.workflow = await runner.doRunStep(
        context, widget.modelLayer.stepsMapper.getStepId("immuno", "readFcs"));
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
