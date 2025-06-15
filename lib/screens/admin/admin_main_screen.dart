/// 관리자 메인 화면
/// 게시물 및 댓글 관리 등 관리자 기능으로 이동하는 대시보드를 제공합니다.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부린이 관리자 페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // 임시 로그아웃 기능
              context.go('/admin/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '관리자 대시보드',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _buildMenuCard(
                  context,
                  '게시물 관리',
                  Icons.article,
                  () => context.go('/admin/posts'),
                ),
                const SizedBox(width: 16),
                _buildMenuCard(
                  context,
                  '댓글 관리',
                  Icons.comment,
                  () => context.go('/admin/comments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 