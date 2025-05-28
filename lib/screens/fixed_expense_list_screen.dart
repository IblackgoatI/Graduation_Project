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
  List<FinancialTransaction> _filteredTransactions = []; // 검색 결과를 위한 리스트
  final TextEditingController _searchController = TextEditingController(); // 검색어 컨트롤러
  Set<String> _existingFixedExpenseIds = {}; // 기존 고정지출 ID 저장

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR', null);
    _loadExistingFixedExpenses().then((_) => loadTransactions());
  }

  @override
  void dispose() {
    _searchController.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  Future<void> _loadExistingFixedExpenses() async {
    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous';
      QuerySnapshot querySnapshot = await _firestore
          .collection('fixed_expenses')
          .where('userId', isEqualTo: userId)
          .get();

      setState(() {
        _existingFixedExpenseIds = querySnapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['originalTransactionId'] as String)
            .toSet();
      });

      debugPrint('기존 고정지출 수: ${_existingFixedExpenseIds.length}');
    } catch (e) {
      debugPrint('기존 고정지출 로드 오류: $e');
    }
  }

  Future<void> loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 월의 시작일과 마지막일 계산
      DateTime now = DateTime.now();
      DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
      DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      debugPrint('조회 기간: ${firstDayOfMonth.toString()} ~ ${lastDayOfMonth.toString()}');

      // Provider에서 먼저 데이터를 가져옵니다
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final providerTransactions = transactionProvider.transactions;
      
      // Provider에 데이터가 있으면 현재 월의 지출 데이터만 필터링하여 사용
      if (providerTransactions.isNotEmpty) {
        final filteredTransactions = providerTransactions
            .where((transaction) => 
                transaction.type == '지출' &&
                transaction.date.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
                transaction.date.isBefore(lastDayOfMonth.add(const Duration(days: 1))))
            .toList();
            
        debugPrint('Provider에서 이번 달 거래내역 ${filteredTransactions.length}개 로드 완료');
            
        setState(() {
          _transactions = filteredTransactions;
          _filteredTransactions = filteredTransactions;
          _isLoading = false;
        });
        
        return;
      }
      
      // Provider에 데이터가 없으면 Firestore에서 가져옵니다
      debugPrint('Provider에 데이터가 없어 Firestore에서 로드합니다');
      String userId = _auth.currentUser?.uid ?? 'anonymous';

      QuerySnapshot querySnapshot = await _firestore
          .collection('ledger')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: '지출')
          .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
          .where('date', isLessThanOrEqualTo: lastDayOfMonth)
          .orderBy('date', descending: true)
          .get();

      debugPrint('이번 달 거래 내역 수: ${querySnapshot.docs.length}개');

      List<FinancialTransaction> transactions = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // 태그 데이터 디버그
        var rawTags = data['tags'];
        debugPrint('원본 태그 데이터: $rawTags');
        
        List<String> tags = [];
        if (rawTags != null) {
          if (rawTags is List) {
            tags = rawTags.map((tag) => tag.toString()).toList();
          }
        }
        debugPrint('변환된 태그 리스트: $tags');

        return FinancialTransaction(
          id: doc.id,
          type: data['type'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
          merchant: data['merchant'] ?? '',
          memo: data['memo'] ?? '',
          tags: tags,
          category: data['category'] ?? '',
          paymentMethod: data['paymentMethod'] ?? '',
        );
      }).toList();

      // 거래 내역 디버그
      for (var transaction in transactions) {
        debugPrint('거래 내역 태그: ${transaction.tags}');
      }

      // 가져온 데이터를 Provider에도 저장합니다
      if (transactions.isNotEmpty) {
        transactionProvider.setTransactions(transactions);
      }

      setState(() {
        _transactions = transactions;
        _filteredTransactions = transactions;
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
          'tags': transaction.tags,  // 태그 추가
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 내역이 고정지출로 등록되었습니다')),
      );
      
      // 이전 화면으로 돌아갈 때 true를 반환하여 데이터 새로고침 트리거
      Navigator.pop(context, true);
      
    } catch (e) {
      debugPrint('고정지출 저장 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('고정지출 등록 중 오류가 발생했습니다')),
      );
    }
  }

  // 트랜잭션 선택/해제 토글
  void _toggleTransactionSelection(FinancialTransaction transaction) {
    // 이미 고정지출로 등록된 내역이면 선택 불가
    if (_existingFixedExpenseIds.contains(transaction.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 고정지출로 등록된 내역입니다')),
      );
      return;
    }

    setState(() {
      if (_selectedTransactions.contains(transaction)) {
        _selectedTransactions.remove(transaction);
      } else {
        _selectedTransactions.add(transaction);
      }
    });
  }

  // 태그 검색 함수 추가
  void _searchByTag(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTransactions = _transactions;
      } else {
        _filteredTransactions = _transactions.where((transaction) {
          return transaction.tags.any((tag) =>
              tag.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 날짜별로 그룹화하기 (필터링된 거래 내역 사용)
    Map<String, List<FinancialTransaction>> groupedTransactions = {};
    for (var transaction in _filteredTransactions) {
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
          // 검색창 추가
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '고정지출에 포함할 내역을 선택해주세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withAlpha(51)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchByTag,
                    decoration: InputDecoration(
                      hintText: '가계부 내역의 태그를 검색해주세요',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
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
              : _filteredTransactions.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text(
                          '검색 결과가 없습니다.',
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
                                        color: _existingFixedExpenseIds.contains(transaction.id)
                                            ? Colors.grey[200] // 이미 등록된 고정지출
                                            : isSelected
                                                ? const Color(0xFF9BE4AF) // 새로 선택된 항목
                                                : Colors.white, // 미선택 항목
                                        borderRadius: BorderRadius.circular(8.0),
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
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            transaction.merchant,
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.grey[800],
                                                            ),
                                                          ),
                                                          if (_existingFixedExpenseIds.contains(transaction.id))
                                                            Text(
                                                              '이미 등록된 고정지출',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey[600],
                                                              ),
                                                            ),
                                                        ],
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
                                                if (transaction.tags.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 8,
                                                    children: transaction.tags.map((tag) {
                                                      return Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[200],
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          '#$tag',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
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