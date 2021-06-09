import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'view/EntrySelection.dart';
import 'controller/DayPickerPage.dart';
import 'model/entities/event.dart';
import 'controller/Http.dart' as http;

var logger = Logger();
final String serverURI = 'http://92.255.182.216:8000/';
DateTime selectedDate = DateTime.now();
String messageText = '';
/// 1 - выбрана дата
/// 2 - выбрана запись
///
int mode = 0;
int userId = 1;
List<Event> events;

_MyAppState myAppState = new _MyAppState();

class _MyAppState extends State<MyApp> {
  final _formatterDate = new DateFormat('yyyyMMdd');

  refresh() {
    setState(() {});
  }

  void initState() {
    super.initState();
    http.initAllEntry('1').then((newEvents) {
      events = newEvents;
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
              child: EntrySelection(notifyParent: refresh),
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
