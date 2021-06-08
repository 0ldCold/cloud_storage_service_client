import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Calendar/event.dart';
import 'main.dart' as main;
import 'json.dart';

Future<String> sendRequestGet(String serverMethod, [String id, String date, String time, String mod]) async {
  String uri = main.serverURI + serverMethod;
  if (id != null) {
    uri = uri + '/' + id;
    if (date != null) {
      uri = uri + '/' + date;
      if (time != null) {
        uri = uri + '/' + time;
        if (mod != null){
          uri = uri + '/' + mod;
        }
      }
    }
  }

  String messageBody = '';
  final formatter = new DateFormat('dd.MM.yyyy HH:mm:ss');
  final dateNow = formatter.format(DateTime.now());

  var response = await http.get(uri);
  try {
    messageBody = response.body;
    print('GET      ' + dateNow.toString() + ' ' + uri + ' : ' + response.statusCode.toString());
  } catch (error) {
    main.logger.e(error);
  }
  return messageBody;
} //_sendRequestGet

Future<bool> sendRequestDelete(String serverMethod, String id, String date, String time) async {
  String uri = main.serverURI + serverMethod + '/'+id+'/'+date+'/'+time;
  final formatter = new DateFormat('dd.MM.yyyy HH:mm:ss');
  final dateNow = formatter.format(DateTime.now());

  var response = await http.delete(uri);
  try {
    print('DELETE   ' + dateNow.toString() + ' ' + uri + ' : ' + response.statusCode.toString());
    return true;
  } catch (error) {
    main.logger.e(error);
  }
  return false;
}


Future<String> sendRequestPost(String serverMethod,
    {String id, String date, String time, String text}) async {
  var body = text;

  String uri = main.serverURI + "$serverMethod/$id/$date/$time";
  String messageBody = 'error';

  final formatter = new DateFormat('dd.MM.yyyy HH:mm:ss');
  final dateNow = formatter.format(DateTime.now());

  var response = await http.post(
    uri,
    headers: {
      "Content-Type": "application/json.dart",
      "ContentEncoding": "UTF-8",
      "Accept": "application/json.dart",
    },
    body: body,
  );
  try {
    messageBody = response.body;
    print('POST     ' + dateNow.toString() + ' ' + uri + ' : ' + response.statusCode.toString());
  } catch (error) {
    main.logger.e(error);
  }
  return messageBody;
} //_sendRequestGet

Future<List<Event>> initAllEntry(String id) async {
  var eventList = List<Event>();
  String messageBody = await sendRequestGet('view', id);
  if (messageBody != "") {
    List<String> responseList = jsonToList(messageBody);
    responseList.forEach((element) {
      try {
        eventList.add(new Event(DateTime.parse(element), element));
      } catch (error) {
        main.logger.e(error);
      }
    });
  }
  return eventList;
}

Future<String> upload(String id, String date, String time, File imageFile) async {
  final formatter = new DateFormat('dd.MM.yyyy HH:mm:ss');
  final dateNow = formatter.format(DateTime.now());

  var stream = new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
  var length = await imageFile.length();
  var uri = Uri.parse(main.serverURI + "file/$id/$date/$time");
  var request = new http.MultipartRequest("POST", uri);
  var multipartFile =
      new http.MultipartFile('file', stream, length, filename: basename(imageFile.path));
  request.files.add(multipartFile);
  request.headers
      .addAll({"Content-Disposition": "attachment; filename=${basename(imageFile.path)}"});
  var response = await request.send();
  print('POST     ' +
      dateNow.toString() +
      ' ' +
      main.serverURI +
      "upload/$id/$date/$time" +
      ' : ' +
      response.statusCode.toString());
  return response.statusCode.toString();
}

void requestPermission() {
  PermissionHandler().requestPermissions([PermissionGroup.storage]);
}
