/// 모든 기능 화면
/// 앱의 모든 주요 기능 및 설정 화면으로 이동할 수 있는 메뉴를 제공합니다.
import 'package:flutter/material.dart';
import 'main_screen_nologin.dart'; // MainScreenNotLogin 클래스 가져오기
import 'settings_screen.dart'; // SettingsScreen import 추가
import 'attendance_screen.dart'; // AttendanceScreen import 추가
import 'daily_quiz_screen.dart'; // DailyQuizScreen import 추가
import 'point_management_screen.dart'; // PointManagementScreen import 추가

class AllScreen extends StatefulWidget {
  const AllScreen({super.key});

  @override
  State<AllScreen> createState() => _AllScreenState();
}

class _AllScreenState extends State<AllScreen> {
  @override
  Widget build(BuildContext context) {
    // 최근 방문 탭 가져오기
    final recentTabs = MainScreenNotLogin.getRecentTabs();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        title: const Text('부린이'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSectionTitle('최근 화면'),
          
          // 최근 방문 탭이 없을 경우 기본 메뉴 표시
          if (recentTabs.isEmpty) ...[
          _buildMenuItem('자산 인증', Icons.verified_user, () {
            // TODO: 자산 인증 화면으로 이동
          }),
          _buildMenuItem('가계부 작성', Icons.edit_note, () {
            // TODO: 가계부 작성 화면으로 이동
          }),
          _buildMenuItem('내 자산 목표', Icons.track_changes, () {
            // TODO: 내 자산 목표 화면으로 이동
          }),
          ] 
          // 최근 방문 탭이 있을 경우 해당 탭들 표시
          else ...[
            ...recentTabs.map((tab) {
              return _buildRecentTabItem(
                tab['name'],
                tab['icon'],
                () {
                  // 메인 화면의 바텀 네비게이션에서 해당 탭으로 이동
                  if (tab['index'] != null) {
                    MainScreenNotLogin.navigateToTab(context, tab['index']);
                  }
                },
              );
            }).toList(),
          ],
          
          _buildSectionTitle('부린이 금융 지식'),
          _buildMenuItem('저축과 이자', Icons.savings, () {
            // TODO: 저축과 이자 화면으로 이동
          }),
          _buildMenuItem('선물과 부채', Icons.card_giftcard, () {
            // TODO: 선물과 부채 화면으로 이동
          }),
          _buildMenuItem('투자', Icons.trending_up, () {
            // TODO: 투자 화면으로 이동
          }),
          _buildMenuItem('세금', Icons.receipt_long, () {
            // TODO: 세금 화면으로 이동
          }),
          _buildMenuItem('보험', Icons.security, () {
            // TODO: 보험 화면으로 이동
          }),
          
          _buildSectionTitle('부린이 기능'),
          _buildMenuItem('출석 체크', Icons.calendar_today, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AttendanceScreen()),
            );
          }),
          _buildMenuItem('일일 경제 퀴즈 도전하기', Icons.school, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DailyQuizScreen()),
            );
          }),
          _buildMenuItem('포인트 관리하기', Icons.receipt_long, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PointManagementScreen()),
            );
          }),
          _buildMenuItem('저축과 이자', Icons.savings, () {
            // TODO: 저축과 이자 화면으로 이동
          }),
          _buildMenuItem('자산 인증', Icons.verified_user, () {
            // TODO: 자산 인증 화면으로 이동
          }),
          _buildMenuItem('자산 연결, 해제', Icons.link, () {
            // TODO: 자산 연결/해제 화면으로 이동
          }),
          _buildMenuItem('내 자산', Icons.account_balance_wallet, () {
            // TODO: 내 자산 화면으로 이동
          }),
          _buildMenuItem('내 자산 목표', Icons.track_changes, () {
            // TODO: 내 자산 목표 화면으로 이동
          }),
          _buildMenuItem('내 소비', Icons.shopping_cart, () {
            // TODO: 내 소비 화면으로 이동
          }),
          _buildMenuItem('가계부 작성', Icons.edit_note, () {
            // TODO: 가계부 작성 화면으로 이동
          }),
          _buildMenuItem('내 포인트', Icons.stars, () {
            // TODO: 내 포인트 화면으로 이동
          }),
          _buildMenuItem('커뮤니티', Icons.people, () {
            // TODO: 커뮤니티 화면으로 이동
          }),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
  
  // 최근 방문 탭 아이템 위젯
  Widget _buildRecentTabItem(String? name, IconData? icon, VoidCallback onTap) {
    return ListTile(
      leading: icon is IconData 
        ? Icon(icon, color: Colors.blue) // IconData인 경우 Icon 위젯으로 표시
        : Icon(Icons.history, color: Colors.blue), // 아닌 경우 기본 아이콘으로 표시
      title: Text(
        name ?? '알 수 없음',
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}