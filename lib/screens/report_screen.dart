import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:immunophenotyping_webapp/screens/components/immuno_image_list_component.dart';
import 'package:webapp_components/components/single_select_table_component.dart';

import 'package:webapp_components/extra/infobox.dart';

import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';

import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_utils/functions/formatter_utils.dart';

class ReportScreen extends StatefulWidget {
  final WebAppData modelLayer;
  const ReportScreen(this.modelLayer, {super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with ScreenBase, ProgressDialog {
  @override
  String getScreenId() {
    return "ReportScreen";
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

    var workflowInfoBox =
        InfoBoxBuilder("Workflow Settings", workflowSettingsInfoBox);

    var workflowList = SingleSelectTableComponent(
        "workflows", getScreenId(), "Workflow List", fetchWorkflows,
        hideColumns: ["Id"], infoBoxBuilder: workflowInfoBox);

    var imageList = ImmunoImageListComponent("workflowImages", getScreenId(),
        "Image List", fetchWorkflowImages, fetchPdfReport, fetchPptReport);
    imageList.addParent(workflowList);

    addComponent("default", workflowList);
    addComponent("default", imageList);

    initScreen(widget.modelLayer as WebAppDataBase);
  }

  Widget workflowSettingsInfoBox(dynamic data, ValueNotifier<int> notifier) {
    Widget content = Container();

    var row = data as List<String>;
    // content = Text((data as List<String>).join("  ::  "));

    var workflow = widget.modelLayer
        .getProjectFiles()
        .where((doc) => doc.hasMeta("immuno.workflow"))
        .where((doc) => doc.getMeta("immuno.workflow")! == "true")
        .cast<sci.ProjectDocument>()
        .firstWhere((doc) => doc.id == row[0]);

    var metaList = workflow.meta;

    var markers = metaList
        .firstWhere((p) => p.key == "selected.markers",
            orElse: () => sci.Pair.from("", ""))
        .value
        .split("|@|");

    var contentString = "Selected markers\n";
    for (var i = 0; i < markers.length; i++) {
      contentString += markers[i];

      if (i < (markers.length - 1)) {
        if (((i + 1) % 10) == 0) {
          contentString += "\n";
        } else {
          contentString += ",";
        }
      }
    }

    contentString += "\n\nGeneral Settings:\n";

    for (var meta in metaList) {
      if (meta.key.startsWith("setting")) {
        contentString += meta.key.split(".").last;
        contentString += ": ";
        contentString += meta.value;
        contentString += "\n";
      }
    }

    content = Text(
      contentString,
      style: Styles()["text"],
    );
    return content;
  }

  bool isFullyRun(sci.Workflow w) {
    bool fullyRun = true;
    for (var stp in w.steps) {
      fullyRun = fullyRun && stp.state.taskState.isFinal;
      fullyRun = fullyRun && stp.state.taskState is! sci.FailedState;
    }
    return fullyRun;
    // return !w.steps.any((stp) => !(stp.state.taskState.isFinal && stp.state.taskState is! sci.FailedState) );
  }

  String getFolderName(String folderId) {
    return widget.modelLayer
        .getProjectFiles()
        .firstWhere((doc) => folderId == doc.id,
            orElse: () => sci.ProjectDocument())
        .name;
  }

  Future<WebappTable> fetchWorkflows() async {
    var res = WebappTable();

    var workflows = widget.modelLayer
        .getProjectFiles()
        .where((doc) => doc.hasMeta("immuno.workflow"))
        .where((doc) => doc.getMeta("immuno.workflow")! == "true")
        .cast<sci.ProjectDocument>()
        .toList();

    var workflowFolderIds = workflows.map((wkf) => wkf.folderId);
    var workflowFolderNames =
        workflowFolderIds.map((folderId) => getFolderName(folderId)).toList();

    res.addColumn("Id", data: workflows.map((w) => w.id).toList());
    res.addColumn("Name", data: workflows.map((w) => w.name).toList());
    res.addColumn("Folder", data: workflowFolderNames.toList());
    res.addColumn("Last Update",
        data: workflows
            .map((w) => DateFormatter.formatShort(w.lastModifiedDate))
            .toList());

    return res;
  }

  Future<WebappTable> fetchWorkflowImages() async {
    var wkfComponent = getComponent("workflows", groupId: getScreenId())
        as SingleSelectTableComponent;

    var selectedRow = wkfComponent.getComponentValue();

    var selectedWorkflow = widget.modelLayer
        .getProjectFiles()
        .where((doc) => doc.hasMeta("immuno.workflow"))
        .where((doc) => doc.getMeta("immuno.workflow")! == "true")
        .cast<sci.ProjectDocument>()
        .firstWhere(
          (doc) => doc.id == selectedRow["Id"].first,
          orElse: () => sci.ProjectDocument(),
        );
    if (selectedWorkflow.id == "") {
      return WebappTable();
    }

    var factory = tercen.ServiceFactory();

    var workflow = await factory.workflowService.get(selectedWorkflow.id);

    return await widget.modelLayer.fetchWorkflowImagesByWorkflow(workflow);
  }

  Future<WebappTable> fetchPdfReport() async {
    return await fetchReport("exportPdf");
  }

  Future<WebappTable> fetchPptReport() async {
    return await fetchReport("exportPpt");
  }

  Future<WebappTable> fetchReport(String step) async {
    var wkfComponent = getComponent("workflows", groupId: getScreenId())
        as SingleSelectTableComponent;

    var selectedRow = wkfComponent.getComponentValue();

    var selectedWorkflow = widget.modelLayer
        .getProjectFiles()
        .where((doc) => doc.hasMeta("immuno.workflow"))
        .where((doc) => doc.getMeta("immuno.workflow")! == "true")
        .cast<sci.ProjectDocument>()
        .firstWhere((doc) => doc.id == selectedRow["Id"].first);

    var factory = tercen.ServiceFactory();

    var workflow = await factory.workflowService.get(selectedWorkflow.id);

    var stp = workflow.steps.firstWhere((e) =>
            e.id == widget.modelLayer.settingsService.getStepId("immuno", step))
        as sci.DataStep;

    var simpleRelations = widget.modelLayer.workflowService
        .getSimpleRelations(stp.computedRelation);

    assert(simpleRelations.isNotEmpty && simpleRelations.length == 1);

    var sch = await factory.tableSchemaService.get(simpleRelations.first.id);
    var nameCol = sch.columns.firstWhere((e) => e.name.contains("name")).name;
    var filenameTbl =
        await factory.tableSchemaService.select(sch.id, [nameCol], 0, 1);
    var byteStream = factory.tableSchemaService
        .selectFileContentStream(sch.id, filenameTbl.columns[0].values.first);

    await doDownload(byteStream,
        filename: filenameTbl.columns[0].values.first,
        mimetype: "application/pdf");

    return WebappTable();
  }

  Future<void> doDownload(Stream<List<int>> data,
      {String filename = "file",
      String mimetype = "application/octet-stream"}) async {
    List<int> bytes = [];
    await for (var b in data) {
      bytes.addAll(b);
    }

    var base64Bytes = base64Encode(Uint8List.fromList(bytes));

    html.AnchorElement(href: 'data:$mimetype;base64,$base64Bytes')
      ..target = 'blank'
      ..download = filename
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    return buildComponents(context);
  }
}
