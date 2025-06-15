/// 출석 체크 화면
/// 사용자별 출석 기록을 관리하고, 연속 출석에 따른 포인트 지급 기능을 제공합니다.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = false;
  bool _isCheckedToday = false;
  int _currentStreak = 0;
  int _totalPoints = 0;
  List<Map<String, dynamic>> _attendanceHistory = [];

  // Helper to get number of days in a month
  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // Helper to check if two DateTimes are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 사용자의 출석 데이터 가져오기
      final attendanceDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(user.uid)
          .get();

      if (attendanceDoc.exists) {
        final data = attendanceDoc.data()!;
        final lastCheckDate = (data['lastCheckDate'] as Timestamp).toDate();
        final today = DateTime.now();

        // 오늘 날짜와 마지막 체크 날짜 비교
        _isCheckedToday = _isSameDay(lastCheckDate, today);

        _currentStreak = data['currentStreak'] ?? 0;
        _totalPoints = data['totalPoints'] ?? 0;

        // 출석 기록 가져오기
        final history = data['history'] as List<dynamic>? ?? [];
        _attendanceHistory = history.map((entry) {
          if (entry is Map<String, dynamic>) {
            return {
              'date': (entry['date'] as Timestamp).toDate(),
              'points': entry['points'] as int? ?? 0,
            };
          } else if (entry is Timestamp) { // Handle old format where history was just Timestamps
            return {
              'date': entry.toDate(),
              'points': 10, // Default points for old entries, if needed for display
            };
          }
          return <String, dynamic>{}; // Fallback for unexpected format
        }).where((element) => element.isNotEmpty).cast<Map<String, dynamic>>().toList(); // Explicit cast added

        // Sort history by date to ensure correct streak calculation
        _attendanceHistory.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      }
    } catch (e) {
      debugPrint('Error loading attendance data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkAttendance() async {
    if (_isCheckedToday) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // 연속 출석 체크
      DateTime? lastRecordedDate;
      if (_attendanceHistory.isNotEmpty) {
        lastRecordedDate = _attendanceHistory.last['date'] as DateTime;
      }

      if (lastRecordedDate != null && _isSameDay(lastRecordedDate, yesterday)) {
        _currentStreak++;
      } else {
        _currentStreak = 1;
      }

      // 포인트 계산 (연속 출석에 따라 차등 지급)
      int points = 10; // 기본 포인트
      if (_currentStreak >= 20) points = 50; // New rule for 50P based on image
      else if (_currentStreak >= 7) points = 30;
      else if (_currentStreak >= 3) points = 20;

      // Firestore에 데이터 업데이트
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(user.uid)
          .set({
        'lastCheckDate': Timestamp.now(),
        'currentStreak': _currentStreak,
        'totalPoints': _totalPoints + points,
        // Store date and points in history
        'history': FieldValue.arrayUnion([
          {'date': Timestamp.now(), 'points': points}
        ]),
      }, SetOptions(merge: true));

      // 상태 업데이트
      setState(() {
        _isCheckedToday = true;
        _totalPoints += points;
        _attendanceHistory.add({'date': today, 'points': points}); // Add in new format
        // Re-sort to maintain order
        _attendanceHistory.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('출석 체크 완료! ${points}포인트가 지급되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('출석 체크 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateFormat('MM월').format(now);
    final daysInCurrentMonth = _daysInMonth(now.year, now.month);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    // Calculate leading blank days for Sunday-first calendar (0 for Sunday, 1 for Monday, ..., 6 for Saturday)
    final int startOffset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday; // Adjust 7 (Sunday) to 0

    // Get only the attendance history for the current month
    final currentMonthAttendance = _attendanceHistory.where((entry) {
      final date = entry['date'] as DateTime;
      return date.year == now.year && date.month == now.month;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row( // Changed to Row for gift icon
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '출석 체크',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.card_giftcard, color: Color(0xFF8BC34A), size: 24), // Gift icon
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              '$currentMonth 출석 체크',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: daysInCurrentMonth + startOffset, // Total cells in grid
                              itemBuilder: (context, index) {
                                if (index < startOffset) {
                                  return Container(); // Empty container for leading blank days
                                }

                                final day = index - startOffset + 1; // 1-indexed day of the month
                                
                                final dateForCell = DateTime(now.year, now.month, day);
                                final attendanceEntry = currentMonthAttendance.firstWhere(
                                      (entry) => _isSameDay(entry['date'] as DateTime, dateForCell),
                                  orElse: () => {},
                                );
                                final isAttended = attendanceEntry.isNotEmpty;
                                final pointsEarned = isAttended ? attendanceEntry['points'] as int : 0;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isAttended ? const Color(0xFF8BC34A) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _isSameDay(dateForCell, now) ? Colors.blue : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        day.toString(),
                                        style: TextStyle(
                                          color: isAttended ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4), // Added a small space
                                      if (isAttended)
                                        Column(
                                          children: [
                                            const Icon(Icons.check, color: Colors.white, size: 16),
                                            Text(
                                              '${pointsEarned}P',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Container(), // Replace with an empty container or SizedBox
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '모은 포인트: $_totalPoints P',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8BC34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isCheckedToday ? null : _checkAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCheckedToday ? Colors.grey : const Color(0xFF8BC34A),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        _isCheckedToday ? '출석 완료' : '출석 체크하기',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      context,
                      '일일 경제 퀴즈 도전하기',
                      Icons.school,
                      const Color(0xFFEFE8F9), // Light purple
                      const Color(0xFF673AB7), // Darker purple
                      () {
                        // TODO: 일일 경제 퀴즈 화면으로 이동
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      context,
                      '포인트 관리하기',
                      Icons.receipt_long,
                      const Color(0xFFEFE8F9), // Light purple
                      const Color(0xFF673AB7), // Darker purple
                      () {
                        // TODO: 포인트 관리 화면으로 이동
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper method for the action buttons at the bottom
  Widget _buildActionButton(BuildContext context, String text, IconData icon, Color bgColor, Color textColor, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!), // Add border for subtle effect
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Icon(icon, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
} 