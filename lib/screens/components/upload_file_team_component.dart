import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:webapp_components/components/upload_multi_file_component.dart';
import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/services/file_data_service.dart';

class UploadFile {
  String filename;
  bool uploaded;

  UploadFile(this.filename, this.uploaded);
}

class UploadFileTeamComponent extends UploadFileComponent {
  final String Function() fileOwnerCallback;

  UploadFileTeamComponent(super.id, super.groupId, super.componentLabel, super.projectId, super.fileOwner, this.fileOwnerCallback, 
    {super.folderId = "", super.maxHeight = 400, super.maxWidth, super.allowedMime, super.showUploadButton = true});



  @override
  Future<void> doUpload(BuildContext context) async{
    if( showUploadButton ){
      openDialog(context);
      log("File upload in progress. Please wait.", dialogTitle: "File Uploading");
    }
    
    
    var fileService = FileDataService();

    for( int i = 0; i < htmlFileList.length; i++ ){
      
      DropzoneFileInterface file = htmlFileList[i];
      
      if( showUploadButton ){
        log("Uploading ${file.name}", dialogTitle: "File Uploading");
      }
      var bytes = await dvController.getFileData(file);
      var fileId = await fileService.uploadFile(file.name, projectId, fileOwnerCallback(), bytes, folderId: folderId);
      uploadedFiles.add(IdElement(fileId, file.name));
    }

    for( int i = 0; i < platformFileList.length; i++ ){
      PlatformFile file = platformFileList[i];
      var bytes = file.bytes!;
      if( showUploadButton ){
        log("Uploading ${file.name}", dialogTitle: "File Uploading");
      }

      var fileId = await fileService.uploadFile(file.name, projectId, fileOwnerCallback(), bytes, folderId: folderId);
      uploadedFiles.add(IdElement(fileId, file.name));
    }

    if( showUploadButton ){
      closeLog();
    }

  }

 
}