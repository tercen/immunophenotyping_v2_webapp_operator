import 'package:immunophenotyping_webapp/service/fcs_service.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:immunophenotyping_webapp/webapp.dart';
import 'package:webapp_ui_commons/webapp_base.dart';
import 'package:sci_tercen_model/sci_model.dart' as sci;


class WebAppData extends WebAppDataBase {
  WebApp webapp;
  WebAppData(this.webapp) : super(webapp as WebAppBase);

  FcsService fcsService = FcsService();

  //Current immunophenotyping workflow 
  var workflow = sci.Workflow();


  Future<IdElementTable> fetchMarkers() async{
    return await fcsService.fetchMarkers(workflow, stepsMapper.getStepId("immuno", "readFcs"));
  }
}
