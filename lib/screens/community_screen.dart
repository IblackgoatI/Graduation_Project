import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        title: const Text('부린이님',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 탭바
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: Colors.black,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: '게시판'),
              Tab(text: '지출 비교'),
            ],
          ),

          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 게시판 탭
                _buildBoardContent(),

                // 지출 비교 탭 - 새로운 구현으로 교체하세요
                const ExpenseComparisonTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 기존 나머지 코드...
  Widget _buildBoardContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 월간 절약왕 TOP 3
            _buildTopSaverSection(),
            const SizedBox(height: 24),

            // 20대 부린이님을 위한 커뮤니티
            _buildCommunitySection(),
            const SizedBox(height: 24),

            // 소비 리포트 공유하기 버튼
            _buildShareButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSaverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '월간 절약왕 TOP 3',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRankingItem(1, '대부린', '😊'),
        _buildRankingItem(2, '부린이', '🙂'),
        _buildRankingItem(3, '부린2', '😎'),
      ],
    );
  }

  Widget _buildRankingItem(int rank, String name, String emoji) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BC34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('정보 보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '20대 부린이님을 위한 커뮤니티',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPostItem(
          profileImage: 'assets/profile1.jpg',
          nickname: '보노보노',
          timeAgo: '11시간 전',
          content:
          '이번 달 식비 절약 성공! 여러분도 해보세요 😄\n인스타해요. 머리부터 발끝까지 소비를 줄여보려고 콘텐츠 새봤고 실\n단체할인, 셋끼니 다 잘짜 골라서 14만 9천원에 완료했습니다.\n➡️ 마지막 식비 절약 꿀팁\n1.집 주식만 미리 계획하기\n✓ 효율적으로 외식까지도 배달용 서비스는 절 중이기 위해...',
        ),
        const SizedBox(height: 16),
        _buildPostItem(
          profileImage: 'assets/profile2.jpg',
          nickname: '케이마',
          timeAgo: '13시간 전',
          content:
          '이번 달 용돈비용 절약 성공! 👏🏼\n이번 달엔 조금 더 신경써서 소비했는데 마음으로 계획대로 쭉이\n했어요. 월리가 낮아지려면 습관화 해야겠죠!\n✨ 이번 달 가계부 정리 방법\n1.돈과 가치까지 기다리기🔍\n✓ 사고 싶은 제품이 있었지만 바로 지르지 않고, 세일 기간을...',
        ),
      ],
    );
  }

  Widget _buildPostItem({
    required String profileImage,
    required String nickname,
    required String timeAgo,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(profileImage),
                onBackgroundImageError: (exception, stackTrace) {
                  // 이미지 로드 실패 시 기본 아이콘 표시
                  debugPrint('이미지 로드 오류: $exception');
                },
                child: const Icon(Icons.person), // 기본 아이콘
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '더보기',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8BC34A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          '소비 리포트 공유하기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ExpenseComparisonTab 클래스 포함
class ExpenseComparisonTab extends StatefulWidget {
  const ExpenseComparisonTab({Key? key}) : super(key: key);

  @override
  State<ExpenseComparisonTab> createState() => _ExpenseComparisonTabState();
}

class _ExpenseComparisonTabState extends State<ExpenseComparisonTab>
    with SingleTickerProviderStateMixin {
  // 선택된 카테고리
  String selectedCategory = '식비';
  
  // 애니메이션 컨트롤러 추가
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 현재 사용자의 지출 합계
  double mySumAmount = 0;

  // 연령대 선택
  Map<String, bool> ageGroups = {
    '10대': true,
    '20대': false,
    '30대': false,
    '40대': false,
    '50대': false,
    '60대': false,
    '70대': false,
  };

  // 성별 선택
  Map<String, bool> genderGroups = {
    '남': true,
    '여': false,
  };

  // 소득 선택
  Map<String, bool> incomeGroups = {
    '월 200이하': true,
    '월 200~300': false,
    '월 300~400': false,
    '월 400~550': false,
    '월 550~700': false,
    '월 700~850': false,
    '월 850~1000': false,
    '월 1000이상': false,
  };

  // 예시 지출 데이터
  Map<String, double> myExpense = {
    '통신비': 38000,
    '식비': 450000,
    '카페': 120000,
    '간식': 80000,
    '생활': 250000,
    '쇼핑': 320000,
    '미용': 150000,
    '교통': 85000,
    '교육': 100000,
    '통신': 38000,
    '문화': 78000,
  };

  Map<String, double> averageExpense = {
    '식비': 55000,
    '카페': 520000,
    '간식': 180000,
    '생활': 95000,
    '쇼핑': 280000,
    '뷰티': 450000,
    '교통': 200000,
    '통신': 95000,
    '문화': 150000,
    '교육': 55000,
    '만남': 120000,
  };

  // 카테고리 목록
  List<String> categories = [
    '식비',
    '카페',
    '간식',
    '생활',
    '쇼핑',
    '뷰티',
    '교통',
    '통신',
    '문화',
    '교육',
    '만남',
  ];

  @override
  void initState() {
    super.initState();
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // 초기 카테고리에 대한 합계 계산
    mySum(selectedCategory);
    // 초기 나이대, 성별 기준 평균 계산
    ageSexCompare();
    // 초기 소득 구간 기준 평균 계산
    incomeCompare();
    
    // 초기 애니메이션 시작
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 카테고리 변경 시 애니메이션 재시작 메서드
  void _resetAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  // Firestore에서 사용자의 지출 합계를 계산하는 함수
  Future<void> mySum(String category) async {
    try {
      // 현재 로그인한 사용자 ID 가져오기
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print('사용자가 로그인되어 있지 않습니다.');
        return;
      }

      String userId = currentUser.uid;

      // Firestore 쿼리 실행
      QuerySnapshot querySnapshot = await _firestore
          .collection('ledger')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .get();

      // amount 필드 값 합산
      double sum = 0;
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('amount')) {
          sum += (data['amount'] as num).toDouble();
        }
      }

      // 상태 업데이트
      setState(() {
        mySumAmount = sum;
        // myExpense 맵도 업데이트
        myExpense[category] = sum;
      });

      print('카테고리 $category의 총 지출: $sum');
    } catch (e) {
      print('데이터 가져오기 오류: $e');
    }
  }

  // 선택된 나이대와 성별에 따른 평균 지출 계산 함수
  Future<void> ageSexCompare() async {
    try {
      // 선택된 나이대 범위 계산
      String selectedAgeGroup = ageGroups.entries.firstWhere((entry) => entry.value).key;
      int minAge = 0;
      int maxAge = 0;

      if (selectedAgeGroup == '10대') {
        minAge = 10;
        maxAge = 19;
      } else if (selectedAgeGroup == '20대') {
        minAge = 20;
        maxAge = 29;
      } else if (selectedAgeGroup == '30대') {
        minAge = 30;
        maxAge = 39;
      } else if (selectedAgeGroup == '40대') {
        minAge = 40;
        maxAge = 49;
      } else if (selectedAgeGroup == '50대') {
        minAge = 50;
        maxAge = 59;
      } else if (selectedAgeGroup == '60대') {
        minAge = 60;
        maxAge = 69;
      } else if (selectedAgeGroup == '70대') {
        minAge = 70;
        maxAge = 79;
      }

      // 선택된 성별 가져오기 및 Firebase에 저장된 값으로 매핑
      String selectedGender = genderGroups.entries.firstWhere((entry) => entry.value).key;
      String selectedGenderValue = (selectedGender == '남') ? "남성" : '여성';

      // User 컬렉션에서 조건에 맞는 userId 목록 가져오기
      QuerySnapshot userSnapshot = await _firestore
          .collection('Users')
          .where('Age', isGreaterThanOrEqualTo: minAge)
          .where('Age', isLessThanOrEqualTo: maxAge)
          .where('Sex', isEqualTo: selectedGenderValue)
          .get();


      List<String> userIds = [];
      for (var doc in userSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('userId')) {
          userIds.add(data['userId'] as String);
        }
      }

      // userIds가 비어있으면 처리 중단
      if (userIds.isEmpty) {
        print('조건에 맞는 사용자가 없습니다.');
        return;
      }

      // 각 사용자의 선택된 카테고리에 대한 지출 금액 합계 계산
      double totalAmount = 0;
      int userCount = 0;

      for (String userId in userIds) {
        QuerySnapshot ledgerSnapshot = await _firestore
            .collection('ledger')
            .where('userId', isEqualTo: userId)
            .where('category', isEqualTo: selectedCategory)
            .get();

        double userTotal = 0;
        for (var doc in ledgerSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('amount')) {
            userTotal += (data['amount'] as num).toDouble();
          }
        }

        // 해당 사용자가 선택된 카테고리에 지출이 있는 경우만 카운트
        if (ledgerSnapshot.docs.isNotEmpty) {
          totalAmount += userTotal;
          userCount++;
        }
      }

      // 평균 계산
      double average = userCount > 0 ? totalAmount / userCount : 0;

      // 상태 업데이트
      setState(() {
        averageExpense[selectedCategory] = average;
      });

      print('카테고리 $selectedCategory의 $selectedAgeGroup, $selectedGender 평균 지출: $average');
    } catch (e) {
      print('평균 지출 계산 오류: $e');
    }
  }

  // 선택된 소득 구간에 따른 평균 지출 계산 함수
  Future<void> incomeCompare() async {
    try {
      // 선택된 소득 구간 가져오기
      String selectedIncome = incomeGroups.entries.firstWhere((entry) => entry.value).key;
      
      // 소득 구간을 최소, 최대 금액으로 변환
      int minIncome = 0;
      int maxIncome = 0;
      
      if (selectedIncome == '월 200이하') {
        minIncome = 0;
        maxIncome = 2000000;
      } else if (selectedIncome == '월 200~300') {
        minIncome = 2000000;
        maxIncome = 3000000;
      } else if (selectedIncome == '월 300~400') {
        minIncome = 3000000;
        maxIncome = 4000000;
      } else if (selectedIncome == '월 400~550') {
        minIncome = 4000000;
        maxIncome = 5500000;
      } else if (selectedIncome == '월 550~700') {
        minIncome = 5500000;
        maxIncome = 7000000;
      } else if (selectedIncome == '월 700~850') {
        minIncome = 7000000;
        maxIncome = 8500000;
      } else if (selectedIncome == '월 850~1000') {
        minIncome = 8500000;
        maxIncome = 10000000;
      } else if (selectedIncome == '월 1000이상') {
        minIncome = 10000000;
        maxIncome = 1000000000; // 충분히 큰 값 설정
      }
      
      // ledger 컬렉션에서 "급여" 카테고리이고 선택된 소득 구간에 해당하는 사용자의 userId 목록을 가져옴
      QuerySnapshot salarySnapshot = await _firestore
          .collection('ledger')
          .where('category', isEqualTo: '급여')
          .where('amount', isGreaterThanOrEqualTo: minIncome)
          .where('amount', isLessThanOrEqualTo: maxIncome)
          .get();
      
      // userId 목록 추출
      Set<String> userIds = {};
      for (var doc in salarySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('userId')) {
          userIds.add(data['userId'] as String);
        }
      }
      
      // userIds가 비어있으면 처리 중단
      if (userIds.isEmpty) {
        print('선택한 소득 구간($selectedIncome)에 해당하는 사용자가 없습니다.');
        return;
      }
      
      // 각 사용자의 선택된 카테고리에 대한 지출 금액 합계 및 평균 계산
      double totalAmount = 0;
      int userCount = 0;
      
      for (String userId in userIds) {
        QuerySnapshot ledgerSnapshot = await _firestore
            .collection('ledger')
            .where('userId', isEqualTo: userId)
            .where('category', isEqualTo: selectedCategory)
            .get();
        
        double userTotal = 0;
        for (var doc in ledgerSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('amount')) {
            userTotal += (data['amount'] as num).toDouble();
          }
        }
        
        // 해당 사용자가 선택된 카테고리에 지출이 있는 경우만 카운트
        if (ledgerSnapshot.docs.isNotEmpty) {
          totalAmount += userTotal;
          userCount++;
        }
      }
      
      // 평균 계산
      double average = userCount > 0 ? totalAmount / userCount : 0;
      
      // 상태 업데이트 - 이미 다른 필터(나이/성별)로 계산된 값이 있을 수 있으므로 결과를 합쳐서 고려할 필요가 있음
      setState(() {
        averageExpense[selectedCategory] = average;
      });
      
      print('카테고리 $selectedCategory의 소득 구간 $selectedIncome 평균 지출: $average');
    } catch (e) {
      print('소득 구간별 평균 지출 계산 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 드롭다운
            _buildCategoryDropdown(),
            const SizedBox(height: 16),

            // 사용자의 평균 지출 알림
            _buildUserExpenseAlert(),
            const SizedBox(height: 24),

            // 비교 차트
            _buildComparisonChart(),
            const SizedBox(height: 24),

            // 필터 섹션
            _buildFilterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return InkWell(
      onTap: _showCategoryDialog,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(
              selectedCategory,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserExpenseAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black),
          children: [
            const TextSpan(text: '부린이님 '),
            const TextSpan(
              text: '월평균금 17,000원\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: '절약하고 있어요',
              style: TextStyle(color: Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          height: 250,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 내 지출 막대
              _buildBarColumn(
                  '나',
                  myExpense[selectedCategory] ?? 0,
                  Colors.blue,
                  '${myExpense[selectedCategory]?.toInt() ?? 0}원'),
              // 부린이 평균 지출 막대
              _buildBarColumn(
                  '부린이 평균금액',
                  averageExpense[selectedCategory] ?? 0,
                  Colors.grey.shade300,
                  '${averageExpense[selectedCategory]?.toInt() ?? 0}원'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarColumn( //그래프 코드
      String label, double value, Color color, String valueText) {
    // 현재 카테고리에서 최대값을 기준으로 높이 비율 계산
    double myValue = myExpense[selectedCategory] ?? 0;
    double avgValue = averageExpense[selectedCategory] ?? 0;
    double maxValue = myValue > avgValue ? myValue : avgValue;
    double heightPercentage =
    maxValue > 0 ? (value / maxValue).clamp(0.1, 1.0) : 0.1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 값 텍스트
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          child: Text(
            valueText,
            key: ValueKey<String>(valueText), // 키를 지정하여 애니메이션 트리거
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 막대
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          width: 80,
          height: 160 * heightPercentage,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),

        // 레이블
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 연령 필터
        _buildFilterGroup('나이', ageGroups),
        const SizedBox(height: 16),

        // 성별 필터
        _buildFilterGroup('성별', genderGroups),
        const SizedBox(height: 16),

        // 소득 필터
        _buildFilterGroup('소득', incomeGroups),
      ],
    );
  }

  Widget _buildFilterGroup(String title, Map<String, bool> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            return InkWell(
              onTap: () {
                setState(() {
                  if (title == '나이') {
                    // 나이의 경우 모든 선택 초기화 후 선택된 항목만 true
                    ageGroups.forEach((key, value) {
                      ageGroups[key] = false;
                    });
                    ageGroups[entry.key] = true;
                    // 애니메이션 재시작
                    _resetAnimation();
                    // 나이 필터 변경 시 평균 다시 계산
                    ageSexCompare();
                  } else if (title == '성별') {
                    // 성별의 경우 모든 선택 초기화 후 선택된 항목만 true
                    genderGroups.forEach((key, value) {
                      genderGroups[key] = false;
                    });
                    genderGroups[entry.key] = true;
                    // 애니메이션 재시작
                    _resetAnimation();
                    // 성별 필터 변경 시 평균 다시 계산
                    ageSexCompare();
                  } else if (title == '소득') {
                    // 소득의 경우 모든 선택 초기화 후 선택된 항목만 true
                    incomeGroups.forEach((key, value) {
                      incomeGroups[key] = false;
                    });
                    incomeGroups[entry.key] = true;
                    // 애니메이션 재시작
                    _resetAnimation();
                    // 소득 필터 변경 시 평균 다시 계산
                    incomeCompare();
                  }
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: entry.value ? Colors.green : Colors.grey,
                      ),
                      color: entry.value
                          ? Colors.green
                          : Colors.transparent,
                    ),
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: entry.value ? 1.0 : 0.0,
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(entry.key),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('카테고리 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(categories[index]),
                  onTap: () {
                    setState(() {
                      selectedCategory = categories[index];
                    });
                    // 애니메이션 재시작
                    _resetAnimation();
                    // 카테고리 변경 시 모든 계산 다시 실행
                    mySum(selectedCategory);
                    ageSexCompare();
                    incomeCompare();
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
