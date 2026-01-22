import 'dart:async';

import 'package:immunophenotyping_webapp/service/fcs_service.dart';

import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/webapp.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/webapp_base.dart';
import 'package:sci_tercen_model/sci_model.dart' as sci;

class WebAppData extends WebAppDataBase {
  WebApp webapp;
  WebAppData(this.webapp) : super(webapp as WebAppBase);

  FcsService fcsService = FcsService();

  var workflow = sci.Workflow();
  // late sci.PatchRecord rec;
  Future<WebappTable> fetchMarkers(String workflowId) async {
    workflow = await workflowService.fetchWorkflow(workflowId);
    return await fcsService.fetchMarkers(
        workflow, settingsService.getStepId("immuno", "readFcs"));
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
}
