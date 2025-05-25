import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'transaction.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FixedExpenseListScreen extends StatefulWidget {
  const FixedExpenseListScreen({super.key});

  @override
  FixedExpenseListScreenState createState() => FixedExpenseListScreenState();
}

class FixedExpenseListScreenState extends State<FixedExpenseListScreen> {
  bool _isLoading = true;
  List<FinancialTransaction> _transactions = [];
  List<FinancialTransaction> _selectedTransactions = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR', null);
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Provider에서 먼저 데이터를 가져옵니다
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final providerTransactions = transactionProvider.transactions;
      
      // Provider에 데이터가 있으면 사용
      if (providerTransactions.isNotEmpty) {
        // 지출 데이터만 필터링
        final filteredTransactions = providerTransactions
            .where((transaction) => transaction.type == '지출')
            .toList();
            
        setState(() {
          _transactions = filteredTransactions;
          _isLoading = false;
        });
        
        debugPrint('Provider에서 거래내역 ${filteredTransactions.length}개 로드 완료');
        return;
      }
      
      // Provider에 데이터가 없으면 Firestore에서 가져옵니다
      debugPrint('Provider에 데이터가 없어 Firestore에서 로드합니다');
      String userId = _auth.currentUser?.uid ?? 'anonymous';

      QuerySnapshot querySnapshot = await _firestore
          .collection('ledger')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: '지출')
          .orderBy('date', descending: true)
          .get();

      debugPrint('Firestore 쿼리 결과: ${querySnapshot.docs.length}개 문서');

      List<FinancialTransaction> transactions = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return FinancialTransaction(
          id: doc.id,
          type: data['type'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
          merchant: data['merchant'] ?? '',
          memo: data['memo'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          category: data['category'] ?? '',
          paymentMethod: data['paymentMethod'] ?? '',
        );
      }).toList();

      // 가져온 데이터를 Provider에도 저장합니다
      if (transactions.isNotEmpty) {
        transactionProvider.setTransactions(transactions);
      }

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
      
      debugPrint('Firestore에서 거래내역 ${transactions.length}개 로드 완료');
    } catch (e) {
      debugPrint('거래내역 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 고정지출로 선택한 트랜잭션 저장하기
  Future<void> saveSelectedTransactionsAsFixedExpenses() async {
    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous';
      
      // 선택된 각 트랜잭션에 대해 고정지출로 저장
      for (var transaction in _selectedTransactions) {
        await _firestore.collection('fixed_expenses').add({
          'userId': userId,
          'originalTransactionId': transaction.id,
          'type': transaction.type,
          'amount': transaction.amount,
          'merchant': transaction.merchant,
          'category': transaction.category,
          'memo': transaction.memo,
          'paymentMethod': transaction.paymentMethod,
          'date': transaction.date,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 내역이 고정지출로 등록되었습니다')),
      );
      Navigator.pop(context); // 저장 후 이전 화면으로 돌아가기
      
    } catch (e) {
      debugPrint('고정지출 저장 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('고정지출 등록 중 오류가 발생했습니다')),
      );
    }
  }

  // 트랜잭션 선택/해제 토글
  void _toggleTransactionSelection(FinancialTransaction transaction) {
    setState(() {
      if (_selectedTransactions.contains(transaction)) {
        _selectedTransactions.remove(transaction);
      } else {
        _selectedTransactions.add(transaction);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 날짜별로 그룹화하기
    Map<String, List<FinancialTransaction>> groupedTransactions = {};
    for (var transaction in _transactions) {
      String formattedDate = DateFormat('d일 EEEE', 'ko_KR').format(transaction.date);
      if (!groupedTransactions.containsKey(formattedDate)) {
        groupedTransactions[formattedDate] = [];
      }
      groupedTransactions[formattedDate]!.add(transaction);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: const Text(
          '고정지출에 포함할 내역 선택',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '고정지출에 포함할 내역을 선택해주세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
          
          _isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF73AD13),
                    ),
                  ),
                )
              : _transactions.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text(
                          '거래 내역이 없습니다.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: loadTransactions,
                        color: const Color(0xFF73AD13),
                        child: ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: groupedTransactions.entries.map((entry) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                ...entry.value.map((transaction) {
                                  // 이미 선택되었는지 확인
                                  bool isSelected = _selectedTransactions.contains(transaction);
                                  
                                  return InkWell(
                                    onTap: () => _toggleTransactionSelection(transaction),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8.0),
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF9BE4AF) : Colors.white,
                                        borderRadius: BorderRadius.circular(8.0),
                                        // 그림자 효과를 약하게 설정
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.08),
                                            spreadRadius: 0,
                                            blurRadius: 1,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          // 내용
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  transaction.merchant,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                Text(
                                                  '-${NumberFormat('#,###').format(transaction.amount)}원',
                                                  style: const TextStyle(
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
                                    ),
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
          
          // 하단 완료 버튼
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: ElevatedButton(
              onPressed: _selectedTransactions.isNotEmpty
                  ? saveSelectedTransactionsAsFixedExpenses
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF73AD13),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                '완료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 