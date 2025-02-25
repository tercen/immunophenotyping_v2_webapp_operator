import 'dart:async';


import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:webapp_template/service/project.dart';
import 'package:webapp_template/service/user.dart';
import 'package:webapp_template/webapp.dart';
import 'package:webapp_ui_commons/webapp_base.dart';



class WebAppData extends WebAppDataBase {
  WebApp webapp;
  WebAppData(this.webapp) : super(webapp as WebAppBase);

  final UserDataService userService = UserDataService();
  final ProjectDataService projectService = ProjectDataService();

  //==================================================
  // Project File State Check
  //==================================================
  bool hasProject() {
    return webapp.projectId != "";
  }


  //-------------------------------------------------------------
  //DATA FETCH Functions
  //-------------------------------------------------------------

  Future<List<String>> fetchUserList() async {
    return await userService.fetchUserList(app.username);
  }

  Future<void> createOrLoadProject(IdElement projectEl, String username) async {
    var project = await projectService.doCreateProject(projectEl, username);

    app.projectId = project.id;
    app.projectName = project.name;
    app.username = username;
    app.teamname = project.acl.owner;
    await init(app.projectId, app.projectName, username);
  }


}
