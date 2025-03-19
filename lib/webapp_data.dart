import 'dart:async';

import 'package:flutter/services.dart';
import 'package:immunophenotyping_webapp/service/fcs_service.dart';
import 'package:json_string/json_string.dart';
import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_model/settings/settings_filter.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/webapp.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/webapp_base.dart';
import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_utils/model/workflow_setting.dart';

class WorkflowSettingsFilter {
  final List<sci.Pair> include = [];
  final List<sci.Pair> exclude = [];
  WorkflowSettingsFilter();
}

class WebAppData extends WebAppDataBase {
  WebApp webapp;
  WebAppData(this.webapp) : super(webapp as WebAppBase);

  FcsService fcsService = FcsService();

  var workflow = sci.Workflow();

  // Map<String, List<WorkflowSettingsFilter>> settingFilterMap = {};

  Future<WebappTable> fetchMarkers(String workflowId) async {
    workflow = await workflowService.fetchWorkflow( workflowId );
    return await fcsService.fetchMarkers(
        workflow,  settingsService.getStepId("immuno", "readFcs"));
  }

  @override
  Future<void> init(String projectId, String projectName, String username,
      {String reposJsonPath = "",
      String settingFilterFile = "",
      String stepMapperJsonFile = "",
      bool storeNavigation = false}) async {
    await super.init(projectId, projectName, username,
        reposJsonPath: reposJsonPath,
        settingFilterFile: settingFilterFile,
        stepMapperJsonFile: stepMapperJsonFile,
        storeNavigation: storeNavigation);

    await fcsService.loadQcChannelsDefinition("assets/qc_channels.json");
  }

  // //TODO move to settings data service
  // Future<void> loadSettings() async {
  //   var factory = tercen.ServiceFactory();

  //   for (var template in workflowService.installedWorkflows.values) {
  //     var dataSteps = template.steps
  //         .whereType<sci.DataStep>()
  //         .where((step) =>
  //             step.model.operatorSettings.operatorRef.operatorId != "")
  //         .toList();
  //     var opIds = dataSteps
  //         .map((step) => step.model.operatorSettings.operatorRef.operatorId)
  //         .toList();
  //     var operators = await factory.operatorService.list(opIds);

  //     List<int>.generate(operators.length, (i) => i).map((i) {});
  //     for (var i = 0; i < operators.length; i++) {
  //       var step = dataSteps[i];
  //       var op = operators[i];
  //       workflowSettings.addAll(op.properties.map((prop) {
  //         if (prop is sci.DoubleProperty) {
  //           return WorkflowSetting(step.name, step.id, prop.name,
  //               prop.defaultValue.toString(), "double", prop.description);
  //         }
  //         if (prop is sci.StringProperty) {
  //           return WorkflowSetting(step.name, step.id, prop.name,
  //               prop.defaultValue, "string", prop.description);
  //         }
  //         if (prop is sci.BooleanProperty) {
  //           return WorkflowSetting(step.name, step.id, prop.name,
  //               prop.defaultValue.toString(), "boolean", prop.description);
  //         }
  //         if (prop is sci.EnumeratedProperty) {
  //           var kind = prop.isSingleSelection ? "ListSingle" : "ListMultiple";
  //           return WorkflowSetting(step.name, step.id, prop.name,
  //               prop.defaultValue, kind, prop.description,
  //               isSingleSelection: prop.isSingleSelection,
  //               opOptions: prop.values);
  //         }

  //         return WorkflowSetting(
  //             step.name, step.id, prop.name, "", "string", prop.description);
  //       }));
  //     }
  //   }
  // }

  // @override
  // Future<void> init(String projectId, String projectName, String username,
  //     {String reposJsonPath = "",
  //     String settingFilterFile = "",
  //     String stepMapperJsonFile = ""}) async {
  //   clear();

  //   await Future.wait([
  //     workflowService.init(reposJsonPath: reposJsonPath),
  //     ProjectUtils().loadFolderStructure(projectId),
  //     stepsMapper.loadSettingsFile(stepMapperJsonFile),
  //     settingsService.loadSettingsFilter(settingFilterFile)
  //   ]).onError((error, stackTrace) {
  //     throw ServiceError(500, error.toString());
  //   }, );

  //   await Future.wait([loadSettings(), loadModel()]);

  //   saveTimer ??= Timer.periodic(const Duration(seconds: 5), (timer) {
  //     saveModel();
  //   });
  // }
}
