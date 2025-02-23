import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'regist.dart'; // 회원가입 화면 (예시)
import 'asset.dart';
import 'pwreset.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 텍스트 컨트롤러 선언
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // 비밀번호 표시 여부 상태
  bool _passwordVisible = false;

  bool get _isLoginFormValid =>
      _idController.text.trim().isNotEmpty && _passwordController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 로그인 함수 (예시)
  Future<void> _login() async {
    FocusScope.of(context).unfocus(); // 키보드 닫기
    setState(() => _isLoading = true);

    try {
      // FirebaseAuth를 통한 이메일/비밀번호 로그인 (아이디→가짜 이메일 기법 가능)
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _idController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 로그인 성공 시 메인 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AssetScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';

      if (e.code == 'user-not-found') {
        errorMessage = '등록된 사용자가 없습니다.';
      } else if (e.code == 'wrong-password') {
        errorMessage = '비밀번호가 올바르지 않습니다.';
      } else if (e.code == 'invalid-email') {
        errorMessage = '이메일 형식이 올바르지 않습니다.';
      } else if (e.code == 'user-disabled') {
        errorMessage = '이 계정은 사용이 중지되었습니다.';
      } else {
        // 기본 메시지 (e.message를 사용하지 않고, 직접 설정)
        errorMessage = '로그인에 실패했습니다.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
    finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 회원가입 화면처럼 AppBar를 둬서 상단 위치를 동일하게 맞춤
      appBar: AppBar(
        elevation: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(), // 화면 터치 시 키보드 닫기
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 타이틀, 부제목 부분 (회원가입 화면과 동일한 간격)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '부린이와 함께 가계부를 시작해봐요!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '현명한 소비생활의 시작',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),

            // 나머지 로그인 필드 및 버튼들
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // 이메일 입력 필드
                      TextField(
                        controller: _idController,
                        decoration: InputDecoration(
                          labelText: '이메일',
                          hintText: '이메일 입력',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        onChanged: (_) => setState(() {}), // 입력이 바뀔 때마다 setState 호출
                      ),
                      const SizedBox(height: 16),

                      // 비밀번호 입력 필드 + 표시/숨기기 아이콘
                      TextField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          hintText: '비밀번호 입력',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),

                      // 로그인 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF69B23F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: _isLoading || !_isLoginFormValid ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : const Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 회원가입/비밀번호 찾기
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // 회원가입 화면으로 이동
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const RegisterScreen(showSkip: false)),
                              );
                            },
                            child: const Text(
                              '회원가입',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text('  |  '),
                          GestureDetector(
                            onTap: () {
                              //비밀번호 찾기 화면으로 이동
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const PasswordResetScreen()),
                              );

                            },
                            child: const Text(
                              '비밀번호 찾기',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 구분선 또는 '또는' 텍스트
                      Row(
                        children: const [
                          Expanded(
                              child: Divider(thickness: 1, color: Colors.grey)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '또는',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(
                              child: Divider(thickness: 1, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 구글 로그인 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          icon: Image.asset(
                            'assets/google_login.png', // 구글 로고
                            width: 24,
                            height: 24,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // 구글 버튼 기본 흰색
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          onPressed: () {
                            // TODO: 구글 로그인 로직 구현
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('구글 로그인 기능 구현 필요')),
                            );
                          },
                          label: const Text(
                            'Google로 시작하기',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // 추가 여백
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
