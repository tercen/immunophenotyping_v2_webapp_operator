import 'package:flutter/material.dart';
import 'package:immunophenotyping_webapp/screens/components/tmp_action.dart';
import 'package:webapp_components/definitions/functions.dart';
import 'package:webapp_components/definitions/list_action.dart';
import 'package:webapp_components/extra/infobox.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/list_utils.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_model/sci_model.dart' as sci;

class WorkflowTaskComponent extends ActionTableComponent {
  // Future<String> Function( List<String> row ) getWorkflowStatus;
  // Future<Map<String, String>> Function (sci.Workflow workflow) getWorkflowStatusCallback;
  List<String> runningTasks = [];
  List<String> workflowTasks = [];

  WebappTable initTable = WebappTable();


  final List<ListAction> workflowActions;

  WorkflowTaskComponent(
      super.id,
      super.groupId,
      super.componentLabel,
      super.dataFetchCallback,
      super.actions,
      this.workflowActions,
      {super.excludeColumns,
      super.hideColumns});

  @override
  Widget buildTable(WebappTable table, BuildContext context) {
    
    List<Widget> tableRows = [];

    for (var workflowTaskId in workflowTasks) {
      var idx = initTable["Id"].indexOf(workflowTaskId);

      var workflowName = initTable["Name"][idx];
      var tableLabel = Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              "Workflow:   $workflowName",
              style: Styles()["textH2"],
            ),
            SizedBox(
              width: 10,
            ),
            IconButton(
                onPressed: () {
                  workflowActions
                      .first.callback!([initTable["WorkflowIds"][idx]]);
                },
                icon: workflowActions.first.actionIcon)
          ],
        ),
      );

      tableRows.add(const SizedBox(
        height: 20,
      ));
      tableRows.add(tableLabel);
      tableRows.add(buildWorkflowTable(workflowTaskId, table, context));
      tableRows.add(const SizedBox(
        height: 20,
      ));
    }


    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tableRows);
  }



  Widget buildWorkflowTable(
      String workflowId, WebappTable table, BuildContext context) {
    // dataTable = table;
    var nRows = table.nRows;

    colNames = table.colNames
        .where((colName) => shouldIncludeColumn(colName))
        .toList();

    var colNamesWithStatus =
        colNames.where((colName) => shouldDisplayColumn(colName)).toList();

    List<TableRow> rows = [];
    rows.add(createTableHeader(colNamesWithStatus));

    var indices = List<int>.generate(nRows, (i) => i);
    if (sortDirection != "" && sortingCol != "") {
      indices = ListUtils.getSortedIndices(table.columns[sortingCol]!);

      if (sortDirection == "desc") {
        indices = indices.reversed.toList();
      }
    }

    for (var si = 0; si < indices.length; si++) {
      var ri = indices[si];
      var rowEls = colNames.map((col) => table.columns[col]![ri]).toList();
      // await
      rows.add(createTableRow(context, rowEls, actions, rowIndex: si));
    }

    Map<int, TableColumnWidth> colWidths = infoBoxBuilder == null
        ? const {0: FixedColumnWidth(30)}
        : {0: const FixedColumnWidth(30), 1: const FixedColumnWidth(50)};

    var tableWidget = Table(
      columnWidths: colWidths,
      children: rows,
    );

    return tableWidget;
  }

  Future<void> processTaskEvent(String channelId) async {
    var factory = tercen.ServiceFactory();
    var taskStream = factory.eventService.channel(channelId);
    await for (var evt in taskStream) {
      if (evt is sci.TaskStateEvent) {
        if (evt.state.isFinal) {
          runningTasks.remove(evt.taskId);
        } else {
          runningTasks.add(evt.taskId);
        }

        runningTasks = runningTasks.toSet().toList();
        await loadTaskTable();
        notifyListeners();
      }
    }
  }

  @override
  Future<void> init() async {
    await super.init();
    await loadTable();

    notifyListeners();
  }

  Future<void> loadTaskTable() async {
    var factory = tercen.ServiceFactory();
    List<String> taskId = [];
    List<String> taskType = [];
    List<String> taskDuration = [];
    List<String> taskStatus = [];

    if (runningTasks.isNotEmpty) {
      var tasks = await factory.taskService.list(runningTasks);
      for (var ct in tasks) {
        taskId.add(ct.id);
        taskType.add(ct.kind);
        taskDuration.add(ct.duration.toString());
        taskStatus.add(ct.state.kind);

      }
    }

    dataTable = WebappTable();
    dataTable.addColumn("Id", data: taskId);
    dataTable.addColumn("Type", data: taskType);
    dataTable.addColumn("Status", data: taskStatus);
    dataTable.addColumn("Duration", data: taskDuration);
  }

  @override
  Future<bool> loadTable() async {

    if (!isInit) {
      print("BUILDING TABLE");
      runningTasks.clear();
      var factory = tercen.ServiceFactory();

      initTable = await dataFetchCallback();
      
      print("Data table loaded");
      workflowTasks = initTable["Id"].where((e) => e != "").toList();
      await loadTaskTable();
      runningTasks.addAll(workflowTasks);
      var tasks = await factory.taskService.list(workflowTasks);

      for (var task in tasks) {
        processTaskEvent(task.channelId);
      }
      // var cacheKey = getCacheKey();
      // if (hasCachedValue(cacheKey)) {
      //   dataTable = getCachedValue(cacheKey);
      // }else{
      //   dataTable = await dataFetchCallback();
      //   addToCache(cacheKey, dataTable);
      // }
    }
    return true;
  }
}
