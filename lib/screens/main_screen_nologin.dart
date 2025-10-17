/// 로그인하지 않은 사용자를 위한 메인 화면 (또는 초기 로그인 시 진입 화면)
/// 다양한 금융 관련 탭 (대시보드, 가계부, 커뮤니티, 전체 기능)을 제공하며, 최근 방문 탭을 관리합니다.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'asset_detail_screen.dart'; // 자산 detail화면 import
import 'account_book_screen.dart'; // 가계부 화면 import
import 'community_screen.dart'; // 커뮤니티 화면 import
import 'all_screen.dart'; // 전체 화면 import
import 'asset.dart'; // 자산 화면 import (계좌 연결 화면)
import 'transaction_provider.dart'; // 트랜잭션 프로바이더 import
import 'transaction.dart'; // 트랜잭션 모델 import
import 'goal_management.dart'; // 목표 관리 화면 import

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

class _MainScreenNotLoginState extends State<MainScreenNotLogin> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _userAccounts = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late ScrollController _scrollController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;
  int currentMonth = DateTime.now().month;
  List<int> availableMonths = [];
  bool _showAllCategories = false; // 더보기 상태를 클래스 레벨로 이동
  String _userName = ''; // 사용자 이름을 저장할 변수 추가
  bool _isHeaderCollapsed = false; // 헤더 축소 상태
  
  // 목표 관련 상태 변수 추가
  List<Map<String, dynamic>> _goalList = [];
  Map<String, int> _accountBalances = {};
  bool _isLoadingGoals = false;
  
  // 월별 리포트 상태를 저장하는 Map
  final Map<BuildContext, int> _monthlyReportYearMonth = {};
  
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
    
    // 스크롤 컨트롤러 초기화
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // 헤더 애니메이션 컨트롤러 초기화
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOutQuart,
    ));
    
    _loadUserAccounts();
    _loadUserName(); // 사용자 이름 로드 함수 호출
    _loadGoalData(); // 목표 데이터 로드 함수 호출
    
    // 초기 거래 내역이 있는 월 목록 계산
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMonthData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _headerAnimationController.dispose();
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

  // 사용자 이름을 로드하는 함수 추가
  Future<void> _loadUserName() async {
    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Firestore에서 사용자 정보 가져오기
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            // 사용자 문서에서 이름 필드를 가져옴
            _userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? '사용자';
          });
        } else {
          // Firestore에 사용자 정보가 없는 경우 Auth 디스플레이네임 사용
          setState(() {
            _userName = currentUser.displayName ?? '사용자';
          });
        }
      }
    } catch (e) {
      debugPrint('사용자 이름 로드 오류: $e');
      setState(() {
        _userName = '사용자';
      });
    }
  }

  // 목표 데이터 로드 함수
  Future<void> _loadGoalData() async {
    try {
      setState(() {
        _isLoadingGoals = true;
      });

      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // goal 컬렉션에서 현재 사용자의 모든 목표 조회
        QuerySnapshot goalQuery = await FirebaseFirestore.instance
            .collection('goal')
            .where('userId', isEqualTo: currentUser.uid)
            .get();

        List<Map<String, dynamic>> goalList = [];
        Map<String, int> accountBalances = {};

        if (goalQuery.docs.isNotEmpty) {
          // 각 목표에 대해 계좌 잔액 조회
          for (var doc in goalQuery.docs) {
            Map<String, dynamic> goalData = doc.data() as Map<String, dynamic>;
            String? bankId = goalData['bank'];
            
            // bank 필드가 있으면 assets 컬렉션에서 잔액 조회
            if (bankId != null) {
              try {
                DocumentSnapshot assetDoc = await FirebaseFirestore.instance
                    .collection('assets')
                    .doc(bankId)
                    .get();
                
                if (assetDoc.exists) {
                  Map<String, dynamic> assetData = assetDoc.data() as Map<String, dynamic>;
                  accountBalances[bankId] = (assetData['balance'] as num?)?.toInt() ?? 0;
                } else {
                  accountBalances[bankId] = 0;
                }
              } catch (e) {
                debugPrint('은행 정보 조회 오류: $e');
                accountBalances[bankId] = 0;
              }
            }
            
            goalList.add(goalData);
          }
        }

        if (mounted) {
          setState(() {
            _goalList = goalList;
            _accountBalances = accountBalances;
            _isLoadingGoals = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingGoals = false;
          });
        }
      }
    } catch (e) {
      debugPrint('목표 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingGoals = false;
        });
      }
    }
  }

  // 목표 달성 퍼센트 계산 함수
  double _calculateProgressPercentage(Map<String, dynamic> goalData) {
    String? bankId = goalData['bank'];
    if (bankId == null || !_accountBalances.containsKey(bankId)) return 0.0;
    
    int goalAmount = (goalData['amount'] as num?)?.toInt() ?? 0;
    if (goalAmount == 0) return 0.0;
    
    int currentBalance = _accountBalances[bankId] ?? 0;
    
    // 목표 설정 시점의 잔액 (목표 데이터에서 가져오거나 기본값 0 사용)
    int initialBalance = (goalData['initialBalance'] as num?)?.toInt() ?? 0;
    
    // 현재 잔액에서 초기 잔액을 뺀 증가 금액
    int increasedAmount = currentBalance - initialBalance;
    
    // 증가 금액이 목표 금액에 비해 얼마나 달성되었는지 계산
    double percentage = (increasedAmount / goalAmount) * 100;
    
    // 100%를 넘지 않도록 제한
    return percentage > 100 ? 100.0 : (percentage < 0 ? 0.0 : percentage);
  }

  // 금액 포맷팅 함수
  String _formatAmount(dynamic amount) {
    if (amount == null) return '0원';
    
    int amountInt = (amount as num).toInt();
    return numberFormat(amountInt) + '원';
  }

  // 증가한 금액 계산 함수
  int _getIncreasedAmount(Map<String, dynamic> goalData) {
    String? bankId = goalData['bank'];
    if (bankId == null || !_accountBalances.containsKey(bankId)) return 0;
    
    int currentBalance = _accountBalances[bankId] ?? 0;
    int initialBalance = (goalData['initialBalance'] as num?)?.toInt() ?? 0;
    
    int increasedAmount = currentBalance - initialBalance;
    return increasedAmount < 0 ? 0 : increasedAmount; // 음수인 경우 0 반환
  }


  // 월별 데이터 초기화 메서드 추가
  void _initializeMonthData() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final transactions = transactionProvider.transactions;
    
    debugPrint('Initializing month data...'); // 디버깅 로그
    debugPrint('Total transactions available: ${transactions.length}'); // 디버깅 로그
    
    // 현재 연도의 지출 거래만 필터링
    final currentYear = DateTime.now().year;
    final thisYearTransactions = transactions.where(
      (t) => t.date.year == currentYear && t.type == '지출'
    ).toList();
    
    debugPrint('Transactions for $currentYear: ${thisYearTransactions.length}'); // 디버깅 로그
    
    // 월별로 그룹화
    Map<int, List<FinancialTransaction>> monthlyTransactions = {};
    for (var transaction in thisYearTransactions) {
      final month = transaction.date.month;
      monthlyTransactions[month] = monthlyTransactions[month] ?? [];
      monthlyTransactions[month]!.add(transaction);
    }
    
    // 거래가 있는 월만 정렬하여 저장
    List<int> sortedMonths = monthlyTransactions.keys.toList()..sort();
    debugPrint('Available months with transactions: $sortedMonths'); // 디버깅 로그
    
    setState(() {
      availableMonths = sortedMonths;
      // 현재 월에 데이터가 없다면 가장 최근 데이터가 있는 월로 설정
      if (!sortedMonths.contains(currentMonth) && sortedMonths.isNotEmpty) {
        currentMonth = sortedMonths.last;
        debugPrint('Setting current month to most recent: $currentMonth'); // 디버깅 로그
      }
    });
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
          ? _buildCustomHeader()
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

  // 동적 헤더 구성
  PreferredSizeWidget _buildCustomHeader() {
    return PreferredSize(
      preferredSize: Size.fromHeight(_isHeaderCollapsed ? 60 : 100),
      child: AnimatedBuilder(
        animation: _headerAnimation,
        builder: (context, child) {
          // 연속적인 애니메이션 값으로 부드러운 전환
          double animationValue = _headerAnimation.value;
          double currentTopPadding = 40 - (20 * animationValue); // 40에서 20으로
          double currentBottomPadding = 16 - (4 * animationValue); // 16에서 12로
          double currentFontSize = 22 - (4 * animationValue); // 22에서 18로
          
          return Container(
            padding: EdgeInsets.fromLTRB(
              20, 
              currentTopPadding, 
              20, 
              currentBottomPadding
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: animationValue > 0.5 
              ? // 축소된 상태: 중앙 정렬
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 사용자 이름
                    Text(
                      '${_userName.isNotEmpty ? _userName : '사용자'}님',
                      style: TextStyle(
                        fontSize: currentFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    // 날짜
                    Text(
                      DateFormat('M월 d일', 'ko_KR').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : // 확장된 상태: 기존 레이아웃
              Row(
                children: [
                  // 왼쪽: 사용자 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 사용자 이름
                        Text(
                          '${_userName.isNotEmpty ? _userName : '사용자'}님',
                          style: TextStyle(
                            fontSize: currentFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        // 동기 부여 문구 (연속적인 투명도)
                        Opacity(
                          opacity: 1 - animationValue,
                          child: Column(
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                '오늘도 목표를 향해 달려볼까요?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 오른쪽: 날짜
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('M월 d일 EEEE', 'ko_KR').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          );
        },
      ),
    );
  }

  // 홈 화면을 별도의 메서드로 정의
  Widget _homeScreen() {
    return RefreshIndicator(
      onRefresh: _loadUserAccounts,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTopCategories(),
            const SizedBox(height: 16.0),
            _buildAccountCard(),
            const SizedBox(height: 16.0),
            _buildLumpSumCard(),
            const SizedBox(height: 16.0),
            _buildMonthlyReportCard(),
            const SizedBox(height: 16.0),
            _buildAIAnalysisCard(),
          ],
        ),
      ),
    );
  }

  // 상단 4개 카테고리 버튼을 만드는 메서드
  Widget _buildTopCategories() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryButton(
                  icon: Icons.savings,
                  label: '계좌 관리',
                  color: Colors.blue,
                  onTap: () {
                    // 저축 설정 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetDetailScreen(
                          initialTabIndex: 0,
                        ),
                      ),
                    );
                  },
                ),
                _buildCategoryButton(
                  icon: Icons.repeat,
                  label: '목표 관리',
                  color: Colors.orange,
                  onTap: () {
                    // 목표 관리 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildCategoryButton(
                  icon: Icons.account_balance_wallet,
                  label: '금융 지식',
                  color: Colors.green,
                  onTap: () {
                    // 예산 설정 화면으로 이동 (추후 구현)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('예산 설정 기능은 준비 중입니다')),
                    );
                  },
                ),
                _buildCategoryButton(
                  icon: Icons.account_balance,
                  label: 'AI 분석',
                  color: Colors.purple,
                  onTap: () {
                    // 계좌 추가 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetScreen(
                          user: widget.user ?? FirebaseAuth.instance.currentUser,
                          previousRouteName: 'main_screen_nologin',
                        ),
                      ),
                    ).then((returnedUser) {
                      _loadUserAccounts();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 개별 카테고리 버튼을 만드는 메서드
  Widget _buildCategoryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 목표 현황 카드를 만드는 메서드
  Widget _buildLumpSumCard() {
    // 첫 번째 목표를 사용 (여러 목표가 있는 경우 첫 번째만 표시)
    Map<String, dynamic>? firstGoal = _goalList.isNotEmpty ? _goalList.first : null;
    
    return Card(
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
                Icon(Icons.savings, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "목표 현황",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    // 목표 관리 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalManagementScreen(),
                      ),
                    ).then((_) {
                      // 목표 관리 화면에서 돌아온 후 데이터 새로고침
                      _loadGoalData();
                    });
                  },
                  child: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // 목표가 있는 경우와 없는 경우를 구분하여 표시
            if (_isLoadingGoals)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.teal,
                ),
              )
            else if (firstGoal != null) ...[
              // 목표가 있는 경우
              Row(
                children: [
                  Text(
                    _formatAmount(_getIncreasedAmount(firstGoal)),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${_calculateProgressPercentage(firstGoal).toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              LinearProgressIndicator(
                value: _calculateProgressPercentage(firstGoal) / 100,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                minHeight: 8,
              ),
            ] else ...[
              // 목표가 없는 경우
              Row(
                children: [
                  Text(
                    "0원",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "0%",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              LinearProgressIndicator(
                value: 0.0,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                minHeight: 8,
              ),
              const SizedBox(height: 8.0),
              Text(
                "목표를 설정해주세요",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // AI 분석 카드를 만드는 메서드
  Widget _buildAIAnalysisCard() {
    return Card(
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
                Icon(Icons.psychology, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "AI 분석",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              ],
            ),
            const SizedBox(height: 16.0),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 40,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "AI 분석 기능 준비 중",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                            previousRouteName: 'main_screen_nologin', // 이전 경로 이름 전달
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
    // TransactionProvider에서 데이터 가져오기
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;
    
    // 현재 연도의 지출 거래만 필터링
    final thisYearTransactions = transactions.where(
      (t) => t.type == '지출'
    ).toList();
    
    // 월별로 그룹화하여 데이터가 있는 월만 찾기
    Map<int, List<FinancialTransaction>> monthlyTransactions = {};
    for (var transaction in thisYearTransactions) {
      final month = transaction.date.month;
      final year = transaction.date.year;
      final key = year * 100 + month; // 예: 202404
      monthlyTransactions[key] = monthlyTransactions[key] ?? [];
      monthlyTransactions[key]!.add(transaction);
    }
    
    // 데이터가 있는 연월을 정렬
    List<int> availableYearMonths = monthlyTransactions.keys.toList()..sort();
    if (availableYearMonths.isEmpty) {
      return _buildEmptyReportCard();
    }
    
    // 가장 최근 데이터의 연월을 기본값으로 설정
    int initialYearMonth = availableYearMonths.last;

    return StatefulBuilder(
      builder: (context, setState) {
        // 상태 변수들을 클래스 레벨로 이동
        if (!_monthlyReportYearMonth.containsKey(context)) {
          _monthlyReportYearMonth[context] = initialYearMonth;
        }
        
        int selectedYearMonth = _monthlyReportYearMonth[context]!;

        // 현재 선택된 월의 데이터
        final selectedMonthData = monthlyTransactions[selectedYearMonth] ?? [];
        
        // 선택된 연월에서 월 추출
        final selectedMonth = selectedYearMonth % 100;
        
        // 총 지출 금액 계산
        final totalExpense = selectedMonthData.fold(0.0, 
          (sum, transaction) => sum + transaction.amount);
        
        // 카테고리별 지출 금액 계산
        Map<String, double> categoryExpenses = {};
        for (var transaction in selectedMonthData) {
          categoryExpenses.update(
            transaction.category,
            (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount
          );
        }
        
        // 카테고리 정렬
        final sortedCategories = categoryExpenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        // 이전/다음 월 이동 가능 여부 확인
        final currentIndex = availableYearMonths.indexOf(selectedYearMonth);
        final canGoToPrevious = currentIndex > 0;
        final canGoToNext = currentIndex < availableYearMonths.length - 1;

        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 월 선택 UI
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 이전 월 버튼
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: canGoToPrevious ? Colors.black54 : Colors.grey[300],
                      ),
                      onPressed: canGoToPrevious ? () {
                        setState(() {
                          _monthlyReportYearMonth[context] = availableYearMonths[currentIndex - 1];
                        });
                      } : null,
                    ),
                    // 중앙 제목
                    Text(
                      "$_userName님의 $selectedMonth월 소비 리포트",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // 다음 월 버튼
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: canGoToNext ? Colors.black54 : Colors.grey[300],
                      ),
                      onPressed: canGoToNext ? () {
                        setState(() {
                          _monthlyReportYearMonth[context] = availableYearMonths[currentIndex + 1];
                        });
                      } : null,
                    ),
                  ],
                ),
                const SizedBox(height: 30.0),
                
                // 소비 그래프 영역
                selectedMonthData.isNotEmpty 
                ? SizedBox(
                    height: 180,
                    child: Row(
                      children: [
                        // 차트를 왼쪽에 배치
                        Expanded(
                          flex: 3,
                          child: PieChart(
                            PieChartData(
                              sections: sortedCategories.map((entry) {
                                final percent = (entry.value / totalExpense) * 100;
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
                  )
                : Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Center(
                      child: Text(
                        "$selectedMonth월 소비 내역이 없습니다",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                const SizedBox(height: 30.0),
                
                // 총 소비 금액
                Center(
                  child: Text(
                    "$selectedMonth월 총 소비 ${numberFormat(totalExpense.toInt())}원",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                const Divider(),
                const SizedBox(height: 16.0),
                
                // 카테고리별 지출 내역
                if (selectedMonthData.isNotEmpty) ...[
                  const SizedBox(height: 8.0),
                  ...(_showAllCategories ? sortedCategories : sortedCategories.take(4))
                    .map((entry) {
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
                                color: color.withAlpha((0.2 * 255).round()),
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
                    }),
                  if (sortedCategories.length > 4)
                    Center(
                      child: TextButton(
                        onPressed: () {
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
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyReportCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "소비 리포트",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Center(
                child: Text(
                  "가계부에 지출 내역을 추가해보세요",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
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

  // 스크롤 감지 메서드
  void _onScroll() {
    const double threshold = 50.0; // 스크롤 임계값
    const double maxScroll = 100.0; // 최대 스크롤값
    
    // 스크롤 위치에 따른 연속적인 애니메이션 값 계산
    double scrollProgress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    
    // 헤더 축소 상태 업데이트
    bool shouldCollapse = _scrollController.offset > threshold;
    if (shouldCollapse != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = shouldCollapse;
      });
    }
    
    // 연속적인 애니메이션 값 설정 (스크롤할 때 1에 가까워짐)
    _headerAnimationController.value = scrollProgress;
  }

  // 외부에서 접근 가능한 public 메서드
  void onItemTapped(int index) {
    _onItemTapped(index);
  }
}