import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'transaction.dart';

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

  // Provider에서 특정 날짜의 거래 내역 가져오기
  List<Transaction> _getEventsForDay(DateTime day, TransactionProvider provider) {
    return provider.transactions.where((transaction) {
      return transaction.date.year == day.year &&
          transaction.date.month == day.month &&
          transaction.date.day == day.day;
    }).toList();
  }

  // 특정 날짜의 수입 합계 계산
  int _calculateTotalIncome(DateTime day, TransactionProvider provider) {
    final transactions = _getEventsForDay(day, provider);
    return transactions
        .where((transaction) => transaction.type == '수입')
        .fold(0, (sum, transaction) => sum + transaction.amount.toInt());
  }

  // 특정 날짜의 지출 합계 계산
  int _calculateTotalExpense(DateTime day, TransactionProvider provider) {
    final transactions = _getEventsForDay(day, provider);
    return transactions
        .where((transaction) => transaction.type != '수입')
        .fold(0, (sum, transaction) => sum + transaction.amount.toInt());
  }

  // 금액 포맷팅 함수
  String _formatAmount(int amount) {
    return NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Provider로부터 트랜잭션 데이터 가져오기
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // 달력 표시 (높이 제한)
          Container(
            height: MediaQuery.of(context).size.height * 0.55, // 화면 높이의 55%로 제한
            child: TableCalendar(
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
              rowHeight: 55, //달력 셀의 높이 설정
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                // 마커 스타일 제거
                markersMaxCount: 0,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                // 날짜 셀 커스텀 빌더
                defaultBuilder: (context, day, focusedDay) {
                  final totalIncome = _calculateTotalIncome(day, transactionProvider);
                  final totalExpense = _calculateTotalExpense(day, transactionProvider);

                  return Container(
                    margin: const EdgeInsets.all(2),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 날짜 숫자
                        Text(
                          '${day.day}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        // 수입이 있는 경우 표시
                        if (totalIncome > 0)
                          Text(
                            '+${_formatAmount(totalIncome)}원',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF73AD13),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        // 지출이 있는 경우 표시
                        if (totalExpense > 0)
                          Text(
                            '-${_formatAmount(totalExpense)}원',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  );
                },
                // 선택된 날짜 셀 커스텀 빌더
                selectedBuilder: (context, day, focusedDay) {
                  final totalIncome = _calculateTotalIncome(day, transactionProvider);
                  final totalExpense = _calculateTotalExpense(day, transactionProvider);

                  return Container(
                    margin: const EdgeInsets.all(2),
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // 수입이 있는 경우 표시
                        if (totalIncome > 0)
                          Text(
                            '+${_formatAmount(totalIncome)}원',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF73AD13),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        // 지출이 있는 경우 표시
                        if (totalExpense > 0)
                          Text(
                            '-${_formatAmount(totalExpense)}원',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  );
                },
                // 오늘 날짜 셀 커스텀 빌더
                todayBuilder: (context, day, focusedDay) {
                  final totalIncome = _calculateTotalIncome(day, transactionProvider);
                  final totalExpense = _calculateTotalExpense(day, transactionProvider);

                  return Container(
                    margin: const EdgeInsets.all(2),
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // 수입이 있는 경우 표시
                        if (totalIncome > 0)
                          Text(
                            '+${_formatAmount(totalIncome)}원',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF73AD13),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        // 지출이 있는 경우 표시
                        if (totalExpense > 0)
                          Text(
                            '-${_formatAmount(totalExpense)}원',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 선택된 날짜의 거래 내역 상세
          if (_selectedDay != null)
            Expanded(
              child: _getEventsForDay(_selectedDay!, transactionProvider).isEmpty
                  ? const Center(
                child: Text(
                  '이 날짜에는 거래 내역이 없습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _getEventsForDay(_selectedDay!, transactionProvider).length,
                itemBuilder: (context, index) {
                  final transaction = _getEventsForDay(_selectedDay!, transactionProvider)[index];
                  final formattedAmount = _formatAmount(transaction.amount.toInt());

                  return ListTile(
                    title: Text(
                      '${transaction.type == '수입' ? '+' : '-'}$formattedAmount원',
                      style: TextStyle(
                        color: transaction.type == '수입' ? const Color(0xFF73AD13) : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: transaction.merchant.isNotEmpty
                        ? Text(transaction.merchant)
                        : null,
                    // 태그 표시
                    trailing: transaction.tags.isNotEmpty
                        ? Wrap(
                      children: transaction.tags.take(2).map((tag) =>
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          )
                      ).toList(),
                    )
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}