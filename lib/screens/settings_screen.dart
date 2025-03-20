import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:immunophenotyping_webapp/screens/components/single_select_table_component.dart';
import 'package:immunophenotyping_webapp/screens/components/temp2.dart';
import 'package:immunophenotyping_webapp/screens/utils/date_utils.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_components/extra/settings_converter.dart';
import 'package:webapp_components/mixins/component_base.dart';

import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_components/components/input_text_component.dart';
import 'package:webapp_components/validators/numeric_validator.dart';
import 'package:webapp_components/validators/range_validator.dart';

import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_components/action_components/button_component.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_workflow/runners/workflow_queu_runner.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

import 'utils/setting_component_generator.dart';

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

    var workflowList = SingleSelectTableComponent(
        "workflowFolders", getScreenId(), "Workflow List", fetchWorkflows,
        hideColumns: ["Id"]);

    var markers = MultiCheckComponentFetch(
        "markerComp", getScreenId(), "Markers", fetchMarkers,
        columns: 4,
        hasSelectAll: false,
        selectAll: true,
        columnWidth: 220,
        displayColumn: "MarkerDescription");
    markers.addParent(workflowList);

    var seedComponent = InputTextComponent("seed", getScreenId(), "Seed");

    var downComponent =
        InputTextComponent("down", getScreenId(), "Downsample %");
    downComponent.addValidator(NumericValidator());
    downComponent.addValidator(RangeValidator(0, 100));
    downComponent.setComponentValue("100");

    var compGenerator = SettingComponentGenerator();

    var defaultSettingsComponents =
        compGenerator.getScreenSettings(getScreenId(), widget.modelLayer);

    var runIdentifierComponent =
        InputTextComponent("runId", getScreenId(), "Run Identifier");

    addComponent("default", workflowList);

    addComponent("default", markers);
    addComponent("default", seedComponent);
    addComponent("default", downComponent);
    addComponent("default", runIdentifierComponent);

    addHorizontalBar("default");

    addHeading("default", "Settings");

    for (var comp in defaultSettingsComponents) {
      var block = (comp as ComponentBase).getMeta("step.name") == null
          ? "Settings"
          : (comp as ComponentBase).getMeta("step.name")!.value;
      addComponent(block, comp, blockType: ComponentBlockType.collapsed);
    }

    var runAnalysisBtn = ButtonActionComponent(
        "createProject", "Run Analysis", runAnalysis,
        blocking: false, parents: [markers, workflowList]);
    addActionComponent(runAnalysisBtn);

    initScreen(widget.modelLayer as WebAppDataBase);
  }

  bool isBaseReadFcs(sci.ProjectDocument pd) {
    return pd.hasMeta("immuno.readFcs.run") &&
        pd.getMeta("immuno.readFcs.run") == "true";
  }


  Future<WebappTable> fetchMarkers() async {

    var workflowComponent =
        getComponent("workflowFolders") as SingleSelectTableComponent;

    var selectedWkfFolder = workflowComponent.getComponentValue()["Id"];

    var res = WebappTable();
    if (selectedWkfFolder.isNotEmpty) {
      var folderId = selectedWkfFolder.first;

      var wkfDoc = widget.modelLayer
          .getProjectFiles()
          .whereType<sci.ProjectDocument>()
          .where((pd) => pd.folderId == folderId)
          .firstWhere((pd) => isBaseReadFcs(pd),
              orElse: () => throw sci.ServiceError(
                  500,
                  "Unexpected file structure",
                  "Workflow containing readFcs execution could not be located"));
      res = await widget.modelLayer.fetchMarkers(wkfDoc.id);
    }

    return res; //await widget.modelLayer.fetchMarkers();
  }

  Future<WebappTable> fetchWorkflows() async {
    var res = WebappTable();
    var dataFolders = widget.modelLayer
        .getProjectFiles()
        .where((doc) => doc.hasMeta("immuno.data.folder"))
        .where((doc) => doc.getMeta("immuno.data.folder")! == "true")
        .toList();

    res.addColumn("Id", data: dataFolders.map((doc) => doc.id).toList());
    res.addColumn("Name", data: dataFolders.map((doc) => doc.name).toList());
    res.addColumn("Date",
        data: dataFolders
            .map((doc) => DateFormatter.formatShort(doc.lastModifiedDate))
            .toList());

    return res;
  }

  Future<void> runAnalysis() async {
    Fluttertoast.showToast(
        msg: "Workflow is being prepared",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM_LEFT,
        webPosition: "left",
        webBgColor: "linear-gradient(to bottom, #aaaaff, #eeeeaff)",
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.lightBlue[100],
        textColor: Styles()["black"],
        fontSize: 16.0);

    var factory = tercen.ServiceFactory();

    //Copy the template with the 'Read FCS' step completed
    var runWorkflow = await factory.workflowService.copyApp(
        widget.modelLayer.workflow.id, widget.modelLayer.app.projectId);

    runWorkflow.folderId = widget.modelLayer.workflow.folderId;
    runWorkflow = await factory.workflowService.create(runWorkflow);

    var runner = WorkflowQueuRunner(widget.modelLayer.app.projectId,
        widget.modelLayer.app.teamname, runWorkflow);

    runner.addWorkflowMeta("immuno.readFcs.run", "false");

    runner.setFolder(runWorkflow.folderId);

    var runIdComp =
        getComponent("runId", groupId: getScreenId()) as InputTextComponent;

    if (runIdComp.isFulfilled()) {
      runner.setNewWorkflowName(runIdComp.getComponentValue());
    }

    var seedComp =
        getComponent("seed", groupId: getScreenId()) as InputTextComponent;
    if( seedComp.getComponentValue() != ""){
      runner.addSettingByName("seed", seedComp.getComponentValue());
      runner.addWorkflowMeta("setting.seed", seedComp.getComponentValue());
    }
    


    var blocks = componentBlocks.keys.where((block) => block != "default");
    for (var block in blocks) {
      var settingsComps = getComponentsPerBlock(block);

      for (var comp in settingsComps) {
        var setting = SettingsConverter.settingComponentToStepSetting(comp);
        if (setting != null) {
          if (setting.value != "") {
            runner.addWorkflowMeta(
                "setting.${setting.settingName}", setting.value);
            runner.addSetting(setting);
          }
        }
      }
    }

    var markers = getComponent("markerComp") as MultiCheckComponentFetch;
    var selectedMarkers = markers.getComponentValueAsTable()["MarkerId"];
    runner.addWorkflowMeta("selected.markers", selectedMarkers.join("|@|"));

    var downComp =
        getComponent("down", groupId: getScreenId()) as InputTextComponent;

    if( downComp.getComponentValue() != ""){
      runner.changeFilterValue("Downsampling Percentage",
        "downsample.random_percentage", downComp.getComponentValue());
      runner.addWorkflowMeta(
          "setting.downsampling", downComp.getComponentValue());
    }
    

    for (var marker in selectedMarkers) {
      runner.addAndFilter(
          "Channel Selection",
          widget.modelLayer.settingsService
              .getStepId("immuno", "channelAndDownsample"),
          [
            "channel_name",
          ],
          [
            [marker]
          ]);
    }

    runner.addWorkflowMeta("immuno.workflow", "true");

    runner.addPostRun(widget.modelLayer.reloadProjectFiles);
    runner.doRun(context);
  }

  @override
  Widget build(BuildContext context) {
    return buildComponents(context);
  }
}
