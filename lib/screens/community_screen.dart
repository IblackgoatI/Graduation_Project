/// 커뮤니티 화면
/// 사용자 간의 게시물 및 댓글 소통을 위한 커뮤니티 기능을 제공합니다.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'expense_report_write_screen.dart';  // 소비 리포트 글쓰기 화면 import
import 'expense_report_detail_screen.dart';  // 소비 리포트 상세 화면 import
import 'ai_analysis_screen.dart';  // AI 분석 화면 import

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String userName = '부린이님'; // 기본값 설정
  int userAge = 0; // 사용자 나이 저장 변수
  
  // 배너 관련
  late PageController _bannerPageController;
  final ValueNotifier<int> _bannerIndexNotifier = ValueNotifier<int>(0);
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bannerPageController = PageController();
    _loadUserInfo(); // 사용자 정보 로드
    _startBannerAutoSlide(); // 배너 자동 슬라이드 시작
  }

  // Firebase에서 사용자 정보를 가져오는 함수
  Future<void> _loadUserInfo() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      debugPrint('현재 로그인한 사용자: ${currentUser?.uid}');

      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .get();
        
        debugPrint('Firestore 문서 존재 여부: ${userDoc.exists}');
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          debugPrint('Firestore 전체 데이터: $userData');
          
          // 데이터의 모든 키와 값, 타입을 출력
          if (userData != null) {
            userData.forEach((key, value) {
              debugPrint('키: $key, 값: $value, 타입: ${value.runtimeType}');
            });
            
            // 이름 처리
            if (userData.containsKey('Name')) {
              userName = userData['Name'] as String? ?? '부린이님';
              debugPrint('이름 설정됨: $userName');
            }
            
            // 나이 처리
            int age = 0;
            if (userData.containsKey('Age')) {
              var ageValue = userData['Age'];
              debugPrint('원본 Age 값: $ageValue, 타입: ${ageValue.runtimeType}');
              
              if (ageValue is int) {
                age = ageValue;
                debugPrint('Age는 int 타입입니다: $age');
              } else if (ageValue is double) {
                age = ageValue.toInt();
                debugPrint('Age는 double 타입입니다: $age');
              } else if (ageValue is String) {
                age = int.tryParse(ageValue) ?? 0;
                debugPrint('Age는 String 타입입니다: $age');
              } else {
                debugPrint('Age는 다른 타입입니다. 문자열로 변환 시도: $ageValue');
                try {
                  String ageStr = ageValue.toString();
                  age = int.tryParse(ageStr) ?? 0;
                  debugPrint('변환 결과: $age');
                } catch (e) {
                  debugPrint('Age 변환 중 오류: $e');
                }
              }
            } else {
              debugPrint('Age 필드가 존재하지 않습니다');
            }
            
            // 상태 업데이트
            setState(() {
              userAge = age;
              debugPrint('최종 설정된 나이: $userAge');
            });
          }
        } else {
          debugPrint('사용자 문서가 존재하지 않습니다.');
        }
      } else {
        debugPrint('로그인된 사용자가 없습니다.');
      }
    } catch (e) {
      debugPrint('사용자 정보 로드 중 오류 발생: $e');
      debugPrint('오류 스택 트레이스: ${StackTrace.current}');
    }
  }


  // 나이를 연령대 문자열로 변환하는 함수
  String _getAgeGroup(int age) {
    if (age >= 10 && age < 20) return '10대';
    if (age >= 20 && age < 30) return '20대';
    if (age >= 30 && age < 40) return '30대';
    if (age >= 40 && age < 50) return '40대';
    if (age >= 50 && age < 60) return '50대';
    if (age >= 60 && age < 70) return '60대';
    if (age >= 70) return '70대';
    return '사용자';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerPageController.dispose();
    _bannerIndexNotifier.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  // 배너 자동 슬라이드 시작
  void _startBannerAutoSlide() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerPageController.hasClients) {
        final nextIndex = (_bannerIndexNotifier.value + 1) % 5;
        _bannerIndexNotifier.value = nextIndex;
        _bannerPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        title: Text('$userName님',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                // 게시판 탭 (버튼 포함)
                _buildBoardContent(),

                // 지출 비교 탭 (버튼 없음)
                const ExpenseComparisonTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 게시판 탭 화면
  Widget _buildBoardContent() {
    return Column(
      children: [
        // 스크롤 가능한 메인 콘텐츠
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 배너 섹션 (RepaintBoundary로 감싸서 리빌드 최소화)
                  RepaintBoundary(
                    child: _buildTopSaverSection(),
                  ),
                  const SizedBox(height: 24),
                  
                  // 20대 부린이님을 위한 커뮤니티 (RepaintBoundary로 감싸서 리빌드 방지)
                  RepaintBoundary(
                    child: _buildCommunitySection(),
                  ),
                  const SizedBox(height: 80), // 버튼을 위한 하단 여백
                ],
              ),
            ),
          ),
        ),
        
        // 하단에 고정된 버튼
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
          ),
          child: ElevatedButton(
            onPressed: () {
              // 새로운 소비리포트 글쓰기 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExpenseReportWriteScreen(),
                ),
              );
            },
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
        ),
      ],
    );
  }

  // 배너 섹션
  Widget _buildTopSaverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _bannerPageController,
            onPageChanged: (index) {
              // setState 대신 ValueNotifier만 업데이트하여 리빌드 방지
              _bannerIndexNotifier.value = index;
            },
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildBannerCard(index);
            },
          ),
        ),
        const SizedBox(height: 8),
        // ValueListenableBuilder를 사용하여 인디케이터만 업데이트
        ValueListenableBuilder<int>(
          valueListenable: _bannerIndexNotifier,
          builder: (context, currentIndex, child) {
            return _BannerIndicator(
              currentIndex: currentIndex,
              itemCount: 5,
            );
          },
        ),
      ],
    );
  }

  // 배너 카드 빌드
  Widget _buildBannerCard(int index) {
    final banners = [
      {
        'text': '나의 소비 성향은?\nAI 분석 보러가기',
        'color': const Color(0xFFF3E5F5), // 연한 보라색
        'icon': '🤖',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AIAnalysisScreen(),
            ),
          );
        },
      },
      {
        'text': '배달비 0원!\nKB(가짜)카드 출시',
        'color': const Color(0xFFFFF9C4), // 연한 노란색
        'icon': '🛵',
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('광고 배너입니다.')),
          );
        },
      },
      {
        'text': '포인트 적립\n최대 10% 캐시백',
        'color': const Color(0xFFE3F2FD), // 연한 파랑
        'icon': '💰',
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('광고 배너입니다.')),
          );
        },
      },
      {
        'text': '목표 저축 달성\n축하 포인트 지급',
        'color': const Color(0xFFE8F5E9), // 연한 초록
        'icon': '🎯',
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('광고 배너입니다.')),
          );
        },
      },
      {
        'text': '소비 리포트 공유\n추천인 포인트 받기',
        'color': const Color(0xFFF5F5F5), // 연한 회색
        'icon': '📊',
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('광고 배너입니다.')),
          );
        },
      },
    ];

    final banner = banners[index];

    return GestureDetector(
      onTap: banner['onTap'] as VoidCallback,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: banner['color'] as Color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  banner['text'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                banner['icon'] as String,
                style: const TextStyle(fontSize: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getAgeGroup(userAge)} $userName님을 위한 커뮤니티',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Firestore에서 소비 리포트 게시글 가져오기
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('community')
              .orderBy('created_at', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text('데이터 로드 중 오류가 발생했습니다: ${snapshot.error}'),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.post_add,
                        size: 50,
                        color: Color(0xFF8BC34A),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '게시글이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '첫 번째 소비 리포트를 공유해보세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // 게시글 리스트 표시
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                return _ExpenseReportCard(docId: doc.id, data: data);
              },
            );
          },
        ),
      ],
    );
  }
}

// 소비 리포트 카드를 별도 위젯으로 분리
class _ExpenseReportCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _ExpenseReportCard({
    required this.docId,
    required this.data,
  });

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('yyyy.MM.dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final title = data['Heading'] as String? ?? '제목 없음';
    final content = data['Content'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseReportDetailScreen(postData: {...data, 'id': docId}),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '소비 리포트 게시판',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    data['author_name'] ?? '익명',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Text(' · ', style: TextStyle(color: Colors.grey)),
                  Text(
                    _timeAgo(
                      (data['created_at'] is Timestamp)
                        ? (data['created_at'] as Timestamp).toDate()
                        : DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
                    ),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 사용하지 않는 메서드들 (경고만 발생)
extension _CommunityScreenStateExtension on _CommunityScreenState {
  Widget _buildCategorySummary(Map<String, dynamic> reportData) {
    // ExpenseReportScreen에서 반환된 데이터 구조 사용
    final totalAmount = reportData['total_expense'] ?? 0;
    final formattedAmount = NumberFormat('#,###').format(totalAmount);
    final categories = reportData['categories'] as Map<String, dynamic>? ?? {};
    
    // 카테고리 데이터를 금액 기준으로 정렬
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 총 금액
        Text(
          '$formattedAmount원',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // 상위 3개 카테고리만 표시
        ...sortedCategories.take(3).map((entry) {
          final categoryName = entry.key;
          final amount = (entry.value is int) ? entry.value.toDouble() : (entry.value as num).toDouble();
          final percent = totalAmount > 0 ? (amount / totalAmount * 100) : 0;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                // 카테고리명
                Expanded(
                  flex: 2,
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
                
                // 퍼센트
                Expanded(
                  flex: 1,
                  child: Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                
                // 금액
                Expanded(
                  flex: 2,
                  child: Text(
                    '${NumberFormat('#,###').format(amount)}원',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 파이 차트 위젯
  Widget _buildPieChart(Map<String, dynamic> reportData) {
    final categories = reportData['categories'] as Map<String, dynamic>? ?? {};
    final totalAmount = reportData['total_expense'] ?? 0;
    
    // 카테고리가 없으면 기본 아이콘 표시
    if (categories.isEmpty || totalAmount == 0) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.pie_chart,
          size: 40,
          color: Colors.grey,
        ),
      );
    }
    
    // 카테고리 데이터 변환
    List<Map<String, dynamic>> chartData = [];
    
    // 색상 정의
    final colors = [
      Colors.red[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.purple[300]!,
      Colors.orange[300]!,
      Colors.teal[300]!,
      Colors.pink[300]!,
      Colors.indigo[300]!,
    ];
    
    int colorIndex = 0;
    categories.forEach((key, value) {
      final amount = (value is int) ? value.toDouble() : (value as num).toDouble();
      final percent = totalAmount > 0 ? amount / totalAmount : 0.0;
      
      chartData.add({
        'color': colors[colorIndex % colors.length],
        'percent': percent,
      });
      
      colorIndex++;
    });
    
    // CustomPaint를 사용하여 파이 차트 그리기
    return CustomPaint(
      size: const Size(80, 80),
      painter: PieChartPainter(sections: chartData),
    );
  }

}

// ExpenseComparisonTab 클래스 포함 (지출 비교 탭 코드 시작)
class ExpenseComparisonTab extends StatefulWidget {
  const ExpenseComparisonTab({super.key});

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

  // 사용자 정보
  String userName = '부린이님';

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
    // 사용자 이름 가져오기
    _loadUserName();
    
    // 초기 애니메이션 시작
    _animationController.forward();
  }
  
  // Firebase에서 사용자 이름을 가져오는 함수
  Future<void> _loadUserName() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['Name'] != null) {
            setState(() {
              userName = userData['Name'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('사용자 이름 로드 중 오류 발생: $e');
    }
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

  // 숫자 포맷 함수 (천 단위 콤마 추가)
  String numberFormat(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Firestore에서 사용자의 지출 합계를 계산하는 함수
  Future<void> mySum(String category) async {
    try {
      // 현재 로그인한 사용자 ID 가져오기
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        debugPrint('사용자가 로그인되어 있지 않습니다.');
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

      debugPrint('카테고리 $category의 총 지출: $sum');
    } catch (e) {
      debugPrint('데이터 가져오기 오류: $e');
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
        debugPrint('조건에 맞는 사용자가 없습니다.');
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

      debugPrint('카테고리 $selectedCategory의 $selectedAgeGroup, $selectedGender 평균 지출: $average');
    } catch (e) {
      debugPrint('평균 지출 계산 오류: $e');
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
        debugPrint('선택한 소득 구간($selectedIncome)에 해당하는 사용자가 없습니다.');
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
      
      debugPrint('카테고리 $selectedCategory의 소득 구간 $selectedIncome 평균 지출: $average');
    } catch (e) {
      debugPrint('소득 구간별 평균 지출 계산 오류: $e');
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
    // 현재 선택된 카테고리의 내 지출과 평균 지출 비교
    double myAmount = myExpense[selectedCategory] ?? 0;
    double avgAmount = averageExpense[selectedCategory] ?? 0;
    
    // 금액 차이 계산
    double difference = 0;
    String message = '';
    Color messageColor = Colors.black;
    
    if (myAmount < avgAmount) {
      // 절약하고 있는 경우
      difference = avgAmount - myAmount;
      message = '절약하고 있어요';
      messageColor = Colors.green.shade700;
    } else {
      // 더 많이 소비하고 있는 경우
      difference = myAmount - avgAmount;
      message = '더 소비하고 있어요';
      messageColor = Colors.red.shade700;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: RichText(
          key: ValueKey<String>("$selectedCategory-$difference-$message"),
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black),
            children: [
              TextSpan(text: '$userName님'),
              TextSpan(
                text: ' 월평균금 ${numberFormat(difference.toInt())}원\n',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: message,
                style: TextStyle(color: messageColor),
              ),
            ],
          ),
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

// 원형 차트를 그리는 커스텀 페인터
class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> sections;
  
  PieChartPainter({required this.sections});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    var startAngle = -90 * 3.14 / 180; // -90도에서 시작 (12시 방향)
    
    for (var section in sections) {
      final percent = (section['percent'] as num).toDouble();
      final sweepAngle = percent * 360 * 3.14 / 180;
      final paint = Paint()
        ..color = section['color'] as Color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
    
    // 가운데 흰색 원 그려서 도넛 차트처럼 만들기
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.6, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PieChartPainter) {
      return oldDelegate.sections != sections;
    }
    return true;
  }
}

// 배너 인디케이터를 별도 위젯으로 분리하여 리빌드 최소화
class _BannerIndicator extends StatelessWidget {
  final int currentIndex;
  final int itemCount;

  const _BannerIndicator({
    required this.currentIndex,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? const Color(0xFF8BC34A)
                : Colors.grey[300],
          ),
        );
      }),
    );
  }
}
