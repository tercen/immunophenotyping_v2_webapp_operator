import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

import 'package:webapp_ui_commons/webapp_base.dart';

class WebApp extends WebAppBase  {
  String gtToken = "";

  // @override
  // Future<void> init({bool awaitInit = false}) async {
  //   if (!isInitialized) {
  //     await super.init();

  //     var factory = tercen.ServiceFactory();
  //     var userSecretService =
  //           factory.userSecretService as sci.UserSecretService;
  //     var googleCredentials = await userSecretService.getGoogleAccessToken();
  //       if (googleCredentials != null && googleCredentials == "") {
  //         throw Exception("Google credentials have not been found");
  //       }
  //     gtToken = googleCredentials!;

  //     // if( !awaitInit ){
  //     //   isInitialized = true;
  //     // }
  //   }
  // }
}
