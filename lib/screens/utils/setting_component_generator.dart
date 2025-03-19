import 'package:flutter/material.dart';
import 'package:immunophenotyping_webapp/webapp.dart';
import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/components/input_text_component.dart';
import 'package:webapp_components/components/multi_check_component.dart';
import 'package:webapp_components/components/select_dropdown.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_utils/model/workflow_setting.dart';

class SettingComponentGenerator {
  List<Component> getScreenSettings(String screenName, WebAppData modelLayer) {
    return modelLayer.workflowService.workflowSettings.map((setting) {
      // print("${setting.name} -- ${setting.type}");
      switch (setting.type) {
        case "int":
        case "double":
        case "string":
          return createTextNumericComponent(setting, screenName);
        case "boolean":
          break;
        case "ListSingle":
          return createSingleListComponent(setting, screenName);
        case "ListMultiple":
          return createMultipleListComponent(setting, screenName);
        default:
          return createTextNumericComponent(setting, screenName);
      }
    }).whereType<Component>().toList();
  }

  String createComponentKey(WorkflowSetting setting) {
    return "${setting.stepName}_${setting.name}";
  }

  Component createTextNumericComponent(
      WorkflowSetting setting, String groupId) {
    var comp =
        InputTextComponent(createComponentKey(setting), groupId, setting.name);
    comp.setComponentValue(setting.value);
    comp.description = setting.description;
    comp.addMeta("setting.name", setting.name);
    comp.addMeta("screen.name", groupId);
    comp.addMeta("step.name", setting.stepName);
    comp.addMeta("step.id", setting.stepId);

    return comp;
  }

  Component createMultipleListComponent(WorkflowSetting setting, String groupId) {
    var comp = MultiCheckComponent(
        createComponentKey(setting), groupId, setting.name,
        columns: 5);
    comp.setOptions(setting.options);
    comp.setComponentValue(setting.value.split(","));
    comp.description = setting.description;
    comp.addMeta("setting.name", setting.name);
    comp.addMeta("screen.name", groupId);
    comp.addMeta("step.name", setting.stepName);
    comp.addMeta("step.id", setting.stepId);
    return comp;
  }

  Component createSingleListComponent(
      WorkflowSetting setting, String groupId) {
    var comp = SelectDropDownComponent(
        createComponentKey(setting), groupId, setting.name);
    comp.setComponentValue( setting.value);
    comp.setOptions(setting.options);
    comp.description = setting.description;
    comp.addMeta("setting.name", setting.name);
    comp.addMeta("screen.name", groupId);
    comp.addMeta("step.name", setting.stepName);
    comp.addMeta("step.id", setting.stepId);
    return comp;
  }
}
