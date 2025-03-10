import 'package:flutter/material.dart';

class NotloginAddTransactionScreen extends StatefulWidget {
  const NotloginAddTransactionScreen({super.key});

  @override
  _NotloginAddTransactionScreenState createState() =>
      _NotloginAddTransactionScreenState();
}

class _NotloginAddTransactionScreenState extends State<NotloginAddTransactionScreen> {
  String _selectedType = '지출';

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
                      const Text(
                        '거래처',
                        style: TextStyle(
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
                  _buildRowWithInput('거래처', '입력하세요'),
                  const SizedBox(height: 24.0),
                  _buildRowWithText('결제수단', '선택하세요'),
                  const SizedBox(height: 24.0),
                  _buildRowWithText('날짜', '2025년 1월 17일 오후 1:37'),
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

  /// '카테고리', '결제수단', '날짜' 등의 행 생성
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

  /// '거래처', '메모', '태그' 등의 입력 필드 생성
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