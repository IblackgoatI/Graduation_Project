import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' show min;
import 'transaction_provider.dart';
import 'asset.dart'; // 자산 화면 import (계좌 연결 화면)

class AssetDetailScreen extends StatefulWidget {
  final User? user;

  const AssetDetailScreen({super.key, this.user});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  int _totalAssets = 0;
  int _savingsTotal = 0;
  int _depositTotal = 0;
  int _stocksTotal = 0;
  int _cashTotal = 0;
  List<Map<String, dynamic>> _assetAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAssetData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 자산 데이터 로드
  Future<void> _loadAssetData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Firestore에서 사용자의 자산 정보 가져오기
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('assets')
            .where('userId', isEqualTo: currentUser.uid)
            .get();

        List<Map<String, dynamic>> accounts = [];
        int totalAssets = 0;
        int savingsTotal = 0;
        int depositTotal = 0;
        int stocksTotal = 0;
        int cashTotal = 0;

        for (var doc in querySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String assetType = data['assetType'] ?? 'savings'; // 기본값은 저축
          int balance = (data['balance'] as num).toInt();

          accounts.add({
            'id': doc.id,
            'bank': data['bank'],
            'account': data['account'],
            'balance': balance,
            'assetType': assetType,
            'iconColor': data['iconColor'] ?? 0xFF73AD13,
          });

          // 총 자산 계산
          totalAssets += balance;

          // 자산 유형별 합계 계산
          switch (assetType) {
            case 'savings':
              savingsTotal += balance;
              break;
            case 'deposit':
              depositTotal += balance;
              break;
            case 'stocks':
              stocksTotal += balance;
              break;
            case 'cash':
              cashTotal += balance;
              break;
          }
        }

        if (mounted) {
          setState(() {
            _assetAccounts = accounts;
            _totalAssets = totalAssets;
            _savingsTotal = savingsTotal;
            _depositTotal = depositTotal;
            _stocksTotal = stocksTotal;
            _cashTotal = cashTotal;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('자산 정보 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('자산', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 탭바
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '조회'),
                Tab(text: '목표'),
              ],
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorWeight: 2.0,
            ),
          ),

          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 조회 탭
                _buildViewTab(),

                // 목표 탭
                _buildGoalTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 자산 추가 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetScreen(
                user: widget.user ?? FirebaseAuth.instance.currentUser,
              ),
            ),
          );

          // 임시로 스낵바 표시
          /*ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('자산 추가 기능 개발 중입니다')),
          );*/
        },
        backgroundColor: const Color(0xFF73AD13),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 조회 탭 위젯
  Widget _buildViewTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF73AD13)))
        : RefreshIndicator(
      onRefresh: _loadAssetData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 총 자산 표시
              _buildTotalAssetSection(),

              const SizedBox(height: 16.0),
              const Divider(),

              // 계좌 섹션
              _buildAccountSection('입출금', _savingsTotal, Icons.account_balance),
              _buildAccountSection('적금', _depositTotal, Icons.savings),
              _buildAccountSection('예금', _cashTotal, Icons.payment),
              _buildAccountSection('주식', _stocksTotal, Icons.trending_up),

              const SizedBox(height: 80.0), // FloatingActionButton 공간 확보
            ],
          ),
        ),
      ),
    );
  }

  // 목표 탭 위젯 수정
  Widget _buildGoalTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 첫 번째 줄: 이번 달 수입 & 이번 달 저축
            Row(
              children: [
                // 이번 달 수입 카드
                Expanded(
                  child: _buildMonthlyIncomeCard(),
                ),
                const SizedBox(width: 16.0),
                // 이번 달 저축 카드
                Expanded(
                  child: _buildMonthlySavingsCard(),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // 두 번째 줄: 이번 달 지출 카드 (파이 차트) - 가로 전체
            _buildMonthlyExpenseCard(),

            const SizedBox(height: 16.0),

            // 세 번째 줄: 고정지출 & 이번 달 예산
            Row(
              children: [
                // 고정지출 카드
                Expanded(
                  child: _buildFixedExpenseCard(),
                ),
                const SizedBox(width: 16.0),
                // 이번 달 예산 카드
                Expanded(
                  child: _buildMonthlyBudgetCard(),
                ),
              ],
            ),

            const SizedBox(height: 80.0), // FloatingActionButton 공간 확보
          ],
        ),
      ),
    );
  }

  // 공통 카드 스타일
  Widget _buildStandardCard({required Widget child, double height = 180}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: Colors.grey[50],
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  // 막대 그래프 위젯
  Widget _buildBarGraph(String month, double amount, Color color, double heightPercent) {
    // 수입 금액을 간단히 표시 (천 단위 구분)
    String amountDisplay = '';
    if (amount >= 10000) {
      final inMillions = amount / 10000;
      amountDisplay = '${inMillions.toStringAsFixed(1)}만';
    } else {
      amountDisplay = NumberFormat('#,###').format(amount);
    }

    return SizedBox(
      width: 35, // 너비 더 감소
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: '${month}: $amountDisplay원',
            child: Container(
              width: 15, // 막대 너비 감소
              height: heightPercent > 0 ? min(heightPercent, 150) : 2, // 높이 제한
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                  bottom: Radius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4), // 간격 축소
          FittedBox( // 텍스트 오버플로우 방지
            fit: BoxFit.scaleDown,
            child: Text(
              month,
              style: TextStyle(
                fontSize: 8, // 텍스트 크기 감소
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 이번 달 수입 카드
  Widget _buildMonthlyIncomeCard() {
    // TransactionProvider에서 데이터 가져오기
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;
    
    // 현재 날짜 정보 가져오기
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // 최근 3개월의 연도와 월 계산
    List<Map<String, dynamic>> lastThreeMonths = [];
    for (int i = 0; i < 3; i++) {
      int month = currentMonth - i;
      int year = currentYear;
      if (month <= 0) {
        month += 12;
        year -= 1;
      }
      lastThreeMonths.add({
        'year': year,
        'month': month,
        'label': '$month월',
      });
    }
    // 가장 오래된 월이 먼저 오도록 뒤집기
    lastThreeMonths = lastThreeMonths.reversed.toList();
    
    // 각 월의 수입 계산
    List<double> monthlyIncomes = [];
    for (var monthData in lastThreeMonths) {
      int year = monthData['year'];
      int month = monthData['month'];
      
      // 해당 월의 수입 트랜잭션 필터링
      final monthlyTransactions = transactions.where((transaction) {
        return transaction.date.year == year && 
               transaction.date.month == month && 
               transaction.type == '수입';
      }).toList();
      
      // 해당 월의 총 수입 계산
      final totalIncome = monthlyTransactions.fold(0.0, 
          (sum, transaction) => sum + transaction.amount);
          
      monthlyIncomes.add(totalIncome);
    }
    
    // 그래프 높이 계산 (최대 수입을 기준으로 비율 계산)
    double maxIncome = monthlyIncomes.isNotEmpty ? 
        monthlyIncomes.reduce((curr, next) => curr > next ? curr : next) : 1.0;
    List<double> heightPercents = monthlyIncomes.map((income) => 
        maxIncome > 0 ? (income / maxIncome) * 90 : 0.0).toList();
    
    // 현재 월의 수입 (마지막 값)
    String currentMonthIncome = '';
    if (monthlyIncomes.isNotEmpty) {
      final lastIncome = monthlyIncomes.last;
      currentMonthIncome = NumberFormat.compact(locale: 'ko').format(lastIncome) + '원';
      if (lastIncome >= 10000) {
        final inMillions = lastIncome / 10000;
        currentMonthIncome = '${inMillions.toStringAsFixed(0)}만원';
      }
    }

    // 월 이름 표시
    List<String> monthLabels = lastThreeMonths.map((data) => data['label'] as String).toList();
    
    return _buildStandardCard(
      height: 250, // 높이 더 증가
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 수입',
            style: TextStyle(
              fontSize: 14, // 제목 텍스트 크기 감소
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          
          // 막대 그래프와 월 표시를 포함하는 컨테이너
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBarGraph(
                    monthLabels[0], 
                    monthlyIncomes[0],
                    Color.fromRGBO(158, 158, 158, 0.3), 
                    heightPercents[0]
                  ),
                  const SizedBox(width: 12),
                  _buildBarGraph(
                    monthLabels[1], 
                    monthlyIncomes[1],
                    Color.fromRGBO(158, 158, 158, 0.3), 
                    heightPercents[1]
                  ),
                  const SizedBox(width: 12),
                  _buildBarGraph(
                    monthLabels[2], 
                    monthlyIncomes[2],
                    const Color(0xFF73AD13), 
                    heightPercents[2]
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              currentMonthIncome,
              style: TextStyle(
                fontSize: 12, // 금액 텍스트 크기 감소
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 이번 달 지출 카드 (도넛 차트)
  Widget _buildMonthlyExpenseCard() {
    // TransactionProvider에서 데이터 가져오기
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;
    
    // 현재 날짜 정보 가져오기
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // 이번 달 지출 트랜잭션 필터링
    final monthlyExpenses = transactions.where((transaction) {
      return transaction.date.year == currentYear && 
             transaction.date.month == currentMonth && 
             transaction.type == '지출';
    }).toList();
    
    // 카테고리별 지출 금액 계산
    Map<String, double> categoryExpenses = {};
    for (var transaction in monthlyExpenses) {
      final category = transaction.category.isEmpty ? '기타' : transaction.category;
      if (categoryExpenses.containsKey(category)) {
        categoryExpenses[category] = categoryExpenses[category]! + transaction.amount;
      } else {
        categoryExpenses[category] = transaction.amount;
      }
    }
    
    // 총 지출액 계산
    final totalExpense = monthlyExpenses.fold(
        0.0, (sum, transaction) => sum + transaction.amount);
    
    // 상위 4개 카테고리 선택 (또는 더 적은 경우 모든 카테고리)
    List<MapEntry<String, double>> sortedCategories = 
        categoryExpenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    
    List<MapEntry<String, double>> topCategories = [];
    double otherAmount = 0.0;
    
    if (sortedCategories.length <= 4) {
      topCategories = sortedCategories;
    } else {
      topCategories = sortedCategories.take(3).toList();
      // 나머지 카테고리 금액 합산
      otherAmount = sortedCategories.skip(3).fold(
          0.0, (sum, entry) => sum + entry.value);
      topCategories.add(MapEntry('기타', otherAmount));
    }
    
    // 퍼센트 계산
    final List<ChartCategory> chartData = [];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    
    if (totalExpense > 0) {
      for (int i = 0; i < topCategories.length; i++) {
        final category = topCategories[i];
        final percent = (category.value / totalExpense * 100).round();
        chartData.add(ChartCategory(
          name: category.key,
          amount: category.value,
          percent: percent,
          color: i < colors.length ? colors[i] : Colors.grey,
        ));
      }
    } else {
      // 지출이 없는 경우 기본 데이터
      chartData.add(ChartCategory(
        name: '지출 없음',
        amount: 0,
        percent: 100,
        color: Colors.grey,
      ));
    }
    
    // 금액 표시 포맷
    String expenseText = '0원';
    if (totalExpense > 0) {
      if (totalExpense >= 10000) {
        final inMillions = totalExpense / 10000;
        expenseText = '${inMillions.toStringAsFixed(0)}만원';
      } else {
        expenseText = '${NumberFormat('#,###').format(totalExpense)}원';
      }
    }
    
    return _buildStandardCard(
      height: 160, // 높이 약간 감소
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 지출',
            style: TextStyle(
              fontSize: 14, // 제목 텍스트 크기 감소
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // 도넛 차트와 범례
          Expanded(
            child: Row(
              children: [
                // 도넛 차트 - 크기 조정
                Expanded(
                  flex: 4, // 전체 너비의 40%
                  child: SizedBox(
                    height: 90, // 높이 제한
                    child: Center(
                      child: SizedBox(
                        width: 90, // 도넛 차트 크기 제한
                        height: 90,
                        child: CustomPaint(
                          painter: DonutChartPainter(categories: chartData),
                        ),
                      ),
                    ),
                  ),
                ),
                // 범례
                Expanded(
                  flex: 6, // 전체 너비의 60%
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end, // 오른쪽 정렬
                        children: chartData.map((category) => 
                          _buildLegendItem(
                            category.name, 
                            '${category.percent}%', 
                            category.color,
                          )
                        ).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: Text(
              expenseText,
              style: TextStyle(
                fontSize: 12, // 금액 텍스트 크기 감소
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 범례 아이템 위젯
  Widget _buildLegendItem(String label, String percentage, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞춤
      children: [
        Container(
          width: 8, // 범례 점 크기 감소
          height: 8, // 범례 점 크기 감소
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $percentage',
          style: TextStyle(
            fontSize: 10, // 범례 텍스트 크기 감소
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // 고정지출 카드
  Widget _buildFixedExpenseCard() {
    return _buildStandardCard(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '고정지출',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          const Text(
            '고정지출을 추가하세요',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // 고정지출 추가 시트 표시
              _showFixedExpenseSheet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF73AD13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text(
              '고정지출 추가',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 고정지출 추가 시트 표시
  void _showFixedExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '고정지출 내역찾기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          '가계부에서',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF73AD13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            '내역찾기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          '고정지출 항목',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF73AD13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            '추가하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 이번 달 예산 카드
  Widget _buildMonthlyBudgetCard() {
    return _buildStandardCard(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 예산',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // 예산과 지출을 보여주는 그래프
          Column(
            children: [
              const Text(
                '30만원', // 예산 금액 (예시)
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildBudgetProgressBar(22.5, 30.0),
              const SizedBox(height: 12),
              const Text(
                '남은 예산: 7.5만원',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // 월 예산 변경 시트 표시
              _showMonthlyBudgetSettingSheet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF73AD13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text(
              '월 예산 변경',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 월 예산 설정 시트 표시
  void _showMonthlyBudgetSettingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '월 지출 예산 설정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  // 현재 시트를 닫고 예산 입력 다이얼로그 표시
                  Navigator.pop(context);
                  _showBudgetInputDialog();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '지출 예산',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              '800,000원',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              '월 수입의 40%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF73AD13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 예산 입력 다이얼로그 표시
  void _showBudgetInputDialog() {
    // 예산 금액 관리를 위한 변수
    String budgetInput = '800000';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 입력된 금액을 포맷팅하여 표시
            String formattedBudget = _numberFormat(int.parse(budgetInput)) + '원';
            String percentageText = '월 수입의 40%';
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom
              ),
              child: SizedBox(
                height: 500,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 제목 및 닫기 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '월 지출 예산을 입력해주세요.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // 예산 금액 표시
                      Center(
                        child: Column(
                          children: [
                            Text(
                              formattedBudget,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              percentageText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // 숫자 키패드
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 첫 번째 줄: 1, 2, 3
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('1', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '1';
                                    }
                                  });
                                }),
                                _buildNumberButton('2', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '2';
                                    }
                                  });
                                }),
                                _buildNumberButton('3', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '3';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // 두 번째 줄: 4, 5, 6
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('4', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '4';
                                    }
                                  });
                                }),
                                _buildNumberButton('5', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '5';
                                    }
                                  });
                                }),
                                _buildNumberButton('6', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '6';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // 세 번째 줄: 7, 8, 9
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('7', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '7';
                                    }
                                  });
                                }),
                                _buildNumberButton('8', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '8';
                                    }
                                  });
                                }),
                                _buildNumberButton('9', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '9';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // 네 번째 줄: 0, 백스페이스
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 50),
                                _buildNumberButton('0', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10 && budgetInput != '0') {
                                      budgetInput += '0';
                                    }
                                  });
                                }),
                                _buildBackspaceButton(onPressed: () {
                                  setState(() {
                                    if (budgetInput.isNotEmpty) {
                                      budgetInput = budgetInput.substring(0, budgetInput.length - 1);
                                      if (budgetInput.isEmpty) {
                                        budgetInput = '0';
                                      }
                                    }
                                  });
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 확인 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF73AD13),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(fontSize: 16),
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
      },
    );
  }

  // 숫자 버튼 위젯
  Widget _buildNumberButton(String number, {required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 백스페이스 버튼 위젯
  Widget _buildBackspaceButton({required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        child: const Icon(Icons.backspace_outlined, size: 24),
      ),
    );
  }

  // 커스텀 예산 진행 바 위젯
  Widget _buildBudgetProgressBar(double spent, double budget) {
    double progress = spent / budget;
    progress = progress.clamp(0.0, 1.0); // 1.0을 넘지 않도록 제한
    
    return Stack(
      children: [
        // 배경(전체 예산)
        Container(
          height: 25,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12.5),
          ),
        ),
        // 진행 바(사용된 예산)
        Container(
          height: 25,
          width: MediaQuery.of(context).size.width * 0.35 * progress, // 화면 너비에 비례하게 조정
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12.5),
          ),
          child: Center(
            child: Text(
              '${spent}만원',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 이번 달 저축 카드
  Widget _buildMonthlySavingsCard() {
    return _buildStandardCard(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 저축',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          const Center(
            child: Text(
              '0원',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // 월 저축 목표 설정 시트 표시
              _showMonthlySavingsGoalSheet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF73AD13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text(
              '월 목표 설정',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 월 저축 목표 설정 시트 표시
  void _showMonthlySavingsGoalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '월 저축 목표 설정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '목표 금액',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '500,000원',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '월 수입의 25%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '저축 계좌',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '국민은행',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '잔액 0원',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF73AD13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 총 자산 섹션
  Widget _buildTotalAssetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '부린이님의 총자산',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          '${_numberFormat(_totalAssets)}원',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '계좌 잔금',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_numberFormat(_savingsTotal + _depositTotal + _cashTotal)}원',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '입출금',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_numberFormat(_savingsTotal)}원',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 계좌 섹션 빌더
  Widget _buildAccountSection(String title, int totalAmount, IconData iconData) {
    // 해당 타입의 계좌 필터링
    List<Map<String, dynamic>> accounts = _assetAccounts.where((account) {
      String type = account['assetType'] ?? 'savings';

      switch (title) {
        case '입출금':
          return type == 'savings';
        case '적금':
          return type == 'deposit';
        case '예금':
          return type == 'cash';
        case '주식':
          return type == 'stocks';
        default:
          return false;
      }
    }).toList();

    // 섹션 내 계좌가 없으면 섹션 자체를 표시하지 않음
    if (accounts.isEmpty && totalAmount == 0) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),

        // 섹션 제목
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_numberFormat(totalAmount)}원',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 계좌 목록
        ...accounts.map((account) => _buildAccountItem(account)),

        const SizedBox(height: 8.0),
        const Divider(),
      ],
    );
  }

  // 개별 계좌 아이템 빌더
  Widget _buildAccountItem(Map<String, dynamic> account) {
    Color iconColor = Color(account['iconColor'] ?? 0xFF73AD13);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // 뱅크 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                account['bank'].toString().substring(0, 1),
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16.0),

          // 계좌 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account['bank'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatAccountNumber(account['account']),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 잔액
          Text(
            '${_numberFormat(account['balance'])}원',
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 계좌번호 포맷팅
  String _formatAccountNumber(String accountNumber) {
    // 숫자만 추출
    String numbers = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length > 8) {
      // 앞 4자리, 중간 부분은 "*"로 가리고, 마지막 4자리 표시
      return '${numbers.substring(0, 4)}****${numbers.substring(numbers.length - 4)}';
    } else if (numbers.length > 4) {
      // 짧은 계좌번호는 앞 2자리와 마지막 2자리만 표시
      return '${numbers.substring(0, 2)}**${numbers.substring(numbers.length - 2)}';
    } else {
      // 너무 짧으면 그대로 표시
      return numbers;
    }
  }

  // 숫자 포맷 (천 단위 콤마)
  String _numberFormat(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}

class ChartCategory {
  final String name;
  final double amount;
  final int percent;
  final Color color;
  
  ChartCategory({
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
  });
}

class DonutChartPainter extends CustomPainter {
  final List<ChartCategory> categories;
  
  DonutChartPainter({this.categories = const []});
  
  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.2;
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    double radius = (size.width - strokeWidth) / 2;
    Offset center = Offset(size.width / 2, size.height / 2);
    
    if (categories.isEmpty || categories.length == 1 && categories[0].name == '지출 없음') {
      // 데이터가 없거나 지출이 없는 경우, 회색 원 그리기
      paint.color = Colors.grey.withAlpha(76);
      canvas.drawCircle(center, radius, paint);
      return;
    }
    
    double startAngle = -0.5 * 3.14; // 12시 방향에서 시작
    
    for (var category in categories) {
      final sweepAngle = category.percent / 100 * 2 * 3.14;
      paint.color = category.color;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}