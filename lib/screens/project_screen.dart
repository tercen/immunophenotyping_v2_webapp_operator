import 'dart:async';

import 'package:flutter/material.dart';


import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_components/action_components/button_component.dart';
import 'package:webapp_components/components/input_text_component.dart';
import 'package:webapp_components/components/upload_multi_file_component.dart';
import 'package:webapp_components/components/select_from_list.dart';
import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/screens/components/upload_file_team_component.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';

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

    var selectTeamComponent = SelectFromListComponent(
        "team", getScreenId(), "Select Team",
        user: widget.modelLayer.app.teamname);

    var fcsComponent = UploadFileTeamComponent("uploadFcs", getScreenId(), 
            "FCS File", widget.modelLayer.app.projectId, "", getFileOwner,
             maxHeight: 150, maxWidth: 200, allowedMime: ["application/zip", "application/vnd.isac.fcs"], showUploadButton: false);
      
    var annotationComponent = UploadFileTeamComponent("uploadAnnotation", getScreenId(), 
            "Marker Annotation File", widget.modelLayer.app.projectId, "", getFileOwner,
             maxHeight: 150, maxWidth: 200, allowedMime: ["text/csv"], showUploadButton: false);

    addComponent("default", projectInputComponent);
    addComponent("default", selectTeamComponent);
    addHorizontalBar("default");
    addComponent("default", fcsComponent);
    addComponent("default", annotationComponent);

    var createProjectBtn = ButtonActionComponent(
        "createProject", "Run Analysis", _doCreateProject,
        blocking: false, parents: [projectInputComponent, selectTeamComponent]);
    addActionComponent(createProjectBtn);
    initScreen(widget.modelLayer as WebAppDataBase);
  }

  String getFileOwner(){
    return widget.modelLayer.app.teamname;
  }

  Future<void> _doCreateProject() async {
    openDialog(context);
    log("Creating/Loading Project", dialogTitle: "Create Project");

    SingleValueComponent teamComponent =
        getComponent("team") as SingleValueComponent;
    var selectedTeam = teamComponent.getValue().label;

    SingleValueComponent projectComponent =
        getComponent("project") as SingleValueComponent;
    var projectName = projectComponent.getValue().label;

    await widget.modelLayer
        .createOrLoadProject(IdElement("", projectName), selectedTeam);

    log("Uploading Files", dialogTitle: "Create Project");
    var upFcsComp = getComponent("uploadFcs") as UploadFileTeamComponent;
    await upFcsComp.doUpload(context);
    
    var upAnnotComp = getComponent("uploadAnnotation") as UploadFileTeamComponent;
    await upAnnotComp.doUpload(context);
    closeLog();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget.modelLayer.fetchUserList(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            (getComponent("team")! as SelectFromListComponent)
                .setOptions(snapshot.data!);
            return buildComponents(context);
          } else {
            // TODO fullscreen wait widget
            (getComponent("team")! as SelectFromListComponent)
                .setOptions(["Loading user list..."]);
            return buildComponents(context);
          }
        });
  }
}
