import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final Map<String, dynamic>? account;
  final User? user;

  const TransactionHistoryScreen({
    super.key,
    this.account,
    this.user,
  });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      
      if (currentUser != null && widget.account != null) {
        // 해당 계좌의 서브 컬렉션 transactions에서 거래 내역을 가져옵니다
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('assets')
            .doc(widget.account!['id'])
            .collection('transactions')
            .orderBy('transtime', descending: true) // 최신순 정렬
            .get();

        setState(() {
          transactions = querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('거래 내역 로드 오류: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatTime(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('HH:mm').format(date); // 시, 분만 표시
  }

  String _numberFormat(num number) {
    return number.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  int _safeIntConvert(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Color _getAmountColor(String spend) {
    if (spend == '-') {
      return const Color(0xFFFF4848); // 빨간색
    } else if (spend == '+') {
      return const Color(0xFF73AD13); // 초록색
    }
    return Colors.black; // 기본 색상
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account?['bank'] ?? '계좌'} 거래내역'),
        backgroundColor: const Color(0xFF73AD13),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 중앙 상단부에 "입출금 내역 조회" 텍스트 추가
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            child: const Text(
              '입출금 내역 조회',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          // 거래 내역 목록
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                    ? const Center(
                        child: Text(
                          '거래 내역이 없습니다.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: transactions.length,
                        separatorBuilder: (context, index) => const Divider(
                          color: Colors.black,
                          thickness: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 좌측: transtime과 transpartner
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatTime(transaction['transtime']),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        transaction['transpartner'] ?? '거래처',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // 우측: prevbalance와 transamount
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${_numberFormat(_safeIntConvert(transaction['prevbalance']))}원',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${transaction['spend'] ?? ''}${_numberFormat(_safeIntConvert(transaction['transamount']))}원',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _getAmountColor(transaction['spend'] ?? ''),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
