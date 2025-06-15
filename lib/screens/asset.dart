/// 자산 설정 화면
/// 사용자의 초기 자산 정보를 설정하고 관리합니다.
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'login.dart';
import 'main_screen_nologin.dart';

// 로컬 알림 표시 함수
Future<void> showLocalNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'deposit_notification_channel',
    '입금 알림',
    channelDescription: '1원 입금 확인에 대한 알림 채널입니다.',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  await FlutterLocalNotificationsPlugin().show(
    0,
    title,
    body,
    platformChannelSpecifics,
  );
}

// 이 함수를 사용하여 서버에 알림 전송 요청
Future<void> _sendFcmNotification(String token, String depositName, String bank, String account) async {
  try {
    final String? token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      debugPrint('FCM 토큰을 가져올 수 없습니다.');
      return;
    }
    final response = await http.post(
      Uri.parse('https://transferonewon-ekqk2sqwxq-du.a.run.app'), // 서버 엔드포인트 URL
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token, // 필요한 경우 인증 토큰 추가
      },
      body: jsonEncode({
        'token': token,
        'title': '1원 입금 확인',
        'body': '$bank 계좌로 1원이 입금되었습니다. 입금자명: $depositName',
        'data': {
          'depositName': depositName,
          'bank': bank,
          'account': account,
          'screen': 'asset_verification',
        },
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('FCM 알림 전송 요청 성공');
    } else {
      debugPrint('FCM 알림 전송 요청 실패: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('FCM 알림 전송 요청 오류: $e');
  }
}

class AssetScreen extends StatefulWidget {
  final User? user;
  final String? previousRouteName; // 이전 경로 이름을 받을 파라미터 추가

  const AssetScreen({super.key, this.user, this.previousRouteName}); // 생성자 수정

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

  /// 계좌번호 입력과 은행 선택이 모두 되었는지 여부
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
      // previousRouteName을 확인하여 분기
      if (widget.previousRouteName == 'main_screen_nologin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreenNotLogin(user: widget.user ?? FirebaseAuth.instance.currentUser)),
        );
      } else if (widget.previousRouteName == 'asset_detail_screen') {
        Navigator.pop(context); // 자산 상세 화면으로 돌아가기
      } else {
        // 기본 동작: 로그인 화면으로 이동 (또는 previousRouteName이 null이거나 다른 값일 때)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
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

  Future<void> _checkAccountAndTransfer() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final accountInput = _accountController.text.trim();
    final bankInput = _selectedBank;
    final User? user = widget.user ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("사용자가 로그인되어 있지 않습니다.")),
      );
      return;
    }

    // Firestore에 계좌 정보 저장
    String formatPhone(String? phone) {
      if (phone == null || phone.isEmpty) return "";
      // 국제형식인 경우 +82를 0으로 변환
      if (phone.startsWith('+82')) {
        phone = '0${phone.substring(3)}';
      }
      // 일반적으로 11자리면 010-1234-5678 형태로 변환
      if (phone.length == 11) {
        return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
      }
      // 10자리인 경우 (지역번호 등) 처리: 0XX-XXX-XXXX
      if (phone.length == 10) {
        return '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}';
      }
      return phone;
    }

    try {
      await FirebaseFirestore.instance.collection('assets').add({
        'account': accountInput,
        'balance': 299999,
        'bank': bankInput,
        'owner': user.displayName, // 현재 로그인한 사용자의 이름 (displayName) 저장
        'pnum': formatPhone(user.phoneNumber), // 전화번호를 010-1234-5678 형식으로 저장
        'userId': user.uid, // 현재 로그인한 사용자의 userId 추가
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("데이터 저장 실패: $e")),
      );
      return;
    }

    // 기존 1원 송금 API 호출
    try {
      final url = 'https://transferonewon-ekqk2sqwxq-du.a.run.app';
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

        // FCM 토큰 가져오기
        final String? fcmToken = await FirebaseMessaging.instance.getToken();

        // 푸시 알림 보내기
        if (fcmToken != null) {
          try {
            // FCM 알림 요청 먼저 전송
            await _sendFcmNotification(fcmToken, depositName, bankInput!, accountInput);

            // 로컬 알림 표시
            await showLocalNotification(
                '1원 입금 확인',
                '$bankInput 계좌로 1원이 입금되었습니다. 입금자명: $depositName'
            );
          } catch (notificationError) {
            debugPrint('알림 전송 실패: $notificationError');
            // 알림 실패해도 계속 진행
          }
        }

        // API 호출 성공 시 결과 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssetVerificationResultScreen(
              bank: bankInput!,
              account: accountInput,
              depositName: depositName,
              assetScreenPreviousRouteName: widget.previousRouteName, // AssetScreen의 previousRouteName 전달
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          response.body == "Asset account not found."
              ? const SnackBar(
            content: Text("존재하지 않는 계좌입니다.\n다시 확인 해주세요."),
            backgroundColor: Colors.red,
          )
              : response.body == "User not found."
              ? const SnackBar(
            content: Text(
                "로그인 정보가 만료되었습니다.\n다시 로그인 해주세요."),
            backgroundColor: Colors.red,
          )
              : SnackBar(
            content: Text("송금 실패: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("오류가 발생했습니다: $e")),
      );
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _prevPage,
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 10),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      // 이전 화면으로 돌아갈 수 있으면 돌아갑니다.
                      Navigator.pop(context);
                    } else {
                      // 이전 화면이 없으면 메인 화면으로 이동합니다.
                      // 현재 로그인한 사용자 정보를 MainScreenNotLogin으로 전달합니다.
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainScreenNotLogin(user: widget.user ?? FirebaseAuth.instance.currentUser),
                        ),
                      );
                    }
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
        ),
      ),
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
                      style:
                      const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
            const Spacer(),
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
  final String? assetScreenPreviousRouteName; // AssetScreen의 previousRouteName을 받기 위한 필드 추가

  const AssetVerificationResultScreen({
    super.key,
    required this.bank,
    required this.account,
    required this.depositName,
    this.assetScreenPreviousRouteName, // 생성자에 파라미터 추가
  });

  @override
  State<AssetVerificationResultScreen> createState() =>
      _AssetVerificationResultScreenState();
}

class _AssetVerificationResultScreenState
    extends State<AssetVerificationResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isError = false;

  final TextEditingController _hangulController = TextEditingController();
  final FocusNode _hangulFocus = FocusNode();

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
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

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
    _shakeController.dispose();
    super.dispose();
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
  }

  void _triggerErrorAnimation() {
    setState(() {
      _isError = true;
    });
    _shakeController.forward(from: 0);
  }

  void _onHangulChanged(String value) {
    final currentValue = _hangulController.value;
    if (!currentValue.composing.isCollapsed) return;

    if (_isError) {
      setState(() {
        _isError = false;
      });
    }
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

  void _onNumberChanged(String value, FocusNode currentFocus, FocusNode? nextFocus) {
    if (_isError) {
      setState(() {
        _isError = false;
      });
    }
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
    // AssetScreen의 이전 화면이 main_screen_nologin인 경우 뒤로가기 화살표를 표시하지 않음
    final bool hideAppBarBackButton = widget.assetScreenPreviousRouteName == 'main_screen_nologin';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: hideAppBarBackButton
            ? null // 뒤로가기 화살표 숨김
            : IconButton(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "${widget.bank} ${widget.account}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 80,
                            height: 80,
                            child: TextField(
                              controller: _hangulController,
                              focusNode: _hangulFocus,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24),
                              decoration: InputDecoration(
                                enabledBorder: _buildBorder(_isError ? Colors.red : Colors.black),
                                focusedBorder: _buildBorder(_isError ? Colors.red : Colors.blue),
                                border: _buildBorder(_isError ? Colors.red : Colors.grey.shade400),
                                counterText: "",
                              ),
                              onChanged: _onHangulChanged,
                              onEditingComplete: () {
                                if (_hangulController.text.length == 1) {
                                  FocusScope.of(context).requestFocus(_numFocus1);
                                }
                              },
                            )
                        ),
                        const SizedBox(width: 10),
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
                              enabledBorder: _buildBorder(_isError ? Colors.red : Colors.black),
                              focusedBorder: _buildBorder(_isError ? Colors.red : Colors.blue),
                              border: _buildBorder(_isError ? Colors.red : Colors.grey.shade400),
                              counterText: "",
                            ),
                            onChanged: (val) => _onNumberChanged(val, _numFocus1, _numFocus2),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                              enabledBorder: _buildBorder(_isError ? Colors.red : Colors.black),
                              focusedBorder: _buildBorder(_isError ? Colors.red : Colors.blue),
                              border: _buildBorder(_isError ? Colors.red : Colors.grey.shade400),
                              counterText: "",
                            ),
                            onChanged: (val) => _onNumberChanged(val, _numFocus2, _numFocus3),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                              enabledBorder: _buildBorder(_isError ? Colors.red : Colors.black),
                              focusedBorder: _buildBorder(_isError ? Colors.red : Colors.blue),
                              border: _buildBorder(_isError ? Colors.red : Colors.grey.shade400),
                              counterText: "",
                            ),
                            onChanged: (val) => _onNumberChanged(val, _numFocus3, null),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("입금자명이 확인되었습니다."),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // 현재 로그인한 사용자 정보 가져오기
                  final User? currentUser = FirebaseAuth.instance.currentUser;

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => MainScreenNotLogin(user: currentUser), // 사용자 정보 전달
                    ),
                        (route) => false, // 모든 이전 화면 제거
                  );
                } else {
                  _triggerErrorAnimation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("입금자명이 일치하지 않습니다.\n확인 후, 다시 시도해주세요."),
                      backgroundColor: Colors.red,
                    ),
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
