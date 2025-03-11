import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotloginAddTransactionScreen extends StatefulWidget {
  const NotloginAddTransactionScreen({super.key});

  @override
  _NotloginAddTransactionScreenState createState() =>
      _NotloginAddTransactionScreenState();
}

class _NotloginAddTransactionScreenState extends State<NotloginAddTransactionScreen> {
  String _selectedType = '지출';
  late DateTime _selectedDate;
  late String _formattedDate;
  String _merchantName = '거래처'; // 거래처 이름을 저장할 변수 추가
  final TextEditingController _merchantController = TextEditingController(); // 텍스트 컨트롤러 추가

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // 현재 날짜와 시간으로 초기화
    _updateFormattedDate(); // 날짜 포맷 초기화

    // 텍스트 컨트롤러에 리스너 추가
    _merchantController.addListener(_updateMerchantName);
  }

  @override
  void dispose() {
    // 컨트롤러 메모리 해제
    _merchantController.removeListener(_updateMerchantName);
    _merchantController.dispose();
    super.dispose();
  }

  // 거래처 이름 업데이트 메서드
  void _updateMerchantName() {
    setState(() {
      // 입력값이 비어있지 않으면 입력값으로 설정, 비어있으면 기본값 유지
      _merchantName = _merchantController.text.isNotEmpty
          ? _merchantController.text
          : '거래처';
    });
  }

  // 날짜 포맷을 업데이트하는 메서드
  void _updateFormattedDate() {
    // DateFormat 사용을 위해 intl 패키지를 pubspec.yaml에 추가
    // 년, 월, 일, 오전/오후, 시간, 분 포맷으로 변환
    final DateFormat formatter = DateFormat('yyyy년 M월 d일 a h:mm', 'ko_KR');
    _formattedDate = formatter.format(_selectedDate)
        .replaceAll('AM', '오전')
        .replaceAll('PM', '오후');
  }

  // 날짜 선택 다이얼로그를 표시하는 메서드
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      // 시간 선택 다이얼로그 표시
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.grey[100],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 70.0), // 상단 여백 조정
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
                mainAxisSize: MainAxisSize.min, // 이 부분이 컨테이너 크기를 내용에 맞게 조정
                children: [
                  // 뒤로 가기 버튼만 포함된 Row (거래 추가 텍스트 제거)
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
                        _merchantName, // 거래처 이름을 동적으로 표시
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '0원',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32.0),
                  _buildRowWithButtons('분류', ['수입', '지출']),
                  const SizedBox(height: 32.0),
                  _buildRowWithText('카테고리', '미분류'),
                  const SizedBox(height: 24.0),
                  _buildRowWithInputController('거래처', '입력하세요', _merchantController), // 컨트롤러 전달
                  const SizedBox(height: 24.0),
                  _buildRowWithText('결제수단', '선택하세요'),
                  const SizedBox(height: 24.0),
                  _buildDateSelector('날짜', _formattedDate),
                  const SizedBox(height: 24.0),
                  _buildRowWithInput('메모', '입력하세요'),
                  const SizedBox(height: 24.0),
                  _buildRowWithInput('태그', '입력하세요'),
                  const SizedBox(height: 40.0),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {},
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
                  const SizedBox(height: 8.0), // 저장 버튼 아래 약간의 여백 추가
                ],
              ),
            ),
          ],
        ),
      ),
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

  /// 컨트롤러가 없는 입력 필드 생성 (기존 메서드)
  Widget _buildRowWithInput(String title, String hintText) {
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

  /// 컨트롤러가 있는 입력 필드 생성 (새로운 메서드)
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
            controller: controller, // 컨트롤러 설정
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