/// 거래 상세 화면
/// 특정 거래 내역의 상세 정보를 표시하고, 수정 또는 삭제 기능을 제공합니다.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionDetailScreen extends StatefulWidget {
  final FinancialTransaction transaction;
  final Function(String)? onTransactionDeleted; // 콜백 추가

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.onTransactionDeleted
  });

  @override
  TransactionDetailScreenState createState() => TransactionDetailScreenState();
}

class TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuth 인스턴스 추가
  bool _isEditing = false;
  late String _type;
  late String _category;
  late String _merchant;
  late DateTime _date;
  late String _memo;
  late List<String> _tags;
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  // 결제수단 관련 상태 변수
  String? _currentPaymentMethodId;
  String _currentPaymentMethodName = '로딩 중...'; // 초기값

  // 수입 카테고리 목록
  final List<String> _incomeCategories = ['급여', '사업수입', '용돈', '판매'];
  // 지출 카테고리 목록
  final List<String> _expenseCategories = ['식비', '카페', '간식', '생활', '쇼핑', '뷰티', '교통', '통신', '문화', '교육', '만남'];

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    _type = widget.transaction.type;
    _category = widget.transaction.category;
    _merchant = widget.transaction.merchant;
    _date = widget.transaction.date;
    _memo = widget.transaction.memo;
    _tags = List<String>.from(widget.transaction.tags);
    _merchantController.text = _merchant;
    _memoController.text = _memo;

    _currentPaymentMethodId = widget.transaction.paymentMethod;
    // paymentMethodId가 '현금'인 경우 _currentPaymentMethodName을 '현금'으로 설정
    if (_currentPaymentMethodId == "현금") {
      _currentPaymentMethodName = "현금";
    } else if (_currentPaymentMethodId != null && _currentPaymentMethodId!.isNotEmpty) {
      _fetchAndSetPaymentMethodName(_currentPaymentMethodId);
    } else {
      // ID가 없거나 비어있는 경우 (편집 모드가 아닐 때)
      _currentPaymentMethodName = '없음';
    }
  }

  Future<void> _fetchAndSetPaymentMethodName(String? paymentMethodId) async {
    if (paymentMethodId == "현금") {
      if (mounted) {
        setState(() {
          _currentPaymentMethodName = "현금";
        });
      }
      return;
    }
    if (paymentMethodId == null || paymentMethodId.isEmpty) {
      if (mounted) {
        setState(() {
          _currentPaymentMethodName = _isEditing ? '선택해주세요' : '없음';
        });
      }
      return;
    }

    try {
      DocumentSnapshot doc =
          await _firestore.collection('assets').doc(paymentMethodId).get();
      if (mounted) { // Firestore 호출 후 mounted 다시 확인
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _currentPaymentMethodName = data['bank'] ?? (_isEditing ? '선택해주세요' : '알 수 없음');
          });
          debugPrint('[TransactionDetailScreen/_fetchAndSetPaymentMethodName] Fetched bank name: $_currentPaymentMethodName for ID: $paymentMethodId');
        } else {
          setState(() {
            _currentPaymentMethodName = _isEditing ? '선택해주세요' : '알 수 없음';
          });
          debugPrint('[TransactionDetailScreen/_fetchAndSetPaymentMethodName] Document does not exist or has no data for ID: $paymentMethodId');
        }
      }
    } catch (e) {
      if (mounted) { // 에러 발생 후 mounted 다시 확인
        setState(() {
          _currentPaymentMethodName = _isEditing ? '선택해주세요' : '오류 발생';
        });
        // 에러 로깅
        debugPrint('[TransactionDetailScreen/_fetchAndSetPaymentMethodName] Error fetching payment method name: $e');
      }
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _memoController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider를 통해 현재 거래 내역 상태 감시
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currentTransaction = transactionProvider.transactions
        .firstWhere((t) => t.id == widget.transaction.id, orElse: () => widget.transaction);

    // 금액 표시 형식 설정
    String amountText = '${currentTransaction.type == '수입' ? '+' : '-'}${NumberFormat('#,###').format(currentTransaction.amount)}원';
    String formattedDate = DateFormat('yyyy년 M월 d일 a h:mm', 'ko_KR')
        .format(_isEditing ? _date : currentTransaction.date)
        .replaceAll('AM', '오전')
        .replaceAll('PM', '오후');

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 140.0),
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
                    // 금액 표시
                    Center(
                      child: Text(
                        amountText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: currentTransaction.type == '수입' ? Colors.green : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    _buildDetailRow('분류', currentTransaction.type),
                    const SizedBox(height: 24.0),
                    _buildDetailRow('카테고리', currentTransaction.category),
                    const SizedBox(height: 24.0),
                    _buildDetailRow('거래처', currentTransaction.merchant),
                    const SizedBox(height: 24.0),
                    _buildDetailRow('결제수단', _currentPaymentMethodName), // 수정됨
                    const SizedBox(height: 24.0),
                    _buildDetailRow('날짜', formattedDate),
                    const SizedBox(height: 24.0),
                    _buildDetailRow('메모', currentTransaction.memo.isNotEmpty ? currentTransaction.memo : '없음'),
                    const SizedBox(height: 24.0),
                    _buildTagsSection(currentTransaction.tags),
                    const SizedBox(height: 40.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isEditing
                                ? () {
                                    setState(() {
                                      _isEditing = false;
                                      _initializeValues(); // 원래 값으로 복원 및 이름 다시 로드
                                    });
                                  }
                                : () {
                                    _showDeleteConfirmation();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isEditing ? Colors.grey[200] : Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(_isEditing ? '취소' : '삭제'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_isEditing) {
                                _updateTransaction();
                              } else {
                                setState(() {
                                  _isEditing = true;
                                  // 편집 모드로 전환 시, 현재 ID가 '현금'이면 이름을 '현금'으로, 아니면 fetch
                                  if (_currentPaymentMethodId == "현금") {
                                    _currentPaymentMethodName = "현금";
                                  } else {
                                    _fetchAndSetPaymentMethodName(_currentPaymentMethodId);
                                  }
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isEditing ? const Color(0xFF73AD13) : Colors.grey[200],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(_isEditing ? '저장' : '수정'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 수정 모드에서 사용할 다이얼로그
  void _showTypeDialog() {
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _type = '수입';
                              // 분류가 변경되면 카테고리 초기화
                              _category = '미분류';
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _type == '수입' ? Colors.black : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '수입',
                                style: TextStyle(
                                  fontWeight: _type == '수입' ? FontWeight.bold : FontWeight.normal,
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
                              _type = '지출';
                              // 분류가 변경되면 카테고리 초기화
                              _category = '미분류';
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _type == '지출' ? Colors.black : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '지출',
                                style: TextStyle(
                                  fontWeight: _type == '지출' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((value) {
      // 바텀시트가 닫힌 후 메인 화면의 상태 업데이트
      if (mounted) {
        setState(() {});
      }
    });
  }

  // 카테고리 선택 다이얼로그
  void _showCategoryDialog() {
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
                '카테고리 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                  children: (_type == '수입' ? _incomeCategories : _expenseCategories).map((category) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        if (mounted) {
                          setState(() {
                            _category = category;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _category == category ? Colors.grey[200] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _category == category ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 상세 정보 행 위젯
  Widget _buildDetailRow(String title, String value) {
    if (!_isEditing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      );
    } else {
      Widget? editWidget;
      switch (title) {
        case '분류':
          editWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypeButton('수입'),
              const SizedBox(width: 8),
              _buildTypeButton('지출'),
            ],
          );
          break;
        case '카테고리':
          editWidget = GestureDetector(
            onTap: _showCategoryDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _category,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          );
          break;
        case '거래처':
          editWidget = TextField(
            controller: _merchantController,
            decoration: const InputDecoration(
              hintText: '거래처 입력',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          );
          break;
        case '결제수단':
          editWidget = GestureDetector(
            onTap: _showPaymentMethodDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _currentPaymentMethodName, // 편집 모드에서도 _currentPaymentMethodName 사용
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          );
          break;
        case '날짜':
          editWidget = GestureDetector(
            onTap: () => _selectDateTime(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                DateFormat('yyyy년 M월 d일 a h:mm', 'ko_KR')
                  .format(_date)
                  .replaceAll('AM', '오전')
                  .replaceAll('PM', '오후'),
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          );
          break;
        case '메모':
          editWidget = TextField(
            controller: _memoController,
            decoration: const InputDecoration(
              hintText: '메모 입력',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          );
          break;
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (editWidget != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: editWidget,
                ),
              ),
            ),
        ],
      );
    }
  }

  // 분류 버튼 위젯
  Widget _buildTypeButton(String type) {
    final isSelected = _type == type;
    return InkWell(
      onTap: () {
        setState(() {
          _type = type;
          _category = '미분류';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF73AD13) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 날짜 선택 다이얼로그
  void _selectDateTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );

    if (pickedTime != null) {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );

      if (pickedDate != null && mounted) {
        setState(() {
          _date = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // 결제 수단 선택 다이얼로그 (notlogin_add_transaction_screen.dart 참조)
  void _showPaymentMethodDialog() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 가져올 수 없습니다.')),
      );
      return;
    }
    String userId = currentUser.uid;

    QuerySnapshot assetsSnapshot = await _firestore
        .collection('assets')
        .where('userId', isEqualTo: userId)
        .get();

    if (!mounted) return;

    List<Map<String, String>> paymentMethods = [
      {'id': "현금", 'bank': "현금"} // "현금" 옵션 기본 추가
    ];

    paymentMethods.addAll(assetsSnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'bank': doc['bank'] as String? ?? '이름 없음',
      };
    }).toList());

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
                        if (mounted) {
                          setState(() {
                            _currentPaymentMethodId = method['id']!;
                            _currentPaymentMethodName = method['bank']!;
                          });
                        }
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

  // 거래 내역 수정 메서드
  Future<void> _updateTransaction() async {
    try {
      // 먼저 Provider를 통해 UI 업데이트
      final updatedTransaction = FinancialTransaction(
        id: widget.transaction.id,
        type: _type,
        amount: widget.transaction.amount,
        date: _date,
        merchant: _merchantController.text,
        memo: _memoController.text,
        tags: _tags,
        category: _category,
        paymentMethod: _currentPaymentMethodId ?? '', // 수정된 결제수단 ID 사용
      );

      if (mounted) {
        Provider.of<TransactionProvider>(context, listen: false)
            .updateTransaction(updatedTransaction);
      }

      // Firestore에 저장할 데이터
      String paymentMethodToStore;
      if (_currentPaymentMethodId == "현금") {
        paymentMethodToStore = "현금"; // Firestore에는 "현금" 문자열로 저장
      } else {
        paymentMethodToStore = _currentPaymentMethodId ?? '';
      }

      // Firestore 업데이트
      await _firestore.collection('ledger').doc(widget.transaction.id).update({
        'type': _type,
        'category': _category,
        'merchant': _merchantController.text,
        'date': _date,
        'memo': _memoController.text,
        'tags': _tags,
        'paymentMethod': paymentMethodToStore, // Firestore에 "현금" 또는 계좌 ID 저장
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래 내역이 수정되었습니다.')),
        );
        setState(() {
          _isEditing = false;
          // 수정 완료 후, paymentMethodId를 '현금'으로, 아니면 fetch
          if (_currentPaymentMethodId == "현금") {
            _currentPaymentMethodName = "현금";
          } else {
            _fetchAndSetPaymentMethodName(_currentPaymentMethodId);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('거래 내역 삭제'),
          content: const Text('이 거래 내역을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                _deleteTransaction();
                Navigator.pop(context); // 다이얼로그 닫기
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // 거래 내역 삭제 메서드
  Future<void> _deleteTransaction() async {
    try {
      // Firestore에서 해당 문서 삭제
      await _firestore.collection('ledger').doc(widget.transaction.id).delete();

      // 콜백 함수 호출 (삭제된 트랜잭션의 ID 전달)
      widget.onTransactionDeleted?.call(widget.transaction.id);

      // 화면 닫기
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래 내역이 삭제되었습니다.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 태그 섹션 위젯
  Widget _buildTagsSection(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '태그',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        if (_isEditing) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    hintText: '새로운 태그 입력',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty && !_tags.contains(value)) {
                      if (mounted) {
                        setState(() {
                          _tags = List.from(_tags)..add(value);
                          _tagController.clear();
                        });
                      }
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final value = _tagController.text.trim();
                  if (value.isNotEmpty && !_tags.contains(value)) {
                    if (mounted) {
                      setState(() {
                        _tags = List.from(_tags)..add(value);
                        _tagController.clear();
                      });
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8.0),
        ],
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _tags.map((tag) {
            return Chip(
              label: Text(tag),
              deleteIcon: _isEditing ? const Icon(Icons.close, size: 18) : null,
              onDeleted: _isEditing ? () {
                if (mounted) {
                  setState(() {
                    _tags = List.from(_tags)..remove(tag);
                  });
                }
              } : null,
              backgroundColor: Colors.grey[200],
              labelStyle: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}