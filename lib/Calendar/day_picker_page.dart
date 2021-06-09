import 'package:flutter/material.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart' as dp;
import 'package:intl/intl.dart';

import '../main.dart' as main;
import '../Http.dart' as myHTTPlib;
import 'event.dart';

class DayPickerPage extends StatefulWidget {
  final Function() notifyParent;

  DayPickerPage({Key key, @required this.notifyParent}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DayPickerPageState();
}

class _DayPickerPageState extends State<DayPickerPage> {
  DateTime _firstDate;
  DateTime _lastDate;
  Color selectedDateStyleColor;
  Color selectedSingleDateDecorationColor;

  final formatter = new DateFormat('yyyyMMdd');

  @override
  void initState() {
    super.initState();

    _firstDate = DateTime.now().subtract(Duration(days: 30));
    _lastDate = DateTime.now().add(Duration(days: 30));
    _onSelectedDateChanged(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // defaults for styles
    selectedDateStyleColor = Theme.of(context).accentTextTheme.bodyText1.color;
    selectedSingleDateDecorationColor = Theme.of(context).accentColor;
  }

  @override
  Widget build(BuildContext context) {
    // add selected colors to default settings
    dp.DatePickerStyles styles = dp.DatePickerRangeStyles(
        selectedDateStyle:
            Theme.of(context).accentTextTheme.bodyText1.copyWith(color: selectedDateStyleColor),
        selectedSingleDateDecoration:
            BoxDecoration(color: selectedSingleDateDecorationColor, shape: BoxShape.circle));

    return dp.DayPicker.single(
      selectedDate: main.selectedDate,
      onChanged: _onSelectedDateChanged,
      firstDate: _firstDate,
      lastDate: _lastDate,
      datePickerStyles: styles,
      datePickerLayoutSettings: dp.DatePickerLayoutSettings(maxDayPickerRowCount: 1),
      eventDecorationBuilder: _eventDecorationBuilder,
    );
  }

  void _onSelectedDateChanged(DateTime newDate) {
    main.selectedDate = newDate;
    main.mode = 1;
    String date = formatter.format(newDate);
    myHTTPlib.sendRequestGet('view', main.userId.toString(), date).then((messageBody) {
      main.messageText = messageBody;
      widget.notifyParent();
    });

  }

  dp.EventDecoration _eventDecorationBuilder(DateTime date) {
    List<DateTime> eventsDates = main.events?.map<DateTime>((Event e) => e.date)?.toList();
    bool isEventDate = eventsDates?.any(
            (DateTime d) => date.year == d.year && date.month == d.month && d.day == date.day) ??
        false;

    BoxDecoration roundedBorder = BoxDecoration(
        border: Border.all(
          color: Colors.deepOrange,
        ),
        borderRadius: BorderRadius.all(Radius.circular(3.0)));

    return isEventDate ? dp.EventDecoration(boxDecoration: roundedBorder) : null;
  }
}
