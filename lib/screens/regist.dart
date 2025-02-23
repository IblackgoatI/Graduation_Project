import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login.dart';

/// 전화번호 입력 시 자동으로 하이픈(-) 삽입하는 Formatter
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 1) 숫자만 추출
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 2) 최대 11자리까지만 허용 (예: 010-1234-5678)
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    String formatted = digits;

    // 3) 전체 자릿수가 충분할 때는 완전한 포맷 적용
    if (digits.length >= 8) {
      if (digits.length == 10) {
        // 10자리: 3-3-4 (예: 010-123-4567)
        formatted = digits.replaceFirstMapped(
          RegExp(r'^(\d{3})(\d{3})(\d{4})$'),
              (m) => '${m[1]}-${m[2]}-${m[3]}',
        );
      } else if (digits.length == 11) {
        // 11자리: 3-4-4 (예: 010-1234-5678)
        formatted = digits.replaceFirstMapped(
          RegExp(r'^(\d{3})(\d{4})(\d{4})$'),
              (m) => '${m[1]}-${m[2]}-${m[3]}',
        );
      } else {
        // 8~9자리 등 아직 완전한 숫자 수가 아닐 때는 부분 포맷
        formatted = digits.replaceFirstMapped(
          RegExp(r'^(\d{3})(\d+)'),
              (m) => '${m[1]}-${m[2]}',
        );
      }
    } else if (digits.length >= 4) {
      // 4~7자리: 첫 3자리 뒤에 하이픈 삽입
      formatted = digits.replaceFirstMapped(
        RegExp(r'^(\d{3})(\d+)'),
            (m) => '${m[1]}-${m[2]}',
      );
    }

    // 4) 커서 위치 조정
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final bool showSkip;

  const RegisterScreen({super.key, this.showSkip = true});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {  final PageController _pageController = PageController();

// 새로 추가할 변수들
Timer? _resendTimer;
int _resendCountdown = 0;

// 새로 추가할 타이머 함수: 1초마다 _resendCountdown 값을 감소시키기. 30초 인증번호 쿨타임
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


// 이메일 필드 자동 포커스용 FocusNode
final FocusNode _emailFocusNode = FocusNode();

// 텍스트 컨트롤러들
final TextEditingController _emailController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();
final TextEditingController _confirmPasswordController = TextEditingController();
final TextEditingController _nameController = TextEditingController();
final TextEditingController _ageController = TextEditingController();
final TextEditingController _phoneController = TextEditingController();
final TextEditingController _verificationController = TextEditingController();

// 드롭다운 선택값 (성별)
String? _genderValue;

// 페이지 상태
int _currentPage = 0;
bool _passwordVisible = false;
bool _confirmPasswordVisible = false;

// 정규식
// 이메일: 간단한 이메일 형식 체크
final RegExp _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
// 비밀번호: 영문으로 시작하며, 영문/숫자만 허용, 총 6~16자
final RegExp _passwordRegex = RegExp(r'^[A-Za-z][A-Za-z0-9]{5,15}$');
// 이름: 한글만
final RegExp _koreanNameRegex = RegExp(r'^[가-힣]+$');
// 전화번호: 하이픈 포함 (예: 010-1234-5678 또는 010-123-4567)
final RegExp phoneRegex = RegExp(r'^01[0-9]-\d{3,4}-\d{4}$');

// Firebase 인증을 위한 verificationId
String? _verificationId;

@override
void initState() {
  super.initState();

  // 화면 진입 후 이메일 입력란에 포커스
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FocusScope.of(context).requestFocus(_emailFocusNode);
  });

  // 필드 변경 시마다 UI 갱신
  _emailController.addListener(_onFieldChanged);
  _passwordController.addListener(_onFieldChanged);
  _confirmPasswordController.addListener(_onFieldChanged);
  _nameController.addListener(_onFieldChanged);
  _ageController.addListener(_onFieldChanged);
  _phoneController.addListener(_onFieldChanged);
  _verificationController.addListener(_onFieldChanged);
}

void _onFieldChanged() => setState(() {});

// 단계별 오류 리턴
List<String> _getValidationErrorsForStep(int step) {
  List<String> errors = [];

  if (step == 0) {
    // Step 1: 이메일 & 비밀번호
    if (!_emailRegex.hasMatch(_emailController.text)) {
      errors.add("유효한 이메일 주소를 입력하세요.");
    }
    if (!_passwordRegex.hasMatch(_passwordController.text)) {
      errors.add("비밀번호는 영문으로 시작하며, 숫자/영문만 6~16자 가능합니다.");
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      errors.add("비밀번호가 일치하지 않습니다.");
    }
  } else if (step == 1) {
    // Step 2: 이름, 나이, 성별
    if (!_koreanNameRegex.hasMatch(_nameController.text)) {
      errors.add("이름은 한글만 입력 가능합니다.");
    }
    int? age = int.tryParse(_ageController.text.trim());
    if (age == null || age <= 0) {
      errors.add("유효한 나이를 입력하세요.");
    }
    if (_genderValue == null) {
      errors.add("성별을 선택하세요.");
    }
  } else if (step == 2) {
    // Step 3: 전화번호, 인증번호
    if (!phoneRegex.hasMatch(_phoneController.text.trim())) {
      errors.add("전화번호 형식이 올바르지 않습니다. (예: 010-1234-5678 또는 010-123-4567)");
    }
    if (_verificationController.text.trim().isEmpty) {
      errors.add("인증번호를 입력하세요.");
    }
  }

  return errors;
}

// 버튼 클릭 시 실제 검증 (SnackBar 에러용)
bool _validateCurrentPage() {
  if (_currentPage == 0) {
    if (!_emailRegex.hasMatch(_emailController.text)) {
      _showError("유효한 이메일 주소를 입력하세요.");
      return false;
    }
    if (!_passwordRegex.hasMatch(_passwordController.text)) {
      _showError("비밀번호는 영문으로 시작하며, 숫자/영문만 6~16자 가능합니다.");
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("비밀번호가 일치하지 않습니다.");
      return false;
    }
  } else if (_currentPage == 1) {
    if (!_koreanNameRegex.hasMatch(_nameController.text)) {
      _showError("이름은 한글만 입력 가능합니다.");
      return false;
    }
    int? age = int.tryParse(_ageController.text.trim());
    if (age == null || age <= 0) {
      _showError("유효한 나이를 입력하세요.");
      return false;
    }
    if (_genderValue == null) {
      _showError("성별을 선택하세요.");
      return false;
    }
  } else if (_currentPage == 2) {
    if (!phoneRegex.hasMatch(_phoneController.text.trim())) {
      _showError("전화번호 형식이 올바르지 않습니다. (예: 010-1234-5678 또는 010-123-4567)");
      return false;
    }
    if (_verificationController.text.trim().isEmpty) {
      _showError("인증번호를 입력하세요.");
      return false;
    }
  }
  return true;
}

// 페이지 유효성 (버튼 활성/비활성 판단)
bool _isCurrentPageValid() {
  if (_currentPage == 0) {
    if (!_emailRegex.hasMatch(_emailController.text)) return false;
    if (!_passwordRegex.hasMatch(_passwordController.text)) return false;
    if (_passwordController.text != _confirmPasswordController.text) return false;
    return true;
  } else if (_currentPage == 1) {
    if (!_koreanNameRegex.hasMatch(_nameController.text)) return false;
    int? age = int.tryParse(_ageController.text.trim());
    if (age == null || age <= 0) return false;
    if (_genderValue == null) return false;
    return true;
  } else if (_currentPage == 2) {
    if (!phoneRegex.hasMatch(_phoneController.text.trim())) return false;
    if (_verificationController.text.trim().isEmpty) return false;
    return true;
  }
  return false;
}

// SnackBar 에러 표시
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red),
  );
}

// 전화번호 인증번호 전송 함수 (전화번호를 E.164 형식으로 변환하여 전달)
Future<void> _sendVerificationCode() async {
  // 입력된 전화번호에서 숫자만 추출
  String digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
  // 만약 전화번호가 0으로 시작하면 제거 (E.164 형식에서 0은 제거됨)
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  // 한국 전화번호의 경우 +82를 접두어로 붙임
  String phoneNumber = '+82' + digits;

  try {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // 자동 인증 완료 시 처리 (필요에 따라 구현)
      },
      verificationFailed: (FirebaseAuthException e) {
        _showError(e.message ?? '전화번호 인증 실패');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _resendCountdown = 60; // 60초 대기 시작
        });
        _startResendTimer(); // 타이머 시작
        _showError('인증번호가 전송되었습니다.');
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  } catch (e) {
    _showError('전화번호 인증 요청 중 오류가 발생했습니다.');
  }
}

// 최종 단계에서 인증번호 확인 후 이메일/비밀번호 계정 생성,
// 전화번호를 계정에 연결하고 Firestore에 사용자 정보 저장
Future<void> _verifyCodeAndRegister() async {
  if (_verificationId == null) {
    _showError('먼저 인증번호 전송을 진행해주세요.');
    return;
  }

  User? user; // 생성된 계정을 참조하기 위해 try 블록 외부에 선언
  try {
    // 1) 이메일/비밀번호로 계정 생성
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    user = userCredential.user;

    if (user != null) {
      // 2) 전화번호 인증번호로 PhoneAuthCredential 생성 후 계정에 연결
      PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _verificationController.text.trim(),
      );
      await user.linkWithCredential(phoneCredential);

      // 3) Firestore에 추가 사용자 정보 저장, 비번은 auth에 저장되고 관리자가 확인못함
      // doc(  ) 안이 사용자 UID로 되있는데, 이걸로 키 접근해도되고, 이메일로 해도가능
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'UserId': _emailController.text.trim(),
        'Name': _nameController.text.trim(),
        'Age': int.tryParse(_ageController.text.trim()),
        'Sex': _genderValue,
        'PNum': _phoneController.text.trim(),
        'CreatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원가입이 완료되었습니다!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 4) 회원가입 완료 후 login.dart로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  } on FirebaseAuthException catch (e) {
    print("Error in _verifyCodeAndRegister: $e");
    // 전화번호 연결에 실패하면, 생성된 계정을 삭제
    if (user != null) {
      try {
        await user.delete();
      } catch (deleteError) {
        print("계정 삭제 실패: $deleteError");
      }
    }

    if (e.code == 'email-already-in-use') {
      _showError('이미 아이디가 존재합니다.');
    } else if (e.code == 'credential-already-in-use') {
      _showError('이미 해당 전화번호로 인증된 계정이 존재합니다.');
    } else {
      _showError(e.message ?? '회원가입에 실패했습니다.');
    }
  } catch (e) {
    print("Error in _verifyCodeAndRegister: $e");
    if (user != null) {
      try {
        await user.delete();
      } catch (deleteError) {
        print("계정 삭제 실패: $deleteError");
      }
    }
    _showError('회원가입에 실패했습니다.');
  }
}


// 다음 단계 버튼 클릭
void _nextPage() {
  if (!_validateCurrentPage()) return;

  if (_currentPage < 2) {
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
    setState(() {
      _currentPage++;
    });
  } else {
    // 마지막 단계에서는 전화번호 인증 후 회원가입 진행
    _verifyCodeAndRegister();
  }
}

// 이전 단계 버튼 클릭
void _prevPage() {
  if (_currentPage > 0) {
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
    setState(() {
      _currentPage--;
    });
  }
}

@override
void dispose() {
  _resendTimer?.cancel(); // 인증번호 재전송 타이머 무한반복 방지
  _pageController.dispose();
  _emailController.dispose();
  _passwordController.dispose();
  _confirmPasswordController.dispose();
  _nameController.dispose();
  _ageController.dispose();
  _phoneController.dispose();
  _verificationController.dispose();
  _emailFocusNode.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: _currentPage > 0
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _prevPage,
      )
          : null,

      // 우상단에 넘어가기 버튼 추가
      actions: widget.showSkip
          ? [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },

            child: const Text(
              "넘어가기",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black, // 검정색 글씨
              ),
            ),
          ),
        ),
      ]
          : null,
    ),
    body: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 타이틀 + 설명
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("회원가입",
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("회원 정보 수집 및 가입을 진행합니다.",
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 24),
              ],
            ),
          ),

          // 단계별 페이지 뷰
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                buildStep1(),
                buildStep2(),
                buildStep3(),
              ],
            ),
          ),

          // "계속하기" 버튼
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0
                  ? 10
                  : 20,
            ),
            child: buildNextButton(_isCurrentPageValid()),
          ),
        ],
      ),
    ),
  );
}

// Step 1: 이메일, 비밀번호, 비밀번호 확인
Widget buildStep1() {
  final errors = _getValidationErrorsForStep(0);
  final bool isValid = _isCurrentPageValid();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTextField(
          label: "이메일",
          hint: "이메일 주소 입력",
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        buildTextField(
          label: "비밀번호",
          hint: "영문으로 시작, 6~16자",
          controller: _passwordController,
          isPassword: true,
          isVisible: _passwordVisible,
          toggleVisibility: () {
            setState(() => _passwordVisible = !_passwordVisible);
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          label: "비밀번호 확인",
          hint: "비밀번호 재입력",
          controller: _confirmPasswordController,
          isPassword: true,
          isVisible: _confirmPasswordVisible,
          toggleVisibility: () {
            setState(() => _confirmPasswordVisible = !_confirmPasswordVisible);
          },
        ),
        if (_currentPage == 0 && !isValid && errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final error in errors)
            Text(error,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ],
    ),
  );
}

// Step 2: 이름, 나이, 성별
Widget buildStep2() {
  final errors = _getValidationErrorsForStep(1);
  final bool isValid = _isCurrentPageValid();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTextField(
          label: "이름(실명)",
          hint: "한글만 입력",
          controller: _nameController,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildTextField(
                label: "나이",
                hint: "나이 입력",
                controller: _ageController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _genderValue,
                decoration: InputDecoration(
                  labelText: "성별",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 12),
                ),
                items: const [
                  DropdownMenuItem(value: "남성", child: Text("남성")),
                  DropdownMenuItem(value: "여성", child: Text("여성")),
                ],
                onChanged: (value) {
                  setState(() {
                    _genderValue = value;
                  });
                },
                hint: const Text("성별 선택"),
              ),
            ),
          ],
        ),
        if (_currentPage == 1 && !isValid && errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final error in errors)
            Text(error,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ],
    ),
  );
}

// Step 3: 전화번호, 인증번호
Widget buildStep3() {
  final errors = _getValidationErrorsForStep(2);
  final bool isValid = _isCurrentPageValid();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTextField(
          label: "전화번호",
          hint: "예) 010-1234-5678 / 010-123-4567",
          controller: _phoneController,
          inputFormatters: [PhoneNumberFormatter()],
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        ElevatedButton(  //인증번호 재전송 대기시간 ui 수정
          style: ElevatedButton.styleFrom(
            backgroundColor: _resendCountdown > 0 ? Colors.grey : Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _resendCountdown > 0 ? null : _sendVerificationCode,
          child: _resendCountdown > 0
              ? Text(
            "재전송 대기: ${_resendCountdown}초",
            style: const TextStyle(color: Colors.red),
          )
              : const Text("인증번호 전송", style: TextStyle(color: Colors.white)),
        ),

        const SizedBox(height: 16),
        buildTextField(
          label: "인증번호",
          hint: "인증번호 입력",
          controller: _verificationController,
          keyboardType: TextInputType.number,
        ),
        if (_currentPage == 2 && !isValid && errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final error in errors)
            Text(error,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ],
    ),
  );
}

// 공통 입력 필드 위젯
Widget buildTextField({
  required String label,
  required String hint,
  required TextEditingController controller,
  FocusNode? focusNode,
  bool isPassword = false,
  bool isVisible = false,
  VoidCallback? toggleVisibility,
  List<TextInputFormatter>? inputFormatters,
  TextInputType? keyboardType,
}) {
  return TextField(
    focusNode: focusNode,
    controller: controller,
    keyboardType: keyboardType,
    obscureText: isPassword && !isVisible,
    inputFormatters: inputFormatters,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 16, color: Colors.grey),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      suffixIcon: isPassword
          ? IconButton(
        icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
        onPressed: toggleVisibility,
      )
          : null,
    ),
  );
}

// 계속하기/완료 버튼
Widget buildNextButton(bool isValid) {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isValid ? Colors.green : Colors.grey,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: isValid ? _nextPage : null,
      child: Text(
        _currentPage < 2 ? "계속하기" : "완료",
        style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

}