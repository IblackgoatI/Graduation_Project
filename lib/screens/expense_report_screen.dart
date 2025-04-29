import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseReportScreen extends StatefulWidget {
  const ExpenseReportScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends State<ExpenseReportScreen> {
  String userName = '부린이님'; // 기본값 설정
  
  @override
  void initState() {
    super.initState();
    _loadUserName();
  }
  
  // Firebase에서 사용자 이름을 가져오는 함수
  Future<void> _loadUserName() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['Name'] != null) {
            setState(() {
              userName = userData['Name'];
            });
          }
        }
      }
    } catch (e) {
      print('사용자 이름 로드 중 오류 발생: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소비 리포트'),
        backgroundColor: Colors.grey[50],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 소비 리포트 설명
              const Text(
                '이번 달 소비 패턴을 확인하고 공유해보세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              
              // 소비 리포트 카드
              _buildExpenseReportCard(),
              const SizedBox(height: 32),
              
              // 공유 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _shareExpenseReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '리포트 공유하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
  
  // 소비 리포트 카드 UI
  Widget _buildExpenseReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${userName}님의 1월 소비 리포트",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
          const SizedBox(height: 24),
          
          // 원형 차트
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(90),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: PieChartPainter(),
                child: const Center(
                  child: Text(
                    "지출",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          const Divider(),
          const SizedBox(height: 12),
          
          // 총 소비 금액
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    "1월 총 소비",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "300,000원",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 카테고리별 지출 목록
          _buildCategoryItem("식비", "33.3%", "100,000원", Colors.red.shade300),
          const SizedBox(height: 12),
          _buildCategoryItem("문화 생활", "25%", "75,000원", Colors.purple.shade300),
          const SizedBox(height: 12),
          _buildCategoryItem("은행", "16.6%", "50,000원", Colors.blue.shade300),
          const SizedBox(height: 12),
          _buildCategoryItem("기타", "25%", "75,000원", Colors.green.shade300),
        ],
      ),
    );
  }
  
  // 카테고리 항목 UI
  Widget _buildCategoryItem(String title, String percent, String amount, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getCategoryIcon(title),
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                percent,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 13,
          ),
        ),
      ],
    );
  }
  
  // 카테고리에 맞는 아이콘 반환
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '식비':
        return Icons.restaurant;
      case '문화 생활':
        return Icons.movie;
      case '은행':
        return Icons.account_balance;
      case '쇼핑':
        return Icons.shopping_bag;
      case '교통':
        return Icons.directions_car;
      case '기타':
        return Icons.category;
      default:
        return Icons.category;
    }
  }
  
  // 리포트 공유 기능
  void _shareExpenseReport() {
    // 실제 공유 기능 구현 (미구현 - 예시로 메시지만 표시)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("소비 리포트가 공유되었습니다"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// 원형 차트를 그리는 커스텀 페인터
class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 각 섹션의 색상과 크기(각도) 정의
    final sections = [
      {'color': Colors.red.shade300, 'percent': 0.33}, // 식비
      {'color': Colors.purple.shade300, 'percent': 0.25}, // 문화 생활
      {'color': Colors.blue.shade300, 'percent': 0.17}, // 은행
      {'color': Colors.green.shade300, 'percent': 0.25}, // 기타
    ];
    
    var startAngle = -90 * 3.14 / 180; // -90도에서 시작 (12시 방향)
    
    for (var section in sections) {
      final sweepAngle = (section['percent'] as double) * 360 * 3.14 / 180;
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
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 