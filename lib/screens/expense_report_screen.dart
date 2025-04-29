import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // FL Chart 패키지 추가

class ExpenseReportScreen extends StatefulWidget {
  const ExpenseReportScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends State<ExpenseReportScreen> {
  String userName = '부린이님'; // 기본값 설정
  double totalExpense = 0; // 총 지출 금액
  Map<String, double> categoryExpenses = {}; // 카테고리별 지출 금액
  bool isLoading = true; // 로딩 상태
  String currentMonth = DateFormat('M').format(DateTime.now()); // 현재 월 (숫자)
  String currentMonthText = DateFormat('MM월').format(DateTime.now()); // 월 표시용 텍스트
  bool _showAllCategories = false; // 모든 카테고리 표시 여부
  
  // 화면에 표시할 카테고리 목록
  List<MapEntry<String, double>> sortedCategories = [];
  
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
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  
  // 사용자 정보와 지출 데이터 로드
  Future<void> _loadUserInfo() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // 사용자 이름 가져오기
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['Name'] != null) {
            userName = userData['Name'];
          }
        }
        
        // 현재 월의 거래 내역 가져오기
        await _loadExpenseData(currentUser.uid);
      }
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('사용자 정보 로드 중 오류 발생: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // 지출 데이터 로드
  Future<void> _loadExpenseData(String userId) async {
    try {
      // 현재 년도 구하기
      String currentYear = DateFormat('yyyy').format(DateTime.now());
      
      // 현재 월의 시작일과 종료일 계산
      DateTime startDate = DateTime(int.parse(currentYear), int.parse(currentMonth), 1);
      DateTime endDate = DateTime(int.parse(currentYear), int.parse(currentMonth) + 1, 0);
      
      print('조회 기간: $startDate ~ $endDate');
      
      // Firestore에서 현재 달의 거래 내역 가져오기
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('ledger')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: '지출') // 지출 항목만 가져오기
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      print('조회된 거래 내역 수: ${querySnapshot.docs.length}');
      
      // 총 지출 금액 및 카테고리별 금액 계산
      double total = 0;
      Map<String, double> categories = {};
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        if (data.containsKey('amount') && data.containsKey('category')) {
          double amount = (data['amount'] as num).toDouble();
          String category = data['category'] as String;
          
          total += amount;
          
          // 카테고리별 합계 업데이트
          if (categories.containsKey(category)) {
            categories[category] = categories[category]! + amount;
          } else {
            categories[category] = amount;
          }
        }
      }
      
      // 내림차순으로 카테고리 정렬 (금액이 큰 순서)
      List<MapEntry<String, double>> sorted = categories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      setState(() {
        totalExpense = total;
        categoryExpenses = categories;
        sortedCategories = sorted;
      });
      
      print('총 지출: $totalExpense');
      print('카테고리별 지출: $categoryExpenses');
    } catch (e) {
      print('지출 데이터 로드 중 오류 발생: $e');
    }
  }
  
  // 천 단위 구분 포맷
  String formatNumber(double number) {
    return NumberFormat('#,###').format(number.round());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소비 리포트'),
        backgroundColor: Colors.grey[50],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 소비 리포트 설명
                    Text(
                      '${userName}님의 $currentMonthText 소비 패턴을 확인하고 공유해보세요',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 소비 리포트 카드
                    _buildExpenseReportCard(),
                    const SizedBox(height: 32),
                    
                    // 공유 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _shareExpenseReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BC34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '리포트 공유하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
  
  // 소비 리포트 카드 UI
  Widget _buildExpenseReportCard() {
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
            Text(
              "${userName}님의 $currentMonthText 소비 리포트",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30.0),
            
            // 소비 그래프 영역
            categoryExpenses.isNotEmpty
                ? SizedBox(
                    height: 180,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 차트와 범례를 Row로 배치
                        Row(
                          children: [
                            // 차트를 왼쪽에 배치
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 150,
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
            const SizedBox(height: 30.0),
            
            // 현재 월 총 소비
            Center(
              child: Text(
                "$currentMonthText 총 소비 ${formatNumber(totalExpense)}원",
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const Divider(),
            const SizedBox(height: 16.0),
            
            // 카테고리별 지출 내역
            if (sortedCategories.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              // 스크롤 가능한 카테고리 목록으로 변경
              ConstrainedBox(
                constraints: BoxConstraints(
                  // 항목이 많을 경우 최대 높이 설정 (4개 항목 높이 기준)
                  maxHeight: 240,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: sortedCategories.map((entry) {
                      final categoryName = entry.key;
                      final amount = entry.value;
                      final percent = (amount / totalExpense) * 100;
                      final icon = categoryIcons[categoryName] ?? Icons.help_outline;
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
                              '${formatNumber(amount)}원',
                              style: const TextStyle(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
    );
  }
  
  // 리포트 공유 기능
  void _shareExpenseReport() {
    // 실제 공유 기능 구현 (미구현 - 예시로 메시지만 표시)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("소비 리포트가 공유되었습니다"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 