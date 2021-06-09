import 'dart:io';

import 'package:ext_storage/ext_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../Http.dart' as myHTTPlib;
import '../json.dart';
import '../main.dart' as main;

class EntrySelection extends StatefulWidget {
  final Function() notifyParent;

  EntrySelection({Key key, @required this.notifyParent}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EntrySelectionState();
}

class _EntrySelectionState extends State<EntrySelection> {
  List<String> timesList;
  String selectedTime;
  String noteText;
  bool fileCheck;
  String fileName;

  final myController = TextEditingController();
  File pathUserFile;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  final _formatterDate = new DateFormat('yyyyMMdd');
  final _formatterTime = new DateFormat('HHmmss');
  final _formatterTime2 = new DateFormat('HH:mm:ss');

  _EntrySelectionState();

  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    switch (main.mode) {
      case 1:
        {
          // timesList = null;
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
                            selectedTime = timesList[index];
                            String date = _formatterDate.format(main.selectedDate);
                            myHTTPlib
                                .sendRequestGet('view', main.userId.toString(), date, selectedTime)
                                .then((messageBody) {
                              noteText = jsonGetNoteText(messageBody);
                              myHTTPlib
                                  .sendRequestGet(
                                      'file', main.userId.toString(), date, selectedTime, 'name')
                                  .then((value) {
                                    fileName = value;
                                fileCheck = fileName!=null && fileName.isNotEmpty;
                                if(fileCheck)
                                  main.mode = 3;
                                else
                                  main.mode = 2;
                                widget.notifyParent();
                              });
                            });
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
              _downloadEntry(fileName);
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
        _deleteEntry(selectedTime);
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
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return _buildAlertDialog();
            });
      },
      style: style,
      child: const Text(
        "+",
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  AlertDialog _buildAlertDialog() {
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
                  controller: myController,
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: () {
                    _uploadEntry();
                  }),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              if (myController.text != "" &&
                  myController.text != null &&
                  myController.text.replaceAll(" ", "") != "") {
                if (pathUserFile != null) {
                  DateTime time = DateTime.now();
                  _uploadFile(myController.text);
                  Navigator.pop(context);
                } else {
                  _createEntry(myController.text);
                  Navigator.pop(context);
                }
              }
            },
            child: Text('Добавить'),
          ),
        ],
      ),
    ));
  }

  _createEntry(String text, [DateTime time]) {
    if (time == null) {
      time = DateTime.now();
    }
    if (timesList == null || timesList.length < 5) {
      myHTTPlib
          .sendRequestPost('create',
              id: main.userId.toString(),
              date: _formatterDate.format(DateTime.now()),
              time: _formatterTime.format(time),
              text: text)
          .then((res) {
        myHTTPlib.initAllEntry(main.userId.toString()).then((newEvents) {
          main.events = newEvents;
          String date = _formatterDate.format(main.selectedDate);
          myHTTPlib.sendRequestGet('view', main.userId.toString(), date).then((messageBody) {
            main.messageText = messageBody;
            widget.notifyParent();
          });
        });
      });
    }
  }

  _deleteEntry(String time) {
    myHTTPlib
        .sendRequestDelete(
            'delete', main.userId.toString(), _formatterDate.format(main.selectedDate), time)
        .then((isOk) {
      if (isOk) {
        myHTTPlib.initAllEntry(main.userId.toString()).then((newEvents) {
          main.events = newEvents;
          main.mode = 0;
          widget.notifyParent();
        });
      } else
        widget.notifyParent();
    });
  }

  _uploadEntry() {
    FilePicker.getFile().then((value) {
      pathUserFile = value;
    }).catchError((error) {
      print("Error: $error");
    });
  }

  _uploadFile(String text, [DateTime time]) {
    if (time == null) {
      time = DateTime.now();
    }
    if (timesList == null || timesList.length < 5) {
      myHTTPlib
          .sendRequestPost('create',
              id: main.userId.toString(),
              date: _formatterDate.format(DateTime.now()),
              time: _formatterTime.format(time),
              text: text)
          .then((res) {
        myHTTPlib
            .upload(main.userId.toString(), _formatterDate.format(DateTime.now()),
                _formatterTime.format(time), pathUserFile)
            .then((value) {
          myHTTPlib.initAllEntry(main.userId.toString()).then((newEvents) {
            pathUserFile = null;
            main.events = newEvents;
            widget.notifyParent();
          });
        });
      });
    }
  }

  _downloadEntry(String fileName) {
    String date = _formatterDate.format(main.selectedDate);
    String time = selectedTime;
    _downloadFile(main.userId.toString(), date, time, fileName);
  }

  String _reformatTime(String befTime) {
    String afTime;
    befTime =
        befTime[0] + befTime[1] + '/' + befTime[2] + befTime[3] + '/' + befTime[4] + befTime[5];
    afTime = _formatterTime2.format(DateFormat('HH/mm/ss').parse(befTime));

    return afTime;
  }

  Future<void> _downloadFile(String id, String date, String time, String fileName) async {
    int _total = 0, _received = 0;
    http.StreamedResponse _response;
    File _file;
    List<int> _bytes = [];

    _response = await http.Client()
        .send(http.Request('GET', Uri.parse(main.serverURI + "file/$id/$date/$time")));
    String path =
        await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DOWNLOADS);
    _total = _response.contentLength;

    _response.stream.listen((value) {
      setState(() {
        _bytes.addAll(value);
        _received += value.length;
      });
    }).onDone(() async {
      final file = File("$path/$fileName");
      await file.writeAsBytes(_bytes);
      setState(() {
        _file = file;
      });
    });
  }
}
