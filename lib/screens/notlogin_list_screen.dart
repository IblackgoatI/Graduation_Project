import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'transaction.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotloginListScreen extends StatefulWidget {
  const NotloginListScreen({super.key});

  @override
  NotloginListScreenState createState() => NotloginListScreenState();
}

class NotloginListScreenState extends State<NotloginListScreen> {
  bool _showTags = true;
  bool _isLoading = true;
  List<FinancialTransaction> _transactions = [];

  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Firebase Auth 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR', null);
    loadTransactions();
  }

  // Firestore에서 현재 로그인한 사용자의 거래 내역을 불러오는 메서드
  Future<void> loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 로그인된 사용자 정보 (없으면 "anonymous" 사용)
      String userId = _auth.currentUser?.uid ?? 'anonymous';

      // userId가 일치하는 문서만 조회
      QuerySnapshot querySnapshot = await _firestore
          .collection('ledger')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      // 트랜잭션 리스트 생성
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

      // Provider에도 트랜잭션 목록 업데이트
      Provider.of<TransactionProvider>(context, listen: false)
          .setTransactions(transactions);

    } catch (e) {
      debugPrint('트랜잭션 불러오기 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
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

    return Column(
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
                        entry.key, // 날짜 한 번만 출력
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    ...entry.value.map((transaction) {
                      return Container(
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
                                      return Chip(
                                        label: Text(tag),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              secondChild: const SizedBox.shrink(),
                            ),
                          ],
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
    );
  }
}