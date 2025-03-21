import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'account_book_screen.dart'; // 가계부 화면 import
import 'community_screen.dart'; // 커뮤니티 화면 import
import 'all_screen.dart'; // 전체 화면 import
import 'asset.dart'; // 자산 화면 import (계좌 연결 화면)

class MainScreenNotLogin extends StatefulWidget {
  final User? user;
  const MainScreenNotLogin({super.key, this.user});

  @override
  State<MainScreenNotLogin> createState() => _MainScreenNotLoginState();
}

class _MainScreenNotLoginState extends State<MainScreenNotLogin> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _userAccounts = [];
  int _totalBalance = 0;

  // late로 선언
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // initState에서 초기화
    _widgetOptions = [
      _homeScreen(), // 홈 화면
      const AccountBookScreen(), // 가계부 화면
      const CommunityScreen(), // 커뮤니티 화면
      const AllScreen(), // 전체 화면
    ];

    // 사용자 계좌 정보 로드
    _loadUserAccounts();
  }

  // 사용자의 계좌 정보를 로드하는 메서드
  Future<void> _loadUserAccounts() async {
    try {
      // 전달받은 사용자 정보가 있으면 사용하고, 없으면 현재 로그인한 사용자 정보 가져오기
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Firestore에서 전달받은 사용자의 계좌 정보 가져오기
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('assets')
            .where('userId', isEqualTo: currentUser.uid)
            .get();

        List<Map<String, dynamic>> accounts = [];
        int totalBalance = 0;

        // 결과를 리스트로 변환
        for (var doc in querySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          accounts.add({
            'id': doc.id,
            'bank': data['bank'],
            'account': data['account'],
            'balance': data['balance'],
          });

          // 총 자산 계산
          totalBalance += (data['balance'] as num).toInt();
          debugPrint('사용자 계좌 정보: ${data['bank']} - ${data['account']}');
        }
        debugPrint('총 계좌 수: ${accounts.length}');
        debugPrint('총 잔액: $totalBalance');

        // 상태 업데이트
        if (mounted) {
          setState(() {
            _userAccounts = accounts;
            _totalBalance = totalBalance;
          });
        }
      }
    } catch (e) {
      debugPrint('계좌 정보 로드 오류: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
        title: const Text('금융 대시보드'),
      )
          : null, // 메인 화면에서만 AppBar 표시
      body: _widgetOptions[_selectedIndex], // 선택된 탭에 해당하는 화면 표시
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFFAAA1A1),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/home.svg',
              colorFilter: ColorFilter.mode(
                _selectedIndex == 0 ? Colors.black : const Color(0xFFAAA1A1),
                BlendMode.srcIn,
              ),
            ),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/calendar.svg',
              colorFilter: ColorFilter.mode(
                _selectedIndex == 1 ? Colors.black : const Color(0xFFAAA1A1),
                BlendMode.srcIn,
              ),
            ),
            label: '가계부',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/Community.svg',
              colorFilter: ColorFilter.mode(
                _selectedIndex == 2 ? Colors.black : const Color(0xFFAAA1A1),
                BlendMode.srcIn,
              ),
            ),
            label: '커뮤니티',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/menu.svg',
              colorFilter: ColorFilter.mode(
                _selectedIndex == 3 ? Colors.black : const Color(0xFFAAA1A1),
                BlendMode.srcIn,
              ),
            ),
            label: '전체',
          ),
        ],
      ),
    );
  }

  // 홈 화면을 별도의 메서드로 정의
  Widget _homeScreen() {
    return RefreshIndicator(
      onRefresh: _loadUserAccounts,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAccountCard(),
            const SizedBox(height: 16.0),
            _buildTotalAssetsCard(),
            const SizedBox(height: 16.0),
            _buildMonthlySpendingCard(),
            const SizedBox(height: 16.0),
            _buildMonthlyReportCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0), // 모서리 반경을 20으로 설정
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "입출금 계좌",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            // 계좌 목록 또는 계좌 연결 버튼
            _userAccounts.isNotEmpty
                ? Column(
              children: _userAccounts.map((account) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${account['bank']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${account['account']}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${numberFormat(account['balance'])}원",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "계좌 미연결",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  "아직 자산이 연결되지 않았습니다.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // 계좌 연결하기 버튼 동작
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssetScreen(
                        user: widget.user ?? FirebaseAuth.instance.currentUser,
                      ),
                    ),
                  ).then((returnedUser) {
                    // 화면 복귀 시 계좌 정보 다시 로드
                    _loadUserAccounts();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF73AD13),
                  minimumSize: const Size(400, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _userAccounts.isNotEmpty ? "계좌 추가하기" : "계좌 연결하러 가기",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAssetsCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0), // 모서리 반경을 20으로 설정
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "총 자산",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            _userAccounts.isNotEmpty
                ? Text(
              "${numberFormat(_totalBalance)}원",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "자산 미연결",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  "아직 자산이 연결되지 않았습니다.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
            if (_userAccounts.isEmpty)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // 계좌 연결하기 버튼 동작
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetScreen(
                          user: widget.user ?? FirebaseAuth.instance.currentUser,
                        ),
                      ),
                    ).then((returnedUser) {
                      // 화면 복귀 시 계좌 정보 다시 로드
                      _loadUserAccounts();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF73AD13),
                    minimumSize: const Size(400, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "계좌 연결하러 가기",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySpendingCard() {
    return SizedBox(
      width: double.infinity, // 부모 위젯의 너비에 맞춤
      child: Card(
        color: Colors.white, // 카드뷰 배경색을 FFFFFF(흰색)로 설정
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // 모서리 반경을 20으로 설정
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 기존 카드뷰와 동일한 패딩 적용
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "이번 달 지출 >",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              const Text(
                "0원",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20.0), // 섹션 간 간격
              const Text(
                "나의 고정지출 >",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              const Text(
                "0원",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyReportCard() {
    return SizedBox(
      width: double.infinity, // 부모 위젯의 너비에 맞춤
      child: Card(
        color: Colors.white, // 카드뷰 배경색을 FFFFFF(흰색)로 설정
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // 모서리 반경을 20으로 설정
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "부린이님의 1월 소비 리포트",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20.0),
              // 소비 그래프 영역
              Container(
                height: 150, // 그래프 높이
                decoration: BoxDecoration(
                  color: Colors.grey[200], // 그래프 배경색 (임시)
                  borderRadius: BorderRadius.circular(12.0), // 그래프 모서리 둥글기
                ),
                child: const Center(
                  child: Text(
                    "소비 그래프 영역",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              // 1월 총 소비 (부드러운 밑줄 추가)
              const Center(
                child: Text(
                  "1월 총 소비 0원",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.underline, // 밑줄 추가
                    decorationStyle: TextDecorationStyle.solid, // 부드러운 밑줄
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              // "아직 이번 달 소비 내역이 없습니다." (가운데 정렬)
              const Center(
                child: Text(
                  "아직 이번 달 소비 내역이 없습니다.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 숫자 포맷 함수 (천 단위 콤마 추가)
  String numberFormat(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}