import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class NotloginCalendarScreen extends StatefulWidget {
  final int selectedMonth; // 선택된 월을 받을 매개변수 추가

  const NotloginCalendarScreen({
    super.key,
    this.selectedMonth = 0, // 기본값은 0으로 설정 (0이면 현재 월 사용)
  });

  @override
  _NotloginCalendarScreenState createState() => _NotloginCalendarScreenState();
}

class _NotloginCalendarScreenState extends State<NotloginCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  // 거래 내역 (임시) - 2025년으로 업데이트
  final Map<DateTime, List<Transaction>> _events = {
    DateTime.utc(2025, 3, 12): [Transaction(amount: 49800, isIncome: true)],
    DateTime.utc(2025, 3, 13): [Transaction(amount: 50000, isIncome: false)],
    DateTime.utc(2025, 3, 14): [Transaction(amount: 28800, isIncome: false)],
    DateTime.utc(2025, 3, 15): [Transaction(amount: 29800, isIncome: false)],
  };

  @override
  void initState() {
    super.initState();
    // 부모 위젯에서 전달받은 월을 사용하거나 현재 월을 사용
    if (widget.selectedMonth > 0) {
      _focusedDay = DateTime(DateTime.now().year, widget.selectedMonth, 1);
    } else {
      _focusedDay = DateTime.now();
    }
    _selectedDay = _focusedDay; // 초기 선택 날짜 설정
  }

  @override
  void didUpdateWidget(NotloginCalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 부모 위젯에서 전달한 월이 변경되었을 때 업데이트
    if (widget.selectedMonth > 0 && widget.selectedMonth != oldWidget.selectedMonth) {
      setState(() {
        _focusedDay = DateTime(DateTime.now().year, widget.selectedMonth, 1);
      });
    }
  }

  List<Transaction> _getEventsForDay(DateTime day) {
    // 모든 키를 확인
    for (final eventDate in _events.keys) {
      // 년, 월, 일 비교
      if (eventDate.year == day.year &&
          eventDate.month == day.month &&
          eventDate.day == day.day) {
        return _events[eventDate]!;
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 달력 표시
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              locale: 'ko_KR',
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.withAlpha(77),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                // 마커 스타일 제거 (커스텀 빌더에서 처리)
                markersMaxCount: 0,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                // 날짜 셀 커스텀 빌더
                defaultBuilder: (context, day, focusedDay) {
                  final events = _getEventsForDay(day);

                  return Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 날짜 숫자
                        Text(
                          '${day.day}',
                          style: const TextStyle(fontSize: 16),
                        ),

                        // 거래내역 표시 (최대 2개)
                        ...events.take(2).map((transaction) {
                          final formattedAmount = NumberFormat.currency(
                            locale: 'ko_KR',
                            symbol: '',
                            decimalDigits: 0,
                          ).format(transaction.amount);

                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${transaction.isIncome ? '+' : '-'}$formattedAmount원',
                              style: TextStyle(
                                fontSize: 10,
                                color: transaction.isIncome ? const Color(0xFF73AD13) : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },

                // 선택된 날짜 셀 커스텀 빌더
                selectedBuilder: (context, day, focusedDay) {
                  final events = _getEventsForDay(day);

                  return Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 날짜 숫자
                        Text(
                          '${day.day}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // 거래내역 표시 (최대 2개)
                        ...events.take(2).map((transaction) {
                          final formattedAmount = NumberFormat.currency(
                            locale: 'ko_KR',
                            symbol: '',
                            decimalDigits: 0,
                          ).format(transaction.amount);

                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${transaction.isIncome ? '+' : '-'}$formattedAmount원',
                              style: TextStyle(
                                fontSize: 10,
                                color: transaction.isIncome ? const Color(0xFF73AD13) : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },

                // 오늘 날짜 셀 커스텀 빌더
                todayBuilder: (context, day, focusedDay) {
                  final events = _getEventsForDay(day);

                  return Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 날짜 숫자
                        Text(
                          '${day.day}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),

                        // 거래내역 표시 (최대 2개)
                        ...events.take(2).map((transaction) {
                          final formattedAmount = NumberFormat.currency(
                            locale: 'ko_KR',
                            symbol: '',
                            decimalDigits: 0,
                          ).format(transaction.amount);

                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${transaction.isIncome ? '+' : '-'}$formattedAmount원',
                              style: TextStyle(
                                fontSize: 10,
                                color: transaction.isIncome ? const Color(0xFF73AD13) : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 선택된 날짜의 거래 내역 상세
            if (_selectedDay != null)
              SizedBox(
                height: 200,
                child: _getEventsForDay(_selectedDay!).isEmpty
                    ? const Center(
                  child: Text(
                    '이 날짜에는 거래 내역이 없습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: _getEventsForDay(_selectedDay!).length,
                  itemBuilder: (context, index) {
                    final transaction = _getEventsForDay(_selectedDay!)[index];
                    final formattedAmount = NumberFormat.currency(
                      locale: 'ko_KR',
                      symbol: '',
                      decimalDigits: 0,
                    ).format(transaction.amount);

                    return ListTile(
                      title: Text(
                        '${transaction.isIncome ? '+' : '-'}$formattedAmount원',
                        style: TextStyle(
                          color: transaction.isIncome ? const Color(0xFF73AD13) : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // 여기에 거래 설명이나 카테고리 등 추가 정보 표시 가능
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 거래 내역을 저장하는 클래스
class Transaction {
  final double amount;
  final bool isIncome;

  Transaction({
    required this.amount,
    required this.isIncome,
  });
}