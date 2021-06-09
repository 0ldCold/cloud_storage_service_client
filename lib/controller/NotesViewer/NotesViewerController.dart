import 'dart:io';

import 'package:ext_storage/ext_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:cloud_storage_service_client/main.dart' as main;
import 'package:cloud_storage_service_client/controller/json.dart';
import 'package:cloud_storage_service_client/controller/httpLib.dart' as httpLib;

class NotesViewerController {
  final _formatterDate = new DateFormat('yyyyMMdd');
  // final _formatterTime = new DateFormat('HHmmss');
  // final _formatterTime2 = new DateFormat('HH:mm:ss');

  //String time = _formatterTime.format(dateTime);
  //String date = _formatterDate.format(dateTime);

  Future<void> updateCalendarNotes() async {
    var newEvents = await httpLib.initAllEntry(main.userId.toString());
    main.events = newEvents;
  }

  Future<void> updateDayNotesList() async {
    final String date = _formatterDate.format(main.selectedDate);
    main.messageText = await httpLib.sendRequestGet('view', main.userId.toString(), date);
    main.mode = 1;
  }

  Future<void> createNote(String date, String time, String text) async {
    await httpLib.sendRequestPost('create',
        id: main.userId.toString(), date: date, time: time, text: text);
  }

  Future<void> deleteNote(String time) async {
    await httpLib.sendRequestDelete(
        'delete', main.userId.toString(), _formatterDate.format(main.selectedDate), time);
  }

  Future<void> attachFileToNote() async {}

  Future<void> downloadFile(String id, String date, String time, String fileName) async {
    http.StreamedResponse _response;
    List<int> _bytes = [];

    _response = await http.Client()
        .send(http.Request('GET', Uri.parse(main.serverURI + "file/$id/$date/$time")));
    String path =
        await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DOWNLOADS);
    _response.stream.listen((value) {
      _bytes.addAll(value);
    }).onDone(() async {
      final file = File("$path/$fileName");
      await file.writeAsBytes(_bytes);
    });
  }

  Future<File> getFileFromMemory() async {
    return FilePicker.getFile().catchError((error) {
      main.logger.e(error);
    });
  }

  Future<String> getNoteText(String date, String time) async{
    String text = await httpLib.sendRequestGet('view', main.userId.toString(), date, time);
    return jsonGetNoteText(text);
  }

  Future<String> getNoteFileName(String date, String time) async{
    return httpLib.sendRequestGet('file', main.userId.toString(), date, time, 'name');
  }
}
