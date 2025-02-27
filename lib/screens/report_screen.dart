import 'package:flutter/material.dart';
import 'package:immunophenotyping_webapp/screens/components/immuno_image_list_component.dart';
import 'package:immunophenotyping_webapp/screens/components/single_select_table_component.dart';

import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_components/components/leaf_selectable_list.dart';
import 'package:webapp_components/components/selectable_list.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';

import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_model/id_element.dart';

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

  //TODO Does it work with a single level?
  @override
  void initState() {
    super.initState();

    var workflowList = SingleSelectTableComponent("workflows", getScreenId(), "Workflow List", 
        fetchWorkflows);

    var imageList = ImmunoImageListComponent("workflows", getScreenId(), "Workflow List", 
        fetchWorkflowImages);
    imageList.addParent(workflowList);

    addComponent("default", workflowList);
    addComponent("default", imageList);
    
    initScreen(widget.modelLayer as WebAppDataBase);
  }

  Future<IdElementTable> fetchWorkflows(List<String> parentKeys, String groupId) async {
    var res = IdElementTable();

    return res;
  }

  Future<IdElementTable> fetchWorkflowImages(List<String> parentKeys, String groupId) async {
    var res = IdElementTable();

    return res;
  }

  @override
  Widget build(BuildContext context) {
    return buildComponents(context);
  }
}
