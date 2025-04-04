import 'package:immunophenotyping_webapp/webapp_data.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/components/input_text_component.dart';
import 'package:webapp_components/components/multi_check_component.dart';
import 'package:webapp_components/components/select_dropdown.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_utils/model/workflow_setting.dart';

class SettingComponentGenerator {
  List<Component> getScreenSettings(String screenName, WebAppData modelLayer, {bool applyFilter = true}) {
    var comps = modelLayer.workflowService.workflowSettings
        .map((setting) {
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
        })
        .whereType<Component>()
        .toList();
    if( applyFilter){
      comps = filterScreenComponents(comps, screenName, modelLayer);
    }
    return comps;
  }

  String createComponentKey(WorkflowSetting setting) {
    return "${setting.stepName}_${setting.name}";
  }

  List<Component> filterScreenComponents(
      List<Component> components, String screenName, WebAppData modelLayer) {
    if (modelLayer.settingsService.hasFilter(screenName)) {
      var filters = modelLayer.settingsService.settingsFilters.filters
          .where((filter) => filter.screen == screenName)
          .toList();

      var filteredComponents = components.where((comp) {
        if (comp is ComponentBase) {
          var settingName =
              (comp as ComponentBase).getMeta("setting.name")!.value;
          var stepName = (comp as ComponentBase).getMeta("step.name")!.value;
          var stepId = (comp as ComponentBase).getMeta("step.id")!.value;

          var include = true;
          for (var filter in filters) {
            if (filter.type == "include") {
              if (filter.settingNames != null) {
                include = include && filter.settingNames!.contains(settingName);
              }
              if (filter.stepId != null) {
                include = include && filter.stepId!.contains(stepId);
              }
              if (filter.stepName != null) {
                include = include && filter.stepName!.contains(stepName);
              }
            }
            if (filter.type == "exclude") {
              if (filter.settingNames != null) {
                include =
                    include && !filter.settingNames!.contains(settingName);
              }
              if (filter.stepId != null) {
                include = include && !filter.stepId!.contains(stepId);
              }
              if (filter.stepName != null) {
                include = include && !filter.stepName!.contains(stepName);
              }
            }
          }
          return include;
        } else {
          return false;
        }
      }).toList();
      // print("Including following components");
      // for( var comp in filteredComponents ){
      //   print(comp.getId());
      // }
      // print(";;;;;;;;;;;;;");
      // for( var comp in components ){
      //   print(comp.getId());
      // }
      return filteredComponents;
    }

    
    return components;
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

  Component createMultipleListComponent(
      WorkflowSetting setting, String groupId) {
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

  Component createSingleListComponent(WorkflowSetting setting, String groupId) {
    var comp = SelectDropDownComponent(
        createComponentKey(setting), groupId, setting.name);
    comp.setComponentValue(setting.value);
    comp.setOptions(setting.options);
    comp.description = setting.description;
    comp.addMeta("setting.name", setting.name);
    comp.addMeta("screen.name", groupId);
    comp.addMeta("step.name", setting.stepName);
    comp.addMeta("step.id", setting.stepId);
    return comp;
  }
}
