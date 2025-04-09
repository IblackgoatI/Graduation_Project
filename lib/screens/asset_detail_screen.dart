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
        title: const Text('자산'),
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
                fontWeight: FontWeight.bold,
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
                          painter: DonutChartPainter(),
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
                        children: [
                          _buildLegendItem('식비', '33%', Colors.blue),
                          const SizedBox(height: 4),
                          _buildLegendItem('여행', '25%', Colors.green),
                          const SizedBox(height: 4),
                          _buildLegendItem('쇼핑', '25%', Colors.orange),
                          const SizedBox(height: 4),
                          _buildLegendItem('기타', '17%', Colors.red),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: Text(
              '70만원',
              style: TextStyle(
                fontSize: 12, // 금액 텍스트 크기 감소
                fontWeight: FontWeight.bold,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '고정지출',
            style: TextStyle(
              fontSize: 14, // 제목 텍스트 크기 감소
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          const Text(
            '고정지출을 추가하세요',
            style: TextStyle(
              fontSize: 12, // 안내 텍스트 크기 감소
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // 고정지출 추가 로직
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF73AD13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              minimumSize: const Size(double.infinity, 36), // 버튼 높이 감소
            ),
            child: const Text(
              '고정지출 추가',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11, // 버튼 텍스트 크기 감소
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 이번 달 예산 카드
  Widget _buildMonthlyBudgetCard() {
    return _buildStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 예산',
            style: TextStyle(
              fontSize: 14, // 제목 텍스트 크기 감소
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          const Text(
            '예산을 설정하세요',
            style: TextStyle(
              fontSize: 12, // 안내 텍스트 크기 감소
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // 월 예산 설정 로직
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF73AD13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              minimumSize: const Size(double.infinity, 36), // 버튼 높이 감소
            ),
            child: const Text(
              '월 예산 설정',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11, // 버튼 텍스트 크기 감소
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 이번 달 저축 카드
  Widget _buildMonthlySavingsCard() {
    return _buildStandardCard(
      height: 250, // 높이 더 증가
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 저축',
            style: TextStyle(
              fontSize: 14, // 제목 텍스트 크기 감소
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          const Center(
            child: Text(
              '0원',
              style: TextStyle(
                fontSize: 16, // 금액 텍스트 크기 감소
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // 월 목표 설정 로직
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF73AD13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              minimumSize: const Size(double.infinity, 36), // 버튼 높이 감소
            ),
            child: const Text(
              '월 목표 설정',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11, // 버튼 텍스트 크기 감소
              ),
            ),
          ),
        ],
      ),
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
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          '${_numberFormat(_totalAssets)}원',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
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
                    ),
                  ),
                  Text(
                    '${_numberFormat(_savingsTotal + _depositTotal + _cashTotal)}원',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
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
                    ),
                  ),
                  Text(
                    '${_numberFormat(_savingsTotal)}원',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
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
                fontWeight: FontWeight.bold,
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
              fontWeight: FontWeight.bold,
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

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.2;
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    double radius = (size.width - strokeWidth) / 2;
    Offset center = Offset(size.width / 2, size.height / 2);

    // 식비 33%
    paint.color = Colors.blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.14,
      0.33 * 2 * 3.14,
      false,
      paint,
    );

    // 여행 25%
    paint.color = Colors.green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.33 * 2 * 3.14 - 0.5 * 3.14,
      0.25 * 2 * 3.14,
      false,
      paint,
    );

    // 쇼핑 25%
    paint.color = Colors.orange;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      (0.33 + 0.25) * 2 * 3.14 - 0.5 * 3.14,
      0.25 * 2 * 3.14,
      false,
      paint,
    );

    // 기타 17%
    paint.color = Colors.red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      (0.33 + 0.25 + 0.25) * 2 * 3.14 - 0.5 * 3.14,
      0.17 * 2 * 3.14,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}