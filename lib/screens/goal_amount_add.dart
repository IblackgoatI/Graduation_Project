/// 목표 금액 추가 화면
/// 목표 계좌에 금액을 추가하는 화면입니다.
library;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GoalAmountAddScreen extends StatefulWidget {
  final Map<String, dynamic> goalData;

  const GoalAmountAddScreen({
    super.key,
    required this.goalData,
  });

  @override
  State<GoalAmountAddScreen> createState() => _GoalAmountAddScreenState();
}

class _GoalAmountAddScreenState extends State<GoalAmountAddScreen> {
  bool _isLoading = false;
  final TextEditingController _amountController = TextEditingController();
  int _currentBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // 현재 계좌 잔액 로드
  Future<void> _loadCurrentBalance() async {
    try {
      String? bankId = widget.goalData['bank'];
      if (bankId != null) {
        DocumentSnapshot assetDoc = await FirebaseFirestore.instance
            .collection('assets')
            .doc(bankId)
            .get();
        
        if (assetDoc.exists) {
          Map<String, dynamic> assetData = assetDoc.data() as Map<String, dynamic>;
          setState(() {
            _currentBalance = (assetData['balance'] as num?)?.toInt() ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('잔액 조회 오류: $e');
    }
  }

  // 금액 포맷팅
  String _formatAmount(String value) {
    if (value.isEmpty) return '';
    
    // 숫자만 추출
    String numbersOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numbersOnly.isEmpty) return '';
    
    // 천 단위 구분자 추가
    int amount = int.parse(numbersOnly);
    return NumberFormat('#,###').format(amount);
  }

  // 목표 금액 추가
  Future<void> _addAmount() async {
    // 입력 검증
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추가할 금액을 입력해주세요.')),
      );
      return;
    }

    int amount = int.tryParse(_amountController.text.trim().replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? bankId = widget.goalData['bank'];
      
      if (currentUser != null && bankId != null) {
        // 1. 계좌 잔액 업데이트
        await FirebaseFirestore.instance
            .collection('assets')
            .doc(bankId)
            .update({
              'balance': _currentBalance + amount,
            });

        // 2. transactions 서브컬렉션에 데이터 추가
        await FirebaseFirestore.instance
            .collection('assets')
            .doc(bankId)
            .collection('transactions')
            .add({
              'prevbalance': _currentBalance,
              'spend': "+",
              'transamount': amount,
              'transpartner': widget.goalData['name'],
              'transtime': FieldValue.serverTimestamp(),
            });

        // 3. ledger 컬렉션에 데이터 추가
        await FirebaseFirestore.instance
            .collection('ledger')
            .add({
              'userId': currentUser.uid,
              'type': "수입",
              'amount': amount,
              'date': FieldValue.serverTimestamp(),
              'merchant': widget.goalData['name'],
              'category': '목표',
              'paymentMethod': bankId,
              'memo': '목표',
              'tags': [],
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('목표 금액이 성공적으로 추가되었습니다.')),
          );
          Navigator.pop(context, true); // 성공적으로 추가됨을 알림
        }
      }
    } catch (e) {
      debugPrint('목표 금액 추가 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목표 금액 추가 중 오류가 발생했습니다.')),
        );
      }
    } finally {
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
      backgroundColor: const Color(0xFFF5F9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF73AD13),
        title: const Text(
          '목표 금액 추가',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF73AD13),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 목표 정보
                      const Text(
                        '목표 정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 목표명
                      Row(
                        children: [
                          const Text(
                            '목표명: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            widget.goalData['name'] ?? '목표명 없음',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 현재 잔액
                      Row(
                        children: [
                          const Text(
                            '현재 잔액: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            NumberFormat('#,###').format(_currentBalance) + '원',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF73AD13),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 금액 입력
                      const Text(
                        '추가할 금액',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '추가할 금액을 입력해주세요',
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF73AD13)),
                          ),
                          suffixText: '원',
                        ),
                        onChanged: (value) {
                          // 실시간으로 천 단위 구분자 추가
                          String formatted = _formatAmount(value);
                          if (formatted != value) {
                            _amountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 추가하기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addAmount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF73AD13),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            '추가하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
}
