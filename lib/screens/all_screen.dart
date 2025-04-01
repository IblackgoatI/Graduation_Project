import 'package:flutter/material.dart';

class AllScreen extends StatelessWidget {
  const AllScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부린이'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 설정 화면으로 이동
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSectionTitle('최근 화면'),
          _buildMenuItem('자산 인증', Icons.verified_user, () {
            // TODO: 자산 인증 화면으로 이동
          }),
          _buildMenuItem('가계부 작성', Icons.edit_note, () {
            // TODO: 가계부 작성 화면으로 이동
          }),
          _buildMenuItem('내 자산 목표', Icons.track_changes, () {
            // TODO: 내 자산 목표 화면으로 이동
          }),
          
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
}