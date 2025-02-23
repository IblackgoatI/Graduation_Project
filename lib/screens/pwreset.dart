import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 사용
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login.dart';


class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({Key? key}) : super(key: key);

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // 스텝 1: 이메일 인증 → Firestore에서 전화번호 조회 후 인증번호 전송
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationController = TextEditingController();
  String? _verificationId;
  Timer? _resendTimer;
  int _resendCountdown = 0;

  // 스텝 2: 비밀번호 변경
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  // 정규식: 이메일, 비밀번호
  final RegExp _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  final RegExp _passwordRegex = RegExp(r'^[A-Za-z][A-Za-z0-9]{5,15}$');

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _verificationController.addListener(_onFieldChanged);
    _newPasswordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _resendTimer?.cancel();
    _pageController.dispose();
    _emailController.dispose();
    _verificationController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  //////////////////////////////////////////////////////////////////////////////
  // STEP 1: 이메일 인증 → Firestore에서 해당 이메일의 전화번호 조회 후 인증번호 전송
  //////////////////////////////////////////////////////////////////////////////

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      _showError('유효한 이메일 주소를 입력하세요.');
      return;
    }

    try {
      // Firestore에서 해당 이메일을 가진 사용자 문서를 조회 (컬렉션 이름은 'Users')
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('UserId', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showError('해당 이메일로 가입된 계정을 찾을 수 없습니다.');
        return;
      }

      // 문서가 존재하면, 그 문서의 'PNum' 필드에서 전화번호를 추출
      final userDoc = querySnapshot.docs.first;
      final String phoneNumberRaw = userDoc.get('PNum') ?? '';
      if (phoneNumberRaw.isEmpty) {
        _showError('이 계정에 등록된 전화번호가 없습니다.');
        return;
      }

      // 전화번호를 E.164 형식으로 변환 (예: "010-1234-5678" → "+821012345678")
      String digits = phoneNumberRaw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.startsWith('0')) {
        digits = digits.substring(1);
      }
      final String phoneNumber = '+82$digits';

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // 자동 인증 완료 시 처리 (필요하면 구현)
        },
        verificationFailed: (FirebaseAuthException e) {
          _showError(e.message ?? '전화번호 인증 실패');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendCountdown = 60;
          });
          _startResendTimer();
          _showError('인증번호가 전송되었습니다.');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      _showError('인증번호 전송 중 오류가 발생했습니다.');
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyCodeAndGoNext() async {
    if (_verificationId == null) {
      _showError('먼저 인증번호 전송을 진행해주세요.');
      return;
    }
    if (_verificationController.text.trim().isEmpty) {
      _showError('인증번호를 입력하세요.');
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _verificationController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 인증 성공 시 스텝 2로 이동
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      setState(() {
        _currentStep = 1;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        _showError('잘못된 인증번호입니다. 다시 입력해주세요.');
      } else if (e.code == 'session-expired') {
        _showError('인증번호가 만료되었습니다. 다시 시도해주세요.');
      } else {
        _showError(e.message ?? '인증에 실패했습니다.');
      }
    } catch (e) {
      _showError('인증에 실패했습니다.');
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // STEP 2: 비밀번호 변경
  //////////////////////////////////////////////////////////////////////////////

  Future<void> _changePassword() async {
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showError('비밀번호를 입력하세요.');
      return;
    }
    if (!_passwordRegex.hasMatch(newPassword)) {
      _showError('비밀번호는 영문으로 시작하며, 영문/숫자만 6~16자 가능합니다.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showError('비밀번호가 일치하지 않습니다.');
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('로그인된 사용자가 없습니다. 다시 인증을 진행해주세요.');
        return;
      }
      await user.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
      );

      // 비밀번호 변경 후 로그인 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? '비밀번호 변경에 실패했습니다.');
    } catch (e) {
      _showError('비밀번호 변경에 실패했습니다.');
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // STEP별 오류 메시지 반환
  //////////////////////////////////////////////////////////////////////////////

  List<String> _getValidationErrorsForStep(int step) {
    List<String> errors = [];
    if (step == 0) {
      // STEP 1: 이메일 & 인증번호
      if (_emailController.text.trim().isEmpty) {
        errors.add("이메일을 입력하세요.");
      } else if (!_emailRegex.hasMatch(_emailController.text.trim())) {
        errors.add("유효한 이메일 주소를 입력하세요.");
      }
      if (_verificationController.text.trim().isEmpty) {
        errors.add("인증번호를 입력하세요.");
      }
    } else if (step == 1) {
      // STEP 2: 새 비밀번호 & 비밀번호 확인
      final String newPw = _newPasswordController.text.trim();
      final String confirmPw = _confirmPasswordController.text.trim();
      if (newPw.isEmpty) {
        errors.add("새 비밀번호를 입력하세요.");
      } else if (!_passwordRegex.hasMatch(newPw)) {
        errors.add("비밀번호는 영문으로 시작, 영문/숫자 6~16자 가능합니다.");
      }
      if (confirmPw.isEmpty) {
        errors.add("비밀번호 확인을 입력하세요.");
      } else if (newPw != confirmPw && newPw.isNotEmpty) {
        errors.add("비밀번호가 일치하지 않습니다.");
      }
    }
    return errors;
  }

  bool _isCurrentStepValid() {
    return _getValidationErrorsForStep(_currentStep).isEmpty;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// STEP 1 - 이메일 입력 및 인증번호 전송
  Widget _buildStep1() {
    final errors = _getValidationErrorsForStep(0);
    final bool isValid = _isCurrentStepValid();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "비밀번호 찾기",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "가입 시 등록한 이메일의 전화번호로\n인증번호가 발송됩니다.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                // 이메일 입력
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "이메일 주소",
                    hintText: "예) example@domain.com",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                ),
                const SizedBox(height: 16),
                // 인증번호 전송 버튼
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _resendCountdown > 0 ? Colors.grey : Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _resendCountdown > 0 ? null : _sendVerificationCode,
                  child: _resendCountdown > 0
                      ? Text(
                    "재전송 대기: $_resendCountdown초",
                    style: const TextStyle(color: Colors.red),
                  )
                      : const Text(
                    "인증번호 전송",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                // 인증번호 입력
                TextField(
                  controller: _verificationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "인증번호",
                    hintText: "인증번호 입력",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                ),
                // 오류 메시지 표시
                if (_currentStep == 0 && errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final error in errors)
                    Text(
                      error,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ],
            ),
          ),
        ),
        // 계속하기 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid ? Colors.green : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isValid ? _verifyCodeAndGoNext : null,
              child: const Text(
                "계속하기",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// STEP 2 - 비밀번호 변경
  Widget _buildStep2() {
    final errors = _getValidationErrorsForStep(1);
    final bool isValid = _isCurrentStepValid();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "비밀번호 변경",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "새로운 비밀번호를 입력 해주세요.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                // 새로운 비밀번호
                TextField(
                  controller: _newPasswordController,
                  obscureText: !_newPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "새로운 비밀번호 (영문+숫자 6~16자)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    suffixIcon: IconButton(
                      icon: Icon(_newPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _newPasswordVisible = !_newPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 비밀번호 확인
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_confirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "비밀번호 확인",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    suffixIcon: IconButton(
                      icon: Icon(_confirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                // 오류 메시지 표시
                if (_currentStep == 1 && errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final error in errors)
                    Text(
                      error,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ],
            ),
          ),
        ),
        // 변경하기 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid ? const Color(0xFF69B23F) : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isValid ? _changePassword : null,
              child: const Text(
                "변경하기",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // 메인 빌드
  //////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
            setState(() {
              _currentStep--;
            });
          },
        )
            : null,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStep1(),
            _buildStep2(),
          ],
        ),
      ),
    );
  }
}
