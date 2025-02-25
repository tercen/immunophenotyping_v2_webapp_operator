// // ignore_for_file: unused_import

// import 'dart:async';
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:kumo_analysis_app/util/util.dart';
// import 'package:kumo_api/kumo_api.dart';

// import 'package:sci_http_client/http_auth_client.dart' as auth_http;
// import 'package:sci_http_client/http_browser_client.dart' as io_http;
// import 'package:sci_tercen_client/sci_client.dart' as sci;
// import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
// import 'package:tson/tson.dart' as tson;

// class FilesResultWidget extends StatefulWidget {
//   List<ExperimentIdentifier> experimentIdentifiers;

//   FilesResultWidget({super.key, required this.experimentIdentifiers});

//   @override
//   State<StatefulWidget> createState() => _FilesResultWidgetState();
// }

// class TFile {
//   ExperimentIdentifier experimentIdentifier;
//   File file;

//   TFile(this.experimentIdentifier, this.file);
// }

// class _FilesResultWidgetState extends State<FilesResultWidget> {
//   final List<TFile> _files = [];
//   Future<List<TFile>>? _searchFiles;
//   bool _isDone = false;
//   String _doneMessage = 'Done';

//   @override
//   void initState() {
//     // _searchFiles = _search();
//     super.initState();
//   }

//   Future<List<TFile>> _search(String kumoAuth) async {
//     var files = <TFile>[];
//     for (var experiment in widget.experimentIdentifiers) {
//       var response = await kumoApi
//           .getDefaultApi()
//           .getExperimentByUuidExperimentsUuidPost(
//               uuid: experiment.uuid, authorization: kumoAuth);

//       if (response.statusCode != 200) {
//         print('$this -- response.statusCode ${response.statusCode}');
//         print(response);
//       } else {
//         files.addAll(
//             response.data!.files.map((file) => TFile(experiment, file)));
//       }
//     }

//     setState(() {
//       _files
//         ..clear()
//         ..addAll(files);
//     });

//     _onOk();

//     return _files;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//         future: _searchFiles,
//         builder: (context, data) {
//           if (data.hasData) {
//             return _basicBuild(context);
//           } else {
//             return const Center(child: CircularProgressIndicator());
//           }
//         });
//   }

//   Widget _basicBuild(BuildContext context) {
//     if (_isDone) {
//       return Scaffold(body: Center(child: Text(_doneMessage)));
//     } else {
//       return Scaffold(
//           appBar: AppBar(
//             backgroundColor: Colors.white,
//             centerTitle: true,
//             title: const Text('Select'),
//           ),
//           floatingActionButtonLocation:
//               FloatingActionButtonLocation.endContained,
//           // floatingActionButton: ElevatedButton(
//           //   onPressed: _onOk,
//           //   child: const Text('Ok'),
//           // ),
//           body: Center(
//               child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                   'Number of experiments : ${_files.map((e) => e.experimentIdentifier.uuid).toSet().length}'),
//               Text('Number of files : ${_files.length}')
//             ],
//           )));
//     }
//   }

//   Future _onOk() async {
//     setState(() {
//       _doneMessage = 'Loading ...';
//       _isDone = true;
//     });

//     try {
//       var token = Uri.base.queryParameters["token"] ?? '';
//       var taskId = Uri.base.queryParameters["taskId"] ?? '';

//       if (token.isEmpty) {
//         throw "A token is required";
//       }

//       if (taskId.isEmpty) {
//         throw "A taskId is required";
//       }

//       var authClient =
//           auth_http.HttpAuthClient(token, io_http.HttpBrowserClient());

//       var factory = sci.ServiceFactory();

//       if (isDev) {
//         await factory.initializeWith(
//             Uri.parse('http://127.0.0.1:5400'), authClient);
//       } else {
//         var uriBase = Uri.base;
//         await factory.initializeWith(
//             Uri(scheme: uriBase.scheme, host: uriBase.host, port: uriBase.port),
//             authClient);
//       }

//       tercen.ServiceFactory.CURRENT = factory;

//       var task = await factory.taskService.get(taskId);

//       if (task is sci.RunComputationTask) {
//         await _runTask(task);
//       } else {
//         throw "bad task -- ${task.kind}";
//       }

//       setState(() {
//         _doneMessage = 'Done';
//       });
//     } catch (e) {
//       setState(() {
//         _doneMessage = e.toString();
//       });
//     }
//   }

//   Future _runTask(sci.RunComputationTask task) async {
//     try {
//       await _basicRunTask(task);
//     } catch (e) {
//       task.state = sci.FailedState()
//         ..error = "task.run.failed"
//         ..reason = "$e";
//       await tercen.ServiceFactory().taskService.update(task);
//       rethrow;
//     }
//   }

//   Future<sci.ComputedTableSchema> table2Schema(
//       sci.Table table, sci.RunComputationTask task) async {
//     var factory = tercen.ServiceFactory();
//     var bytes = tson.encode(table.toJson());

//     var resultFile = sci.FileDocument()
//       ..name = table.properties.name
//       ..isHidden = true
//       ..isTemp = true
//       ..projectId = task.projectId
//       ..acl.owner = task.owner;

//     resultFile = await factory.fileService
//         .upload(resultFile, Stream.fromIterable([bytes]));

//     var csvTask = sci.CSVTask()
//       ..state = sci.InitState()
//       ..owner = task.owner
//       ..projectId = task.projectId
//       ..fileDocumentId = resultFile.id;

//     csvTask = await factory.taskService.create(csvTask) as sci.CSVTask;

//     await factory.taskService.runTask(csvTask.id);
//     await factory.taskService.waitDone(csvTask.id);

//     csvTask = await factory.taskService.get(csvTask.id) as sci.CSVTask;

//     var schema = await factory.tableSchemaService.get(csvTask.schemaId);

//     var computedSchema = sci.ComputedTableSchema()
//       ..nRows = schema.nRows
//       ..projectId = task.projectId
//       ..acl.owner = task.owner
//       ..name = table.properties.name
//       ..query = task.query.copy()
//       ..dataDirectory = schema.dataDirectory;

//     for (var column in schema.columns) {
//       computedSchema.columns.add(column.copy());
//     }

//     computedSchema = await factory.tableSchemaService.create(computedSchema)
//         as sci.ComputedTableSchema;

//     await factory.tableSchemaService.delete(schema.id, schema.rev);

//     return computedSchema;
//   }

//   Future _basicRunTask(sci.RunComputationTask task) async {
//     var factory = tercen.ServiceFactory();

//     task.state = sci.RunningState();
//     await factory.taskService.update(task);

//     var summary = '''
//     ### Summary
    
//     Number of experiments: ${widget.experimentIdentifiers.length}
//     Number of files: ${_files.length}
    
//     ${widget.experimentIdentifiers.map((e) => e.name).join(", ")}
    
//     ''';

//     var summaryTable = sci.Table()..properties.name = "Summary";
//     summaryTable.columns
//       ..add(sci.Column()
//         ..type = 'string'
//         ..name = '.content'
//         ..values =
//             tson.CStringList.fromList([base64.encode(utf8.encode(summary))]))
//       ..add(sci.Column()
//         ..type = 'string'
//         ..name = 'mimetype'
//         ..values = tson.CStringList.fromList(["text/markdown"]))
//       ..add(sci.Column()
//         ..type = 'string'
//         ..name = 'filename'
//         ..values = tson.CStringList.fromList(['Summary.md']));

//     var summarySchema = await table2Schema(summaryTable, task);

//     var table = sci.Table()..properties.name = "Kumo files";

//     table.columns
//       ..add(sci.Column()
//         ..type = 'string'
//         ..name = 'path'
//         ..values = tson.CStringList.fromList(_files
//             .map((e) => '${e.experimentIdentifier.name}${e.file.path}')
//             .toList()))
//       ..add(sci.Column()
//         ..type = 'string'
//         ..name = 'md5'
//         ..values =
//             tson.CStringList.fromList(_files.map((e) => e.file.md5).toList()))
//       ..add(sci.Column()
//         ..type = 'string'
//         ..name = 'ref64'
//         ..values = tson.CStringList.fromList(_files
//             .map((e) => base64.encode(utf8.encode(e.file.href)))
//             .toList()));

//     var computedSchema = await table2Schema(table, task);

//     task.computedRelation = sci.CompositeRelation()
//       ..joinOperators.addAll([
//         sci.JoinOperator()
//           ..rightRelation = (sci.SimpleRelation()..id = computedSchema.id),
//         sci.JoinOperator()
//           ..rightRelation = (sci.SimpleRelation()..id = summarySchema.id)
//       ]);

//     task.state = sci.DoneState();
//     await factory.taskService.update(task);
//   }
// }