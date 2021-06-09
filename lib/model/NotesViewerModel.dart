import 'dart:io';
import 'package:cloud_storage_service_client/model/entities/event.dart';

// import 'package:cloud_storage_service_client/controller/NotesViewer/NotesViewerController.dart';
// import 'package:cloud_storage_service_client/view/NotesViewer.dart';
// import 'package:cloud_storage_service_client/main.dart';


int userId = 1;

List<Event> events;
int mode = 0;

DateTime selectedDate = DateTime.now();
String selectedTime;

String messageText = '';
List<String> timesList;
String noteText;

String fileName;
File pathUserFile;