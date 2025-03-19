import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:immunophenotyping_webapp/screens/components/immuno_image_list_component.dart';
import 'package:immunophenotyping_webapp/screens/components/single_select_table_component.dart';
import 'package:immunophenotyping_webapp/screens/components/tmp_action.dart';
import 'package:immunophenotyping_webapp/screens/components/tmp_workflow.dart';
import 'package:immunophenotyping_webapp/screens/utils/date_utils.dart';
import 'package:intl/intl.dart';
import 'package:webapp_components/definitions/list_action.dart';
import 'package:webapp_components/extra/infobox.dart';

import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_components/components/leaf_selectable_list.dart';
import 'package:webapp_components/components/selectable_list.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';

import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_workflow/runners/workflow_queu_runner.dart';
import 'package:webapp_utils/functions/workflow_utils.dart';
import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

class TaskManagerScreen extends StatefulWidget {
  final WebAppData modelLayer;
  const TaskManagerScreen(this.modelLayer, {super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen>
    with ScreenBase, ProgressDialog {
  @override
  String getScreenId() {
    return "TaskManagerScreen";
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

    var taskList = WorkflowTaskComponent(
        "workflows", getScreenId(), "Running Tasks", fetchTasks, [
      //#509bb4
      ListAction(
          const Icon(Icons.stop_circle_rounded,
              color: Color.fromARGB(255, 103, 153, 178)),
          cancelTask),
    ], [
      ListAction(
          const Icon(Icons.info_outline_rounded,
              color: Color.fromARGB(255, 103, 153, 178)),
          workflowInfo)
    ],
        hideColumns: [
          "Id"
        ]);

    var workflowList = ActionTableComponent(
        "workflows",
        getScreenId(),
        "Finished Workflows",
        fetchWorkflows,
        [
          ListAction(
              const Icon(Icons.error_outline,
                  color: Color.fromARGB(255, 103, 153, 178)),
              workflowInfoWithError),
        ],
        hideColumns: ["Id"]);

    addComponent("default", workflowList);
    addComponent("default", taskList);
    

    initScreen(widget.modelLayer as WebAppDataBase);
  }

  Widget buildTest() {
    return AlertDialog(
      title: Text(
        "Error Information",
        style: Styles()["textH1"],
      ),
      content: Container(
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 1200),
        child: Text("AAA "),
      ),
    );
  }

  Future<void> cancelTask(List<String> row) async {
    Fluttertoast.showToast(
        msg: "Cancelling task",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM_LEFT,
        webPosition: "left",
        webBgColor: "linear-gradient(to bottom, #aaaaff, #eeeeaff)",
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.lightBlue[100],
        textColor: Styles()["black"],
        fontSize: 16.0);
    var taskId = row.first;
    var factory = tercen.ServiceFactory();
    await factory.taskService.cancelTask(taskId);

    //     Fluttertoast.showToast(
    //     msg: "Cancelling task",
    //     toastLength: Toast.LENGTH_LONG,
    //     gravity: ToastGravity.BOTTOM_LEFT,
    //     webPosition: "left",
    //     webBgColor: "linear-gradient(to bottom, #aaaaff, #eeeeaff)",
    //     timeInSecForIosWeb: 1,
    //     backgroundColor: Colors.lightBlue[100],
    //     textColor: Styles()["black"],
    //     fontSize: 16.0
    // );
  }

  //TODO use cache for this
  Future<Widget> workflowSettingsInfoBox(String workflowId,
      {bool printError = false}) async {
    var factory = tercen.ServiceFactory();
    var workflow = await factory.workflowService.get(workflowId);

    Widget content = Container();

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

    if (printError) {
      var status =
          await widget.modelLayer.workflowService.getWorkflowStatus(workflow);
      if (status["error"] != null && status["error"] != "") {
        contentString += "\nERROR INFORMATION";
        contentString += "\n\n";
        contentString += status["error"]!;
      }
    }

    content = Text(
      contentString,
      style: Styles()["text"],
    );
    return content;
  }

  Future<void> workflowInfoWithError(List<String> row) async {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (stfCtx, stfSetState) {
            return FutureBuilder(
                future: workflowSettingsInfoBox(row.first, printError: true),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return AlertDialog(
                      title: Text(
                        "Workflow Information",
                        style: Styles()["textH2"],
                      ),
                      content: snapshot.data!,
                    );
                  } else {
                    return TercenWaitIndicator()
                        .waitingMessage(suffixMsg: "Loading information");
                  }
                });
          });
        });
  }

  Future<void> workflowInfo(List<String> row) async {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (stfCtx, stfSetState) {
            return FutureBuilder(
                future: workflowSettingsInfoBox(row.first),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return AlertDialog(
                      title: Text(
                        "Workflow Information",
                        style: Styles()["textH2"],
                      ),
                      content: snapshot.data!,
                    );
                  } else {
                    return TercenWaitIndicator()
                        .waitingMessage(suffixMsg: "Loading information");
                  }
                });
          });
        });
  }

  Future<void> action1(List<String> row) async {
    print("Doing action1");
  }

  Future<void> action2(List<String> row) async {
    print("Doing action2");
  }

  bool action2enabled(List<String> row) {
    return false;
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

  bool isFinished(sci.Workflow workflow) {
    return workflow.steps
        .where((step) => !step.state.taskState.isFinal)
        .isEmpty;
  }

  Future<WebappTable> fetchWorkflows() async {
    var res = WebappTable();

    var workflows = await widget.modelLayer.workflowService
        .fetchWorkflowsRemote(widget.modelLayer.app.projectId);
    workflows = workflows
        .where((doc) => doc.hasMeta("immuno.workflow"))
        .where((doc) => doc.getMeta("immuno.workflow")! == "true")
        .toList();
    List<String> status = [];
    List<String> error = [];

    for (var w in workflows) {
      var sw = await widget.modelLayer.workflowService.getWorkflowStatus(w);
      status.add(sw["status"]! == "Failed" ? "Failed" : "");
      error.add(sw["error"]!);
    }

    res.addColumn("Id", data: workflows.map((w) => w.id).toList());
    res.addColumn("Name", data: workflows.map((w) => w.name).toList());
    res.addColumn("Fail Status", data: status);
    // res.addColumn("Error", data: error);
    res.addColumn("Last Update",
        data: workflows
            .map((w) => DateFormatter.formatShort(w.lastModifiedDate))
            .toList());

    return res;
  }

  Future<WebappTable> fetchTasks() async {
    var res = WebappTable();

    var factory = tercen.ServiceFactory();
    var tasks = await factory.taskService.getTasks(["RunWorkflowTask"]);
    var compTasks = tasks.whereType<sci.RunWorkflowTask>();

    // var workflows = await widget.modelLayer.workflowService.fetchWorkflowsRemote(widget.modelLayer.app.projectId);
    print("Found ${compTasks.length} tasks");

    var workflowIds = compTasks.map((task) => task.workflowId).toList();

    var workflows = await factory.workflowService.list(workflowIds);

    // var workflowFolderIds = workflows.map((wkf) => wkf.folderId);
    // var workflowFolderNames = widget.modelLayer.getProjectFiles().where((doc) => workflowFolderIds.contains( doc.id ) ).map((doc) => doc.name);

    // var factory = tercen.ServiceFactory();

    // workflows = workflows.where((workflow) => isFinished(workflow)).toList();
    // var taskIds = workflows.map((w) => w.hasMeta("workflow.task.id") ? w.getMeta("workflow.task.id")! : "" ).toList();
    res.addColumn("Id", data: compTasks.map((w) => w.id).toList());
    res.addColumn("Name", data: workflows.map((w) => w.name).toList());
    res.addColumn("WorkflowIds", data: workflows.map((w) => w.id).toList());
    res.addColumn("Last Update",
        data: workflows
            .map((w) => DateFormatter.formatShort(w.lastModifiedDate))
            .toList());
    // if( res.nRows > 0){
    //   print(res);
    // }else{
    //   print("UNEXPECTED!");
    // }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return buildComponents(context);
  }
}
