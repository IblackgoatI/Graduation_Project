/// 관리자 메인 화면
/// 게시물 및 댓글 관리 등 관리자 기능으로 이동하는 대시보드를 제공합니다.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart' show BarTooltipItem, BarChart, BarChartData, BarChartGroupData, BarChartRodData, FlTitlesData, FlBorderData, FlGridData, BarTouchData, BarTouchTooltipData, AxisTitles, SideTitles, BarChartAlignment;
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

  // 주간/월간/연간 게시물 추이 데이터
  List<Map<String, dynamic>> _weeklyData = [];
  List<Map<String, dynamic>> _monthlyData = [];
  List<Map<String, dynamic>> _yearlyData = [];
  int _selectedChartType = 0; // 0: 주간, 1: 월간, 2: 연간

  // 주간/월간 차트 데이터 로드
  Future<void> _loadChartData() async {
    final now = DateTime.now();

    // 주간 데이터 (최근 7일)
    _weeklyData = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('community')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('created_at', isLessThan: Timestamp.fromDate(end))
          .get();

      _weeklyData.add({
        'date': '${date.month}/${date.day}',
        'count': snapshot.docs.length,
      });
    }

    // 월간 데이터 (1월~12월)
    _monthlyData = [];
    for (int month = 1; month <= 12; month++) {
      final date = DateTime(now.year, month, 1);
      final nextMonth = month == 12 
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, month + 1, 1);

      final snapshot = await FirebaseFirestore.instance
          .collection('community')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
          .where('created_at', isLessThan: Timestamp.fromDate(nextMonth))
          .get();

      _monthlyData.add({
        'date': '$month월',
        'count': snapshot.docs.length,
      });
    }

    // 연간 데이터 (2024년~현재 연도)
    _yearlyData = [];
    for (int year = 2024; year <= now.year; year++) {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year + 1, 1, 1);

      final snapshot = await FirebaseFirestore.instance
          .collection('community')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', isLessThan: Timestamp.fromDate(endDate))
          .get();

      _yearlyData.add({
        'date': '$year년',
        'count': snapshot.docs.length,
      });
    }
  }

  // 차트 위젯 생성
  Widget _buildChart() {
    final data = _selectedChartType == 0 
        ? _weeklyData 
        : (_selectedChartType == 1 ? _monthlyData : _yearlyData);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '게시물 통계',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ToggleButtons(
                  isSelected: [
                    _selectedChartType == 0, 
                    _selectedChartType == 1,
                    _selectedChartType == 2,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedChartType = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  selectedColor: Colors.white,
                  fillColor: Colors.blue,
                  color: Colors.blue,
                  constraints: const BoxConstraints(
                    minHeight: 36.0,
                    minWidth: 60.0,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('주간'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('월간'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('연간'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 250,
              child: BarChart(
                duration: const Duration(milliseconds: 1000), // 1초로 늘려 더 부드럽게 전환
                curve: Curves.easeInOut,
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.isEmpty 
                      ? 10.0 // 데이터가 없을 때 기본값
                      : math.max(1.0, (data.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b) * 1.2).roundToDouble()),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey,
                      tooltipMargin: 0,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${data[groupIndex]['date']}\n${rod.toY.toInt()}개',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data[index]['date'].toString().split(' ')[0],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: data.isEmpty
                      ? []
                      : List.generate(
                          data.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: (data[index]['count'] as int).toDouble(),
                                color: Colors.blue,
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

      // 주간/월간 데이터 로드
      await _loadChartData();

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
          _buildChart(),
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