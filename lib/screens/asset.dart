import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'main_screen_nologin.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AssetScreen extends StatefulWidget {
  const AssetScreen({Key? key}) : super(key: key);

  @override
  State<AssetScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  final TextEditingController _accountController = TextEditingController();
  String? _selectedBank;
  int _currentPage = 0;
  final PageController _pageController = PageController();

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

  /// 계좌번호와 은행이 입력되었는지 확인
  bool get _isInputValid =>
      _accountController.text.isNotEmpty && _selectedBank != null;

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
      setState(() {
        _currentPage--;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );    }
  }

  /// 은행 목록 BottomSheet
  void _showBankSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 높이 조절 가능
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7, // 전체 높이의 70%
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "은행 목록",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
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
                              const SizedBox(height: 4),
                              Text(
                                _banks[index]['name'],
                                style: const TextStyle(fontSize: 12),
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

  // 계좌정보 조회 후 1원 송금 시뮬레이션 (API 호출 방식)
  Future<void> _checkAccountAndTransfer() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final accountInput = _accountController.text.trim();
    final bankInput = _selectedBank;

    final User? user = FirebaseAuth.instance.currentUser; // 현재 로그인된 유저 객체
    if (user == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("사용자가 로그인되어 있지 않습니다.")),
      );
      return;
    }

    try {
      // API 호출을 위한 POST 요청
      final url = 'https://transferonewon-ekqk2sqwxq-uc.a.run.app';
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'userEmail': user.email,
          'account': accountInput,
          'bank': bankInput,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String depositName = responseData['depositName'];

        // API 호출 성공 시, 결과 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssetVerificationResultScreen(
              bank: bankInput!,
              account: accountInput,
              depositName: depositName,
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("송금 실패: ${response.body}")),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("오류가 발생했습니다: $e")),
      );
    }
  }


  // 한글 한 글자와 랜덤 3자리 숫자로 입금자명 생성 (예: 가123)
  String _generateDepositName() {
    final random = Random();
    int koreanRange = 0xD7A3 - 0xAC00 + 1;
    String randomKorean =
    String.fromCharCode(0xAC00 + random.nextInt(koreanRange));
    int randomNumber = 100 + random.nextInt(900);
    return "$randomKorean$randomNumber";
  }

  @override
  void dispose() {
    _accountController.dispose();
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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "자산 본인인증",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "자산을 연결하기 위한 본인인증이에요.\n주로 사용하는 은행 계좌를 입력해주세요.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "계좌번호를 입력 해주세요.",
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _showBankSelection,
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedBank ?? "은행을 선택 해주세요.",
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainScreenNotLogin()),
                      );
                    },
                    child: const Text(
                      "나중에 하기",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      _isInputValid ? const Color(0xFF73AD13) : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _isInputValid ? _checkAccountAndTransfer : null,
                    child: const Text(
                      "확인하기",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class AssetVerificationResultScreen extends StatefulWidget {
  final String bank;
  final String account;
  final String depositName;

  const AssetVerificationResultScreen({
    Key? key,
    required this.bank,
    required this.account,
    required this.depositName,
  }) : super(key: key);

  @override
  State<AssetVerificationResultScreen> createState() =>
      _AssetVerificationResultScreenState();
}

class _AssetVerificationResultScreenState
    extends State<AssetVerificationResultScreen> {
  // 한글 입력 필드 (첫 칸)
  final TextEditingController _hangulController = TextEditingController();
  final FocusNode _hangulFocus = FocusNode();

  // 숫자 입력 필드 3개 (나머지 칸)
  final TextEditingController _numController1 = TextEditingController();
  final FocusNode _numFocus1 = FocusNode();

  final TextEditingController _numController2 = TextEditingController();
  final FocusNode _numFocus2 = FocusNode();

  final TextEditingController _numController3 = TextEditingController();
  final FocusNode _numFocus3 = FocusNode();

  final String maskedTime = "**** 11:59";
  final String transferAmount = "+1원";
  final String balance = "100,000원";

  @override
  void dispose() {
    _hangulController.dispose();
    _hangulFocus.dispose();
    _numController1.dispose();
    _numFocus1.dispose();
    _numController2.dispose();
    _numFocus2.dispose();
    _numController3.dispose();
    _numFocus3.dispose();
    super.dispose();
  }

  // 한글 필드
  // 첫 문자가 한글(가~힣)인 경우만 다음 필드로 포커스 이동
  void _onHangulChanged(String value) {
    if (value.isNotEmpty) {
      final lastChar = value.codeUnitAt(value.length - 1);
      if (lastChar >= 0xAC00 && lastChar <= 0xD7A3) {
        setState(() {
          _hangulController.text = String.fromCharCode(lastChar);
        });
        FocusScope.of(context).requestFocus(_numFocus1);
      }
    }
  }

  // 숫자 필드
  // 2~4번째 문자는 숫자로입력, 입력받을시 바로 다음 필드로 포커스 이동
  void _onNumberChanged(String value, FocusNode currentFocus, FocusNode? nextFocus) {
    if (value.length == 1) {
      if (nextFocus != null) {
        FocusScope.of(context).requestFocus(nextFocus);
      } else {
        currentFocus.unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
          child: Column(
            children: [
              // 상단 문구 등 기존 내용...
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("자산 본인인증", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("1원이 입금되었습니다.\n내역을 확인 후, 입금자명을 입력 해주세요.", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              // 은행정보, 4칸 입력란, 힌트 등 나머지...
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "${widget.bank} ${widget.account}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 한글 입력 필드
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: TextField(
                          controller: _hangulController,
                          focusNode: _hangulFocus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                          decoration: InputDecoration(
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                          onChanged: _onHangulChanged,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 숫자 입력 필드 1
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: TextField(
                          controller: _numController1,
                          focusNode: _numFocus1,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                          onChanged: (val) => _onNumberChanged(val, _numFocus1, _numFocus2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 숫자 입력 필드 2
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: TextField(
                          controller: _numController2,
                          focusNode: _numFocus2,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                          onChanged: (val) => _onNumberChanged(val, _numFocus2, _numFocus3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 숫자 입력 필드 3
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: TextField(
                          controller: _numController3,
                          focusNode: _numFocus3,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                          onChanged: (val) => _onNumberChanged(val, _numFocus3, null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 거래내역 박스
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              maskedTime,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue, // 파란색
                                fontWeight: FontWeight.bold, // 볼드체
                              ),
                            ),
                            Text(
                              transferAmount,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(balance, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ],
          ),
        ),
      ),
      // 확인하기 버튼 (키보드 열리면 같이 올라감)
      bottomNavigationBar: AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 10),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF73AD13),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // 사용자가 입력한 값 4개 텍스트를 모두 합치기.
                String userInput = _hangulController.text +
                    _numController1.text +
                    _numController2.text +
                    _numController3.text;

                if (userInput == widget.depositName) {
                  // 일치하는 경우: 다음 단계로 진행.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("입금자명이 확인되었습니다.")),
                  );
                  // 다음 화면으로 이동하는 코드를 만들어야함. 코드가 길어지므로 새 dart파일로 작성하는게 좋을듯
                } else {
                  // 일치하지 않는 경우: 오류 메시지 표시.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("입금자명이 일치하지 않습니다. 다시 시도해주세요.")),
                  );
                }
              },

              child: const Text("확인하기", style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
