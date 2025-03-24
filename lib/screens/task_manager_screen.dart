import 'package:flutter/material.dart';

import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_model/webapp_table.dart';

import 'package:webapp_ui_commons/screens/task_manager_screen.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart' as sci;

class ImmunoTaskManagerScreen extends TaskManagerScreen {
  const ImmunoTaskManagerScreen(super.modelLayer, {super.key});

  @override
  State createState() => _ImmunoTaskManagerScreenState();
}

class _ImmunoTaskManagerScreenState extends TaskManagerScreenState {
  @override
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

  @override
  Future<WebappTable> fetchWorkflows() async {
    var modelLayer = widget.modelLayer as WebAppData;
    return await modelLayer.fcsService
        .fetchImmunoWorkflows(widget.modelLayer.app.projectId);
  }
}
