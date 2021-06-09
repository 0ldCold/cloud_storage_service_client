import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';

import 'package:cloud_storage_service_client/view/NotesViewer.dart';
import 'package:cloud_storage_service_client/controller/DayPickerPage.dart';
import 'package:cloud_storage_service_client/controller/httpLib.dart' as http;
import 'package:cloud_storage_service_client/model/NotesViewerModel.dart' as model;

var logger = Logger();
final String serverURI = 'http://92.255.182.216:8000/';

_MyAppState myAppState = new _MyAppState();

class _MyAppState extends State<MyApp> {

  refresh() {
    setState(() {});
  }

  void initState() {
    super.initState();
    http.initAllEntry('1').then((newEvents) {
      model.events = newEvents;
      http.requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('CloudStorage Service')),
        body: Center(
            child: Column(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Container(
                child: DayPickerPage(notifyParent: refresh),
              ),
            ),
            Expanded(
              flex: 1,
              child: NotesViewer(notifyParent: refresh),
            ),
          ],
        )));
  } //Text('Logs:' + messageText)
}

class MyApp extends StatefulWidget {
  MyApp();

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

void main() => runApp(MaterialApp(
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: [
      //const Locale('en', 'US'), // American English
      const Locale('ru', 'RU'), // Russian
    ],
    title: 'CloudService0720',
    theme: ThemeData(
      primarySwatch: Colors.blueGrey,
    ),
    debugShowCheckedModeBanner: false,
    home: MyApp()));

//Scaffold.of(context).showSnackBar(SnackBar(
// content: Text('Processing Data')));
