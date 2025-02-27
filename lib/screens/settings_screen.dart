import 'package:flutter/material.dart';

import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_components/components/input_text_component.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_components/extra/settings_loader.dart';
import 'package:webapp_components/action_components/button_component.dart';


class SettingsScreen extends StatefulWidget {
  final WebAppData modelLayer;
  const SettingsScreen(this.modelLayer, {super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with ScreenBase, ProgressDialog {
  @override
  String getScreenId() {
    return "SettingsScreen";
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

    var seedComponent = InputTextComponent("seed", getScreenId(), "Seed");

    var settingsLoader =
        SettingsLoader(getScreenId(), "assets/workflow_settings.json");
    var defaultSettingsComponents =
        settingsLoader.componentsFromSettings(mode: "default");
    
    var runIdentifierComponent = InputTextComponent("runId", getScreenId(), "Run Identifier");

    addComponent("default", seedComponent);
    addComponent("default", runIdentifierComponent);


    for (var comp in defaultSettingsComponents) {
      addComponent("Workflow Settings", comp,
          blockType: ComponentBlockType.expanded);
    }


    var runAnalysisBtn = ButtonActionComponent(
        "createProject", "Run Analysis", runAnalysis,
        blocking: false);
    addActionComponent(runAnalysisBtn);
    
    initScreen(widget.modelLayer as WebAppDataBase);
  }

  Future<void> runAnalysis() async {

  }

  @override
  Widget build(BuildContext context) {
    return buildComponents(context);
  }
}
