/// 로그인하지 않은 사용자를 위한 캘린더 화면
/// 날짜별 수입/지출 내역을 캘린더 형태로 시각화하여 보여줍니다.
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'transaction.dart';

class NotloginCalendarScreen extends StatefulWidget {
  final int selectedMonth;

  const NotloginCalendarScreen({
    super.key,
    this.selectedMonth = 0,
  });

  @override
  NotloginCalendarScreenState createState() => NotloginCalendarScreenState();
}

class NotloginCalendarScreenState extends State<NotloginCalendarScreen> with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  // 하단 시트용 애니메이션 컨트롤러
  late AnimationController _bottomSheetController;
  late Animation<double> _bottomSheetAnimation;

  @override
  void initState() {
    super.initState();
    // 애니메이션 컨트롤러 초기화
    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 슬라이드 애니메이션 생성
    _bottomSheetAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _bottomSheetController,
        curve: Curves.easeOutQuad,
      ),
    );

    // 포커스된 날짜 설정
    if (widget.selectedMonth > 0) {
      _focusedDay = DateTime(DateTime.now().year, widget.selectedMonth, 1);
    } else {
      _focusedDay = DateTime.now();
    }
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    // 애니메이션 컨트롤러 해제
    _bottomSheetController.dispose();
    super.dispose();
  }

  // Provider에서 특정 날짜의 거래 내역 가져오기
  List<FinancialTransaction> _getEventsForDay(DateTime day, TransactionProvider provider) {
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

  // 새로운 메서드: 애니메이션이 있는 하단 시트로 거래 내역 표시
  void _showTransactionBottomSheet(BuildContext context, DateTime selectedDay, TransactionProvider transactionProvider) {
    final transactions = _getEventsForDay(selectedDay, transactionProvider);

    if (transactions.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: GestureDetector(
            onTap: () {},
            child: AnimatedBuilder(
              animation: _bottomSheetController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, MediaQuery.of(context).size.height * _bottomSheetAnimation.value),
                  child: child,
                );
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.25,
                maxChildSize: 0.9,
                builder: (_, controller) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 6,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            '${DateFormat('M월 d일').format(selectedDay)} 거래 내역',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: controller,
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
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
                },
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _bottomSheetController.reset();
    });

    _bottomSheetController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // 캘린더
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
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

                // 날짜 선택 시 하단 시트 표시
                _showTransactionBottomSheet(context, selectedDay, transactionProvider);
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
              rowHeight: 55, // 달력 셀의 높이 설정
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
        ],
      ),
    );
  }
}