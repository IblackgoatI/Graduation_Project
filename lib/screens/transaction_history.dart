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
  List<Map<String, dynamic>> filteredTransactions = []; // 필터링된 거래 내역
  bool isLoading = true;
  String? selectedPeriod; // 선택된 기간 ('1month' 또는 '3months')
  String? selectedSpend; // '+'(입금) 또는 '-'(출금)

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
          _applyFilter(); // 필터 적용
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

  // 필터 적용 함수
  void _applyFilter() {
    List<Map<String, dynamic>> base = List.from(transactions);
    
    if (selectedPeriod != null) {
      final now = DateTime.now();
      DateTime filterDate = now;
      if (selectedPeriod == '1month') {
        filterDate = now.subtract(const Duration(days: 30));
      } else if (selectedPeriod == '3months') {
        filterDate = now.subtract(const Duration(days: 90));
      }

      base = base.where((t) {
        final raw = t['transtime'];
        if (raw is! Timestamp) return false;
        final d = raw.toDate();
        return !d.isBefore(filterDate); // filterDate 이상
      }).toList();
    }

    // 입출금 필터 ('+' 또는 '-')
    if (selectedSpend != null) {
      base = base.where((t) => (t['spend'] ?? '') == selectedSpend).toList();
    }

    filteredTransactions = base;
    setState(() {}); // 리스트 갱신 반영
  }

  // 기간 선택 함수
  void _selectPeriod(String period) {
    setState(() {
      if (selectedPeriod == period) {
        // 같은 버튼을 다시 클릭하면 선택 해제
        selectedPeriod = null;
      } else {
        // 다른 기간 선택
        selectedPeriod = period;
      }
      _applyFilter();
    });
  }

  // 입출금 필터 선택 함수
  void _selectSpend(String spend) {
    setState(() {
      if (selectedSpend == spend) {
        selectedSpend = null; // 재클릭 → 해제
      } else {
        selectedSpend = spend;
      }
      _applyFilter();
    });
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

  // 기간 선택 버튼 위젯
  Widget _buildPeriodButton(String label, String period) {
    bool isSelected = selectedPeriod == period;
    
    return GestureDetector(
      onTap: () => _selectPeriod(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF73AD13) : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF73AD13) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 입출금 필터 버튼 위젯
  Widget _buildSpendButton(String label, String spend) {
    final bool isSelected = selectedSpend == spend;

    return GestureDetector(
      onTap: () => _selectSpend(spend),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF73AD13) : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF73AD13) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
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

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildPeriodButton('1개월', '1month'),
                const SizedBox(width: 12),
                _buildPeriodButton('3개월', '3months'),
                const SizedBox(width: 58),
                _buildSpendButton('입금', '+'),
                const SizedBox(width: 12),
                _buildSpendButton('출금', '-'),
              ],
            ),
          ),

          // 거래 내역 목록
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTransactions.isEmpty
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
                        itemCount: filteredTransactions.length,
                        separatorBuilder: (context, index) => const Divider(
                          color: Colors.black,
                          thickness: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          
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
