/// 일일 경제 퀴즈 화면
/// 매일 새로운 경제 퀴즈를 제공하고, 정답 시 포인트를 지급합니다.
/// 이미 푼 퀴즈는 비활성화됩니다.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// 퀴즈 데이터 모델
class Quiz {
  final String id;
  final String category;
  final String question;
  final List<String> options;
  final int correctAnswerIndex; // 0-indexed
  final int points;

  Quiz({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.points,
  });

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      category: data['category'] ?? '',
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswerIndex: data['correctAnswerIndex'] ?? 0,
      points: data['points'] ?? 0,
    );
  }
}

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  Quiz? _currentQuiz;
  int? _selectedAnswerIndex; // 사용자가 선택한 답
  bool _isAnswerChecked = false; // 정답 확인 버튼 눌렀는지 여부
  bool _isQuizSolvedToday = false; // 오늘 퀴즈 풀었는지 여부
  bool _isLoading = true;
  String _quizSolvedDate = ''; // 퀴즈를 푼 날짜 (YYYY-MM-DD)

  @override
  void initState() {
    super.initState();
    _loadDailyQuiz();
  }

  Future<void> _loadDailyQuiz() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _isLoading = false; });
      return;
    }

    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // 1. 오늘의 퀴즈가 이미 풀렸는지 확인
      final userQuizDoc = await FirebaseFirestore.instance
          .collection('user_daily_quizzes')
          .doc(user.uid)
          .collection('solved_quizzes')
          .doc(todayDate)
          .get();

      if (userQuizDoc.exists) {
        setState(() {
          _isQuizSolvedToday = true;
          _quizSolvedDate = todayDate;
        });
        // 이미 풀린 퀴즈라면 해당 퀴즈 정보를 가져와서 보여줍니다.
        final solvedQuizId = userQuizDoc.data()?['quizId'];
        if (solvedQuizId != null) {
          final quizDoc = await FirebaseFirestore.instance.collection('daily_quizzes').doc(solvedQuizId).get();
          if (quizDoc.exists) {
            _currentQuiz = Quiz.fromFirestore(quizDoc);
            _selectedAnswerIndex = userQuizDoc.data()?['selectedAnswerIndex'];
            _isAnswerChecked = true; // 이미 풀었으므로 정답이 확인된 상태로 보여줌
          }
        }
      } else {
        // 2. 오늘의 퀴즈를 Firestore에서 가져오기 (임시: 첫 번째 문서 가져오기)
        // 실제 서비스에서는 날짜별 퀴즈를 제공하거나, 무작위 퀴즈를 가져와야 합니다.
        final quizSnapshot = await FirebaseFirestore.instance
            .collection('daily_quizzes')
            .limit(1)
            .get();

        if (quizSnapshot.docs.isNotEmpty) {
          _currentQuiz = Quiz.fromFirestore(quizSnapshot.docs.first);
        } else {
          debugPrint('No quizzes found.');
        }
      }
    } catch (e) {
      debugPrint('Error loading daily quiz: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkAnswer() async {
    if (_selectedAnswerIndex == null || _isAnswerChecked) return;

    setState(() {
      _isAnswerChecked = true;
    });

    if (_currentQuiz == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userQuizDocRef = FirebaseFirestore.instance
        .collection('user_daily_quizzes')
        .doc(user.uid)
        .collection('solved_quizzes')
        .doc(todayDate);

    // 이미 오늘 퀴즈를 풀었는지 다시 확인
    final userQuizDoc = await userQuizDocRef.get();
    if (userQuizDoc.exists) {
      setState(() {
        _isQuizSolvedToday = true;
        _quizSolvedDate = todayDate;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 오늘 퀴즈를 풀었습니다.'), backgroundColor: Colors.orange),
        );
      }
      return; // 이미 풀었다면 추가 처리 없이 종료
    }

    int pointsEarned = 0;
    bool isCorrect = (_selectedAnswerIndex == _currentQuiz!.correctAnswerIndex);

    if (isCorrect) {
      pointsEarned = _currentQuiz!.points;

      // 사용자 총 포인트 업데이트
      final userDocRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDocRef);
        if (userSnapshot.exists) {
          final currentPoints = (userSnapshot.data()?['points'] as num?)?.toInt() ?? 0;
          transaction.update(userDocRef, {'points': currentPoints + pointsEarned});
        } else {
          transaction.set(userDocRef, {'points': pointsEarned}, SetOptions(merge: true));
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('정답입니다! ${pointsEarned}포인트를 획득했습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오답입니다. 다시 도전해주세요!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // 퀴즈 풀이 기록 저장
    await userQuizDocRef.set({
      'quizId': _currentQuiz!.id,
      'solvedAt': Timestamp.now(),
      'isCorrect': isCorrect,
      'pointsEarned': pointsEarned,
      'selectedAnswerIndex': _selectedAnswerIndex, // 사용자가 선택한 답 저장
    });

    setState(() {
      _isQuizSolvedToday = true;
      _quizSolvedDate = todayDate;
    });
  }

  Color _getOptionButtonColor(int index) {
    if (!_isAnswerChecked) {
      // 정답 확인 전: 선택된 항목만 파란 테두리
      return _selectedAnswerIndex == index ? Colors.blue[100]! : Colors.grey[200]!;
    } else {
      // 정답 확인 후:
      if (index == _currentQuiz!.correctAnswerIndex) {
        return Colors.green[100]!; // 정답은 연한 초록
      } else if (_selectedAnswerIndex == index) {
        return Colors.red[100]!; // 오답 선택은 연한 빨강
      } else {
        return Colors.grey[200]!; // 나머지 보기는 회색
      }
    }
  }

  Color _getOptionBorderColor(int index) {
    if (!_isAnswerChecked) {
      // 정답 확인 전: 선택된 항목만 파란 테두리
      return _selectedAnswerIndex == index ? Colors.blue : Colors.grey[300]!;
    } else {
      // 정답 확인 후:
      if (index == _currentQuiz!.correctAnswerIndex) {
        return Colors.green; // 정답은 초록 테두리
      } else if (_selectedAnswerIndex == index) {
        return Colors.red; // 오답 선택은 빨강 테두리
      } else {
        return Colors.grey[300]!; // 나머지 보기는 회색 테두리
      }
    }
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
              '일일 경제 퀴즈',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.receipt_long, color: Color(0xFF673AB7), size: 24), // Quiz icon (purple for economic quiz)
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentQuiz == null
              ? const Center(child: Text('오늘의 퀴즈를 찾을 수 없습니다.'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _currentQuiz!.category,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${_currentQuiz!.points}P',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF673AB7), // Purple color for points
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _currentQuiz!.question,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ..._currentQuiz!.options.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  String option = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: InkWell(
                                      onTap: _isAnswerChecked || _isQuizSolvedToday
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedAnswerIndex = index;
                                              });
                                            },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
                                        decoration: BoxDecoration(
                                          color: _getOptionButtonColor(index),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getOptionBorderColor(index),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: _isAnswerChecked && index == _currentQuiz!.correctAnswerIndex
                                                ? Colors.green[900]
                                                : (_isAnswerChecked && _selectedAnswerIndex == index
                                                    ? Colors.red[900]
                                                    : Colors.black87),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: (_selectedAnswerIndex == null || _isAnswerChecked || _isQuizSolvedToday)
                              ? null
                              : _checkAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_isAnswerChecked || _isQuizSolvedToday) ? Colors.grey : const Color(0xFF8BC34A),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            _isQuizSolvedToday ? '오늘 푼 퀴즈에요' : '정답을 골랐어요.',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
} 