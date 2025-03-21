import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/definitions/list_action.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class ActionBarComponent
    with ComponentBase, ChangeNotifier
    implements Component {
  final List<ListAction> actions;

  ActionBarComponent(id, groupId, this.actions) {
    super.id = id;
    super.groupId = groupId;
  }

  Widget createButtonLabel(String label) {
    return Text(
      label,
      style: Styles()["textH1"],
    );
  }

  Widget buildActionWidget(ListAction action) {
    var rszIcon = Icon(action.actionIcon.icon, size: 32);
    var actionIcon = IconButton(
      onPressed: () async {
        if (action.enabledCallback == null ||
            action.enabledCallback!([]) == true) {
          action.callback([]);
        }
      },
      icon: rszIcon,
      tooltip: action.description,
    );
    List<Widget> row = [];

    row.add(actionIcon);
    if (action.buttonLabel != null) {
      row.add(createButtonLabel(action.buttonLabel!));
    }

    return wrapActionWidget(Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: row,
    ));
  }

  Widget wrapActionWidget(Widget wdg) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: wdg,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: actions.map((action) => buildActionWidget(action)).toList(),
    );
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simpleNoLabel;
  }

  @override
  getComponentValue() {
    return "";
  }

  @override
  bool isFulfilled() {
    return true;
  }

  @override
  void setComponentValue(value) {}
}
