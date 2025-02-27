import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webapp_components/components/action_list_component.dart';
import 'package:webapp_components/components/workflow_list_component.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';

import 'package:webapp_ui_commons/mixin/progress_log.dart';

import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_components/components/table_component.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_components/action_components/button_component.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_model/id_element.dart';

import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:webapp_components/widgets/wait_indicator.dart';

//TODO Clean up and move some fetch functions to the modellayer/webapp_lib
class TaskManagerScreen extends StatefulWidget {
  final WebAppData modelLayer;
  const TaskManagerScreen(this.modelLayer, {super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen>
    with ScreenBase, ProgressDialog {

  Timer? refreshTimer;
  bool firstRefresh = true;
  List<sci.Workflow> currentList = [];
  List<String> currentStatus = [];

  @override
  String getScreenId() {
    return "TaskManagerScreen";
  }

  @override
  void dispose() {
    super.dispose();
    disposeScreen();
    if( refreshTimer != null ){
      refreshTimer!.cancel();
    }
  }

  @override
  void refresh() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    
    var workflowComponent = WorkflowListComponent("workflowList", getScreenId(), "Workflows", 
          _fetchWorkflows, ["name", "status", "date"],  widget.modelLayer.app.projectHref,
          actions: [
            ListAction(const Icon(Icons.cancel), cancelWorkflow, enabledCallback: widget.modelLayer.workflowService.canCancelWorkflow)
          ],
          emptyMessage: "Retrieving Tasks",
          colWidths: [40, 10, 10],
          detailColumn: "error");
    addComponent("default", workflowComponent);

    

    initScreen(widget.modelLayer as WebAppDataBase);

    refreshTimer = Timer.periodic( const Duration(seconds: 1), (timer) async {
      // if( firstRefresh ){
      //   firstRefresh = false;
      // }else{
      if( await refreshWorkflowList()){
        refresh();
      }

        
      // }
    });
  }

  bool canCancelWorkflow(IdElementTable row){
    return row["status"][0].label != "Done" && row["status"][0].label != "Failed" && row["status"][0].label != "Unknown";
  }

  Future<void> cancelWorkflow(IdElementTable row) async {
    openDialog(context);
    
    var workflowId = row["name"][0].id;

    log("Canceling workflow  ${row["name"][0].label}");
    var factory = tercen.ServiceFactory();
    var workflow = await factory.workflowService.get(workflowId);

    var taskId = workflow.meta.firstWhere((e) => e.key == "run.task.id").value;
    await factory.taskService.cancelTask(taskId);
    
    await factory.workflowService.delete(workflow.id, workflow.rev);
    closeLog();
    
  }


  Future<Map<String, String>> getWorkflowStatus(sci.Workflow workflow) async {
    var meta = workflow.meta;
    var results = {"status":"", "error":"", "finished":"true"};
    results["status"] = "Unknown";
    

    if(meta.any((e) => e.key == "run.task.id")){

      var factory = tercen.ServiceFactory();

      List<String> currentOnQueuWorkflow = [];
      List<String> currentOnQueuStep = [];
      List<sci.State> currentOnQueuStatus = [];
      var compTasks = await factory.taskService.getTasks(["RunComputationTask"]);
        for( var ct in compTasks ){
          if( ct is sci.RunComputationTask){
            for( var p in ct.environment ){
              if( p.key == "workflow.id"){
                currentOnQueuWorkflow.add(p.value);
              }
              if( p.key == "step.id"){
                currentOnQueuStep.add(p.value);
                currentOnQueuStatus.add(ct.state);
              }
            }
          }
        }
      
      var isRunning = currentOnQueuWorkflow.contains(workflow.id);
      var isFail = workflow.steps.any((e) => e.state.taskState is sci.FailedState );


      if( isFail ){
        results["status"] = "Failed";
        results["error"] = meta.firstWhere((e) => e.key.contains("run.error"), orElse: () => sci.Pair.from("", "")).value;
        if( meta.any((e) => e.key == "run.error.reason")){
          results["error"] = meta.firstWhere((e) => e.key == "run.error.reason").value;
        }else{
          results["error"] = "${results["error"]}\n\nNo Error Details were Provided.";
        }
        results["finished"] = isRunning ? "false" : "true";
      }else{
        var status = isRunning ? "Running" : "Pending";
        var allInit = true;
        var allDone = true;
        results["finished"] = isRunning ? "false" : "true";
        
        for( var s in workflow.steps ){
          for( var i = 0; i < currentOnQueuStep.length; i++ ){
            if( currentOnQueuStep[i] == s.id && currentOnQueuWorkflow[i] == workflow.id ){
              status = currentOnQueuStatus[i] is sci.PendingState ? "Pending" : "Running";
            }
          }
         
          allInit = allInit && (s.state.taskState is sci.InitState);
          allDone = allDone && (s.state.taskState is sci.DoneState);
        }
        if( allInit  ){
          status = "Not Started";
        }
        if( allDone ){
          status = "Done";
        }
        results["status"] = status;
      }
    }
    return results;
  }

  Future<IdElementTable> _fetchWorkflows( List<String> parentKeys, String groupId ) async {
    var workflows = List<sci.Workflow>.from( currentList );

    List<IdElement> nameCol = [];
    List<IdElement> statusCol = [];
    List<IdElement> dateCol = [];
    List<IdElement> errorCol = [];

    final dateFormatter =  DateFormat('yyyy/MM/dd hh:mm');
    
    for( var w in workflows ){
      var dt = DateTime.parse(w.lastModifiedDate.value);
      var stMap =  await getWorkflowStatus(w);
      nameCol.add(IdElement(w.id, w.name));
      statusCol.add(IdElement(w.id, stMap["status"]!));
      dateCol.add(IdElement(w.id, dateFormatter.format(dt)));
      errorCol.add(IdElement(w.id, stMap["error"]!));

    }
    var tbl = IdElementTable()
      ..addColumn("name", data: nameCol)
      ..addColumn("status", data: statusCol)
      ..addColumn("date", data: dateCol)
      ..addColumn("error", data: errorCol);

    return tbl;
  }

  Future<List<sci.Workflow>> fetchWorkflowsRemote(String projectId) async{
    var factory = tercen.ServiceFactory();
    var projObjs = await factory.projectDocumentService.findProjectObjectsByLastModifiedDate(startKey: [projectId, '0000'], endKey: [projectId, '9999']);
    var workflowIds = projObjs.where((e) => e.subKind == "Workflow").map((e) => e.id).toList();

    return await factory.workflowService.list(workflowIds);
  }


  


  Future<bool> refreshWorkflowList() async {
    var workflowList = await fetchWorkflowsRemote(widget.modelLayer.project.id);

    List<String> statusList = [];

    for( var w in workflowList ){
      var stMap = await getWorkflowStatus(w);
      statusList.add( stMap["status"]!);
    }
    // var statusList = workflowList.map((w) async {
    //   var stMap = await getWorkflowStatus(w);
    //   return stMap["status"]!;
    // } ).toList();

    
    if( workflowList.length != currentList.length ){
      currentList = workflowList;
      currentStatus = statusList;
      return true;  
    }else{
      for( var i = 0; i < workflowList.length; i++ ){
        if( workflowList[i].id != currentList[i].id || currentStatus[i] != statusList[i] ){
          currentList = workflowList;
          currentStatus = statusList;
          return true;  
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return buildComponents(context);
    
  }
}