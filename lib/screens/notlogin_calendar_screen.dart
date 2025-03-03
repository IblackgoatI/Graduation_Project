import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class NotloginCalendarScreen extends StatefulWidget {
  const NotloginCalendarScreen({super.key});

  @override
  _NotloginCalendarScreenState createState() => _NotloginCalendarScreenState();
}

class _NotloginCalendarScreenState extends State<NotloginCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 거래 내역 (임시)
  final Map<DateTime, List<String>> _events = {
    DateTime.utc(2023, 10, 12): ['+49,800원'],
    DateTime.utc(2023, 10, 13): ['-50,000원'],
    DateTime.utc(2023, 10, 14): ['-28,800원'],
    DateTime.utc(2023, 10, 15): ['-29,800원'],
  };

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null, // 뒤로가기 버튼 제거
        automaticallyImplyLeading: false, // 자동으로 생성되는 leading 버튼 비활성화
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
          children: [
            // 드롭다운 메뉴
            DropdownButton<int>(
              value: _focusedDay.month,
              onChanged: (int? newValue) {
                setState(() {
                  _focusedDay = DateTime(_focusedDay.year, newValue!, 1);
                });
              },
              items: List.generate(12, (index) => index + 1)
                  .map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(
                    '$value월',
                    style: TextStyle(
                      color: Colors.white, // 텍스트 색상 변경
                      fontSize: 18, // 텍스트 크기 조정
                    ),
                  ),
                );
              }).toList(),
              underline: Container(), // 밑줄 제거
              icon: Container(), // 화살표 제거
              dropdownColor: Colors.blue, // 드롭다운 배경색
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 달력 표시
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
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
                _focusedDay = focusedDay;
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.withAlpha(77), // 불투명도 30%
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false, // 월/주 전환 버튼 숨기기
                titleCentered: true, // 제목 가운데 정렬
              ),
            ),

            // 선택된 날짜의 거래 내역
            if (_selectedDay != null)
              SizedBox(
                height: 200, // 고정 높이 지정 (적절히 조절 가능)
                child: ListView.builder(
                  itemCount: _getEventsForDay(_selectedDay!).length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        _getEventsForDay(_selectedDay!)[index],
                        style: TextStyle(
                          color: _getEventsForDay(_selectedDay!)[index].startsWith('+')
                              ? Colors.blue
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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