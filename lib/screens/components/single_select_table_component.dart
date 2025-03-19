import 'dart:math';

import 'package:flutter/material.dart';
import 'package:immunophenotyping_webapp/screens/components/tmp.dart';

import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/definitions/functions.dart';
import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';

import 'package:webapp_model/utils/key_utils.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/list_utils.dart';

class SingleSelectTableComponent extends MultiSelectTableComponent {
  SingleSelectTableComponent(super.id, super.groupId, super.componentLabel, super.dataFetchCallback, {super.excludeColumns, super.saveState = true, super.hideColumns, super.infoBoxBuilder});

  @override
  Widget wrapSelectable(Widget contentWdg, List<String> selectionValues) {
    return InkWell(
      onHover: (value) {
        if (!value) {
          currentRowKey = -1;
        } else {
          setSelectionRow(selectionValues);
        }
        uiUpdate.value = Random().nextInt(1<<32-1);
      
        // notifyListeners();
      },
      onTap: () {
        var clickedEl = KeyUtils.listToKey(selectionValues);
        if (isSelected(clickedEl)) {
          deselect(clickedEl);
        } else {
          if( selected.isNotEmpty ){
            selected.clear();
          }
          select(clickedEl);
        }

        notifyListeners();
      },
      child: contentWdg,
    );
  }

}
