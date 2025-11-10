/// 로그인하지 않은 사용자를 위한 거래 내역 목록 화면
/// 사용자의 수입/지출 거래 내역을 목록 형태로 보여줍니다.
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertest/screens/transaction_detail_screen.dart';
import 'package:provider/provider.dart';
import 'categories.dart';
import 'transaction_provider.dart';
import 'transaction.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'goal_management.dart';

class NotloginListScreen extends StatefulWidget {
  final int selectedMonth;
  final Function(DateTime?, DateTime?)? onDateRangeChanged;
  
  const NotloginListScreen({
    super.key, 
    this.selectedMonth = 0,
    this.onDateRangeChanged,
  });

  @override
  NotloginListScreenState createState() => NotloginListScreenState();
}

class NotloginListScreenState extends State<NotloginListScreen> {
  bool _showTags = true;
  bool _isLoading = true;
  List<FinancialTransaction> _transactions = [];
  // ChoiceChip 필터 상태
  final List<String> _filters = ['전체', '오늘', '1주일'];
  int _selectedFilterIndex = 0;
  // 상세 조건: 카테고리 멀티 선택, 거래유형 세그먼트
  Set<String> _selectedCategories = {};
  int _selectedTypeIndex = 0; // 0 전체, 1 수입, 2 지출
  // 날짜 범위 필터
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  // 목표 관련 상태 변수
  List<Map<String, dynamic>> _goalList = [];
  Map<String, int> _accountBalances = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR', null);
    loadTransactions();
    loadGoalData();
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

  // 목표 데이터 로드 함수
  Future<void> loadGoalData() async {
    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous';
      
      // goal 컬렉션에서 현재 사용자의 모든 목표 조회
      QuerySnapshot goalQuery = await _firestore
          .collection('goal')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> goalList = [];
      Map<String, int> accountBalances = {};

      if (goalQuery.docs.isNotEmpty) {
        // 각 목표에 대해 계좌 잔액 조회
        for (var doc in goalQuery.docs) {
          Map<String, dynamic> goalData = doc.data() as Map<String, dynamic>;
          String? bankId = goalData['bank'];
          
          // bank 필드가 있으면 assets 컬렉션에서 잔액 조회
          if (bankId != null) {
            try {
              DocumentSnapshot assetDoc = await _firestore
                  .collection('assets')
                  .doc(bankId)
                  .get();
              
              if (assetDoc.exists) {
                Map<String, dynamic> assetData = assetDoc.data() as Map<String, dynamic>;
                accountBalances[bankId] = (assetData['balance'] as num?)?.toInt() ?? 0;
              } else {
                accountBalances[bankId] = 0;
              }
            } catch (e) {
              debugPrint('은행 정보 조회 오류: $e');
              accountBalances[bankId] = 0;
            }
          }
          
          goalList.add(goalData);
        }
      }

      if (mounted) {
        setState(() {
          _goalList = goalList;
          _accountBalances = accountBalances;
        });
      }
    } catch (e) {
      debugPrint('목표 데이터 로드 오류: $e');
    }
  }

  // D-Day 계산 함수
  String _calculateDDay(dynamic deadline) {
    if (deadline == null) return '';
    
    DateTime deadlineDate;
    if (deadline is Timestamp) {
      deadlineDate = deadline.toDate();
    } else if (deadline is DateTime) {
      deadlineDate = deadline;
    } else {
      return '';
    }
    
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime targetDate = DateTime(deadlineDate.year, deadlineDate.month, deadlineDate.day);
    
    int difference = targetDate.difference(today).inDays;
    
    if (difference > 0) {
      return 'D-$difference';
    } else if (difference == 0) {
      return 'D-Day';
    } else {
      return 'D+${-difference}';
    }
  }

  // 목표 달성 퍼센트 계산 함수
  double _calculateProgressPercentage(Map<String, dynamic> goalData) {
    String? bankId = goalData['bank'];
    if (bankId == null || !_accountBalances.containsKey(bankId)) return 0.0;
    
    int goalAmount = (goalData['amount'] as num?)?.toInt() ?? 0;
    if (goalAmount == 0) return 0.0;
    
    int currentBalance = _accountBalances[bankId] ?? 0;
    
    // 목표 설정 시점의 잔액 (목표 데이터에서 가져오거나 기본값 0 사용)
    int initialBalance = (goalData['initialBalance'] as num?)?.toInt() ?? 0;
    
    // 현재 잔액에서 초기 잔액을 뺀 증가 금액
    int increasedAmount = currentBalance - initialBalance;
    
    // 증가 금액이 목표 금액에 비해 얼마나 달성되었는지 계산
    double percentage = (increasedAmount / goalAmount) * 100;
    
    // 100%를 넘지 않도록 제한
    return percentage > 100 ? 100.0 : (percentage < 0 ? 0.0 : percentage);
  }

  // 목표 섹션 위젯
  Widget _buildGoalSection() {
    if (_goalList.isEmpty) return const SizedBox.shrink();
    
    // 첫 번째 목표만 표시
    Map<String, dynamic> goalData = _goalList.first;
    double progressPercentage = _calculateProgressPercentage(goalData);
    
    return GestureDetector(
      onTap: () {
        // 목표 관리 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GoalManagementScreen(),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 목표 제목과 D-Day
            Row(
              children: [
                Expanded(
                  child: Text(
                    goalData['name'] ?? '목표명 없음',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _calculateDDay(goalData['deadline']),
                  style: const TextStyle(
                    color: Color(0xFF7D7D7D),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 진행률 막대 그래프
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progressPercentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF5E8BFE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${progressPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF73AD13),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailFilterBottomSheet(BuildContext context, List<FinancialTransaction> source) async {
    // 기본: 전체 카테고리
    List<String> categories = List<String>.from(allCategories);

    final Set<String> tempSelectedCategories = Set<String>.from(_selectedCategories);
    int tempSelectedTypeIndex = _selectedTypeIndex;
    DateTime? tempStartDate = _selectedStartDate;
    DateTime? tempEndDate = _selectedEndDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                  top: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('상세 조건', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('거래유형', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              CupertinoSegmentedControl<int>(
                                children: const {
                                  0: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Text('전체')),
                                  1: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Text('수입')),
                                  2: Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Text('지출')),
                                },
                                groupValue: tempSelectedTypeIndex,
                                onValueChanged: (val) {
                                  setModalState(() { 
                                    tempSelectedTypeIndex = val;
                                    // 거래유형 변경 시 해당 유형의 카테고리만 표시
                                    if (val == 0) {
                                      categories = List<String>.from(allCategories);
                                    } else if (val == 1) {
                                      categories = List<String>.from(incomeCategories);
                                    } else {
                                      categories = List<String>.from(expenseCategories);
                                    }
                                    // 선택된 카테고리 중 현재 표시되지 않는 것들은 선택 해제
                                    tempSelectedCategories.removeWhere((cat) => !categories.contains(cat));
                                  });
                                },
                                pressedColor: const Color(0xFF73AD13).withValues(alpha: 0.15),
                                selectedColor: const Color(0xFF73AD13),
                                unselectedColor: Colors.white,
                                borderColor: const Color(0xFF73AD13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('날짜 범위', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final DateTime? pickedStart = await showDatePicker(
                                    context: ctx,
                                    initialDate: tempStartDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                    locale: const Locale('ko', 'KR'),
                                  );
                                  if (pickedStart != null) {
                                    setModalState(() {
                                      tempStartDate = pickedStart;
                                      // 종료일이 시작일보다 이전이면 종료일 초기화
                                      if (tempEndDate != null && tempEndDate!.isBefore(pickedStart)) {
                                        tempEndDate = null;
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tempStartDate != null
                                            ? DateFormat('yyyy.MM.dd').format(tempStartDate!)
                                            : '시작일',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: tempStartDate != null ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final DateTime? pickedEnd = await showDatePicker(
                                    context: ctx,
                                    initialDate: tempEndDate ?? (tempStartDate ?? DateTime.now()),
                                    firstDate: tempStartDate ?? DateTime(2000),
                                    lastDate: DateTime(2100),
                                    locale: const Locale('ko', 'KR'),
                                  );
                                  if (pickedEnd != null) {
                                    setModalState(() {
                                      tempEndDate = pickedEnd;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tempEndDate != null
                                            ? DateFormat('yyyy.MM.dd').format(tempEndDate!)
                                            : '종료일',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: tempEndDate != null ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('카테고리', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: categories.map((cat) {
                            final bool selected = tempSelectedCategories.contains(cat);
                            return FilterChip(
                              label: Text(cat),
                              selected: selected,
                              onSelected: (val) {
                                setModalState(() {
                                  if (val) {
                                    tempSelectedCategories.add(cat);
                                  } else {
                                    tempSelectedCategories.remove(cat);
                                  }
                                });
                              },
                              selectedColor: const Color(0xFF73AD13),
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.grey.shade200,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              setState(() {
                                _selectedCategories.clear();
                                _selectedTypeIndex = 0;
                                _selectedStartDate = null;
                                _selectedEndDate = null;
                              });
                              // 날짜 범위 초기화 콜백 호출
                              if (widget.onDateRangeChanged != null) {
                                widget.onDateRangeChanged!(null, null);
                              }
                            },
                            child: const Text('초기화'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF73AD13),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              setState(() {
                                _selectedCategories = tempSelectedCategories;
                                _selectedTypeIndex = tempSelectedTypeIndex;
                                _selectedStartDate = tempStartDate;
                                _selectedEndDate = tempEndDate;
                              });
                              // 날짜 범위 변경 콜백 호출
                              if (widget.onDateRangeChanged != null) {
                                widget.onDateRangeChanged!(tempStartDate, tempEndDate);
                              }
                            },
                            child: const Text('적용'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final allTransactions = transactionProvider.transactions;
    
    // 날짜 범위 필터링 (날짜 범위가 선택되면 월 필터와 기간 필터 무시)
    List<FinancialTransaction> filteredTransactions;
    if (_selectedStartDate != null || _selectedEndDate != null) {
      // 날짜 범위가 선택되면 전체 거래에서 필터링
      filteredTransactions = allTransactions;
      filteredTransactions = filteredTransactions.where((t) {
        // 거래 날짜를 날짜만으로 정규화 (시간 제거)
        final DateTime transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
        
        // 시작일 체크
        bool afterStart = true;
        if (_selectedStartDate != null) {
          final DateTime startDate = DateTime(_selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day);
          // 시작일 포함 (같거나 이후)
          afterStart = !transactionDate.isBefore(startDate);
        }
        
        // 종료일 체크
        bool beforeEnd = true;
        if (_selectedEndDate != null) {
          final DateTime endDate = DateTime(_selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day);
          // 종료일 포함 (같거나 이전)
          beforeEnd = !transactionDate.isAfter(endDate);
        }
        
        return afterStart && beforeEnd;
      }).toList();
    } else {
      // 선택된 월에 해당하는 거래만 1차 필터링 (날짜 범위가 없을 때만 적용)
      filteredTransactions = widget.selectedMonth > 0
          ? allTransactions.where((transaction) => 
              transaction.date.month == widget.selectedMonth).toList()
          : allTransactions;
      
      // 기간 필터(전체/오늘/1주일) 2차 필터링 (날짜 범위가 없을 때만 적용)
      if (_selectedFilterIndex != 0) {
        final DateTime now = DateTime.now();
        DateTime start;
        switch (_selectedFilterIndex) {
          case 1: // 오늘
            start = DateTime(now.year, now.month, now.day);
            break;
          case 2: // 1주일
            final from = now.subtract(const Duration(days: 7));
            start = DateTime(from.year, from.month, from.day);
            break;
          default:
            start = DateTime(1900);
        }
        filteredTransactions = filteredTransactions.where((t) {
          final bool afterStart = t.date.isAfter(start) || t.date.isAtSameMomentAs(start);
          final bool beforeNow = t.date.isBefore(now) || t.date.isAtSameMomentAs(now);
          return afterStart && beforeNow;
        }).toList();
      }
    }

    // 상세 조건 필터링 (거래유형, 카테고리)
    filteredTransactions = filteredTransactions.where((t) {
      final bool typeOk = _selectedTypeIndex == 0
          ? true
          : (_selectedTypeIndex == 1 ? t.type == '수입' : t.type == '지출');
      final bool categoryOk = _selectedCategories.isEmpty
          ? true
          : _selectedCategories.contains(t.category);
      return typeOk && categoryOk;
    }).toList();
    
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
          // 기간 필터 + 상세 조건 (우측) 영역
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    children: _filters.asMap().entries.map((entry) {
                      final index = entry.key;
                      final label = entry.value;
                      final bool isSelected = _selectedFilterIndex == index;
                      return ChoiceChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        },
                        selectedColor: const Color(0xFF73AD13),
                        backgroundColor: Colors.grey.shade200,
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF73AD13) : Colors.grey.shade400,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8.0),
                _DetailFilterChip(
                  isActive: _selectedCategories.isNotEmpty || _selectedTypeIndex != 0 || _selectedStartDate != null || _selectedEndDate != null,
                  onTap: () => _openDetailFilterBottomSheet(context, allTransactions),
                ),
              ],
            ),
          ),
          
          // 목표 섹션
          if (_goalList.isNotEmpty) _buildGoalSection(),
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

class _DetailFilterChip extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _DetailFilterChip({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF73AD13) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF73AD13) : Colors.grey.shade400,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '상세 조건 ▼',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}