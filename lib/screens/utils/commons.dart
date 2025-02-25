
import 'dart:typed_data';

import 'package:flutter/material.dart';



Widget createImageWidget(List<Uint8List> bytesList, ValueNotifier<int> notifier) {
  double scale = notifier.value/10;
  if( scale == 0){
    scale = 1.4;
  }
  List<Widget> wdgList = [];

  for (var bytes in bytesList) {
    Widget imgWdg = Image.memory(
      bytes,
      fit: BoxFit.none,
      scale: scale,
    );
    wdgList.add(imgWdg);
  }

  var colWdg = Column(
    children: [
      Row(
        children: [
          IconButton(
              onPressed: () {
                scale -= 0.1;
                if (scale <= 0.1) {
                  scale = 0.1;
                }
                notifier.value = (scale * 10).ceil();
              },
              icon: const Icon(Icons.zoom_in)),
          IconButton(
              onPressed: () {
                scale += 0.1;
                notifier.value = (scale * 10).ceil();

              },
              icon: const Icon(Icons.zoom_out)),
          IconButton(
              onPressed: () {
                scale = 1.4;
                notifier.value = (scale * 10).ceil();
              },
              icon: const Icon(Icons.zoom_in_map_sharp))
        ],
      ),
      ...wdgList
    ],
  );

  return colWdg;
}
