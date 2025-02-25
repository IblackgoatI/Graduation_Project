import 'package:flutter/material.dart';
import 'main_screen_nologin.dart';
import 'login.dart'; // LoginScreen 추가
import 'package:cloud_firestore/cloud_firestore.dart';

class AssetScreen extends StatefulWidget {
  const AssetScreen({super.key});

  @override
  State<AssetScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController();
  String? _selectedBank;
  int _currentPage = 0; // 현재 페이지 상태 추가
  final PageController _pageController = PageController(); // 페이지 컨트롤러 추가

  final List<Map<String, dynamic>> _banks = [
    {'name': 'KB국민은행', 'icon': 'assets/banks/KB_Square.png'},
    {'name': 'NH농협은행', 'icon': 'assets/banks/NH_Square.png'},
    {'name': '카카오뱅크', 'icon': 'assets/banks/Kakao_Square.png'},
    {'name': '신한은행', 'icon': 'assets/banks/Shinhan_Square.png'},
    {'name': '지역농협', 'icon': 'assets/banks/LocalNH_Square.png'},
    {'name': '하나은행', 'icon': 'assets/banks/Hana_Square.png'},
    {'name': '새마을금고', 'icon': 'assets/banks/MG_Square.png'},
    {'name': '우리은행', 'icon': 'assets/banks/Woori_Square.png'},
    {'name': 'IBK기업은행', 'icon': 'assets/banks/IBK_Square.png'},
    {'name': '케이뱅크', 'icon': 'assets/banks/Kbank_Square.png'},
    {'name': '신협은행', 'icon': 'assets/banks/Sinhyup_Square.png'},
    {'name': 'SC제일은행', 'icon': 'assets/banks/SC_Square.png'},
    {'name': '수협은행', 'icon': 'assets/banks/Sh_Square.png'},
    {'name': '수협중앙회', 'icon': 'assets/banks/ShMid_Square.png'},
    {'name': '광주은행', 'icon': 'assets/banks/Gwangju_Square.png'},
    {'name': '전북은행', 'icon': 'assets/banks/Jeonbuk_Square.png'},
    {'name': '제주은행', 'icon': 'assets/banks/Jeju_Square.png'},
    {'name': '한국산업은행', 'icon': 'assets/banks/KDB_Square.png'},
    {'name': 'BNK부산은행', 'icon': 'assets/banks/Busan_Square.png'},
    {'name': 'BNK경남은행', 'icon': 'assets/banks/Kyungnam_Square.png'},
    {'name': 'iM뱅크', 'icon': 'assets/banks/IM_Square.png'},
  ];

  // 모든 필드가 입력되었는지 여부
  bool get _isInputValid =>
      _accountController.text.isNotEmpty &&
          _ownerController.text.isNotEmpty &&
          _selectedBank != null;

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
      setState(() {
        _currentPage--;
      });
    } else {
      // 첫 페이지일 때 login.dart로 이동
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  void _showBankSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 높이 조절 가능하게 설정
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7, // 전체 화면의 70% 높이
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "은행 목록",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      shrinkWrap: true, // 스크롤 가능하게 설정
                      physics: NeverScrollableScrollPhysics(), // GridView 자체 스크롤 비활성화
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 4개씩 가로 배치
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1 / 1.2,
                      ),
                      itemCount: _banks.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBank = _banks[index]['name'];
                            });
                            Navigator.pop(context);
                          },
                          child: Column(
                            children: [
                              Image.asset(
                                _banks[index]['icon'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 4),
                              Text(
                                _banks[index]['name'],
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Firestore에 데이터 저장하는 함수
  Future<void> _saveData() async {
    // context를 await 이전에 변수에 저장
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance.collection('assets').add({
        'account': _accountController.text.trim(),
        'owner': _ownerController.text.trim(),
        'bank': _selectedBank,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("데이터가 저장되었습니다.")),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("데이터 저장 실패: $e")),
      );
    }
  }


  @override
  void dispose() {
    _accountController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _prevPage,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "자산 본인인증",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "자산을 연결하기 위한 본인인증이에요.\n주로 사용하는 은행 계좌를 입력해주세요.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 30),
            // 계좌번호 입력 필드
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "계좌번호를 입력 해주세요.",
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
            SizedBox(height: 20),
            // 예금주 입력 필드 추가
            TextField(
              controller: _ownerController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "예금주를 입력 해주세요.",
                labelText: "예금주",
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
            SizedBox(height: 20),
            // 은행 선택 필드
            GestureDetector(
              onTap: _showBankSelection,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedBank ?? "은행을 선택 해주세요.",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MainScreenNotLogin()),
                      );
                    },
                    child: Text("나중에 하기", style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isInputValid ? Color(0xFF73AD13) : Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _isInputValid ? _saveData : null,
                    child: Text("확인하기", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
