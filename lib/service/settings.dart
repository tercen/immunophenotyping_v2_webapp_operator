import 'package:flutter/services.dart';
import 'package:json_string/json_string.dart';


class SettingsEntry{
  static const String typeInt = "int";
  static const String typeDouble = "double";
  static const String typeText = "string";
  static const String typeBool = "boolean";
  static const String typeListSingle = "ListSingle";
  static const String typeListMultiple = "ListMultiple";
  static const String typeRichText = "RichText";


  final String settingName;
  final String stepName;
  final String stepId;
  final String hint;
  final String type;
  final String mode;
  final String section;
  
  late String textValue;
  late List<String> options = [];


  SettingsEntry(this.stepName, this.stepId, this.settingName, this.section,  this.hint, this.type, this.textValue, this.mode) {
    textValue = textValue.trim();

  }

  void clearOptions(){

    options.clear();
  }

  void addOptions(List<String> opt){

    for( var o in opt ){
      options.add(o);
    }
  }

  String info(){
    return "Name: $settingName\nType: $type\nValue: $textValue\nSection: $section";
  }
}


class SettingsDataService{
  final Map<String, List<SettingsEntry>> _settingsMap = {};

  List<SettingsEntry> get( String key ){
    if( !_settingsMap.containsKey(key)){
      throw Exception("Key $key not found in settings map");
    }
    return _settingsMap[key]!;
  }

  Future<void> loadSettings() async {

    var settings = await Future.wait([
      _loadSettingsFile("assets/umap_settings.json"),
      _loadSettingsFile("assets/umap_apply_settings.json"),
      _loadSettingsFile("assets/ml_apply_settings.json"),
      _loadSettingsFile("assets/ml_settings.json")
    ]);

    _settingsMap["assets/umap_settings.json"] = settings[0];
    _settingsMap["assets/umap_apply_settings.json"] = settings[1];
    _settingsMap["assets/ml_apply_settings.json"] = settings[2];
    _settingsMap["assets/ml_settings.json"] = settings[3];
    
  }

  Future<List<SettingsEntry>> _loadSettingsFile(String path) async {

    List<SettingsEntry> settingsList = [];

    String settingsStr = await rootBundle.loadString(path);
    try {
      final jsonString = JsonString(settingsStr);
      final settingsMap = jsonString.decodedValueAsMap;

      
      for(int i = 0; i < settingsMap["settings"].length; i++){
        Map<String, dynamic> jsonEntry = settingsMap["settings"][i];  
        
        SettingsEntry setting = SettingsEntry(
          jsonEntry["step_name"],
          jsonEntry["step_id"],
          jsonEntry["setting_name"],
          jsonEntry["section"],
          jsonEntry["hint"],
          jsonEntry["type"], 
          jsonEntry["value"],
          jsonEntry["mode"]);

        if( jsonEntry.keys.contains("options") ){
          List<String> options = jsonEntry["options"].toString().replaceAll("[", "").replaceAll("]", "").split(",").map((e) => e.trim()).toList();

          setting.addOptions(options);
        }

        settingsList.add(setting);
      }

    } on Exception catch (e) {
        print('Invalid JSON: $e');
    }
    return settingsList;
  }
}