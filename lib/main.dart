import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // 인디케이터 패키지 추가
import 'screens/regist.dart'; // ✅ regist_login.dart에서 HomeScreen 가져오기
import 'package:firebase_core/firebase_core.dart'; // firebase_core 임포트

// main() 함수를 async로 변경하고 Firebase 초기화
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// 🟢 스플래시 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2), // 상단 여백

          // 🟢 메인 텍스트
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: '가계부',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  TextSpan(
                    text: '를 시작하는 당신께\n',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                    ),
                  ),
                  TextSpan(
                    text: '부자',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  TextSpan(
                    text: '의 앞날에 서있는 모두에게',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // 🟢 로고 이미지
          Center(
            child: Image.asset(
              'assets/piggy_bank.png',
              width: 150,
            ),
          ),

          const SizedBox(height: 20),

          // 🟢 부린이 텍스트
          const Text(
            '부린이',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // 🟢 가계부 설명 텍스트
          const Text(
            '가계부가 처음인 당신에게',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// 🟢 온보딩 화면
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/piggy.png",
      "title": "지금까지 몰랐던\n새로운 금융 지식",
      "subtitle": "해보고 싶지만, 모르고 있던 지식\n부린이와 함께 배워나갈 수 있습니다.",
      "buttonText": "다음"
    },
    {
      "image": "assets/coins.png",
      "title": "확실한 자산관리와\n커뮤니케이션",
      "subtitle": "가계부를 통한 보다 나은 자산관리와\n자신의 소비패턴을 모두와 공유할 수 있습니다.",
      "buttonText": "시작하기"
    }
  ];

  void _onNext() {
    if (_currentIndex < onboardingData.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const RegisterScreen()));
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F7),
      body: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 56, right: 20),
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  "넘어가기",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),

          // 🔹 온보딩 콘텐츠를 위한 PageView
          Expanded(
            flex: 7,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: onboardingData.length,
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(onboardingData[index]["image"]!, width: 150),
                    const SizedBox(height: 30),
                    Text(
                      onboardingData[index]["title"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E355E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      onboardingData[index]["subtitle"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 🔹 인디케이터 추가
          SmoothPageIndicator(
            controller: _pageController,
            count: onboardingData.length,
            effect: const ExpandingDotsEffect(
              dotWidth: 8,
              dotHeight: 8,
              activeDotColor: Colors.blue,
              dotColor: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(300, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              onboardingData[_currentIndex]["buttonText"]!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

