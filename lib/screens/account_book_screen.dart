// account_book_screen.dart 수정 버전
import 'package:flutter/material.dart';
import 'notlogin_add_transaction_screen.dart';
import 'notlogin_list_screen.dart';
import 'notlogin_calendar_screen.dart';

class AccountBookScreen extends StatefulWidget {
  const AccountBookScreen({super.key});

  @override
  _AccountBookScreenState createState() => _AccountBookScreenState();
}

class _AccountBookScreenState extends State<AccountBookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonth = DateTime.now().month; // 현재 월로 초기화
  int _income = 700000; // 임시 수입 데이터
  int _expense = 200000; // 임시 지출 데이터

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
                        color: Colors.black, // 텍스트 색상 변경
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
            ),
          ),
          // 수입과 지출 지표 (한 줄로 출력)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            color: Colors.white, // 배경색을 흰색으로 설정
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 공간 균등 분배
              children: [
                // 수입
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '수입 ',
                        style: TextStyle(
                          color: Colors.black, // "수입" 텍스트 색상
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '${_income.toString()}원',
                        style: TextStyle(
                          color: Color(0xFF73AD13), // 가격 색상 (#73AD13)
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // 지출
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '지출 ',
                        style: TextStyle(
                          color: Colors.black, // "지출" 텍스트 색상
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '${_expense.toString()}원',
                        style: TextStyle(
                          color: Colors.red, // 가격 색상
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                NotloginListScreen(), // 내역 화면
                NotloginCalendarScreen(selectedMonth: _selectedMonth), // 선택된 월을 전달
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
                builder: (context) => const NotloginAddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}