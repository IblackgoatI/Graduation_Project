/// 앱의 전반적인 라우팅 설정을 담당하는 파일입니다.
/// GoRouter 패키지를 사용하여 화면 간의 이동 경로를 정의합니다.
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/admin/admin_posts_screen.dart';
import 'screens/admin/admin_comments_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/daily_quiz_screen.dart';
import 'screens/admin/admin_quiz_management_screen.dart';
import 'screens/point_management_screen.dart';
import 'screens/transaction_history.dart';
import 'screens/goal_management.dart';
import 'screens/my_page_screen.dart';
import 'screens/my_posts_screen.dart';
import 'screens/my_comments_screen.dart';

final router = GoRouter(
  initialLocation: '/admin/login',
  routes: [
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminMainScreen(),
    ),
    GoRoute(
      path: '/admin/posts',
      builder: (context, state) => const AdminPostsScreen(),
    ),
    GoRoute(
      path: '/admin/comments',
      builder: (context, state) => const AdminCommentsScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
    GoRoute(
      path: '/attendance',
      builder: (context, state) => const AttendanceScreen(),
    ),
    GoRoute(
      path: '/daily_quiz',
      builder: (context, state) => const DailyQuizScreen(),
    ),
    GoRoute(
      path: '/admin/quiz_management',
      builder: (context, state) => const AdminQuizManagementScreen(),
    ),
    GoRoute(
      path: '/point_management',
      builder: (context, state) => const PointManagementScreen(),
    ),
    GoRoute(
      path: '/transaction_history',
      builder: (context, state) {
        final account = state.extra as Map<String, dynamic>?;
        final user = FirebaseAuth.instance.currentUser;
        return TransactionHistoryScreen(account: account, user: user);
      },
    ),
    GoRoute(
      path: '/goal_management',
      builder: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        return GoalManagementScreen(user: user);
      },
    ),
    GoRoute(
      path: '/my_page',
      builder: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        return MyPageScreen(user: user);
      },
    ),
    GoRoute(
      path: '/my_posts',
      builder: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        return MyPostsScreen(user: user);
      },
    ),
    GoRoute(
      path: '/my_comments',
      builder: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        return MyCommentsScreen(user: user);
      },
    ),
  ],
); 