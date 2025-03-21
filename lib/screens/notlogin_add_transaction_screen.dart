import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // 수입 카테고리 목록
  final List<String> _incomeCategories = ['급여', '사업수입', '용돈', '판매'];

  // 지출 카테고리 목록
  final List<String> _expenseCategories = ['식비', '카페', '간식', '생활', '쇼핑', '뷰티', '교통', '통신', '문화', '교육', '만남'];

  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _updateFormattedDate();
    _merchantController.addListener(_updateMerchantName);
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
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

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

  // Firestore에 데이터 저장 메서드
  Future<void> _saveTransactionToFirestore() async {
    try {
      // 금액 변환 (쉼표나 '원' 단위 제거)
      final amount = double.tryParse(_amountController.text.replaceAll(",", "").replaceAll("원", "")) ?? 0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('금액을 올바르게 입력해주세요.')),
        );
        return;
      }

      // 현재 로그인된 사용자 정보 (없으면 "anonymous" 사용)
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      // Transaction 객체 생성
      final transaction = FinancialTransaction(
        id: DateTime.now().toString(),
        type: _selectedType,
        amount: amount,
        date: _selectedDate,
        merchant: _merchantController.text,
        memo: _memoController.text,
        tags: _tags,
        category: _selectedCategory, // 카테고리 정보 추가
      );

      // Transaction 객체에서 Firestore 데이터 형식 생성
      Map<String, dynamic> transactionData = {
        'userId': userId,
        'type': transaction.type,
        'amount': transaction.amount,
        'date': Timestamp.fromDate(transaction.date),
        'merchant': transaction.merchant,
        'category': transaction.category,
        'paymentMethod': transaction.paymentMethod,
        'memo': transaction.memo,
        'tags': transaction.tags,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Firestore의 ledger 컬렉션에 데이터 추가
      await _firestore.collection('ledger').add(transactionData);

      // Provider에 Transaction 추가
      Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction);

      // 저장 후 화면 닫기 (true를 반환하여 저장이 성공했음을 알림)
      Navigator.pop(context, true);
    } catch (e) {
      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
      );
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
                            decoration: const InputDecoration(
                              hintText: '0원',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
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
                    _buildRowWithInputController('거래처', '입력하세요', _merchantController),
                    const SizedBox(height: 24.0),
                    _buildRowWithText('결제수단', '선택하세요'),
                    const SizedBox(height: 24.0),
                    _buildDateSelector('날짜', _formattedDate),
                    const SizedBox(height: 24.0),
                    _buildRowWithInputController('메모', '입력하세요', _memoController),
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

  /// '카테고리', '결제수단' 등의 행 생성
  Widget _buildRowWithText(String title, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          text,
          style: const TextStyle(color: Colors.grey),
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
  Widget _buildRowWithInputController(String title, String hintText, TextEditingController controller) {
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
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              hintStyle: const TextStyle(color: Colors.grey),
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