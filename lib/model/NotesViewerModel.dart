import 'dart:io';

// import 'package:cloud_storage_service_client/controller/NotesViewer/NotesViewerController.dart';
// import 'package:cloud_storage_service_client/view/NotesViewer.dart';
// import 'package:cloud_storage_service_client/main.dart';

class NotesViewerModel{
  int mode = 0;
  int userId = 1;
  DateTime selectedDate = DateTime.now();
  String messageText = '';
  List<String> timesList;
  String selectedTime;
  String noteText;
  bool fileCheck;
  String fileName;
  File pathUserFile;

}