/// 가계부 화면
/// 사용자의 수입과 지출 내역을 기록하고 관리하는 가계부 기능을 제공합니다.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'notlogin_add_transaction_screen.dart';
import 'notlogin_list_screen.dart';
import 'notlogin_calendar_screen.dart';
import 'transaction_provider.dart';

class AccountBookScreen extends StatefulWidget {
  const AccountBookScreen({super.key});

  @override
  AccountBookScreenState createState() => AccountBookScreenState();
}

class AccountBookScreenState extends State<AccountBookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonth = DateTime.now().month; // 현재 월로 초기화

  // NotloginListScreen에 접근하기 위한 키 생성
  final GlobalKey<NotloginListScreenState> listScreenKey = GlobalKey<NotloginListScreenState>();
  
  // 날짜 범위 변경 시 월 업데이트 콜백
  void _onDateRangeChanged(DateTime? startDate, DateTime? endDate) {
    if (startDate != null || endDate != null) {
      // 시작일이 있으면 시작일의 월, 없으면 종료일의 월 사용
      final DateTime targetDate = startDate ?? endDate!;
      setState(() {
        _selectedMonth = targetDate.month;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider로부터 데이터 가져오기
    final transactionProvider = Provider.of<TransactionProvider>(context);

    // 선택된 월의 수입, 지출, 목표 계산
    final transactions = transactionProvider.transactions;
    int income = 0;
    int expense = 0;
    int goal = 0;

    for (var transaction in transactions) {
      // 선택된 월과 같은 월의 트랜잭션만 필터링
      if (transaction.date.month == _selectedMonth) {
        // 카테고리가 '목표'인 경우 별도 통계
        if (transaction.category == '목표') {
          goal += transaction.amount.toInt();
        } else if (transaction.type == '수입') {
          income += transaction.amount.toInt();
        } else {
          expense += transaction.amount.toInt();
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('가계부'), // AppBar 제목
        backgroundColor: Colors.white, // AppBar 배경색을 흰색으로 설정
        foregroundColor: Colors.black, // AppBar 텍스트 및 아이콘 색상을 검정색으로 설정
      ),
      body: Column(
        children: [
          // 드롭다운 메뉴
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.white, // 배경색을 흰색으로 설정
            child: DropdownButton<int>(
              value: _selectedMonth,
              onChanged: (int? newValue) {
                setState(() {
                  _selectedMonth = newValue!;
                });
              },
              items: List.generate(12, (index) => index + 1)
                  .map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Center( // 텍스트를 가운데 정렬
                    child: Text(
                      '$value월',
                      style: TextStyle(
                        color: value == _selectedMonth ? const Color(0xFF73AD13) : Colors.black, // 드롭다운 메뉴에서는 선택된 항목은 녹색
                        fontSize: 24, // 텍스트 크기 조정
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
              underline: Container(), // 밑줄 제거
              icon: Container(), // 화살표 제거
              isExpanded: true, // 드롭다운 메뉴를 최대 너비로 확장
              alignment: Alignment.center, // 드롭다운 메뉴 텍스트 가운데 정렬
              dropdownColor: Colors.white, // 드롭다운 메뉴의 배경색을 흰색으로 설정
              selectedItemBuilder: (BuildContext context) {
                // 선택된 항목의 표시 방식을 별도로 지정 (드롭다운 닫혔을 때)
                return List.generate(12, (index) => index + 1)
                    .map<Widget>((int value) {
                  return Center(
                    child: Text(
                      '$value월',
                      style: const TextStyle(
                        color: Colors.black, // 선택된 항목은 검은색으로 표시
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
          ),
          // 수입, 지출, 목표 지표
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            color: Colors.white, // 배경색을 흰색으로 설정
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 공간 균등 분배
              children: [
                // 수입
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '수입 ',
                          style: TextStyle(
                            color: Colors.black, // "수입" 텍스트 색상
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: '${NumberFormat('#,###').format(income)}원',
                          style: TextStyle(
                            color: Color(0xFF73AD13), // 가격 색상 (#73AD13)
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 지출
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '지출 ',
                          style: TextStyle(
                            color: Colors.black, // "지출" 텍스트 색상
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: '${NumberFormat('#,###').format(expense)}원',
                          style: TextStyle(
                            color: Colors.red, // 가격 색상
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 목표
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '목표 ',
                          style: TextStyle(
                            color: Colors.black, // "목표" 텍스트 색상
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: '${NumberFormat('#,###').format(goal)}원',
                          style: TextStyle(
                            color: Color(0xFF9C27B0), // 가격 색상 (보라색)
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // 내역과 달력 버튼
          Container(
            color: Colors.white, // 배경색을 흰색으로 설정
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black, // 선택된 탭의 텍스트 색상
              unselectedLabelColor: Colors.grey, // 선택되지 않은 탭의 텍스트 색상
              labelStyle: const TextStyle(
                fontSize: 18, // 글씨 크기 조정
                fontWeight: FontWeight.bold, // bold체 적용
              ),
              indicatorColor: Colors.black, // 선택된 탭의 밑줄 색상
              tabs: const [
                Tab(text: '내역'), // 아이콘 없이 텍스트만 표시
                Tab(text: '달력'), // 아이콘 없이 텍스트만 표시
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                NotloginListScreen(
                  key: listScreenKey,
                  selectedMonth: _selectedMonth, // 선택된 월 매개변수 전달
                  onDateRangeChanged: _onDateRangeChanged, // 날짜 범위 변경 콜백 전달
                ),
                NotloginCalendarScreen(selectedMonth: _selectedMonth),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotloginAddTransactionScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF73AD13),
        child: const Icon(Icons.add),
      ),
    );
  }
}