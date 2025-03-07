import 'package:flutter/material.dart';

import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_components/components/input_text_component.dart';
import 'package:webapp_components/components/multi_check_fetch.dart';
import 'package:webapp_components/validators/numeric_validator.dart';
import 'package:webapp_components/validators/range_validator.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_components/extra/settings_loader.dart';
import 'package:webapp_components/action_components/button_component.dart';
import 'package:webapp_workflow/runners/workflow_queu_runner.dart';

import 'package:webapp_model/id_element_table.dart';



import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_workflow/runners/workflow_runner.dart';


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

    var markers = MultiCheckComponentFetch("markerComp", getScreenId(), "Markers", fetchMarkers, columns: 4, 
          hasSelectAll: true, selectAll: true, columnWidth: 220);

    var seedComponent = InputTextComponent("seed", getScreenId(), "Seed");

    var downComponent = InputTextComponent("down", getScreenId(), "Downsample %");
    downComponent.addValidator(NumericValidator());
    downComponent.addValidator(RangeValidator(0, 100));
    downComponent.setValue(IdElement("100", "100"));

    var settingsLoader =
        SettingsLoader(getScreenId(), "assets/workflow_settings.json");
    var defaultSettingsComponents =
        settingsLoader.componentsFromSettings(mode: "default");
    
    var runIdentifierComponent = InputTextComponent("runId", getScreenId(), "Run Identifier");

    addComponent("default", markers);
    addComponent("default", seedComponent);
    addComponent("default", downComponent);
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

  Future<IdElementTable> fetchMarkers(List<String> parentKeys, String groupId) async{
    return await widget.modelLayer.fetchMarkers();
  }


  Future<void> runAnalysis() async {
    var factory = tercen.ServiceFactory();

    var runWorkflow = await factory.workflowService.copyApp(widget.modelLayer.workflow.id, widget.modelLayer.project.id);

    runWorkflow.folderId = widget.modelLayer.workflow.folderId;
    runWorkflow = await factory.workflowService.create(runWorkflow);

    var runner = WorkflowQueuRunner(
        widget.modelLayer.project.id,
        widget.modelLayer.teamname.id,
        runWorkflow);

    runner.setFolder(runWorkflow.folderId);

    var runIdComp = getComponent("runId", groupId: getScreenId()) as InputTextComponent;
    runner.setNewWorkflowName(runIdComp.getValue().label);

    var seedComp = getComponent("seed", groupId: getScreenId()) as InputTextComponent;
    runner.addSettingByName("seed", seedComp.getValue().label);

    var settingsComps = getComponentsPerBlock("Workflow Settings");

    for (var comp in settingsComps) {
      var setting = SettingsLoader.settingComponentToStepSetting(comp);
      if (setting != null) {
        runner.addSetting(setting);
      }
    }

    var markers = getComponent("markerComp") as MultiCheckComponentFetch;
    var selectedMarkers = markers.getValue();

    //TODO test and perhaps change function name (what does updateFilterValues do?)
    var downComp = getComponent("down", groupId: getScreenId()) as InputTextComponent;
    runner.changeFilterValue("Downsampling Percentage", "downsample.random_percentage", downComp.getValue().label);
    // runner.addAndFilter(widget.modelLayer.stepsMapper.getStepId("immuno", "channelAndDownsample"), 
    //      ["downsample.random_percentage"],
    //      [downComp.getValue().label]);
    

    for (var marker in selectedMarkers) {
      runner.addAndFilter(
        "Channel Selection",
          widget.modelLayer.stepsMapper.getStepId("immuno", "channelAndDownsample"), [
        "channel_name",
      ], [
        [marker.id]
      ]);
    }

    runner.addPostRun(widget.modelLayer.reloadProjectFiles);
    runner.doRun(context);

    
  }

  @override
  Widget build(BuildContext context) {
    return buildComponents(context);
  }
}
