import 'package:flutter/material.dart';

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

class _ExpenseComparisonTabState extends State<ExpenseComparisonTab> {
  // 선택된 카테고리
  String selectedCategory = '통신비';

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
    '통신비': 55000,
    '식비': 520000,
    '카페': 180000,
    '간식': 95000,
    '생활': 280000,
    '쇼핑': 450000,
    '미용': 200000,
    '교통': 95000,
    '교육': 150000,
    '통신': 55000,
    '문화': 120000,
  };

  // 카테고리 목록
  List<String> categories = [
    '통신비',
    '식비',
    '카페',
    '간식',
    '생활',
    '쇼핑',
    '미용',
    '교통',
    '교육',
    '통신',
    '문화',
  ];

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
        Text(
          valueText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        // 막대
        Container(
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
                  } else if (title == '성별') {
                    // 성별의 경우 모든 선택 초기화 후 선택된 항목만 true
                    genderGroups.forEach((key, value) {
                      genderGroups[key] = false;
                    });
                    genderGroups[entry.key] = true;
                  } else if (title == '소득') {
                    // 소득의 경우 모든 선택 초기화 후 선택된 항목만 true
                    incomeGroups.forEach((key, value) {
                      incomeGroups[key] = false;
                    });
                    incomeGroups[entry.key] = true;
                  }
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
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
                    child: entry.value
                        ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                        : null,
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
