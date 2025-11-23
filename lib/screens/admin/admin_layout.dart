/// 관리자 화면 공통 레이아웃
/// 사이드바와 헤더가 포함된 웹 스타일 레이아웃을 제공합니다.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminLayout extends StatelessWidget {
  final String currentMenu;
  final Widget child;
  final String title;

  const AdminLayout({
    super.key,
    required this.currentMenu,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 왼쪽 사이드바 (20%)
          _buildSidebar(context, currentMenu),
          // 오른쪽 콘텐츠 영역 (80%)
          Expanded(
            child: Column(
              children: [
                _buildHeader(context, title),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, String currentMenu) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      color: const Color(0xFF1E293B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: const Text(
              '부린이 Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildMenuItem(context, '대시보드', Icons.dashboard, '대시보드', '/admin'),
          _buildMenuItem(context, '게시물 관리', Icons.article, '게시물 관리', '/admin/posts'),
          _buildMenuItem(context, '댓글 관리', Icons.comment, '댓글 관리', '/admin/comments'),
          _buildMenuItem(context, '퀴즈 관리', Icons.quiz, '퀴즈 관리', '/admin/quiz_management'),
          _buildMenuItem(context, '설정', Icons.settings, '설정', '/admin'),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    String menuKey,
    String route,
  ) {
    final isSelected = currentMenu == menuKey;
    return InkWell(
      onTap: () {
        if (route != '/admin' || menuKey == '대시보드') {
          context.go(route);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Text(
                user?.email ?? '관리자',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.go('/admin/login');
                },
                tooltip: '로그아웃',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

