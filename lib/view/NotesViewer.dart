import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cloud_storage_service_client/controller/httpLib.dart' as httpLib;
import 'package:cloud_storage_service_client/controller/json.dart';
import 'package:cloud_storage_service_client/controller/NotesViewer/NotesViewerController.dart';
import 'package:cloud_storage_service_client/model/NotesViewerModel.dart' as model;

class NotesViewer extends StatefulWidget {
  final Function() notifyParent;

  NotesViewer({Key key, @required this.notifyParent}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NotesViewerState();
}

class _NotesViewerState extends State<NotesViewer> {
  final alertDialogController = TextEditingController();
  final NotesViewerController _notesViewerController = new NotesViewerController();

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
    switch (model.mode) {
      case 1:
        {
          model.timesList = null;
          //Список записей
          if (model.messageText.isEmpty) {
            break;
          }
          model.timesList = jsonToList(model.messageText);
          return _buildNoteList();
        }
      case 2:
        {
          //Запись без файла
          return _buildNoteWithoutFile(model.noteText);
        }
      case 3:
        {
          //Запись с файлом
          return _buildNoteWithFile(model.noteText);
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
              itemCount: model.timesList.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                if (model.timesList.length == 0) {
                  return Text('Записей нет!');
                } else {
                  return Center(
                      child: ElevatedButton(
                          onPressed: () {
                            _handlerNoteListButton(index);
                          },
                          child: Text(_reformatTime(model.timesList[index]))));
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
    model.selectedTime = model.timesList[index];
    String date = _formatterDate.format(model.selectedDate);

    model.noteText = await _notesViewerController.getNoteText(date, model.selectedTime);

    model.fileName = await _notesViewerController.getNoteFileName(date, model.selectedTime);
    if (model.fileName != null && model.fileName.trim().isNotEmpty) {
      model.mode = 3;
    } else {
      model.mode = 2;
      model.fileName = null;
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
              _handlerNoteWithFileDownloadFileButton(model.fileName);
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
        _handlerDeleteButton(model.selectedTime);
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
      if (model.timesList == null || model.timesList.length < 5) {
        await _notesViewerController.createNote(date, time, text);
        if (model.pathUserFile != null) {
          // await _notesViewerController.attachFileToNote();
          await httpLib.upload(model.userId.toString(), date, time, model.pathUserFile);
          model.pathUserFile = null;
        }
        await _notesViewerController.updateCalendarNotes();
        await _notesViewerController.updateDayNotesList();
        widget.notifyParent();
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handlerAlertDialogDownloadFileButton() async{
    model.pathUserFile = await _notesViewerController.getFileFromMemory();
  }

  Future<void> _handlerDeleteButton(String time) async {
    await _notesViewerController.deleteNote(time);

    await _notesViewerController.updateCalendarNotes();
    await _notesViewerController.updateDayNotesList();

    widget.notifyParent();
  }

  Future<void> _handlerNoteWithFileDownloadFileButton(String fileName) async{
    String date = _formatterDate.format(model.selectedDate);
    String time = model.selectedTime;
    await _notesViewerController.downloadFile(model.userId.toString(), date, time, fileName);
  }

  String _reformatTime(String befTime) {
    return befTime[0] + befTime[1] + ':' + befTime[2] + befTime[3] + ':' + befTime[4] + befTime[5];
  }
}
