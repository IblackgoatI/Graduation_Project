import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'screens/regist.dart';
import 'screens/main_screen_nologin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'screens/transaction_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 임포트
import 'router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// FCM 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("백그라운드 메시지 처리: ${message.messageId}");
}

// 로컬 알림 채널 설정을 위한 전역 객체
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// main() 함수를 async로 변경하고 Firebase 초기화
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBWl9e_RC-aBdAr9Cu4K0Jard5vKT-8Jr4",
      appId: "1:24911651038:android:8bf6958b484083afd0224f",
      messagingSenderId: "24911651038",
      projectId: "graduation-5caa0",
    ),
  );

  // 웹이 아닌 경우에만 FCM 초기화
  if (!kIsWeb) {
    // FCM 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // FCM 권한 요청
    await requestNotificationPermissions();
    // 로컬 알림 초기화
    await initializeLocalNotifications();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TransactionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// 알림 권한 요청 함수
Future<void> requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // iOS의 경우 별도 권한 요청 필요
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  debugPrint('사용자 알림 권한 상태: ${settings.authorizationStatus}');

  // FCM 토큰 가져오기
  String? token = await messaging.getToken();
  debugPrint('FCM 토큰: $token'); // 실제 앱에서는 이 토큰을 서버에 저장해야 함
}

// 로컬 알림 초기화 함수
Future<void> initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse details) {
      debugPrint('알림 실행: ${details.payload}');
    },
  );

  // Android 채널 생성
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'deposit_notification_channel',
    '입금 알림',
    description: '1원 입금 확인에 대한 알림 채널입니다.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // FCM 포그라운드 메시지 처리 설정
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['screen'],
      );
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
        ],
        locale: const Locale('ko', 'KR'),
      );
    } else {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
        ],
        locale: const Locale('ko', 'KR'),
        home: const SplashScreen(),
      );
    }
  }
}

// 스플래시 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 스플래시 화면을 보여주면서 동시에 인증 상태 확인
    _checkAuthState();
  }

  // 인증 상태 확인 함수
  Future<void> _checkAuthState() async {
    // 최소 스플래시 화면 노출 시간 (1초)
    await Future.delayed(const Duration(seconds: 1));

    // 현재 로그인된 사용자 정보 가져오기
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (mounted) {
      if (currentUser != null) {
        // 로그인한 사용자가 있으면 메인 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreenNotLogin(user: currentUser)),
        );
      } else {
        // 로그인한 사용자가 없으면 온보딩 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
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

          // 메인 텍스트
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

          // 로고 이미지
          Center(
            child: Image.asset(
              'assets/piggy_bank.png',
              width: 150,
            ),
          ),

          const SizedBox(height: 20),

          // 부린이 텍스트
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

          // 가계부 설명 텍스트
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

// 온보딩 화면
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

          // 온보딩 콘텐츠를 위한 PageView
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
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
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

          // 인디케이터 추가
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