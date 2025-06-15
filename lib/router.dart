import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/admin/admin_posts_screen.dart';
import 'screens/admin/admin_comments_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/attendance_screen.dart';

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
      path: '/attendance',
      builder: (context, state) => const AttendanceScreen(),
    ),
  ],
); 