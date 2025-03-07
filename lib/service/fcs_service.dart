import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_utils/functions/workflow_utils.dart';
import 'package:webapp_utils/mixin/data_cache.dart';

class FcsService with DataCache {

  Future<IdElementTable> fetchMarkers(sci.Workflow workflow, String readFcsStepId) async{
    var key = "${workflow.id}_${workflow.rev}";
    if(hasCachedValue(key )){
      return getCachedValue(key);
    }
    var resTbl = IdElementTable();
    var factory = tercen.ServiceFactory();
    List<IdElement> options = [];
    for( var stp in workflow.steps ){
      if( stp.id == readFcsStepId){
        var srIds = WorkflowUtils.getSimpleRelations((stp as sci.DataStep).computedRelation);
        var schList = await factory.tableSchemaService.list(srIds.map((e) => e.id).toList());
        for( var sch in schList ){

          if( sch.name == "Variables"){
            var col = sch.columns.firstWhere((e) => e.name.contains("name"));
            var markerTbl = await factory.tableSchemaService.select(sch.id ,[col.name], 0, sch.nRows);
            
            options.addAll( (markerTbl.columns[0].values as List<String>).map((e) => IdElement(e, e)) );
          }
        }
      }
    }
    resTbl.addColumn("options", data: options);

    addToCache(key, resTbl);
    return resTbl;
  }
}