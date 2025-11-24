/// 로그인하지 않은 사용자를 위한 거래 추가 화면 (가계부)
/// 사용자가 수입/지출 내역을 입력하고 관리할 수 있도록 합니다.
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'category_edit_screen.dart';
import 'category_manager.dart';

class NotloginAddTransactionScreen extends StatefulWidget {
  const NotloginAddTransactionScreen({super.key});

  @override
  NotloginAddTransactionScreenState createState() =>
      NotloginAddTransactionScreenState();
}

class NotloginAddTransactionScreenState extends State<NotloginAddTransactionScreen> {
  String _selectedType = '지출';
  late DateTime _selectedDate;
  late String _formattedDate;
  String _merchantName = '거래처';
  String _selectedCategory = '미분류';
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final List<String> _tags = [];

  // 동적 카테고리 목록
  List<String> _incomeCategories = [];
  List<String> _expenseCategories = [];

  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 선택된 결제 수단 이름 및 ID
  String _selectedPaymentMethodName = '선택하세요';
  String? _selectedPaymentMethodId;

  // 목표 카테고리용 입금/출금 계좌 선택 변수 추가
  String _selectedIncomeAccountName = '선택하세요';
  String? _selectedIncomeAccountId;
  String _selectedExpenseAccountName = '선택하세요';
  String? _selectedExpenseAccountId;

  // 금액 입력 포맷터 추가
  final List<TextInputFormatter> _amountInputFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text.replaceAll(',', '');
      if (text.isEmpty) return newValue.copyWith(text: '');
      final number = int.parse(text);
      final formatted = NumberFormat('#,###').format(number);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _updateFormattedDate();
    _merchantController.addListener(_updateMerchantName);
    _loadCategories();
  }

  // 카테고리 로드
  Future<void> _loadCategories() async {
    try {
      // 캐시 초기화 후 새로 로드
      CategoryManager.clearCache();
      final incomeCats = await CategoryManager.getIncomeCategories();
      final expenseCats = await CategoryManager.getExpenseCategories();
      
      setState(() {
        _incomeCategories = incomeCats;
        _expenseCategories = expenseCats;
      });
    } catch (e) {
      debugPrint('카테고리 로드 실패: $e');
      // 기본 카테고리 사용
      setState(() {
        _incomeCategories = ['급여', '사업수입', '용돈', '판매'];
        _expenseCategories = [
          '식비',
          '카페',
          '간식',
          '생활',
          '쇼핑',
          '뷰티',
          '교통',
          '통신',
          '문화',
          '교육',
          '만남',
          '목표 저축',
          '저축',
        ];
      });
    }
  }

  @override
  void dispose() {
    _merchantController.removeListener(_updateMerchantName);
    _merchantController.dispose();
    _amountController.dispose();
    _tagController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _updateMerchantName() {
    setState(() {
      _merchantName = _merchantController.text.isNotEmpty ? _merchantController.text : '거래처';
    });
  }

  void _updateFormattedDate() {
    final DateFormat formatter = DateFormat('yyyy년 M월 d일 a h:mm', 'ko_KR');
    _formattedDate = formatter.format(_selectedDate)
        .replaceAll('AM', '오전')
        .replaceAll('PM', '오후');
  }

  // 태그 추가 메서드
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  // 태그 삭제 메서드
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // 카테고리 선택 다이얼로그 표시 메서드
  void _showCategoryDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedType = '수입';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _selectedType == '수입' ? Colors.black : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '수입',
                                      style: TextStyle(
                                        fontWeight: _selectedType == '수입' ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedType = '지출';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _selectedType == '지출' ? Colors.black : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '지출',
                                      style: TextStyle(
                                        fontWeight: _selectedType == '지출' ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToCategoryEdit();
                        },
                        tooltip: '카테고리 편집',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 4,
                      childAspectRatio: 1.0,
                      padding: const EdgeInsets.all(4.0),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      shrinkWrap: true,
                      children: _selectedType == '수입'
                          ? _buildCategoryWidgets(_incomeCategories)
                          : _buildCategoryWidgets(_expenseCategories),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((value) {
      // 바텀시트가 닫힌 후 메인 화면의 상태 업데이트
      setState(() {});
    }    );
  }

  // 카테고리 편집 화면으로 이동
  void _navigateToCategoryEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryEditScreen(type: _selectedType),
      ),
    ).then((_) {
      // 편집 화면에서 돌아왔을 때 카테고리 목록 새로고침
      _loadCategories();
    });
  }

  // 카테고리 위젯 목록 생성
  List<Widget> _buildCategoryWidgets(List<String> categories) {
    return categories.map((category) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
          Navigator.pop(context);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(category),
          ),
        ),
      );
    }).toList();
  }

  // 날짜 및 시간 선택 메서드
  void _selectDateTime(BuildContext context) async {
    if (!mounted) return;
    final currentContext = context; // 현재 컨텍스트 저장

    final DateTime? pickedDate = await showDatePicker(
      context: currentContext, // 저장된 컨텍스트 사용
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (!mounted) return; // async gap 이후 mounted 확인

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: currentContext, // 저장된 컨텍스트 사용
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (!mounted) return; // async gap 이후 mounted 확인

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _updateFormattedDate();
        });
      }
    }
  }

  // 결제 수단 선택 다이얼로그 표시 메서드 (목표 카테고리용으로 수정)
  void _showPaymentMethodDialog() async {
    if (!mounted) return;
    final currentContext = context;
    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    QuerySnapshot assetsSnapshot = await _firestore
        .collection('assets')
        .where('userId', isEqualTo: userId)
        .get();

    if (!mounted) return;

    List<Map<String, String>> paymentMethods = [
      {'id': "현금", 'bank': "현금"}
    ];

    paymentMethods.addAll(assetsSnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'bank': doc['bank'] as String? ?? '이름 없음',
      };
    }).toList());

    // 목표 카테고리인 경우 입금/출금 계좌 선택 다이얼로그 표시
    if (_selectedCategory == '목표 저축') {
      _showGoalAccountDialog(currentContext, paymentMethods);
    } else {
      _showSinglePaymentMethodDialog(currentContext, paymentMethods);
    }
  }

  // 단일 결제수단 선택 다이얼로그
  void _showSinglePaymentMethodDialog(BuildContext context, List<Map<String, String>> paymentMethods) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '계좌 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = paymentMethods[index];
                    return ListTile(
                      title: Text(method['bank']!),
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethodName = method['bank']!;
                          _selectedPaymentMethodId = method['id']!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 목표 카테고리용 입금/출금 계좌 선택 다이얼로그
  void _showGoalAccountDialog(BuildContext context, List<Map<String, String>> paymentMethods) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '목표 계좌 선택',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // 출금 계좌 선택
                  const Text(
                    '출금 계좌',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        _showAccountSelectionDialog(context, paymentMethods, '출금', (name, id) {
                          setState(() {
                            _selectedExpenseAccountName = name;
                            _selectedExpenseAccountId = id;
                          });
                        });
                      },
                      child: Text(
                        _selectedExpenseAccountName,
                        style: TextStyle(
                          color: _selectedExpenseAccountId == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 입금 계좌 선택
                  const Text(
                    '입금 계좌',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        _showAccountSelectionDialog(context, paymentMethods, '입금', (name, id) {
                          setState(() {
                            _selectedIncomeAccountName = name;
                            _selectedIncomeAccountId = id;
                          });
                        });
                      },
                      child: Text(
                        _selectedIncomeAccountName,
                        style: TextStyle(
                          color: _selectedIncomeAccountId == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 확인 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedExpenseAccountId != null && _selectedIncomeAccountId != null) {
                          setState(() {
                            _selectedPaymentMethodName = '$_selectedExpenseAccountName → $_selectedIncomeAccountName';
                          });
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('출금 계좌와 입금 계좌를 모두 선택해주세요.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('확인'),
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

  // 계좌 선택 다이얼로그
  void _showAccountSelectionDialog(
    BuildContext context,
    List<Map<String, String>> paymentMethods,
    String type,
    Function(String, String) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$type 계좌 선택',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = paymentMethods[index];
                    return ListTile(
                      title: Text(method['bank']!),
                      onTap: () {
                        onSelected(method['bank']!, method['id']!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Firestore에 데이터 저장 메서드 (목표 카테고리 처리 추가)
  Future<void> _saveTransactionToFirestore() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

    try {
      final amount = double.tryParse(_amountController.text.replaceAll(",", "").replaceAll("원", "")) ?? 0;
      final amountInt = amount.toInt();

      if (amountInt <= 0) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('금액을 올바르게 입력해주세요.')),
        );
        return;
      }

      // 목표 카테고리인 경우 입금/출금 계좌 검증
      if (_selectedCategory == '목표 저축') {
        if (_selectedExpenseAccountId == null || _selectedIncomeAccountId == null) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('출금 계좌와 입금 계좌를 모두 선택해주세요.')),
          );
          return;
        }
      } else {
        if (_selectedPaymentMethodId == null) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('결제수단을 선택해주세요.')),
          );
          return;
        }
      }

      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      if (_selectedCategory == '목표 저축') {
        // 목표 카테고리인 경우 두 개의 거래 내역 생성
        await _saveGoalTransactions(userId, amount, amountInt, transactionProvider);
      } else {
        // 일반 거래 내역 저장
        await _saveSingleTransaction(userId, amount, amountInt, transactionProvider);
      }

      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
      );
      debugPrint('[NotloginAddTransactionScreen] Error saving transaction: $e');
    }
  }

  // 목표 카테고리용 두 개의 거래 내역 저장
  Future<void> _saveGoalTransactions(String userId, double amount, int amountInt, TransactionProvider transactionProvider) async {
    final timestamp = DateTime.now();
    
    // 1. 출금 거래 내역 (지출) - 카테고리는 미분류로 설정 (목표 통계 중복 방지)
    final expenseTransactionData = {
      'userId': userId,
      'type': '지출',
      'amount': amount,
      'date': Timestamp.fromDate(_selectedDate),
      'merchant': _merchantController.text,
      'category': '목표 저축', // 목표 저축으로 통일
      'paymentMethod': _selectedExpenseAccountId,
      'memo': _memoController.text,
      'tags': _tags,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedTransactionId': timestamp.toString(), // 관련 거래 식별자
    };

    // 2. 입금 거래 내역 (수입) - 카테고리는 목표로 설정
    final incomeTransactionData = {
      'userId': userId,
      'type': '수입',
      'amount': amount,
      'date': Timestamp.fromDate(_selectedDate),
      'merchant': _merchantController.text,
      'category': '목표 저축', // 목표 저축으로 통일
      'paymentMethod': _selectedIncomeAccountId,
      'memo': _memoController.text,
      'tags': _tags,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedTransactionId': timestamp.toString(), // 관련 거래 식별자
    };

    // Firestore에 두 개의 거래 내역 저장
    final expenseDocRef = await _firestore.collection('ledger').add(expenseTransactionData);
    final incomeDocRef = await _firestore.collection('ledger').add(incomeTransactionData);

    // 출금 계좌 잔액 업데이트
    if (_selectedExpenseAccountId != null && _selectedExpenseAccountId != "현금") {
      await _updateAccountBalance(_selectedExpenseAccountId!, amountInt, '-');
    }

    // 입금 계좌 잔액 업데이트
    if (_selectedIncomeAccountId != null && _selectedIncomeAccountId != "현금") {
      await _updateAccountBalance(_selectedIncomeAccountId!, amountInt, '+');
    }

    // Provider에 두 개의 거래 내역 추가
    final expenseDoc = await expenseDocRef.get();
    final incomeDoc = await incomeDocRef.get();

    if (expenseDoc.exists && incomeDoc.exists) {
      
      final expenseTransaction = FinancialTransaction(
        id: expenseDoc.id,
        type: '지출',
        amount: amount,
        date: _selectedDate,
        merchant: _merchantController.text,
        memo: _memoController.text,
        tags: _tags,
        category: '목표 저축', // 목표 저축으로 통일
        paymentMethod: _selectedExpenseAccountId!,
      );

      final incomeTransaction = FinancialTransaction(
        id: incomeDoc.id,
        type: '수입',
        amount: amount,
        date: _selectedDate,
        merchant: _merchantController.text,
        memo: _memoController.text,
        tags: _tags,
        category: '목표 저축', // 목표 저축으로 통일
        paymentMethod: _selectedIncomeAccountId!,
      );

      transactionProvider.addTransaction(expenseTransaction);
      transactionProvider.addTransaction(incomeTransaction);
    }
  }

  // 일반 거래 내역 저장 (기존 로직)
  Future<void> _saveSingleTransaction(String userId, double amount, int amountInt, TransactionProvider transactionProvider) async {
    final transaction = FinancialTransaction(
      id: DateTime.now().toString(),
      type: _selectedType,
      amount: amount,
      date: _selectedDate,
      merchant: _merchantController.text,
      memo: _memoController.text,
      tags: _tags,
      category: _selectedCategory,
      paymentMethod: _selectedPaymentMethodId ?? '',
    );

    Map<String, dynamic> transactionData = {
      'userId': userId,
      'type': transaction.type,
      'amount': transaction.amount,
      'date': Timestamp.fromDate(transaction.date),
      'merchant': transaction.merchant,
      'category': transaction.category,
      'paymentMethod': _selectedPaymentMethodId == "현금" ? "현금" : _selectedPaymentMethodId,
      'memo': transaction.memo,
      'tags': transaction.tags,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection('ledger').add(transactionData);

    // 계좌 잔액 업데이트
    if (_selectedPaymentMethodId != null && _selectedPaymentMethodId != "현금") {
      String operation = _selectedType == "지출" ? '-' : '+';
      await _updateAccountBalance(_selectedPaymentMethodId!, amountInt, operation);
    }

    // Provider에 거래 내역 추가
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final data = docSnap.data() as Map<String, dynamic>;
      String paymentMethodValueFromFirestore = data['paymentMethod'] ?? '';
      String finalPaymentMethodIdForObject;

      if (paymentMethodValueFromFirestore == "현금") {
        finalPaymentMethodIdForObject = "현금";
      } else {
        finalPaymentMethodIdForObject = paymentMethodValueFromFirestore;
      }

      final syncedTransaction = FinancialTransaction(
        id: docSnap.id,
        type: data['type'] ?? '',
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        date: (data['date'] is Timestamp)
            ? (data['date'] as Timestamp).toDate()
            : DateTime.now(),
        merchant: data['merchant'] ?? '',
        memo: data['memo'] ?? '',
        tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        category: data['category'] ?? '미분류',
        paymentMethod: finalPaymentMethodIdForObject,
      );

      transactionProvider.addTransaction(syncedTransaction);
    }
  }

  // 계좌 잔액 업데이트 헬퍼 메서드
  Future<void> _updateAccountBalance(String accountId, int amount, String operation) async {
    try {
      DocumentSnapshot assetDoc = await _firestore.collection('assets').doc(accountId).get();
      
      if (assetDoc.exists) {
        int currentBalance = ((assetDoc.data() as Map<String, dynamic>)['balance'] ?? 0).toInt();
        int newBalance = operation == '+' ? currentBalance + amount : currentBalance - amount;
        
        await _firestore.collection('assets').doc(accountId).update({
          'balance': newBalance
        });
        
        // 계좌 거래 내역 추가
        await _firestore.collection('assets').doc(accountId)
            .collection('transactions').add({
          'prevbalance': currentBalance,
          'spend': operation,
          'transamount': amount,
          'transpartner': _merchantController.text,
          'transtime': Timestamp.fromDate(_selectedDate),
        });
      }
    } catch (e) {
      debugPrint('[NotloginAddTransactionScreen] Error updating account balance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(51),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _merchantName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _amountController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            inputFormatters: _amountInputFormatters,
                            maxLength: 11, // 1,000,000,000까지 입력 가능
                            decoration: const InputDecoration(
                              hintText: '0원',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                              counterText: '',
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32.0),
                    _buildRowWithButtons('분류', ['수입', '지출']),
                    const SizedBox(height: 32.0),
                    _buildRowWithTextButton('카테고리', _selectedCategory),
                    const SizedBox(height: 24.0),
                    _buildRowWithInputController('거래처', '입력하세요', _merchantController, maxLength: 10),
                    const SizedBox(height: 24.0),
                    _buildPaymentMethodRow('결제수단', _selectedPaymentMethodName),
                    const SizedBox(height: 24.0),
                    _buildDateSelector('날짜', _formattedDate),
                    const SizedBox(height: 24.0),
                    _buildRowWithInputController('메모', '입력하세요', _memoController, maxLength: 15),
                    const SizedBox(height: 24.0),
                    _buildTagInput(),
                    const SizedBox(height: 40.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveTransactionToFirestore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 태그 입력란 위젯
  Widget _buildTagInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '태그',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _tagController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                maxLength: 5,
                decoration: InputDecoration(
                  hintText: '입력하세요',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addTag,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          children: _tags.map((tag) {
            return Chip(
              label: Text(tag),
              onDeleted: () => _removeTag(tag),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// '분류' 버튼 생성
  Widget _buildRowWithButtons(String title, List<String> options) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: options
              .map((option) => Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: _buildCategoryButton(option, isSelected: _selectedType == option),
          ))
              .toList(),
        ),
      ],
    );
  }

  /// 클릭 가능한 텍스트 버튼이 있는 행 생성 (카테고리용)
  Widget _buildRowWithTextButton(String title, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: _showCategoryDialog,
          child: Text(
            text,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  /// 결제 수단 선택 행 생성
  Widget _buildPaymentMethodRow(String title, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: _showPaymentMethodDialog,
          child: Text(
            text,
            style: TextStyle(
                color: _selectedPaymentMethodId == null
                    ? Colors.grey
                    : Colors.black),
          ),
        ),
      ],
    );
  }

  /// 날짜 선택기 생성
  Widget _buildDateSelector(String title, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: () => _selectDateTime(context),
          child: Text(
            text,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  /// 컨트롤러가 있는 입력 필드 생성
  Widget _buildRowWithInputController(String title, String hintText, TextEditingController controller, {int? maxLength}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          width: 200,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              hintStyle: const TextStyle(color: Colors.grey),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  /// '수입' / '지출' 버튼 스타일 지정
  Widget _buildCategoryButton(String text, {bool isSelected = false}) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedType = text;
          // 타입이 변경되면 기본 카테고리를 미분류로 설정
          _selectedCategory = '미분류';
        });
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isSelected ? Colors.purple : Colors.grey,
        ),
        backgroundColor: isSelected ? Colors.purple.withAlpha(26) : Colors.transparent,
        foregroundColor: isSelected ? Colors.purple : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(text),
    );
  }
}