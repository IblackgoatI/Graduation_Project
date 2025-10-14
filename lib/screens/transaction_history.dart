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
  String? selectedPeriod; // 선택된 기간 ('1month', '3months', 또는 'custom')
  String? selectedSpend; // '+'(입금), '-'(출금), 또는 'all'(전체)
  DateTime? customStartDate; // 직접입력 시작 날짜
  DateTime? customEndDate; // 직접입력 종료 날짜
  bool showDatePicker = false; // 날짜 선택 박스 표시 여부

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
      DateTime? filterStartDate;
      
      if (selectedPeriod == '1month') {
        filterStartDate = DateTime.now().subtract(const Duration(days: 30));
      } else if (selectedPeriod == '3months') {
        filterStartDate = DateTime.now().subtract(const Duration(days: 90));
      } else if (selectedPeriod == 'custom' && customStartDate != null) {
        filterStartDate = customStartDate;
      }

      if (filterStartDate != null) {
        base = base.where((t) {
          final raw = t['transtime'];
          if (raw is! Timestamp) return false;
          final d = raw.toDate();
          
          if (selectedPeriod == 'custom' && customEndDate != null && filterStartDate != null) {
            // 직접입력의 경우 시작일과 종료일 사이 (포함)
            final startOfDay = DateTime(filterStartDate.year, filterStartDate.month, filterStartDate.day);
            final endOfDay = DateTime(customEndDate!.year, customEndDate!.month, customEndDate!.day, 23, 59, 59);
            return d.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
                   d.isBefore(endOfDay.add(const Duration(milliseconds: 1)));
          } else {
            // 1개월, 3개월의 경우 시작일 이후
            return !d.isBefore(filterStartDate!);
          }
        }).toList();
      }
    }

    // 입출금 필터 ('+', '-', 또는 'all')
    if (selectedSpend != null && selectedSpend != 'all') {
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
        showDatePicker = false;
        customStartDate = null;
        customEndDate = null;
      } else {
        // 다른 기간 선택
        selectedPeriod = period;
        if (period == 'custom') {
          showDatePicker = true;
        } else {
          showDatePicker = false;
          customStartDate = null;
          customEndDate = null;
        }
      }
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
    });
  }


  // 모달용 날짜 선택 함수 (StateSetter 포함)
  void _selectCustomDateRangeForModal(StateSetter setModalState) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: customStartDate != null && customEndDate != null
          ? DateTimeRange(start: customStartDate!, end: customEndDate!)
          : null,
    );
    
    if (picked != null) {
      setModalState(() {
        customStartDate = picked.start;
        customEndDate = picked.end;
      });
    }
  }

  // 조회하기 버튼 클릭 시 필터 적용
  void _applyQuery() {
    _applyFilter();
    Navigator.of(context).pop(); // 모달 닫기
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

  // 조회조건 선택 모달 표시
  void _showQueryConditionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, size: 24),
                      ),
                      const Text(
                        '조회조건 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24), // 균형을 위한 공간
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // 조회기간 섹션
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '조회기간',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildModalPeriodButton('1개월', '1month', setModalState),
                      const SizedBox(width: 12),
                      _buildModalPeriodButton('3개월', '3months', setModalState),
                      const SizedBox(width: 12),
                      _buildModalPeriodButton('직접입력', 'custom', setModalState),
                    ],
                  ),
                  
                  // 날짜 선택 박스 (직접입력 선택 시에만 표시)
                  if (showDatePicker) ...[
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '시작일',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customStartDate != null
                                        ? '${customStartDate!.year}.${customStartDate!.month.toString().padLeft(2, '0')}.${customStartDate!.day.toString().padLeft(2, '0')}'
                                        : '선택 안됨',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: customStartDate != null ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    '종료일',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customEndDate != null
                                        ? '${customEndDate!.year}.${customEndDate!.month.toString().padLeft(2, '0')}.${customEndDate!.day.toString().padLeft(2, '0')}'
                                        : '선택 안됨',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: customEndDate != null ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () => _selectCustomDateRangeForModal(setModalState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF73AD13),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: const Text('날짜 선택'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // 거래구분 섹션
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '거래구분',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildModalSpendButton('전체', 'all', setModalState),
                      const SizedBox(width: 12),
                      _buildModalSpendButton('입금', '+', setModalState),
                      const SizedBox(width: 12),
                      _buildModalSpendButton('출금', '-', setModalState),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 하단 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyQuery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF73AD13),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('조회하기'),
                        ),
                      ),
                    ],
                  ),
                  
                  // 하단 여백 (키보드 대응)
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 모달 내 기간 선택 버튼
  Widget _buildModalPeriodButton(String label, String period, StateSetter setModalState) {
    bool isSelected = selectedPeriod == period;
    
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectPeriod(period);
        });
      },
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

  // 모달 내 거래구분 버튼
  Widget _buildModalSpendButton(String label, String spend, StateSetter setModalState) {
    bool isSelected = selectedSpend == spend;
    
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectSpend(spend);
        });
      },
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _showQueryConditionsModal,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
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
