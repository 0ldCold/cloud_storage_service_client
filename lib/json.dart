import 'main.dart' as main;

import 'dart:convert';

List<String> jsonToList(String jsonString){
  List<dynamic> resDynList = jsonDecode(jsonString);
  List<String> resStrList = [];
  for(int i=0; i < resDynList.length; i++){
    resStrList.add(resDynList[i].toString());
  }
  return resStrList;
}



String jsonGetNoteText(String jsonString){
  Map<String, dynamic> resMap = jsonDecode(jsonString);
  return resMap['text'];
}

bool isJson(String jsonString){
  var res;
  try{
    res = jsonDecode(jsonString);
  }catch(e){
    return false;
  }
  return true;
}