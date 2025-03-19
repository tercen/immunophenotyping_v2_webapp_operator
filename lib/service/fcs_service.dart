import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:immunophenotyping_webapp/model/qc_channels.dart';
import 'package:json_string/json_string.dart';
import 'package:sci_tercen_client/sci_client_base.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_utils/functions/workflow_utils.dart';
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
    // var qcChannels =  qcChannels;

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

  // Future<List<String>> getQcChannels() async {
  //   var qcCacheKey = "qcChannels";

  //   if (hasCachedValue(qcCacheKey)) {
  //     return getCachedValue(qcCacheKey);
  //   } else {
  //     var qcChannelsJson =
  //         await rootBundle.loadString("assets/qc_channels.json");

  //     final jsonString = JsonString(qcChannelsJson);
  //     final qcChannelsMap = jsonString.decodedValueAsMap;

  //     var channelList = (qcChannelsMap["channels"] as List).map((e) => e as String).toList();
  //     addToCache(qcCacheKey, channelList );

  //     return getCachedValue(qcCacheKey);
  //   }
  // }
}
