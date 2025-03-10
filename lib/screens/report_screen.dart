import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:immunophenotyping_webapp/screens/components/immuno_image_list_component.dart';
import 'package:immunophenotyping_webapp/screens/components/single_select_table_component.dart';
import 'package:intl/intl.dart';

import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_components/components/leaf_selectable_list.dart';
import 'package:webapp_components/components/selectable_list.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';

import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_workflow/runners/workflow_queu_runner.dart';
import 'package:webapp_utils/functions/workflow_utils.dart';
import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
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

    var workflowList = SingleSelectTableComponent("workflows", getScreenId(), "Workflow List", 
        fetchWorkflows);

    var imageList = ImmunoImageListComponent("workflowImages", getScreenId(), "Image List", 
        fetchWorkflowImages, fetchPdfReport, fetchPptReport);
    imageList.addParent(workflowList);

    addComponent("default", workflowList);
    addComponent("default", imageList);
    
    initScreen(widget.modelLayer as WebAppDataBase);
  }

  bool isFullyRun(sci.Workflow w){
    bool fullyRun = true;
    for( var stp in w.steps ){
      fullyRun = fullyRun && stp.state.taskState.isFinal;
      fullyRun = fullyRun && stp.state.taskState is! sci.FailedState;
    }
    return fullyRun;
    // return !w.steps.any((stp) => !(stp.state.taskState.isFinal && stp.state.taskState is! sci.FailedState) );
  }


  Future<IdElementTable> fetchWorkflows(List<String> parentKeys, String groupId) async {
    print("FETCHING workflows for project ${widget.modelLayer.app.projectId}");
    var res = IdElementTable();
    var workflows = await widget.modelLayer.fetchProjectWorkflows(widget.modelLayer.app.projectId);
    List<IdElement> workflowColumn = [];
    List<IdElement> dateColumn = [];
    final dateFormatter =  DateFormat('yyyy/MM/dd hh:mm');
    for( var w in workflows ){
      if(isFullyRun(w)){
        var dt = DateTime.parse(w.lastModifiedDate.value);
        workflowColumn.add(IdElement(w.id, w.name));
        dateColumn.add(IdElement(w.id, dateFormatter.format(dt )));
      }
    }

    res.addColumn("Workflow Name", data: workflowColumn);
    res.addColumn("Last Update", data: dateColumn);

    return res;
  }

  Future<IdElementTable> fetchWorkflowImages(List<String> parentKeys, String groupId) async {
    var wkfComponent = getComponent("workflows", groupId: getScreenId()) as SingleSelectTableComponent;

    var selectedWorkflow = wkfComponent.getSelected();
    
    var factory = tercen.ServiceFactory();

    var workflow = await factory.workflowService.get(selectedWorkflow.id);

    return await widget.modelLayer.fetchWorkflowImagesByWorkflow(workflow);
  }

  Future<void> doDownload(Stream<List<int>> data, {String filename = "file", String mimetype = "application/octet-stream"}) async {
    List<int> bytes = [];
    await for( var b in data ){
      bytes.addAll(b);
    }
    
    var base64Bytes =  base64Encode( Uint8List.fromList(bytes));

    html.AnchorElement(href: 'data:$mimetype;base64,$base64Bytes')
      ..target = 'blank'
      ..download = filename
      ..click();
  }

  Future<IdElementTable> fetchPdfReport( List<String> parentIds, String groupId ) async {
    var compId = parentIds.first;
    print("Fetching pdf report");
    var wkfComponent = getComponent(compId, groupId: groupId) as SingleSelectTableComponent;

    var selectedWorkflow = wkfComponent.getSelected();
    var factory = tercen.ServiceFactory();

    var workflow = await factory.workflowService.get(selectedWorkflow.id);
    var stp = workflow.steps.firstWhere((e) => e.id == widget.modelLayer.stepsMapper.getStepId("immuno", "exportPdf")) as sci.DataStep;
    print("\tFound step report: ${stp.name} -- ${stp.computedRelation.id}");

    var simpleRelations = WorkflowUtils.getSimpleRelations(stp.computedRelation);

    assert( simpleRelations.isNotEmpty && simpleRelations.length == 1);

    
    var sch = await factory.tableSchemaService.get(simpleRelations.first.id);
    var nameCol = sch.columns.firstWhere((e) => e.name.contains("name")).name;
    var filenameTbl = await factory.tableSchemaService.select(sch.id, [nameCol], 0, 1);
    var byteStream = factory.tableSchemaService.selectFileContentStream(sch.id, filenameTbl.columns[0].values.first);
    
    await doDownload(byteStream, filename: filenameTbl.columns[0].values.first, mimetype: "application/pdf");
    //TODO GET Simple relation, then get schema and download it

    
    

    return IdElementTable();
  }

  Future<IdElementTable> fetchPptReport( List<String> parentIds, String groupId) async {
        var compId = parentIds.first;
    print("Fetching pdf report");
    var wkfComponent = getComponent(compId, groupId: groupId) as SingleSelectTableComponent;

    var selectedWorkflow = wkfComponent.getSelected();
    var factory = tercen.ServiceFactory();

    var workflow = await factory.workflowService.get(selectedWorkflow.id);
    var stp = workflow.steps.firstWhere((e) => e.id == widget.modelLayer.stepsMapper.getStepId("immuno", "exportPpt")) as sci.DataStep;
    print("\tFound step report: ${stp.name} -- ${stp.computedRelation.id}");

    var simpleRelations = WorkflowUtils.getSimpleRelations(stp.computedRelation);

    assert( simpleRelations.isNotEmpty && simpleRelations.length == 1);

    
    var sch = await factory.tableSchemaService.get(simpleRelations.first.id);
    var nameCol = sch.columns.firstWhere((e) => e.name.contains("name")).name;
    var filenameTbl = await factory.tableSchemaService.select(sch.id, [nameCol], 0, 1);
    var byteStream = factory.tableSchemaService.selectFileContentStream(sch.id, filenameTbl.columns[0].values.first);
    
    await doDownload(byteStream, filename: filenameTbl.columns[0].values.first, mimetype: "application/vnd.ms-powerpoint");

    
    

    return IdElementTable();
  }

  @override
  Widget build(BuildContext context) {
    return buildComponents(context);
  }
}
