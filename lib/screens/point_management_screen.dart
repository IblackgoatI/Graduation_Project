/// 포인트 관리 화면
/// 사용자의 현재 보유 포인트 및 누적 포인트를 표시하고, 포인트를 획득할 수 있는 방법들의 진행 상황을 보여줍니다.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PointManagementScreen extends StatefulWidget {
  const PointManagementScreen({super.key});

  @override
  State<PointManagementScreen> createState() => _PointManagementScreenState();
}

class _PointManagementScreenState extends State<PointManagementScreen> {
  int _currentPoints = 0;
  int _totalAccumulatedPoints = 0; // 누적 포인트
  bool _isLoading = true;
  bool _isDailyQuizCompletedToday = false;
  bool _isAttendanceCompletedToday = false;
  // TODO: 예산 목표 달성 상태 추가 (추후 구현)
  bool _isBudgetGoalAchieved = false;

  @override
  void initState() {
    super.initState();
    _loadPointData();
  }

  Future<void> _loadPointData() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
      return;
    }

    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // 1. 사용자 포인트 정보 가져오기 (user_points 컬렉션에서)
      final pointsDoc = await FirebaseFirestore.instance
          .collection('user_points')
          .doc(user.uid)
          .get();
      
      if (pointsDoc.exists) {
        final pointsData = pointsDoc.data();
        _currentPoints = (pointsData?['currentPoints'] as num?)?.toInt() ?? 0;
        _totalAccumulatedPoints = (pointsData?['totalAccumulatedPoints'] as num?)?.toInt() ?? 0;
      } else {
        // 문서가 없는 경우 초기화
        await FirebaseFirestore.instance
            .collection('user_points')
            .doc(user.uid)
            .set({
          'currentPoints': 0,
          'totalAccumulatedPoints': 0,
          'lastUpdated': Timestamp.now(),
        });
      }

      // 2. 일일 경제 퀴즈 완료 여부 확인
      final dailyQuizDoc = await FirebaseFirestore.instance
          .collection('user_daily_quizzes')
          .doc(user.uid)
          .collection('solved_quizzes')
          .doc(todayDate)
          .get();
      _isDailyQuizCompletedToday = dailyQuizDoc.exists && (dailyQuizDoc.data()?['isCorrect'] == true || dailyQuizDoc.data()?['isCorrect'] == false); // 풀기만 하면 완료로 간주

      // 3. 출석 체크 완료 여부 확인
      final attendanceDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(user.uid)
          .get();
      if (attendanceDoc.exists) {
        final lastCheckDate = (attendanceDoc.data()?['lastCheckDate'] as Timestamp?)?.toDate();
        if (lastCheckDate != null) {
          _isAttendanceCompletedToday = DateFormat('yyyy-MM-dd').format(lastCheckDate) == todayDate;
        }
      }

      // TODO: 4. 예산 목표 달성 여부 확인 로직 추가 (추후 구현)
      // 현재는 임시로 false
      _isBudgetGoalAchieved = false; // Placeholder

    } catch (e) {
      debugPrint('Error loading point data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // TODO: 출금하기 기능 구현 (추후 구현)
  void _withdrawPoints() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('출금하기 기능은 아직 준비 중입니다.'), backgroundColor: Colors.blueAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '포인트 관리',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // 'P' 아이콘 (이미지와 유사한 보라색)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0), // 보라색
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 보유 포인트 카드
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.blueAccent, // 이미지의 파란색
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          '보유 포인트: $_currentPoints P',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 출금하기 버튼
                  ElevatedButton(
                    onPressed: _withdrawPoints,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BC34A), // 이미지의 녹색
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      '출금하기',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 포인트를 얻는 방법 섹션
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA), // 연한 하늘색 배경 (이미지 유사)
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '포인트를 얻는 방법',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9C27B0), // 보라색
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 일일 섹션
                        const Text(
                          '일일',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPointEarnMethodItem(
                          '경제 퀴즈',
                          Icons.receipt_long,
                          _isDailyQuizCompletedToday,
                          '완료',
                          '미완료',
                          const Color(0xFF673AB7), // 보라색 아이콘
                          const Color(0xFF9C27B0), // 보라색 텍스트
                        ),
                        _buildPointEarnMethodItem(
                          '출석 체크',
                          Icons.card_giftcard,
                          _isAttendanceCompletedToday,
                          '완료',
                          '미완료',
                          const Color(0xFF8BC34A), // 녹색 아이콘
                          const Color(0xFF8BC34A), // 녹색 텍스트
                        ),
                        const SizedBox(height: 16),
                        // 월간 섹션
                        const Text(
                          '월간',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPointEarnMethodItem(
                          '예산 목표달성',
                          Icons.flag, // 목표 달성 아이콘
                          _isBudgetGoalAchieved,
                          '좋은 소비에요',
                          '목표 미달성',
                          Colors.blue, // 파란색 아이콘
                          const Color(0xFF8BC34A), // 녹색 텍스트 (좋은 소비에요)
                          iconColorIfIncomplete: Colors.red, // 미달성 시 빨간색 아이콘
                          textColorIfIncomplete: Colors.red, // 미달성 시 빨간색 텍스트
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 누적 포인트
                  Text(
                    '누적 포인트: $_totalAccumulatedPoints P',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16), // 하단 여백
                ],
              ),
            ),
    );
  }

  Widget _buildPointEarnMethodItem(
      String title,
      IconData icon,
      bool isCompleted,
      String completedText,
      String incompleteText,
      Color completedIconColor,
      Color completedTextColor,
      {Color? iconColorIfIncomplete, Color? textColorIfIncomplete}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: isCompleted ? completedIconColor : (iconColorIfIncomplete ?? Colors.grey),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isCompleted ? completedTextColor : (textColorIfIncomplete ?? Colors.black87),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.transparent : Colors.transparent, // 이미지에선 배경색이 없거나 투명
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted ? Colors.transparent : Colors.transparent, // 이미지에선 테두리가 없음
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.cancel,
                  color: isCompleted ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  isCompleted ? completedText : incompleteText,
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 