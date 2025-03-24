import 'package:flutter/services.dart';
import 'package:immunophenotyping_webapp/model/qc_channels.dart';
import 'package:json_string/json_string.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_model/sci_model.dart' as sci;

import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_utils/functions/formatter_utils.dart';

import 'package:webapp_utils/mixin/data_cache.dart';
import 'package:webapp_utils/services/workflow_data_service.dart';

class FcsService with DataCache {
  QcChannels qcChObject = QcChannels(channels: []);
  Future<WebappTable> fetchMarkers(
      sci.Workflow workflow, String readFcsStepId) async {
    var key = "${workflow.id}_${workflow.rev}";
    if (hasCachedValue(key)) {
      return getCachedValue(key);
    }
    var workflowService = WorkflowDataService();
    var resTbl = WebappTable();
    var factory = tercen.ServiceFactory();
    List<String> optionIds = [];
    List<String> optionDescs = [];

    for (var stp in workflow.steps) {
      if (stp.id == readFcsStepId) {
        var srIds = workflowService
            .getSimpleRelations((stp as sci.DataStep).computedRelation);
        var schList = await factory.tableSchemaService
            .list(srIds.map((e) => e.id).toList());
        for (var sch in schList) {
          if (sch.name == "Variables") {
            var nameCol =
                sch.columns.firstWhere((e) => e.name.contains("name"));
            var descCol =
                sch.columns.firstWhere((e) => e.name.contains("description"));

            var markerTbl = await factory.tableSchemaService
                .select(sch.id, [nameCol.name, descCol.name], 0, sch.nRows);

            var rows = List<int>.generate(sch.nRows, (i) => i);

            optionIds.addAll(rows
                .where((row) => !qcChannels.contains(
                    (markerTbl.columns[0].values as List<String>)[row]))
                .map((row) {
              var desc = markerTbl.columns[0].values[row];
              return desc;
            }));

            optionDescs.addAll(rows
                .where((row) => !qcChannels.contains(
                    (markerTbl.columns[0].values as List<String>)[row]))
                .map((row) {
              var desc = markerTbl.columns[1].values[row];
              return desc;
            }));
          }
        }
      }
    }

    resTbl.addColumn("MarkerId", data: optionIds);
    resTbl.addColumn("MarkerDescription", data: optionDescs);

    addToCache(key, resTbl);
    return resTbl;
  }

  List<String> get qcChannels => qcChObject.channels;

  Future<void> loadQcChannelsDefinition(String assetPath) async {
    if (assetPath == "") {
      return;
    }
    var assetString = await rootBundle.loadString(assetPath);
    final jsonString = JsonString(assetString);

    qcChObject = QcChannels.fromJson(jsonString.decodedValueAsMap);
  }

  Future<WebappTable> fetchImmunoWorkflows(String projectId) async {
    var key = projectId;
    if (hasCachedValue(key)) {
      return getCachedValue(key);
    } else {
      var workflowService = WorkflowDataService();
      var workflows = (await workflowService.fetchWorkflowsRemote(projectId))
          .where((doc) => doc.hasMeta("immuno.workflow"))
          .where((doc) => doc.getMeta("immuno.workflow")! == "true")
          .toList();

      var res = WebappTable();

      List<String> status = [];
      List<String> error = [];

      for (var w in workflows) {
        // var sw = await workflowService.getWorkflowStatus(w);
        var sw = await getImmunoWorkflowStatus(w);

        status.add(sw["status"]!);
        error.add(sw["error"]!);
      }

      res.addColumn("Id", data: workflows.map((w) => w.id).toList());
      res.addColumn("Name", data: workflows.map((w) => w.name).toList());
      res.addColumn("Status", data: status);
      // res.addColumn("Error", data: error);
      res.addColumn("Last Update",
          data: workflows
              .map((w) => DateFormatter.formatShort(w.lastModifiedDate))
              .toList());

      return res;
    }
  }

  Future<Map<String, String>> getImmunoWorkflowStatus(
      sci.Workflow workflow) async {
    var meta = workflow.meta;
    var results = {"status": "", "error": "", "finished": "true"};
    results["status"] = "Unknown";

    if (workflow.steps.any((e) => e.state.taskState is sci.FailedState)) {
      results["status"] = "Failed";
      results["error"] = meta
          .firstWhere((e) => e.key.contains("run.error"),
              orElse: () => sci.Pair.from("", ""))
          .value;
      if (meta.any((e) => e.key == "run.error.reason")) {
        var reason = meta.firstWhere((e) => e.key == "run.error.reason").value;
        results["error"] = reason != "" ? reason : "No details provided";
      } else {
        results["error"] =
            "${results["error"]}\n\nNo Error Details were Provided.";
      }
    } else if (!workflow.steps
        .whereType<sci.DataStep>()
        .map((step) => step.state.taskState is sci.DoneState)
        .any((state) => state == false)) {
      results["status"] = "Finished";
    } else {
      results["status"] = "Running";
    }

    return results;
  }
}
