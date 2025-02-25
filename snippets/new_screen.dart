import 'package:flutter/material.dart';

import 'package:webapp_components/screens/screen_base.dart';
import 'package:webapp_model/webapp_data_base.dart';
import 'package:webapp_template/webapp_data.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';



class Screen extends StatefulWidget {
  final WebAppData modelLayer;
  const Screen(this.modelLayer, {super.key});

  @override
  State<Screen> createState() => _ScreenState();
}

class _ScreenState extends State<Screen>
    with ScreenBase, ProgressDialog {
  @override
  String getScreenId() {
    return "Screen";
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

  @override
  void initState() {
    super.initState();


    initScreen(widget.modelLayer as WebAppDataBase);
  }

  @override
  Widget build(BuildContext context) {
    return buildComponents(context);
  }
}
