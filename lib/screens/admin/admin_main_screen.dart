/// 관리자 메인 화면
/// 게시물 및 댓글 관리 등 관리자 기능으로 이동하는 대시보드를 제공합니다.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_layout.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  String _selectedMenu = '대시보드';
  int _totalPosts = 0;
  int _todayPosts = 0;
  int _reportedComments = 0;
  int _activeQuizzes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // 전체 게시물 수
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('community')
          .get();
      _totalPosts = postsSnapshot.docs.length;

      // 오늘 게시물 수
      final todayPostsSnapshot = await FirebaseFirestore.instance
          .collection('community')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
          .get();
      _todayPosts = todayPostsSnapshot.docs.length;

      // 미답변 댓글 (신고된 댓글) - 실제 신고 기능이 있다면 그 컬렉션을 확인
      // 여기서는 임시로 전체 댓글 수를 표시
      _reportedComments = 0; // TODO: 실제 신고 댓글 수로 변경

      // 활성 퀴즈 수
      final quizzesSnapshot = await FirebaseFirestore.instance
          .collection('daily_quizzes')
          .where('isActive', isEqualTo: true)
          .get();
      _activeQuizzes = quizzesSnapshot.docs.length;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentMenu: _selectedMenu,
      title: '관리자 대시보드',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_selectedMenu != '대시보드') {
      return const Center(
        child: Text('해당 메뉴는 별도 화면으로 이동합니다.'),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 카드들
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '총 게시물 수',
                  '오늘 올라온 글: $_todayPosts개',
                  '전체: ${_formatNumber(_totalPosts)}개',
                  Icons.article,
                  Colors.blue,
                  () => context.go('/admin/posts'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '미답변 댓글',
                  '신규 신고 댓글: $_reportedComments건',
                  _reportedComments > 0 ? '🚨' : '정상',
                  Icons.comment,
                  Colors.orange,
                  () => context.go('/admin/comments'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '활성 퀴즈',
                  '현재 진행 중: $_activeQuizzes개',
                  '퀴즈 관리',
                  Icons.quiz,
                  Colors.green,
                  () => context.go('/admin/quiz_management'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // 최근 활동 로그
          _buildRecentActivityTable(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String subtitle,
    String footer,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 32),
                  Text(
                    footer,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '최근 활동 로그',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community')
                  .orderBy('created_at', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('최근 활동이 없습니다.'));
                }

                return DataTable(
                  columns: const [
                    DataColumn(label: Text('작성자')),
                    DataColumn(label: Text('제목')),
                    DataColumn(label: Text('작성일')),
                    DataColumn(label: Text('작업')),
                  ],
                  rows: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['created_at'] as Timestamp?;
                    final dateTime = timestamp?.toDate() ?? DateTime.now();
                    final formattedDate = DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
                    final authorName = data['author_name'] ?? '알 수 없음';
                    final heading = data['Heading'] ?? '제목 없음';

                    return DataRow(
                      cells: [
                        DataCell(Text(authorName)),
                        DataCell(
                          SizedBox(
                            width: 200,
                            child: Text(
                              heading,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(formattedDate)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 18),
                                onPressed: () {
                                  // 상세 보기
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('게시물 삭제'),
                                      content: const Text('이 게시물을 삭제하시겠습니까?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('취소'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('삭제', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('community')
                                        .doc(doc.id)
                                        .delete();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('게시물이 삭제되었습니다.')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }
} 