import 'package:common_utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum ActiveType { begin, end }

typedef DateTimeRangeCallback = Function(DateTime beginTime, DateTime endTime);

class MyDatePicker extends StatefulWidget {
  const MyDatePicker({
    Key? key,
    required this.beginDate,
    required this.endDate,
    required this.onSelectedDone,
  }) : super(key: key);
  final DateTime beginDate;
  final DateTime endDate;
  final DateTimeRangeCallback onSelectedDone;

  @override
  State<MyDatePicker> createState() => _MyDatePickerState();
}

class _MyDatePickerState extends State<MyDatePicker> {
  ActiveType activeType = ActiveType.begin;
  late DateTime selectedBeginTime;
  late DateTime selectedEndTime;

  @override
  initState() {
    selectedBeginTime = widget.beginDate;
    selectedEndTime = widget.endDate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const double kRadius = 25;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _textButton(
                title: '取消',
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            Text('请选择'),
            _textButton(
                title: '确定',
                onPressed: () {
                  widget.onSelectedDone(selectedBeginTime, selectedEndTime);
                  Navigator.of(context).pop();
                }),
          ],
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: 50,
          decoration: BoxDecoration(border: Border.all(width: 1, color: Colors.teal), borderRadius: BorderRadius.circular(kRadius)),
          child: Row(
            children: [
              _tabBeginButton(kRadius, title: '开始日期', datetime: DateUtil.formatDate(selectedBeginTime, format: DateFormats.y_mo_d)),
              _tabEndButton(kRadius, title: '结束日期', datetime: DateUtil.formatDate(selectedEndTime, format: DateFormats.y_mo_d)),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          width: 300,
          child: MyPicker(
            activeType: activeType,
            beginDate: widget.beginDate,
            endDate: widget.endDate,
            onDateTimeChanged: (dateTime) {
              if (activeType == ActiveType.begin) {
                selectedBeginTime = dateTime;
              } else if (activeType == ActiveType.end) {
                selectedEndTime = dateTime;
              }
              setState(() {});
            },
          ),
        )
      ],
    );
  }

  Expanded _tabBeginButton(double kRadius, {required String title, required String datetime}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (activeType == ActiveType.begin) return;
          setState(() {
            activeType = ActiveType.begin;
          });
        },
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            color: activeType == ActiveType.begin ? Colors.teal : Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title),
              Text(datetime),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _tabEndButton(double kRadius, {required String title, required String datetime}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (activeType == ActiveType.end) return;
          setState(() {
            activeType = ActiveType.end;
          });
        },
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            color: activeType == ActiveType.end ? Colors.teal : Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title),
              Text(datetime),
            ],
          ),
        ),
      ),
    );
  }

  TextButton _textButton({required String title, required VoidCallback onPressed}) {
    return TextButton(onPressed: onPressed, child: Text(title));
  }
}

final _kMonth = List.generate(12, (index) => '${index + 1}月');
final _kDays = List.generate(31, (index) => '${index + 1}日');

class MyPicker extends StatefulWidget {
  const MyPicker({
    Key? key,
    required this.beginDate,
    required this.endDate,
    required this.activeType,
    required this.onDateTimeChanged,
  }) : super(key: key);
  final DateTime beginDate;
  final DateTime endDate;
  final ActiveType activeType;
  final ValueChanged<DateTime> onDateTimeChanged;

  @override
  State<MyPicker> createState() => _MyPickerState();
}

class _MyPickerState extends State<MyPicker> {
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;
  late FixedExtentScrollController dayController;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController yearController;
  bool isDayPickerScrolling = false;
  bool isMonthPickerScrolling = false;
  bool isYearPickerScrolling = false;

  bool get isScrolling => isDayPickerScrolling || isMonthPickerScrolling || isYearPickerScrolling;

// Estimated width of columns.
  Map<int, double> estimatedColumnWidths = <int, double>{};

  @override
  void initState() {
    super.initState();
    selectedDay = widget.activeType == ActiveType.begin ? widget.beginDate.day : widget.endDate.day;
    selectedMonth = widget.activeType == ActiveType.begin ? widget.beginDate.month : widget.endDate.month;
    selectedYear = widget.activeType == ActiveType.begin ? widget.beginDate.year : widget.endDate.year;

    dayController = FixedExtentScrollController(initialItem: selectedDay - 1);
    monthController = FixedExtentScrollController(initialItem: selectedMonth - 1);
    yearController = FixedExtentScrollController(initialItem: selectedYear - 1);
  }

  @override
  didUpdateWidget(MyPicker oldWidget) {
    if (oldWidget.activeType == widget.activeType) {
      return;
    }
    super.didUpdateWidget(oldWidget);
    _scrollAnimate();
  }

  @override
  void dispose() {
    print('dispose');
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();

    // PaintingBinding.instance.systemFonts.removeListener(_handleSystemFontsChange);
    super.dispose();
  }

  _scrollAnimate() {
    const Duration kDuration = Duration(milliseconds: 200);
    selectedDay = widget.activeType == ActiveType.begin ? widget.beginDate.day : widget.endDate.day;
    selectedMonth = widget.activeType == ActiveType.begin ? widget.beginDate.month : widget.endDate.month;
    selectedYear = widget.activeType == ActiveType.begin ? widget.beginDate.year : widget.endDate.year;
    dayController.animateToItem(selectedDay - 1, duration: kDuration, curve: Curves.easeInOut);
    monthController.animateToItem(selectedMonth - 1, duration: kDuration, curve: Curves.easeInOut);
    yearController.animateToItem(selectedYear - 1, duration: kDuration, curve: Curves.easeInOut);
  }

  // One or more pickers have just stopped scrolling.
  void _pickerDidStopScrolling() {
    // Call setState to update the greyed out days/months/years, as the currently
    // selected year/month may have changed.
    setState(() {});

    if (isScrolling) {
      return;
    }

    // Whenever scrolling lands on an invalid entry, the picker
    // automatically scrolls to a valid one.
    final DateTime minSelectDate = DateTime(selectedYear, selectedMonth, selectedDay);
    final DateTime maxSelectDate = DateTime(selectedYear, selectedMonth, selectedDay + 1);

    // final bool minCheck = widget.minimumDate?.isBefore(maxSelectDate) ?? true;
    // final bool maxCheck = widget.maximumDate?.isBefore(minSelectDate) ?? false;
    //
    // if (!minCheck || maxCheck) {
    //   // We have minCheck === !maxCheck.
    //   final DateTime targetDate = minCheck ? widget.maximumDate! : widget.minimumDate!;
    //   _scrollToDate(targetDate);
    //   return;
    // }

    // Some months have less days (e.g. February). Go to the last day of that month
    // if the selectedDay exceeds the maximum.
    if (minSelectDate.day != selectedDay) {
      final DateTime lastDay = _lastDayInMonth(selectedYear, selectedMonth);
      _scrollToDate(lastDay);
    }
  }

  void _animateColumnControllerToItem(FixedExtentScrollController controller, int targetItem) {
    controller.animateToItem(
      targetItem,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 200),
    );
  }

  void _scrollToDate(DateTime newDate) {
    SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
      if (selectedYear != newDate.year) {
        _animateColumnControllerToItem(yearController, newDate.year);
      }

      if (selectedMonth != newDate.month) {
        _animateColumnControllerToItem(monthController, newDate.month - 1);
      }

      if (selectedDay != newDate.day) {
        _animateColumnControllerToItem(dayController, newDate.day - 1);
      }
    });
  }

  DateTime _lastDayInMonth(int year, int month) => DateTime(year, month + 1, 0);

  @override
  Widget build(BuildContext context) {
    final style = CupertinoTheme.of(context).textTheme.dateTimePickerTextStyle;
    final iStyle = style.copyWith(color: CupertinoDynamicColor.resolve(CupertinoColors.inactiveGray, context));

    return DefaultTextStyle(
      style: style,
      child: Row(
        children: [
          Expanded(
            child: CupertinoPicker.builder(
              scrollController: yearController,
              selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                capEndEdge: false,
              ),
              backgroundColor: Colors.transparent,
              useMagnifier: true,
              magnification: 1.3,
              squeeze: 1,
              itemExtent: 25,
              onSelectedItemChanged: (index) {
                selectedYear = index + 1;
                widget.onDateTimeChanged(DateTime(selectedYear, selectedMonth, selectedDay));
              },
              itemBuilder: (BuildContext context, int index) {
                if (index < 0) return null;

                final year = '${index + 1}';
                return Text(
                  year,
                );
              },
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: monthController,
              selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                capEndEdge: false,
                capStartEdge: false,
              ),
              looping: true,
              useMagnifier: true,
              magnification: 1.3,
              squeeze: 1,
              itemExtent: 25,
              onSelectedItemChanged: (index) {
                selectedMonth = index + 1;
                widget.onDateTimeChanged(DateTime(selectedYear, selectedMonth, selectedDay));
              },
              children: List.generate(_kMonth.length, (index) => Text(_kMonth[index])),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollStartNotification) {
                  isDayPickerScrolling = true;
                } else if (notification is ScrollEndNotification) {
                  isDayPickerScrolling = false;
                  _pickerDidStopScrolling();
                }

                return false;
              },
              child: CupertinoPicker(
                scrollController: dayController,
                selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                  capStartEdge: false,
                ),
                looping: true,
                useMagnifier: true,
                magnification: 1.3,
                squeeze: 1,
                itemExtent: 25,
                onSelectedItemChanged: (index) {
                  selectedDay = index + 1;
                  widget.onDateTimeChanged(DateTime(selectedYear, selectedMonth, selectedDay));
                },
                children: List.generate(
                  _kDays.length,
                  (index) {
                    final int daysInCurrentMonth = _lastDayInMonth(selectedYear, selectedMonth).day;
                    return Text(
                      _kDays[index],
                      style: index < daysInCurrentMonth ? style : iStyle,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
