import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sci_base/subscription.dart';
import 'package:sci_base/value.dart';

// ignore: must_be_immutable
class ValueWidget<T> extends StatefulWidget {
  Value<T> model;
  ValueWidget({super.key, required this.model});

  @override
  State<StatefulWidget> createState() {
    return _ValueState<T>();
  }
}

class _ValueState<T> extends State<ValueWidget<T>> with SubscriptionHelper {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print("$this -- initState");
    }
    addSub(widget.model.onChange.listen((event) {
      setState(() {
        // model changed
        if (kDebugMode) {
          print("$this -- setState");
        }
      });
    }));
  }

  @override
  void dispose() {
    super.dispose();
    releaseSubscriptionsSync();
    if (kDebugMode) {
      print("$this -- dispose");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("$this -- build");
    }
    return Row(
      children: [
        ElevatedButton(
          onPressed: () => widget.model.value = '${Uri.base}+' as T,
          child: const Text('Press'),
        ),
        Text(widget.model.value.toString())
      ],
    );
  }
}