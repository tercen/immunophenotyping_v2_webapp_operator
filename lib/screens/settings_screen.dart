import 'package:flutter/material.dart';



import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_components/components/multi_check_fetch.dart';
import 'package:webapp_components/components/single_select_table_component.dart';
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
import 'package:webapp_utils/functions/formatter_utils.dart';
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
    openDialog(context);

    log("Preparing workflow task for execution.", dialogTitle: "Task Runner");

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
    var selectedMarkers = markers.getComponentValueAsTable()["MarkerDescription"];
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
    runner.doRun(context, stepsToRun: [
      "78726478-262f-40bd-acbd-8bed9ce0e274",
      "5860d4ae-9c43-48a4-b89b-6af49a0c7397",
      "5821188f-ea58-4380-9e1d-1ed2a327fff6",
      "ec2c9500-28bd-40ed-9749-fa4e1519fcbb",
      "a144b0d5-8bd2-40ed-8be1-10e1f23da168",
      "242e2bd5-8e25-4aef-a311-dfb2a2997497",
      "513c56bf-fefa-4155-95f5-375309a21b11",
      "d9faca40-2209-45c8-9f19-5d41f8580ac1",
      "89e2c483-0c20-4372-a0ca-1b7191756276",
      "50ba414c-c2a2-457f-9d02-bdde0d0a7cc5",
      "b6468539-d35a-4aa8-95b4-209afe6bb316",
      "a09c1cfc-2b52-47e9-8561-3418c267b3f3",
      "5338d6a2-6dce-485d-811c-a74da87e92a6",
      "3818ccac-9a98-4877-914e-957dea2a0c76",
      "b2a5cc9f-a734-4f47-ab29-669b73c0c968",
      "94e69450-93bc-44d8-9b3f-9b4f6e75a9fc",
      "236b6c0f-2b79-4e57-b459-6f1c2f63d722",
      "6418bff0-98b2-450e-84e8-b3c1f6a19457",
      "c3dafe03-d1e2-41a6-b9e0-4de359853230",
      "9ef9af59-2958-4e22-93f0-e35c0325b022",
      "d180f5bb-a877-4cbf-948c-c711a480d51a",
      "432cc003-6a8f-41c3-98a6-d8a7400f4a7b",
      "bfbd3b3d-b4ec-4815-834f-872ae4e09e25",
      "530b337e-534a-4435-89f6-15f32a7eb341",
      "2b7083f8-bfdc-43f6-80ac-574a0f301ad8",
      "63870c9e-a2e5-4267-97fd-0f0ee4715ef9",
      "56ccde5c-ebf6-47c8-85e2-7068ff5a1ba1",
      "5c0619a4-e073-4962-be02-3a31250c85c7",
      "4ef403a9-3e85-4a01-a292-3c04cc9cc688",
      "c9de769a-dc43-4a90-a0df-574e46de6e5f"
    ] );
    log("Done", dialogTitle: "Task Runner");

    await Future.delayed(Duration(milliseconds: 300), (){
      closeLog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildComponents(context);
  }
}
