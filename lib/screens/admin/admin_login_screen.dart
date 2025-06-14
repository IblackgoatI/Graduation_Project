import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '부린이 관리자',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // 임시 로그인 처리
                    context.go('/admin');
                  },
                  child: const Text('관리자 로그인'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 