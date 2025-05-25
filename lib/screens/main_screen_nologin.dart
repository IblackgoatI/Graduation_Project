import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'asset_detail_screen.dart'; // 자산 detail화면 import
import 'account_book_screen.dart'; // 가계부 화면 import
import 'community_screen.dart'; // 커뮤니티 화면 import
import 'all_screen.dart'; // 전체 화면 import
import 'asset.dart'; // 자산 화면 import (계좌 연결 화면)
import 'transaction_provider.dart'; // 트랜잭션 프로바이더 import
import 'transaction.dart'; // 트랜잭션 모델 import

class MainScreenNotLogin extends StatefulWidget {
  final User? user;
  const MainScreenNotLogin({super.key, this.user});
  
  // 최근 방문 탭 정보 가져오는 정적 메서드
  static List<Map<String, dynamic>> getRecentTabs() {
    return _MainScreenNotLoginState.recentTabs;
  }
  
  // 탭 전환 메서드 추가
  static void navigateToTab(BuildContext context, int index) {
    final mainScreenState = context.findAncestorStateOfType<_MainScreenNotLoginState>();
    if (mainScreenState != null) {
      mainScreenState.onItemTapped(index);
    }
  }

  @override
  State<MainScreenNotLogin> createState() => _MainScreenNotLoginState();
}

class _MainScreenNotLoginState extends State<MainScreenNotLogin> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _userAccounts = [];
  int _totalBalance = 0;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // 최근에 방문한 탭 저장 (최대 3개)
  static List<Map<String, dynamic>> recentTabs = [];
  
  // 탭 이름 매핑
  final List<String> tabNames = ['홈', '가계부', '커뮤니티', '전체'];
  final List<IconData> tabIcons = [
    Icons.home, 
    Icons.calendar_today, 
    Icons.people, 
    Icons.menu
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _loadUserAccounts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 사용자의 계좌 정보를 로드하는 메서드
  Future<void> _loadUserAccounts() async {
    // 로딩 시작
    setState(() {
      _isLoading = true;
    });

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
            _isLoading = false; // 로딩 완료
          });
        }
        debugPrint('_userAccounts.isNotEmpty: ${_userAccounts.isNotEmpty}');
        debugPrint('_userAccounts 내용: $_userAccounts');
        debugPrint('_isLoading 내용: $_isLoading');
      } else {
        // 사용자가 없는 경우 로딩 완료 처리
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('계좌 정보 로드 오류: $e');
      // 오류 발생 시에도 로딩 완료 처리
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    _animationController.reset();
    _animationController.forward();
    
    // 현재 선택하는 탭이 '전체' 탭이 아니면 최근 방문 탭에 추가
    if (index != 3) {
      // 최근 방문 탭에 현재 선택한 탭 추가
      _addToRecentTabs(index);
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }
  
  // 최근 방문 탭에 추가하는 메서드
  void _addToRecentTabs(int index) {
    // 이미 같은 탭이 있는지 확인
    int existingIndex = recentTabs.indexWhere((tab) => tab['index'] == index);
    
    // 있으면 목록에서 제거 (나중에 맨 앞에 다시 추가하기 위해)
    if (existingIndex != -1) {
      recentTabs.removeAt(existingIndex);
    }
    
    // 새 방문 기록 추가
    recentTabs.insert(0, {
      'index': index,
      'name': tabNames[index],
      'icon': tabIcons[index],
      'timestamp': DateTime.now(),
    });
    
    // 최대 3개만 유지
    if (recentTabs.length > 3) {
      recentTabs.removeLast();
    }
  }
  
  // 최근 방문 탭 목록을 가져오는 메서드 (다른 클래스에서 접근 가능)
  static List<Map<String, dynamic>> getRecentTabs() {
    return recentTabs;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = [
      _homeScreen(),
      const AccountBookScreen(),
      const CommunityScreen(),
      const AllScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _selectedIndex == 0
          ? AppBar(
        title: const Text('금융 대시보드'),
              backgroundColor: Colors.grey[50],
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: IndexedStack(
          key: ValueKey<int>(_selectedIndex),
          index: _selectedIndex,
          children: widgetOptions,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFFAAA1A1),
          backgroundColor: Colors.grey[50],
          elevation: 0,
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
            Row(
              children: [
                Icon(Icons.account_balance, color: Colors.green, size: 20),
                SizedBox(width: 8),
                const Text(
                  "입출금 계좌",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // 로딩 상태에 따라 다른 위젯 표시
            _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF73AD13),
              ),
            )
                : _userAccounts.isNotEmpty
                ? Column(
              children: _userAccounts.map((account) {
                debugPrint(account['bank'].toString());
                debugPrint(account['account'].toString());
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${account['account']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${numberFormat(account['balance'])}원",
                        style: const TextStyle(
                          fontSize: 14,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  "아직 자산이 연결되지 않았습니다.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16.0),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAssetsCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssetDetailScreen(
              user: widget.user ?? FirebaseAuth.instance.currentUser,
            ),
          ),
        ).then((_) => _loadUserAccounts());
      },
      child: SizedBox(
        width: double.infinity, // 부모 위젯의 너비에 맞춤
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.savings, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    const Text(
                      "총 자산 >",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF73AD13),
                  ),
                )
                    : _userAccounts.isNotEmpty
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "입출금계좌: ${numberFormat(_totalBalance)}원",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "자산 미연결",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      "아직 자산이 연결되지 않았습니다.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                if (!_isLoading && _userAccounts.isEmpty)
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssetScreen(
                              user: widget.user ?? FirebaseAuth.instance.currentUser,
                            ),
                          ),
                        ).then((returnedUser) {
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
        ),
      ),
    );
  }


  Widget _buildMonthlySpendingCard() {
    // 현재 월 가져오기
    final currentMonth = DateTime.now().month;
    
    // TransactionProvider에서 데이터 가져오기
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;
    
    // 현재 월의 지출 트랜잭션만 필터링
    final currentMonthExpenses = transactions.where((transaction) {
      return transaction.date.month == currentMonth && 
             transaction.date.year == DateTime.now().year && 
             transaction.type == '지출';
    }).toList();
    
    // 총 지출 금액 계산
    final totalExpense = currentMonthExpenses.fold(0.0, 
      (sum, transaction) => sum + transaction.amount);
    
    // 고정 지출 계산 (예: 매달 같은 금액으로 지출되는 카테고리만 계산)
    // 여기서는 예시로 '생활용품', '서비스' 카테고리를 고정 지출로 간주
    final fixedExpenseCategories = ['생활용품', '서비스', '교통', '의료'];
    final fixedExpenses = 0.0; // 고정 지출 금액을 0원으로 설정

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
              Row(
                children: [
                  Icon(Icons.trending_down, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  // 이번 달 지출 전체를 버튼으로 만들기
                  InkWell(
                    onTap: () {
                      // 가계부 탭으로 이동 (인덱스 1)
                      _onItemTapped(1);
                    },
                    child: Row(
                      children: [
                        const Text(
                          "이번 달 지출 ",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ">",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                "${numberFormat(totalExpense.toInt())}원",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20.0), // 섹션 간 간격
              Row(
                children: [
                  Icon(Icons.repeat, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      // 자산의 목표 탭으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssetDetailScreen(
                            initialTabIndex: 1, // 목표 탭 인덱스
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "나의 고정지출 >",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                "${numberFormat(fixedExpenses.toInt())}원",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case '식비':
        return Icons.restaurant;
      case '카페':
        return Icons.local_cafe;
      case '간식':
        return Icons.icecream;
      case '생활':
      case '생활용품':
        return Icons.home;
      case '쇼핑':
        return Icons.shopping_bag;
      case '뷰티':
      case '미용':
        return Icons.spa;
      case '교통':
        return Icons.directions_car;
      case '통신':
        return Icons.phone_android;
      case '문화':
      case '문화생활':
        return Icons.movie;
      case '교육':
        return Icons.school;
      case '만남':
        return Icons.people;
      case '의료':
        return Icons.local_hospital;
      case '여행':
        return Icons.flight;
      case '주거':
        return Icons.house;
      case '용돈':
        return Icons.attach_money;
      case '서비스':
        return Icons.miscellaneous_services;
      case '미분류':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }

  Widget _buildMonthlyReportCard() {
    // 현재 월 가져오기
    final currentMonth = DateTime.now().month;
    final monthInKorean = '$currentMonth월';

    // TransactionProvider에서 데이터 가져오기
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;
    
    // 현재 월의 지출 트랜잭션만 필터링
    final currentMonthExpenses = transactions.where((transaction) {
      return transaction.date.month == currentMonth && 
             transaction.date.year == DateTime.now().year && 
             transaction.type == '지출';
    }).toList();
    
    // 총 지출 금액 계산
    final totalExpense = currentMonthExpenses.fold(0.0, 
      (sum, transaction) => sum + transaction.amount);
    
    // 카테고리별 지출 금액 계산
    Map<String, double> categoryExpenses = {};
    for (var transaction in currentMonthExpenses) {
      if (categoryExpenses.containsKey(transaction.category)) {
        categoryExpenses[transaction.category] = 
          categoryExpenses[transaction.category]! + transaction.amount;
      } else {
        categoryExpenses[transaction.category] = transaction.amount;
      }
    }
    
    // 카테고리별 퍼센트 계산 및 정렬
    List<MapEntry<String, double>> sortedCategories = [];
    if (totalExpense > 0) {
      sortedCategories = categoryExpenses.entries.map((entry) {
        return MapEntry(entry.key, entry.value);
      }).toList();
      
      // 금액이 큰 순서대로 정렬
      sortedCategories.sort((a, b) => b.value.compareTo(a.value));
    }
    
    // 원형 차트 색상 매핑
    final Map<String, Color> categoryColors = {
      '식비': Colors.red[300]!,
      '쇼핑': Colors.pink[300]!,
      '교통': Colors.orange[300]!,
      '문화생활': Colors.purple[300]!,
      '의료': Colors.blue[300]!,
      '여행': Colors.amber[300]!,
      '용돈': Colors.teal[300]!,
      '생활용품': Colors.indigo[300]!,
      '서비스': Colors.lime[300]!,
      '미분류': Colors.grey[400]!,
    };
    
    // 카테고리별 아이콘 매핑
    final Map<String, IconData> categoryIcons = {
      '식비': Icons.restaurant,
      '쇼핑': Icons.shopping_bag,
      '교통': Icons.directions_car,
      '문화생활': Icons.movie,
      '의료': Icons.medical_services,
      '여행': Icons.flight,
      '용돈': Icons.attach_money,
      '생활용품': Icons.home,
      '서비스': Icons.miscellaneous_services,
      '미분류': Icons.help_outline,
    };

    // 표시할 카테고리 수를 관리하는 상태 변수
    bool _showAllCategories = false;
    
    return StatefulBuilder(
      builder: (context, setState) {
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
              Row(
                children: [
                  Icon(Icons.pie_chart, color: Colors.purple, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "부린이님의 $monthInKorean 소비 리포트",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
                  const SizedBox(height: 30.0), // 상단 여백 조정
              // 소비 그래프 영역
                  currentMonthExpenses.isNotEmpty 
                  ? SizedBox(
                      height: 180, // 그래프 컨테이너 높이 조정
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
                        children: [
                          // 차트와 범례를 Row로 배치
                          Row(
                            children: [
                              // 차트를 왼쪽에 배치
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 150, // 차트 높이 조정
                                  child: Center(
                                    child: PieChart(
                                      PieChartData(
                                        sections: sortedCategories.map((entry) {
                                          final percent = (entry.value / totalExpense) * 100;
                                          final index = sortedCategories.indexOf(entry);
                                          // 고정된 색상 목록에서 순서대로 색상 할당 (색상이 부족하면 순환)
                                          final colors = [
                                            Colors.red[300]!,
                                            Colors.pink[300]!,
                                            Colors.orange[300]!,
                                            Colors.purple[300]!,
                                            Colors.blue[300]!,
                                            Colors.amber[300]!,
                                            Colors.teal[300]!,
                                            Colors.indigo[300]!,
                                            Colors.lime[300]!,
                                            Colors.green[300]!,
                                            Colors.cyan[300]!,
                                            Colors.brown[300]!,
                                          ];
                                          final color = colors[index % colors.length];
                                          return PieChartSectionData(
                                            color: color,
                                            value: entry.value,
                                            title: '${percent.toStringAsFixed(1)}%',
                                            radius: 50,
                                            titleStyle: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          );
                                        }).toList(),
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // 범례를 오른쪽에 배치
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: sortedCategories.take(4).map((entry) {
                                      final index = sortedCategories.indexOf(entry);
                                      final colors = [
                                        Colors.red[300]!,
                                        Colors.pink[300]!,
                                        Colors.orange[300]!,
                                        Colors.purple[300]!,
                                        Colors.blue[300]!,
                                        Colors.amber[300]!,
                                        Colors.teal[300]!,
                                        Colors.indigo[300]!,
                                        Colors.lime[300]!,
                                        Colors.green[300]!,
                                        Colors.cyan[300]!,
                                        Colors.brown[300]!,
                                      ];
                                      final color = colors[index % colors.length];
                                      final percent = (entry.value / totalExpense) * 100;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          children: [
              Container(
                                              width: 12,
                                              height: 12,
                                              color: color,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              entry.key,
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${percent.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Container(
                      height: 150,
                decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Center(
                  child: Text(
                          "이번 달 소비 내역이 없습니다",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
                  const SizedBox(height: 30.0), // 하단 여백 조정
                  // 현재 월 총 소비
                  Center(
                    child: Text(
                      "$monthInKorean 총 소비 ${numberFormat(totalExpense.toInt())}원",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Divider(),
                  const SizedBox(height: 16.0), // 구분선과 카테고리 상세 사이 간격 추가
                  // 카테고리별 지출 내역
                  if (currentMonthExpenses.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    AnimatedCrossFade(
                      firstChild: Column(
                        children: sortedCategories.take(4).map((entry) {
                          final categoryName = entry.key;
                          final amount = entry.value;
                          final percent = (amount / totalExpense) * 100;
                          final icon = getCategoryIcon(categoryName);
                          final index = sortedCategories.indexOf(entry);
                          final colors = [
                            Colors.red[300]!,
                            Colors.pink[300]!,
                            Colors.orange[300]!,
                            Colors.purple[300]!,
                            Colors.blue[300]!,
                            Colors.amber[300]!,
                            Colors.teal[300]!,
                            Colors.indigo[300]!,
                            Colors.lime[300]!,
                            Colors.green[300]!,
                            Colors.cyan[300]!,
                            Colors.brown[300]!,
                          ];
                          final color = colors[index % colors.length];
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        categoryName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '${percent.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${numberFormat(amount.toInt())}원',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      secondChild: Column(
                        children: sortedCategories.map((entry) {
                          final categoryName = entry.key;
                          final amount = entry.value;
                          final percent = (amount / totalExpense) * 100;
                          final icon = getCategoryIcon(categoryName);
                          final index = sortedCategories.indexOf(entry);
                          final colors = [
                            Colors.red[300]!,
                            Colors.pink[300]!,
                            Colors.orange[300]!,
                            Colors.purple[300]!,
                            Colors.blue[300]!,
                            Colors.amber[300]!,
                            Colors.teal[300]!,
                            Colors.indigo[300]!,
                            Colors.lime[300]!,
                            Colors.green[300]!,
                            Colors.cyan[300]!,
                            Colors.brown[300]!,
                          ];
                          final color = colors[index % colors.length];
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        categoryName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '${percent.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${numberFormat(amount.toInt())}원',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      crossFadeState: _showAllCategories ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                    if (sortedCategories.length > 4)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            // 현재 상태를 반대로 전환
                            setState(() {
                              _showAllCategories = !_showAllCategories;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _showAllCategories ? '접기' : '더보기',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _showAllCategories ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ],
                  ),
                ),
              ),
                  ] else
              const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                          "가계부에 지출 내역을 추가해보세요",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
        );
      }
    );
  }

  // 숫자 포맷 함수 (천 단위 콤마 추가)
  String numberFormat(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // 외부에서 접근 가능한 public 메서드
  void onItemTapped(int index) {
    _onItemTapped(index);
  }
}