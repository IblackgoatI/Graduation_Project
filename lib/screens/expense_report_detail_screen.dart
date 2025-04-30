import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 파이 차트 커스텀 페인터
class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> sections;
  
  PieChartPainter({required this.sections});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    var startAngle = -90 * 3.14 / 180; // -90도(12시 방향)에서 시작
    
    // 파이 차트 섹션 그리기
    for (var section in sections) {
      final percent = (section['percent'] as num).toDouble();
      final sweepAngle = percent * 2 * 3.14; // 라디안 각도로 변환
      
      final paint = Paint()
        ..color = section['color'] as Color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // 섹션 경계선 그리기
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        strokePaint,
      );
      
      startAngle += sweepAngle;
    }
    
    // 가운데 흰색 원 그리기 (도넛 차트 효과)
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PieChartPainter) {
      return oldDelegate.sections != sections;
    }
    return true;
  }
}

class ExpenseReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> postData;

  const ExpenseReportDetailScreen({
    Key? key,
    required this.postData,
  }) : super(key: key);

  @override
  State<ExpenseReportDetailScreen> createState() => _ExpenseReportDetailScreenState();
}

class _ExpenseReportDetailScreenState extends State<ExpenseReportDetailScreen> {
  String _authorName = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAuthorInfo();
  }

  Future<void> _loadAuthorInfo() async {
    try {
      // 먼저 author_name 필드가 있는지 확인
      if (widget.postData.containsKey('author_name') && widget.postData['author_name'] != null) {
        setState(() {
          _authorName = widget.postData['author_name'];
          _isLoading = false;
        });
        return;
      }
      
      // author_name이 없는 경우에만 Firebase에서 가져오기
      if (widget.postData['userId'] != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.postData['userId'])
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['Name'] != null) {
            setState(() {
              _authorName = userData['Name'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('작성자 정보 로드 중 오류 발생: $e');
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportData = widget.postData['report_data'] as Map<String, dynamic>?;
    final totalAmount = reportData?['total_expense'] ?? 0;
    final formattedAmount = NumberFormat('#,###').format(totalAmount);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('소비 리포트 게시판'),
        backgroundColor: Colors.grey[50],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    const Text(
                      '제목',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.postData['Heading'] ?? '제목 없음',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 내용
                    const Text(
                      '내용',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.postData['Content'] ?? '내용 없음',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 작성자 이름
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '작성자: $_authorName',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // 소비 리포트 카드
                    _buildExpenseReportCard(reportData),
                    
                    const SizedBox(height: 16),
                    
                    // 댓글 남기기 버튼
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 댓글 작성 기능 구현
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('댓글 기능은 아직 준비 중입니다'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.comment),
                        label: const Text('댓글 남기기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BC34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildExpenseReportCard(Map<String, dynamic>? reportData) {
    if (reportData == null) {
      return const Center(
        child: Text('소비 리포트 데이터가 없습니다'),
      );
    }

    final totalAmount = reportData['total_expense'] ?? 0;
    final formattedAmount = NumberFormat('#,###').format(totalAmount);
    final categories = reportData['categories'] as Map<String, dynamic>? ?? {};
    final month = widget.postData['Month'] ?? '1';
    
    // 카테고리 데이터를 금액 기준으로 정렬
    List<MapEntry<String, dynamic>> sortedCategories = [];
    if (categories.isNotEmpty) {
      sortedCategories = categories.entries.toList()
        ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    }

    // 파이 차트용 색상 정의
    final colors = [
      Colors.red[300]!,
      Colors.yellow[300]!,
      Colors.purple[300]!,
      Colors.blue[300]!,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 소비 리포트 헤더
          Row(
            children: [
              Text(
                '${_authorName}님의 ${month}월 소비 리포트',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 파이 차트 - 중앙 배치
          Center(
            child: Container(
              height: 160,
              width: 160,
              child: _buildPieChart(reportData, categories, month, formattedAmount),
            ),
          ),
          const SizedBox(height: 24),
          
          // 카테고리 헤더
          const Row(
            children: [
              Text(
                '카테고리별 지출',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 카테고리 목록 - 스크롤 형식으로 변경
          Container(
            constraints: BoxConstraints(
              // 화면 크기에 맞게 동적으로 높이 제한
              maxHeight: MediaQuery.of(context).size.height * 0.25,
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero, // 패딩 제거
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final entry = sortedCategories[index];
                final color = colors[index % colors.length];
                final categoryName = entry.key;
                final amount = (entry.value is int) ? entry.value.toDouble() : (entry.value as num).toDouble();
                final percent = totalAmount > 0 ? amount / totalAmount * 100 : 0;
                
                // 카테고리 아이콘 매핑
                IconData categoryIcon;
                switch (categoryName) {
                  case '식비':
                    categoryIcon = Icons.restaurant;
                    break;
                  case '문화생활':
                  case '문화 생활':
                    categoryIcon = Icons.videogame_asset;
                    break;
                  case '쇼핑':
                    categoryIcon = Icons.shopping_bag;
                    break;
                  case '교통':
                    categoryIcon = Icons.directions_car;
                    break;
                  case '미용':
                  case '뷰티':
                    categoryIcon = Icons.spa;
                    break;
                  case '의료':
                    categoryIcon = Icons.medical_services;
                    break;
                  case '음행':
                  case '카페':
                    categoryIcon = Icons.local_cafe;
                    break;
                  default:
                    categoryIcon = Icons.category;
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // 카테고리 아이콘
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withAlpha(50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          categoryIcon,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // 카테고리 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${percent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 금액
                      Text(
                        '${NumberFormat('#,###').format(amount)}원',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 파이 차트 위젯
  Widget _buildPieChart(Map<String, dynamic> reportData, Map<String, dynamic> categories, String month, String formattedAmount) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              '${month}월 총 소비',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${formattedAmount}원',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    // 총 금액
    final totalAmount = reportData['total_expense'] ?? 0;
    
    // 카테고리 데이터 변환
    List<Map<String, dynamic>> sections = [];
    
    // 색상 정의
    final colors = [
      Colors.red[300]!,
      Colors.yellow[300]!,
      Colors.purple[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.teal[300]!,
      Colors.pink[300]!,
    ];
    
    int colorIndex = 0;
    categories.forEach((key, value) {
      final amount = (value is int) ? value.toDouble() : (value as num).toDouble();
      final percent = totalAmount > 0 ? amount / totalAmount : 0.0;
      
      sections.add({
        'name': key,
        'color': colors[colorIndex % colors.length],
        'percent': percent,
        'amount': amount,
      });
      
      colorIndex++;
    });
    
    // 비율 순으로 섹션 정렬
    sections.sort((a, b) => ((b['percent'] as num).toDouble()).compareTo((a['percent'] as num).toDouble()));
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: CustomPaint(
            size: const Size(120, 120),
            painter: PieChartPainter(sections: sections),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${month}월 총 소비: ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${formattedAmount}원',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 