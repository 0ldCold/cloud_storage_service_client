import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cloud_storage_service_client/controller/httpLib.dart' as httpLib;
import 'package:cloud_storage_service_client/controller/json.dart';
import 'package:cloud_storage_service_client/main.dart' as main;
import 'package:cloud_storage_service_client/controller/NotesViewer/NotesViewerController.dart';

class NotesViewer extends StatefulWidget {
  final Function() notifyParent;

  NotesViewer({Key key, @required this.notifyParent}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NotesViewerState();
}

class _NotesViewerState extends State<NotesViewer> {
  List<String> timesList;
  String selectedTime;
  String noteText;
  bool fileCheck;
  String fileName;

  final alertDialogController = TextEditingController();
  File pathUserFile;
  NotesViewerController _notesViewerController = new NotesViewerController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    alertDialogController.dispose();
    super.dispose();
  }

  final _formatterDate = new DateFormat('yyyyMMdd');
  final _formatterTime = new DateFormat('HHmmss');
  // final _formatterTime2 = new DateFormat('HH:mm:ss');

  _NotesViewerState();

  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    switch (main.mode) {
      case 1:
        {
          timesList = null;
          //Список записей
          if (main.messageText.isEmpty) {
            break;
          }
          timesList = jsonToList(main.messageText);
          return _buildNoteList();
        }
      case 2:
        {
          //Запись без файла
          return _buildNoteWithoutFile(noteText);
        }
      case 3:
        {
          //Запись с файлом
          return _buildNoteWithFile(noteText);
        }
    }
    return _buildEmpty();
  }

  Widget _buildNoteList() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: timesList.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                if (timesList.length == 0) {
                  return Text('Записей нет!');
                } else {
                  return Center(
                      child: ElevatedButton(
                          onPressed: () {
                            _handlerNoteListButton(index);
                          },
                          child: Text(_reformatTime(timesList[index]))));
                }
              }),
        ),
        Center(
          child: _buildCreateButton(),
        ),
      ],
    );
  }

  Future<void> _handlerNoteListButton(int index) async {
    selectedTime = timesList[index];
    String date = _formatterDate.format(main.selectedDate);

    noteText = await _notesViewerController.getNoteText(date, selectedTime);

    fileName = await _notesViewerController.getNoteFileName(date, selectedTime);
    if (fileName != null && fileName.trim().isNotEmpty) {
      main.mode = 3;
    } else {
      main.mode = 2;
      fileName = null;
    }

    widget.notifyParent();
  }

  Widget _buildNoteWithoutFile(String noteText) {
    return Row(
      children: <Widget>[
        Center(
          child: _buildDeleteButton(),
        ),
        Expanded(
          flex: 3,
          child: Center(child: Text(noteText)),
        ),
      ],
    );
  }

  Widget _buildNoteWithFile(String noteText) {
    return Row(
      children: <Widget>[
        Center(
          child: _buildDeleteButton(),
        ),
        Expanded(
          flex: 3,
          child: Center(child: Text(noteText)),
        ),
        IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () {
              _handlerNoteWithFileDownloadFileButton(fileName);
            }),
      ],
    );
  }

  Widget _buildEmpty() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Center(child: Text("Записи не найдены")),
        ),
        Center(
          child: _buildCreateButton(),
        ),
      ],
    );
  }

  ElevatedButton _buildDeleteButton() {
    final ButtonStyle style = ElevatedButton.styleFrom(
      primary: Colors.deepOrangeAccent,
    );
    return ElevatedButton(
      onPressed: () {
        _handlerDeleteButton(selectedTime);
      },
      style: style,
      child: Text(
        "-",
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  ElevatedButton _buildCreateButton() {
    final ButtonStyle style = ElevatedButton.styleFrom(
      primary: Colors.lightGreenAccent,
    );
    return ElevatedButton(
      onPressed: () {
        _openAlertDialog();
      },
      style: style,
      child: const Text(
        "+",
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  Future<dynamic> _openAlertDialog() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              content: Container(
            height: 100,
            width: 250,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 200.0,
                      child: TextFormField(
                        controller: alertDialogController,
                      ),
                    ),
                    IconButton(
                        icon: Icon(Icons.attach_file),
                        onPressed: () async {
                          _handlerAlertDialogDownloadFileButton();
                        }),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    _handlerAlertDialogSubmitButton();
                  },
                  child: Text('Добавить'),
                ),
              ],
            ),
          ));
        });
  }

  Future<void> _handlerAlertDialogSubmitButton([DateTime dateTime]) async {
    if (alertDialogController.text != null &&
        alertDialogController.text.isNotEmpty &&
        alertDialogController.text.trim().isNotEmpty) {
      String text = alertDialogController.text;
      if (dateTime == null) {
        dateTime = DateTime.now();
      }
      String time = _formatterTime.format(dateTime);
      String date = _formatterDate.format(dateTime);
      if (timesList == null || timesList.length < 5) {
        await _notesViewerController.createNote(date, time, text);
        if (pathUserFile != null) {
          // await _notesViewerController.attachFileToNote();
          await httpLib.upload(main.userId.toString(), date, time, pathUserFile);
          pathUserFile = null;
        }
        await _notesViewerController.updateCalendarNotes();
        await _notesViewerController.updateDayNotesList();
        widget.notifyParent();
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handlerAlertDialogDownloadFileButton() async{
    pathUserFile = await _notesViewerController.getFileFromMemory();
  }

  Future<void> _handlerDeleteButton(String time) async {
    await _notesViewerController.deleteNote(time);

    await _notesViewerController.updateCalendarNotes();
    await _notesViewerController.updateDayNotesList();

    widget.notifyParent();
  }

  Future<void> _handlerNoteWithFileDownloadFileButton(String fileName) async{
    String date = _formatterDate.format(main.selectedDate);
    String time = selectedTime;
    await _notesViewerController.downloadFile(main.userId.toString(), date, time, fileName);
  }

  String _reformatTime(String befTime) {
    return befTime[0] + befTime[1] + ':' + befTime[2] + befTime[3] + ':' + befTime[4] + befTime[5];
  }
}
