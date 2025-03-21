import 'package:flutter/material.dart';
import 'package:immunophenotyping_webapp/screens/components/multi.dart';
import 'package:immunophenotyping_webapp/screens/components/temp3.dart';
import 'package:immunophenotyping_webapp/screens/modal_screens/modal_screen_base.dart';
import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_components/definitions/functions.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_model/id_element.dart';

import 'package:webapp_components/components/multi_check_component.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/list_utils.dart';

class MultiCheckComponentFetch extends MultiCheckComponent2 with ComponentCache {
  DataFetchCallback optionsFetchCallback;
  final String emptyMessage;

  String displayColumn = "";
  bool isInit = false;
  WebappTable optionTable = WebappTable();

  MultiCheckComponentFetch(
      super.id, super.groupId, super.componentLabel, this.optionsFetchCallback,
      {super.columns = 5,
      this.emptyMessage = "No data available",
      super.hasSelectAll = false,
      super.selectAll = false,
      super.columnWidth,
      super.saveState,
      this.displayColumn = ""});

  Future<WebappTable> fetchCachedOptions() async {
    var key = getKey();
    if (hasCachedValue(key)) {
      return getCachedValue(key);
    } else {
      var val = await optionsFetchCallback();
      addToCache(key, val);
      return val;
    }
  }

  void loadSelection() {
    var key = "${getKey()}_selection";
    if (hasCachedValue(key)) {
      selected.addAll(getCachedValue(key));
    }
  }

  @override
  void reset() {
    print("Reseting");
    super.reset();
    isInit = false;
    options.clear();
    init().then((_) => postInit());
  }

  @override
  Future<void> init( ) async {
    print("Init");
    await super.init();

    if( isActive() ){
      await loadOptions();
      loadSelection();
      isInit = true;
    }
    

    notifyListeners();
  }

  Future<void> loadOptions() async {
    if (!isInit) {
      optionTable = await fetchCachedOptions();
      options.clear();
      if (optionTable.nRows > 0) {
        if (displayColumn == "") {
          displayColumn = optionTable.colNames[0];
        }
        options.addAll(optionTable.columns[displayColumn]!);
        if (selectAll) {
          for (var opt in options) {
            select(opt);
          }
        }
      }
    }
  }




  Widget buildCountWidget( BuildContext context ){
    List<Widget> rowWidgets = [];

    rowWidgets.add(
      Text("${selected.length}/${options.length} selected", style: Styles()["text"],)
    );

    rowWidgets.add(
      IconButton(onPressed: (){
        var modalCheck = MultiCheckComponent3( "${id}_modal", getGroupId(), "", columns: 5, columnWidth: columnWidth, selectAll: false, hasSelectAll: true, saveState: false);
        modalCheck.setOptions(options);
        for( var opt in selected ){
          modalCheck.select(opt);  
        }
        // modalCheck.selected.addAll(selected);
        modalCheck.addListener((){
          
        });


        var selectionScreen = ModalScreenBase("Marker Selection", [modalCheck]);
        selectionScreen.addListener((){
          selected.clear(); 
          selected.addAll(modalCheck.selected);

          selectAll = false;

          notifyListeners();
        });
        selectionScreen.build(context);
      }, icon: const Icon(Icons.library_add_check_outlined))
    );

    return Row(children: rowWidgets,);
  }

  @override
  Widget buildContent(BuildContext context) {
    if (state == ComponentState.loading) {
      return TercenWaitIndicator().waitingMessage(suffixMsg: "Loading data");
    } else {
      return buildCountWidget(context); //super.buildCheckTable();
    }
  }
  // @override
  // Widget buildContent(BuildContext context) {
  //   return FutureBuilder(
  //       future: fetchCachedOptions(),
  //       builder: (context, snapshot) {
  //         if (snapshot.hasData && snapshot.data != null) {
  //           if (snapshot.data!.colNames.isEmpty) {
  //             return Text(emptyMessage);
  //           } else {
  //             options.clear();
  //             if (displayColumn == "") {
  //               displayColumn = snapshot.data!.colNames[0];
  //             }
  //             options.addAll(snapshot.data!.columns[displayColumn]!);
  //             if (selectAll) {
  //               for (var opt in options) {
  //                 select(opt);
  //               }
  //               selectAll = false;
  //             }

  //             return super.buildCheckTable();
  //           }
  //         } else if (snapshot.hasError) {
  //           throw Exception(snapshot.error);
  //         } else {
  //           return TercenWaitIndicator()
  //               .waitingMessage(suffixMsg: "Loading data");
  //         }
  //       });
  // }

  WebappTable getComponentValueAsTable(  ){
    List<int> indices = [];
    for( var s in selected ){
      indices.addAll(ListUtils.indexWhereAll(optionTable[displayColumn], s));
    }
    indices.sort();
    return optionTable.select(indices);
  }

  @override
  void setOptions(List<String> optList) {
    throw ServiceError(
        500, "Options must be retrieved using the fetch callback function");
  }
}
