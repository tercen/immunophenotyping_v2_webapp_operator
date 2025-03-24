import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:webapp_components/components/image_list_component.dart';
import 'package:webapp_model/webapp_table.dart';

typedef ByteFetchCallback = Future<WebappTable> Function();

class ImmunoImageListComponent extends ImageListComponent {
  ByteFetchCallback pdfReportFetchCallback;
  ByteFetchCallback pptReportFetchCallback;
  ImmunoImageListComponent(
      super.id,
      super.groupId,
      super.componentLabel,
      super.dataFetchFunc,
      this.pdfReportFetchCallback,
      this.pptReportFetchCallback);

  Widget downloadPdfActionWidget() {
    return IconButton(
        onPressed: () async {
          isBusy = true;
          notifyListeners();

          await pdfReportFetchCallback();
          isBusy = false;
          notifyListeners();
        },
        icon: const Icon(Icons.picture_as_pdf));
  }

  Widget downloadPptActionWidget() {
    return IconButton(
        onPressed: () async {
          isBusy = true;
          notifyListeners();
          await pptReportFetchCallback();

          isBusy = false;
          notifyListeners();
        },
        icon: Image.asset('assets/img/ppt_icon.jpeg'));
  }

  @override
  Widget createToolbar() {
    var sep = const SizedBox(
      width: 15,
    );
    return Row(
      children: [
        wrapActionWidget(expandAllActionWidget()),
        sep,
        wrapActionWidget(collapseAllActionWidget()),
        sep,
        wrapActionWidget(downloadPdfActionWidget()),
        sep,
        wrapActionWidget(downloadPptActionWidget()),
      ],
    );
  }

  @override
  Widget createWidget(BuildContext context, WebappTable table) {
    widgetExportContent.clear();
    expansionControllers.clear();

    String titleColName = table.colNames
        .firstWhere((e) => e.contains("filename"), orElse: () => "");

    String stepColName =
        table.colNames.firstWhere((e) => e.contains("step"), orElse: () => "");
    String dataColName =
        table.colNames.firstWhere((e) => e.contains("data"), orElse: () => "");

    List<Widget> wdgList = [];

    for (var ri = 0; ri < table.nRows; ri++) {
      var title = table.columns[titleColName]![ri];
      title = "$title [${table.columns[stepColName]![ri]}]";

      if (shouldIncludeEntry(title)) {
        var imgData =
            Uint8List.fromList(table.columns[dataColName]![ri].codeUnits);
        Widget wdg = createImageListEntry(title, imgData);

        widgetExportContent.add(ExportPageContent(title, imgData));

        if (collapsible == true) {
          wdg = collapsibleWrap(ri, title, wdg);
        }
        wdgList.add(wdg);
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [createToolbar(), ...wdgList],
    );
  }
}
