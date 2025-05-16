import 'package:flutter/material.dart';
import 'package:fluttertest/screens/transaction_detail_screen.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'transaction.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotloginListScreen extends StatefulWidget {
  final int selectedMonth;
  
  const NotloginListScreen({super.key, this.selectedMonth = 0});

  @override
  NotloginListScreenState createState() => NotloginListScreenState();
}

class NotloginListScreenState extends State<NotloginListScreen> {
  bool _showTags = true;
  bool _isLoading = true;
  List<FinancialTransaction> _transactions = [];

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
      String userId = _auth.currentUser?.uid ?? 'anonymous';

      QuerySnapshot querySnapshot = await _firestore
          .collection('ledger')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

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

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });

      // 거래내역을 Provider에 저장
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      transactionProvider.setTransactions(transactions);
      
      debugPrint('notlogin_list_screen: ${transactions.length}개 거래내역 로드 및 Provider 설정 완료');

    } catch (e) {
      debugPrint('트랜잭션 불러오기 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 트랜잭션 삭제 메서드 추가
  void _deleteTransaction(String transactionId) {
    setState(() {
      _transactions.removeWhere((transaction) => transaction.id == transactionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final allTransactions = transactionProvider.transactions;
    
    // 선택된 월에 해당하는 거래만 필터링
    final filteredTransactions = widget.selectedMonth > 0
        ? allTransactions.where((transaction) => 
            transaction.date.month == widget.selectedMonth).toList()
        : allTransactions;
    
    // 날짜별로 그룹화하기
    Map<String, List<FinancialTransaction>> groupedTransactions = {};
    for (var transaction in filteredTransactions) {
      String formattedDate = DateFormat('d일 EEEE', 'ko_KR').format(transaction.date);
      if (!groupedTransactions.containsKey(formattedDate)) {
        groupedTransactions[formattedDate] = [];
      }
      groupedTransactions[formattedDate]!.add(transaction);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Text(
                  '태그 표시',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  decoration: BoxDecoration(
                    color: _showTags ? Colors.green : Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: _showTags ? Colors.green : Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showTags = !_showTags;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.check,
                        size: 18.0,
                        color: _showTags ? Colors.white : Colors.transparent,
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
              child: CircularProgressIndicator(),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      ...entry.value.map((transaction) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionDetailScreen(
                                  transaction: transaction,
                                  // 삭제 콜백 전달
                                  onTransactionDeleted: _deleteTransaction,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withAlpha(26),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 40,
                                  alignment: Alignment.center,
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
                                        '${transaction.type == '수입' ? '+' : '-'}${NumberFormat('#,###').format(transaction.amount)}원',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: transaction.type == '수입' ? const Color(0xFF73AD13) : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 태그 표시 애니메이션
                                AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 300),
                                  crossFadeState: _showTags && transaction.tags.isNotEmpty
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  firstChild: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 300),
                                      opacity: _showTags ? 1 : 0,
                                      child: Wrap(
                                        spacing: 8.0,
                                        children: transaction.tags.map((tag) {
                                          return Text(
                                            '#$tag',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  secondChild: const SizedBox.shrink(),
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
        ],
      ),
    );
  }
}