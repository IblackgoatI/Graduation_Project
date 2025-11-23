/// 포인트 관리 화면
/// 사용자의 현재 보유 포인트 및 누적 포인트를 표시하고, 포인트를 획득할 수 있는 방법들의 진행 상황을 보여줍니다.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PointManagementScreen extends StatefulWidget {
  const PointManagementScreen({super.key});

  @override
  State<PointManagementScreen> createState() => _PointManagementScreenState();
}

class _PointManagementScreenState extends State<PointManagementScreen> {
  int _currentPoints = 0;
  int _totalAccumulatedPoints = 0; // 누적 포인트
  bool _isLoading = true;
  bool _isDailyQuizCompletedToday = false;
  bool _isAttendanceCompletedToday = false;
  // TODO: 예산 목표 달성 상태 추가 (추후 구현)
  bool _isBudgetGoalAchieved = false;

  @override
  void initState() {
    super.initState();
    _loadPointData();
  }

  Future<void> _loadPointData() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
      return;
    }

    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // 1. 사용자 포인트 정보 가져오기 (user_points 컬렉션에서)
      final pointsDoc = await FirebaseFirestore.instance
          .collection('user_points')
          .doc(user.uid)
          .get();
      
      if (pointsDoc.exists) {
        final pointsData = pointsDoc.data();
        _currentPoints = (pointsData?['currentPoints'] as num?)?.toInt() ?? 0;
        _totalAccumulatedPoints = (pointsData?['totalAccumulatedPoints'] as num?)?.toInt() ?? 0;
      } else {
        // 문서가 없는 경우 초기화
        await FirebaseFirestore.instance
            .collection('user_points')
            .doc(user.uid)
            .set({
          'currentPoints': 0,
          'totalAccumulatedPoints': 0,
          'lastUpdated': Timestamp.now(),
        });
      }

      // 2. 일일 경제 퀴즈 완료 여부 확인
      final dailyQuizDoc = await FirebaseFirestore.instance
          .collection('user_daily_quizzes')
          .doc(user.uid)
          .collection('solved_quizzes')
          .doc(todayDate)
          .get();
      _isDailyQuizCompletedToday = dailyQuizDoc.exists && (dailyQuizDoc.data()?['isCorrect'] == true || dailyQuizDoc.data()?['isCorrect'] == false); // 풀기만 하면 완료로 간주

      // 3. 출석 체크 완료 여부 확인
      final attendanceDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(user.uid)
          .get();
      if (attendanceDoc.exists) {
        final lastCheckDate = (attendanceDoc.data()?['lastCheckDate'] as Timestamp?)?.toDate();
        if (lastCheckDate != null) {
          _isAttendanceCompletedToday = DateFormat('yyyy-MM-dd').format(lastCheckDate) == todayDate;
        }
      }

      // TODO: 4. 예산 목표 달성 여부 확인 로직 추가 (추후 구현)
      // 현재는 임시로 false
      _isBudgetGoalAchieved = false; // Placeholder

    } catch (e) {
      debugPrint('Error loading point data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 출금하기 기능
  Future<void> _withdrawPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_currentPoints < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출금 가능한 최소 포인트는 1,000P입니다.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // 계좌 선택 다이얼로그 표시
    final selectedAccount = await _showSelectAccountDialog();
    if (selectedAccount == null) return;

    // 출금 금액 입력 다이얼로그 표시
    final withdrawAmount = await _showWithdrawAmountDialog();
    if (withdrawAmount == null || withdrawAmount <= 0) return;

    if (withdrawAmount > _currentPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보유 포인트보다 많은 금액을 출금할 수 없습니다.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (withdrawAmount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 출금 금액은 1,000P입니다.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // 출금 확인 다이얼로그
    final confirmed = await _showWithdrawConfirmDialog(selectedAccount, withdrawAmount);
    if (confirmed != true) return;

    // 출금 처리
    await _processWithdrawal(user.uid, selectedAccount, withdrawAmount);
  }

  // 계좌 선택 다이얼로그
  Future<Map<String, dynamic>?> _showSelectAccountDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // 사용자의 계좌 목록 가져오기
    final assetsSnapshot = await FirebaseFirestore.instance
        .collection('assets')
        .where('userId', isEqualTo: user.uid)
        .get();

    if (assetsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록된 계좌가 없습니다. 먼저 계좌를 등록해주세요.'), backgroundColor: Colors.orange),
      );
      return null;
    }

    List<Map<String, dynamic>> accounts = assetsSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    Map<String, dynamic>? selectedAccount;

    return await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '출금할 계좌를 선택해주세요',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 10),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _buildAccountIcon(account),
                          title: Text(
                            account['bank'] ?? '은행',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${account['account'] ?? ''}\n${_formatNumber(account['balance'] ?? 0)}원',
                          ),
                          trailing: Radio<String>(
                            value: account['id'],
                            groupValue: selectedAccount?['id'],
                            onChanged: (String? value) {
                              setDialogState(() {
                                selectedAccount = account;
                              });
                            },
                            activeColor: const Color(0xFF73AD13),
                          ),
                          onTap: () {
                            setDialogState(() {
                              selectedAccount = account;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedAccount == null
                          ? null
                          : () {
                              Navigator.pop(context, selectedAccount);
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
                        '다음',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 출금 금액 입력 다이얼로그
  Future<int?> _showWithdrawAmountDialog() async {
    final TextEditingController amountController = TextEditingController();
    
    return await showDialog<int?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('출금 금액 입력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '보유 포인트: ${_formatNumber(_currentPoints)}P',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '최소 출금 금액: 1,000P',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '출금할 포인트',
                  suffixText: 'P',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = int.tryParse(amountController.text);
                Navigator.pop(context, amount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF73AD13),
                foregroundColor: Colors.white,
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // 출금 확인 다이얼로그
  Future<bool?> _showWithdrawConfirmDialog(Map<String, dynamic> account, int amount) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('출금 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('출금 계좌: ${account['bank']}'),
              Text('계좌번호: ${account['account']}'),
              const SizedBox(height: 10),
              Text(
                '출금 금액: ${_formatNumber(amount)}P',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '위 계좌로 포인트를 출금하시겠습니까?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF73AD13),
                foregroundColor: Colors.white,
              ),
              child: const Text('출금하기'),
            ),
          ],
        );
      },
    );
  }

  // 출금 처리
  Future<void> _processWithdrawal(String userId, Map<String, dynamic> account, int amount) async {
    try {
      final currentTime = Timestamp.now();
      
      // 1. 사용자 포인트 차감
      await FirebaseFirestore.instance
          .collection('user_points')
          .doc(userId)
          .update({
        'currentPoints': FieldValue.increment(-amount),
        'lastUpdated': currentTime,
      });

      // 2. 계좌 잔액 조회 및 업데이트
      final accountDocRef = FirebaseFirestore.instance
          .collection('assets')
          .doc(account['id']);
      
      final accountDoc = await accountDocRef.get();
      final currentBalance = (accountDoc.data()?['balance'] as num?)?.toInt() ?? 0;
      
      await accountDocRef.update({
        'balance': FieldValue.increment(amount),
      });

      // 3. 출금 내역 기록 (point_withdrawals 컬렉션)
      await FirebaseFirestore.instance
          .collection('point_withdrawals')
          .add({
        'userId': userId,
        'accountId': account['id'],
        'bank': account['bank'],
        'accountNumber': account['account'],
        'amount': amount,
        'withdrawalDate': currentTime,
        'status': 'completed',
      });

      // 4. 가계부(ledger)에 수입 내역 추가
      await FirebaseFirestore.instance.collection('ledger').add({
        'userId': userId,
        'type': '수입',
        'amount': amount.toDouble(),
        'date': currentTime,
        'merchant': '포인트 출금',
        'category': '기타수입',
        'paymentMethod': account['id'],
        'memo': '포인트 ${_formatNumber(amount)}P 출금',
        'tags': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. 계좌 거래 내역 추가 (assets의 transactions 서브컬렉션)
      await FirebaseFirestore.instance
          .collection('assets')
          .doc(account['id'])
          .collection('transactions')
          .add({
        'prevbalance': currentBalance,
        'spend': '+',
        'transamount': amount,
        'transpartner': '포인트 출금',
        'transtime': currentTime,
      });

      // UI 업데이트
      setState(() {
        _currentPoints -= amount;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_formatNumber(amount)}P가 출금되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 데이터 새로고침
      await _loadPointData();

    } catch (e) {
      debugPrint('Error processing withdrawal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('출금 처리 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 계좌 아이콘 빌드
  Widget _buildAccountIcon(Map<String, dynamic> account) {
    final bank = account['bank'] ?? '';
    final assetType = account['assetType'] ?? 'savings';
    
    // 은행 이미지 경로 매핑
    final bankImageMap = {
      '신한은행': 'assets/banks/Shinhan_Square.png',
      '국민은행': 'assets/banks/KB_Square.png',
      '우리은행': 'assets/banks/Woori_Square.png',
      '하나은행': 'assets/banks/Hana_Square.png',
      'NH농협은행': 'assets/banks/NH_Square.png',
      'IBK기업은행': 'assets/banks/IBK_Square.png',
      '카카오뱅크': 'assets/banks/Kakao_Square.png',
      '케이뱅크': 'assets/banks/Kbank_Square.png',
      'SC제일은행': 'assets/banks/SC_Square.png',
      '부산은행': 'assets/banks/Busan_Square.png',
      '광주은행': 'assets/banks/Gwangju_Square.png',
      '제주은행': 'assets/banks/Jeju_Square.png',
      '전북은행': 'assets/banks/Jeonbuk_Square.png',
      '경남은행': 'assets/banks/Kyungnam_Square.png',
      'MG새마을금고': 'assets/banks/MG_Square.png',
      '신협': 'assets/banks/Sinhyup_Square.png',
      '저축은행': 'assets/banks/Sh_Square.png',
      'KDB산업은행': 'assets/banks/KDB_Square.png',
      'IM투자증권': 'assets/banks/IM_Square.png',
    };

    final imagePath = bankImageMap[bank];

    if (imagePath != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _getDefaultIcon(assetType);
            },
          ),
        ),
      );
    }

    return _getDefaultIcon(assetType);
  }

  Widget _getDefaultIcon(String assetType) {
    IconData iconData;
    Color iconColor;

    switch (assetType) {
      case 'savings':
        iconData = Icons.account_balance_wallet;
        iconColor = const Color(0xFF4CAF50);
        break;
      case 'deposit':
        iconData = Icons.savings;
        iconColor = const Color(0xFF2196F3);
        break;
      case 'stock':
        iconData = Icons.show_chart;
        iconColor = const Color(0xFFFF9800);
        break;
      default:
        iconData = Icons.account_balance;
        iconColor = const Color(0xFF9E9E9E);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '포인트 관리',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // 'P' 아이콘 (이미지와 유사한 보라색)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0), // 보라색
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 보유 포인트 카드
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.blueAccent, // 이미지의 파란색
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          '보유 포인트: $_currentPoints P',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 출금하기 버튼
                  ElevatedButton(
                    onPressed: _withdrawPoints,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BC34A), // 이미지의 녹색
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      '출금하기',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 포인트를 얻는 방법 섹션
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA), // 연한 하늘색 배경 (이미지 유사)
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '포인트를 얻는 방법',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9C27B0), // 보라색
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 일일 섹션
                        const Text(
                          '일일',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPointEarnMethodItem(
                          '경제 퀴즈',
                          Icons.receipt_long,
                          _isDailyQuizCompletedToday,
                          '완료',
                          '미완료',
                          const Color(0xFF673AB7), // 보라색 아이콘
                          const Color(0xFF9C27B0), // 보라색 텍스트
                        ),
                        _buildPointEarnMethodItem(
                          '출석 체크',
                          Icons.card_giftcard,
                          _isAttendanceCompletedToday,
                          '완료',
                          '미완료',
                          const Color(0xFF8BC34A), // 녹색 아이콘
                          const Color(0xFF8BC34A), // 녹색 텍스트
                        ),
                        const SizedBox(height: 16),
                        // 월간 섹션
                        const Text(
                          '월간',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPointEarnMethodItem(
                          '예산 목표달성',
                          Icons.flag, // 목표 달성 아이콘
                          _isBudgetGoalAchieved,
                          '좋은 소비에요',
                          '목표 미달성',
                          Colors.blue, // 파란색 아이콘
                          const Color(0xFF8BC34A), // 녹색 텍스트 (좋은 소비에요)
                          iconColorIfIncomplete: Colors.red, // 미달성 시 빨간색 아이콘
                          textColorIfIncomplete: Colors.red, // 미달성 시 빨간색 텍스트
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 누적 포인트
                  Text(
                    '누적 포인트: $_totalAccumulatedPoints P',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16), // 하단 여백
                ],
              ),
            ),
    );
  }

  Widget _buildPointEarnMethodItem(
      String title,
      IconData icon,
      bool isCompleted,
      String completedText,
      String incompleteText,
      Color completedIconColor,
      Color completedTextColor,
      {Color? iconColorIfIncomplete, Color? textColorIfIncomplete}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: isCompleted ? completedIconColor : (iconColorIfIncomplete ?? Colors.grey),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isCompleted ? completedTextColor : (textColorIfIncomplete ?? Colors.black87),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.transparent : Colors.transparent, // 이미지에선 배경색이 없거나 투명
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted ? Colors.transparent : Colors.transparent, // 이미지에선 테두리가 없음
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.cancel,
                  color: isCompleted ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  isCompleted ? completedText : incompleteText,
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 