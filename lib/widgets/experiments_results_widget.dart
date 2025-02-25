// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:kumo_analysis_app/widgets/selected_files_results.widget.dart';
// import 'package:kumo_analysis_app/util/util.dart';
// import 'package:kumo_api/kumo_api.dart';
// import 'package:kumo_api/kumo_api.dart' as kumo;
// import 'package:sci_tercen_client/sci_client.dart' as sci;
// import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

// void showFlashError(BuildContext context, String message) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text(message),
//     ),
//   );
// }

// class ExperimentsResultWidget extends StatefulWidget {
//   ExperimentsResultWidget({super.key});

//   @override
//   State<StatefulWidget> createState() {
//     return _ExperimentsResultWidgetState(
//         startDate: DateTime.now().subtract(const Duration(days: 6 * 30)),
//         endDate: DateTime.now());
//   }
// }

// class _ExperimentsResultWidgetState extends State<ExperimentsResultWidget> {
//   DateTime startDate;
//   DateTime endDate;

//   final _scrollController = ScrollController();

//   _ExperimentsResultWidgetState(
//       {required this.startDate, required this.endDate});

//   List<sci.ProjectDocument> _folders = [];

//   List<ExperimentIdentifier>? experimentIdentifiers;
//   int _page = 0;
//   bool _allPagesLoaded = false;
//   String? error;

//   @override
//   void initState() {
//     _search(_page);
//     _page++;
//     _scrollController.addListener(_loadMore);
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   int get nExperiments =>
//       experimentIdentifiers == null ? 0 : experimentIdentifiers!.length;

//   _doSearch() {
//     _search(_page);
//     _page++;
//   }

//   _loadMore() async {
//     if (_allPagesLoaded) return;
//     if (_scrollController.position.pixels ==
//         _scrollController.position.maxScrollExtent) {
//       var nn = nExperiments;
//       var page = _page;
//       _page++;
//       await _search(page);

//       if (nn == nExperiments) {
//         _allPagesLoaded = true;
//       }
//     }
//   }

//   final Set<ExperimentIdentifier> _selected = {};

//   void _toggleSelected(ExperimentIdentifier result) {
//     setState(() {
//       if (_selected.contains(result)) {
//         _selected.remove(result);
//       } else {
//         _selected.add(result);
//       }
//     });
//   }

//   Iterable<Widget> _listViewRows(BuildContext context) {
//     var experimentIdentifiers = this.experimentIdentifiers!;
//     var paddingTable =
//         const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0);
//     var loadings = <Widget>[];
//     if (_searching) {
//       loadings.add(Container(
//           margin: const EdgeInsets.only(top: 50.0),
//           child: const Center(child: CircularProgressIndicator())));
//     }
//     return [
//       Row(
//         children: [
//           Padding(
//               padding: paddingTable,
//               child: Checkbox(
//                 value: experimentIdentifiers.isNotEmpty &&
//                     _selected.containsAll(experimentIdentifiers),
//                 onChanged: (bool? value) {
//                   setState(() {
//                     if (value != null && value) {
//                       _selected.addAll(experimentIdentifiers);
//                     } else {
//                       _selected.clear();
//                     }
//                   });
//                 },
//               )),
//           Padding(
//               padding: paddingTable,
//               child: const Text('Downloaded',
//                   style: TextStyle(
//                       fontWeight: FontWeight.bold, color: Colors.white))),
//           Padding(
//               padding: paddingTable,
//               child: const Text('Experiments',
//                   style: TextStyle(fontWeight: FontWeight.bold)))
//         ],
//       ),
//       const Divider(
//         height: 10,
//         thickness: 2,
//         indent: 20,
//         endIndent: 0,
//         // color: Colors.blue,
//       ),
//       ...experimentIdentifiers.map((experiment) => Row(children: [
//             Padding(
//                 padding: paddingTable,
//                 child: Checkbox(
//                   value: _selected.contains(experiment),
//                   onChanged: (bool? value) {
//                     _toggleSelected(experiment);
//                   },
//                 )),
//             Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
//                 child:
//                     _folders.any((element) => element.name == experiment.name)
//                         ? const Icon(Icons.check)
//                         : const Icon(Icons.question_mark, color: Colors.white)),
//             Padding(padding: paddingTable, child: Text(experiment.name)),
//           ])),
//       ...loadings
//     ];
//   }

//   Widget _listView(BuildContext context) {
//     if (experimentIdentifiers == null) {
//       return ListView(
//         controller: _scrollController,
//         padding: const EdgeInsets.all(8),
//         children: [
//           _dateWidget(context),
//           const Divider(
//             height: 20,
//             thickness: 1,
//             indent: 0,
//             endIndent: 0,
//             // color: Colors.blue,
//           ),
//           Container(
//               margin: const EdgeInsets.only(top: 50.0),
//               child: const Center(child: CircularProgressIndicator()))
//         ],
//       );
//     } else {
//       return ListView(
//         controller: _scrollController,
//         padding: const EdgeInsets.all(8),
//         children: [
//           _dateWidget(context),
//           const Divider(
//             height: 20,
//             thickness: 1,
//             indent: 0,
//             endIndent: 0,
//             // color: Colors.blue,
//           ),
//           ..._listViewRows(context)
//         ],
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return basicBuild(context);
//   }

//   Widget basicBuild(BuildContext context) {
//     print("Building experiment results");
//     return  _listView(context);
//     // return Scaffold(
//     //     appBar: AppBar(
//     //       backgroundColor: Colors.white,
//     //       centerTitle: true,
//     //       title: const Text('Select'),
//     //     ),
//     //     floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
//     //     floatingActionButton: ElevatedButton(
//     //       onPressed: () => _select(context),
//     //       child: const Text('Ok'),
//     //     ),
//     //     body: Center(child: _listView(context)));
//   }

//   Widget _dateWidget(BuildContext context) {
//     var padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0);
//     TableColumnWidth;

//     var tbl = Table(
//       // border: TableBorder.all(),
//       columnWidths: const <int, TableColumnWidth>{
//         0: IntrinsicColumnWidth(),
//         1: IntrinsicColumnWidth(),
//         2: IntrinsicColumnWidth(),
//         // 3: IntrinsicColumnWidth(),
//         // 4: IntrinsicColumnWidth(),
//         // 5: IntrinsicColumnWidth(),
//       },
//       defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//       children: [
//         TableRow(children: [
//           Padding(
//               padding: padding,
//               child: const Text(
//                 "Start date",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               )),
//           Padding(
//               padding: padding,
//               child: Text("${startDate.toLocal()}".split(' ')[0])),
//           Padding(
//               padding: padding,
//               child: IconButton(
//                 onPressed: () => _selectStartDate(context),
//                 icon: const Icon(Icons.calendar_today),
//               )),
//         ]),
//         TableRow(children: [
//           Padding(
//               padding: padding,
//               child: const Text("End date",
//                   style: TextStyle(fontWeight: FontWeight.bold))),
//           Padding(
//               padding: padding,
//               child: Text("${endDate.toLocal()}".split(' ')[0])),
//           Padding(
//               padding: padding,
//               child: IconButton(
//                 onPressed: () => _selectEndDate(context),
//                 icon: const Icon(Icons.calendar_today),
//               )),
//         ]),
//       ],
//     );

//     // return SizedBox(
//     //   width: 300.0,
//     //   // height: 100.0,
//     //   child: tbl,
//     // );
//     return Align(alignment: Alignment.centerLeft,
//         child: SizedBox(
//           width: 300.0,
//           // height: 100.0,
//           child: tbl,
//         ));
//     return Center(
//         child: SizedBox(
//       width: 300.0,
//       // height: 100.0,
//       child: tbl,
//     ));
//   }

//   Future<void> _selectStartDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//         // barrierColor: Colors.transparent,
//         context: context,
//         initialDate: startDate,
//         firstDate: DateTime(2020, 1),
//         lastDate: DateTime.now());

//     if (picked != null && picked != startDate) {
//       setState(() {
//         startDate = picked;
//         experimentIdentifiers = null;
//         _page = 0;
//         _allPagesLoaded = false;
//         _doSearch();
//       });
//     }
//   }

//   Future<void> _selectEndDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//         context: context,
//         initialDate: endDate,
//         firstDate: DateTime(2020, 1),
//         lastDate: DateTime.now());
//     if (picked != null && picked != endDate) {
//       setState(() {
//         endDate = picked;
//         experimentIdentifiers = null;
//         _page = 0;
//         _allPagesLoaded = false;
//         _doSearch();
//       });
//     }
//   }

//   Future<void> _select(BuildContext context) async {
//     if (_selected.isEmpty) {
//       showFlashError(context, "Select an experiment.");
//     } else {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => FilesResultWidget(
//             experimentIdentifiers: _selected.toList(),
//           ),
//         ),
//       );
//     }
//   }

//   Future<List<sci.ProjectDocument>>? _foldersFuture;

//   bool _searching = false;

//   Future<List<ExperimentIdentifier>> _search([int? searchPage, String kumoAuthorization = ""]) async {
//     setState(() {
//       _searching = true;
//     });
//     try {
//       _foldersFuture ??= Future(() async {
//         var factory = tercen.ServiceFactory();

//         var taskId = Uri.base.queryParameters["taskId"] ?? '';

//         var task = (await factory.taskService.get(taskId) as sci.ProjectTask);

//         var projectId = task.projectId;
//         var folderId = ''; // empty=root of the project

//         var docs = await factory.projectDocumentService
//             .findProjectObjectsByFolderAndName(
//                 startKey: [projectId, folderId, ''],
//                 endKey: [projectId, folderId, 'zzzzzzzzzzz']);

//         var folders =
//             docs.where((element) => element.subKind == 'FolderDocument');

//         return folders.toList();
//       });

//       _folders = await _foldersFuture!;

//       List<ExperimentIdentifier> result = [];
//       bool flag = true;
//       var page = searchPage ?? 0;

//       // while (flag) {
//       var queryBuilder = kumo.QueryBuilder();

//       queryBuilder.createdAfter = startDate.toIso8601String();
//       queryBuilder.createdBefore = endDate.toIso8601String();
//       // queryBuilder.instrumentId = "VS03";
//       queryBuilder.page = page;

//       var experimentResponse = await kumoApi
//           .getDefaultApi()
//           .getExperimentsExperimentsPost(
//               authorization: kumoAuthorization, query: queryBuilder.build());

//       var tmpExperimentIdentifiers = experimentResponse.data!.results.toList();
//       flag = tmpExperimentIdentifiers.isNotEmpty;

//       result.addAll(tmpExperimentIdentifiers);

//       page++;
//       // }

//       setState(() {
//         if (experimentIdentifiers == null) {
//           experimentIdentifiers = result;
//         } else {
//           experimentIdentifiers!.addAll(result);
//         }

//         experimentIdentifiers!.sort((a, b) => b.name.compareTo(a.name));

//         _searching = false;
//       });

//       // setState(() {
//       //   experimentIdentifiers = List.generate(
//       //       20,
//       //       (index) => (ExperimentIdentifierBuilder()
//       //             ..uuid = 'uuid[$index]'
//       //             ..name = 'experiment-$index')
//       //           .build());
//       // });
//     } catch (e, st) {
//       if (kDebugMode) {
//         print(e);
//         print(st);
//       }
//       // setState(() {
//       //   error = e.toString();
//       // });
//     }

//     // print("$this -- _search -- experimentIdentifiers $experimentIdentifiers");

//     if (experimentIdentifiers == null) {
//       return [];
//     } else {
//       return experimentIdentifiers!;
//     }
//   }
// }