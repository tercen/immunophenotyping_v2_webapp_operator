import 'dart:async';

import 'package:flutter/material.dart';


import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_components/action_components/button_component.dart';
import 'package:webapp_components/components/input_text_component.dart';
import 'package:webapp_components/components/select_from_list.dart';
import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:webapp_template/webapp_data.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';

class ProjectScreen extends StatefulWidget {
  final WebAppData modelLayer;
  const ProjectScreen(this.modelLayer, {super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen>
    with ScreenBase, ProgressDialog {
  @override
  String getScreenId() {
    return "ProjectScreen";
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
    // projectInputComponent.onChange(checkRun);
    projectInputComponent.onChange(refresh);

    var selectTeamComponent = SelectFromListComponent(
        "team", getScreenId(), "Select Team",
        user: widget.modelLayer.app.teamname);

    addComponent("default", projectInputComponent);
    addComponent("default", selectTeamComponent);

    var createProjectBtn = ButtonActionComponent(
        "createProject", "Run Analysis", _doCreateProject,
        blocking: false, parents: [projectInputComponent, selectTeamComponent]);
    addActionComponent(createProjectBtn);
    initScreen(widget.modelLayer as WebAppDataBase);
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
