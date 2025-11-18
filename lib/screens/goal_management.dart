/// 목표 관리 화면
/// 사용자의 목표를 조회하고 관리하는 화면입니다.
library;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'goal_add.dart';
import 'goal_update.dart';
import 'goal_amount_add.dart';

const Color _successBadgeColor = Color(0xFF4CAF50);
const Color _successBackgroundColor = Color(0xFFE8F5E9);
const Color _successBorderColor = Color(0xFF81C784);
const Color _successTextColor = Color(0xFF2E7D32);
const Color _failedBackgroundColor = Color(0xFFF4F4F4);
const Color _failedBorderColor = Color(0xFFD6D6D6);
const Color _failedTextColor = Color(0xFF8A8A8A);

class GoalManagementScreen extends StatefulWidget {
  final User? user;

  const GoalManagementScreen({
    super.key,
    this.user,
  });

  @override
  State<GoalManagementScreen> createState() => _GoalManagementScreenState();
}

enum _GoalTab {
  ongoing,
  ended,
}

class _GoalManagementScreenState extends State<GoalManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _goalList = [];
  Map<String, int> _accountBalances = {};
  _GoalTab _selectedTab = _GoalTab.ongoing;

  @override
  void initState() {
    super.initState();
    _loadGoalData();
  }

  // 목표 데이터 로드 함수
  Future<void> _loadGoalData() async {
    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // goal 컬렉션에서 현재 사용자의 모든 목표 조회
        QuerySnapshot goalQuery = await FirebaseFirestore.instance
            .collection('goal')
            .where('userId', isEqualTo: currentUser.uid)
            .get();

        List<Map<String, dynamic>> goalList = [];
        Map<String, int> accountBalances = {};

        if (goalQuery.docs.isNotEmpty) {
          // 각 목표에 대해 계좌 잔액 조회
          for (var doc in goalQuery.docs) {
            Map<String, dynamic> goalData = doc.data() as Map<String, dynamic>;
            String? bankId = goalData['bank'];
            goalData['id'] = doc.id;
            
            // bank 필드가 있으면 assets 컬렉션에서 잔액 조회
            if (bankId != null) {
              try {
                DocumentSnapshot assetDoc = await FirebaseFirestore.instance
                    .collection('assets')
                    .doc(bankId)
                    .get();
                
                if (assetDoc.exists) {
                  Map<String, dynamic> assetData = assetDoc.data() as Map<String, dynamic>;
                  accountBalances[bankId] = (assetData['balance'] as num?)?.toInt() ?? 0;
                } else {
                  accountBalances[bankId] = 0;
                }
              } catch (e) {
                debugPrint('은행 정보 조회 오류: $e');
                accountBalances[bankId] = 0;
              }
            }
            
            goalList.add(goalData);
          }
        }

        if (mounted) {
          setState(() {
            _goalList = goalList;
            _accountBalances = accountBalances;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('목표 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  // 금액 포맷팅 함수
  String _formatAmount(dynamic amount) {
    if (amount == null) return '0원';
    
    int amountInt = (amount as num).toInt();
    return NumberFormat('#,###원').format(amountInt);
  }

  // 날짜 포맷팅 함수
  String? _formatDate(dynamic date) {
    if (date == null) return null;
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return null;
    }
    
    return DateFormat('yy-MM-dd').format(dateTime);
  }

  // D-Day 계산 함수
  String _calculateDDay(dynamic deadline) {
    if (deadline == null) return '';
    
    DateTime deadlineDate;
    if (deadline is Timestamp) {
      deadlineDate = deadline.toDate();
    } else if (deadline is DateTime) {
      deadlineDate = deadline;
    } else {
      return '';
    }
    
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime targetDate = DateTime(deadlineDate.year, deadlineDate.month, deadlineDate.day);
    
    int difference = targetDate.difference(today).inDays;
    
    if (difference > 0) {
      return 'D-$difference';
    } else if (difference == 0) {
      return 'D-Day';
    } else {
      return 'D+${-difference}';
    }
  }

  // 목표 달성 퍼센트 계산 함수
  double _calculateProgressPercentage(Map<String, dynamic> goalData) {
    String? bankId = goalData['bank'];
    if (bankId == null || !_accountBalances.containsKey(bankId)) return 0.0;
    
    int goalAmount = (goalData['amount'] as num?)?.toInt() ?? 0;
    if (goalAmount == 0) return 0.0;
    
    int currentBalance = _accountBalances[bankId] ?? 0;
    
    // 목표 설정 시점의 잔액 (목표 데이터에서 가져오거나 기본값 0 사용)
    int initialBalance = (goalData['initialBalance'] as num?)?.toInt() ?? 0;
    
    // 현재 잔액에서 초기 잔액을 뺀 증가 금액
    int increasedAmount = currentBalance - initialBalance;
    
    // 증가 금액이 목표 금액에 비해 얼마나 달성되었는지 계산
    double percentage = (increasedAmount / goalAmount) * 100;
    
    // 100%를 넘지 않도록 제한
    return percentage > 100 ? 100.0 : (percentage < 0 ? 0.0 : percentage);
  }

  // 증가한 금액 계산 함수
  int _getIncreasedAmount(Map<String, dynamic> goalData) {
    String? bankId = goalData['bank'];
    if (bankId == null || !_accountBalances.containsKey(bankId)) return 0;
    
    int currentBalance = _accountBalances[bankId] ?? 0;
    int initialBalance = (goalData['initialBalance'] as num?)?.toInt() ?? 0;
    
    int increasedAmount = currentBalance - initialBalance;
    return increasedAmount < 0 ? 0 : increasedAmount; // 음수인 경우 0 반환
  }

  // 응원 문구 생성 함수
  String _getEncouragementMessage(Map<String, dynamic> goalData) {
    double percentage = _calculateProgressPercentage(goalData);
    
    if (percentage < 50) {
      return '곧 절반입니다! 😊';
    } else if (percentage < 80) {
      return '절반 도달했습니다! 👍';
    } else if (percentage < 100) {
      return '거의 도달했습니다! 👏';
    } else {
      return '목표를 달성했습니다! 🎉';
    }
  }

  // 목표 삭제 대화상자 표시
  void _showDeleteGoalDialog(Map<String, dynamic> goalData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('목표 삭제'),
          content: const Text('목표를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 대화상자 닫기
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 대화상자 닫기
                _deleteGoal(goalData); // 목표 삭제 실행
              },
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // 목표 삭제 함수
  Future<void> _deleteGoal(Map<String, dynamic> goalData) async {
    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // goal 컬렉션에서 해당 목표 문서 찾기
        QuerySnapshot goalQuery = await FirebaseFirestore.instance
            .collection('goal')
            .where('userId', isEqualTo: currentUser.uid)
            .where('name', isEqualTo: goalData['name'])
            .where('amount', isEqualTo: goalData['amount'])
            .where('bank', isEqualTo: goalData['bank'])
            .get();

        if (goalQuery.docs.isNotEmpty) {
          // 첫 번째 일치하는 문서 삭제
          await FirebaseFirestore.instance
              .collection('goal')
              .doc(goalQuery.docs.first.id)
              .delete();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('목표가 삭제되었습니다.')),
            );
            
            // 목표 관리 화면 재로드
            _loadGoalData();
          }
        }
      }
    } catch (e) {
      debugPrint('목표 삭제 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목표 삭제 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF73AD13),
        title: const Text(
          '목표 관리',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF73AD13),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadGoalData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildGoalTabBar(),
                      const SizedBox(height: 16),
                      _buildGoalSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildGoalTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton(_GoalTab.ongoing, '진행 중'),
          const SizedBox(width: 8),
          _buildTabButton(_GoalTab.ended, '종료된 목표'),
        ],
      ),
    );
  }

  Expanded _buildTabButton(_GoalTab tab, String label) {
    final bool isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTab != tab) {
            setState(() {
              _selectedTab = tab;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF73AD13) : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected ? const Color(0xFF73AD13) : const Color(0xFFDDDDDD),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSection() {
    if (_selectedTab == _GoalTab.ongoing) {
      return _buildOngoingGoals();
    }
    return _buildEndedGoals();
  }

  Widget _buildOngoingGoals() {
    final ongoingGoals = _ongoingGoals;
    if (ongoingGoals.isEmpty) {
      return Column(
        children: [
          _buildEmptyGoalCard(),
          const SizedBox(height: 20),
          _buildAddButton(),
        ],
      );
    }

    return Column(
      children: [
        ...ongoingGoals.asMap().entries.map((entry) {
          final bool isLast = entry.key == ongoingGoals.length - 1;
          return Column(
            children: [
              _buildGoalCard(entry.value),
              if (!isLast) const SizedBox(height: 16),
            ],
          );
        }),
        const SizedBox(height: 20),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildEndedGoals() {
    final endedGoals = _endedGoals;
    if (endedGoals.isEmpty) {
      return Column(
        children: [
          _buildEmptyEndedCard(),
          const SizedBox(height: 20),
          _buildAddButton(),
        ],
      );
    }

    return Column(
      children: [
        ...endedGoals.asMap().entries.map((entry) {
          final bool isLast = entry.key == endedGoals.length - 1;
          return Column(
            children: [
              _buildEndedGoalCard(entry.value),
              if (!isLast) const SizedBox(height: 16),
            ],
          );
        }),
        const SizedBox(height: 20),
        _buildAddButton(),
      ],
    );
  }

  // 목표 카드 위젯
  Widget _buildGoalCard(Map<String, dynamic> goalData) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: _buildGoalContent(goalData),
      ),
    );
  }

  Widget _buildEndedGoalCard(Map<String, dynamic> goalData) {
    final bool isSuccess = _isGoalSuccessful(goalData);
    final double progressPercentage = _calculateProgressPercentage(goalData);
    final Color badgeColor = isSuccess ? _successBadgeColor : _failedTextColor;
    final String badgeText = isSuccess ? '[달성 완료]' : '[기간 만료]';

    return Card(
      color: isSuccess ? _successBackgroundColor : _failedBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSuccess ? _successBorderColor : _failedBorderColor,
          width: 1.5,
        ),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goalData['name'] ?? '목표명 없음',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSuccess ? _successTextColor : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSuccess
                            ? '목표 달성 완료! 🏆'
                            : '아쉽게 달성하지 못했어요 💤',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSuccess ? _successTextColor : _failedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSuccess
                            ? Icons.emoji_events_rounded
                            : Icons.watch_later_outlined,
                        size: 14,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isSuccess)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _successBorderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      color: _successTextColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '축하합니다! 100%를 달성했어요.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _successTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                '진행도 ${progressPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _failedTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFB0B0B0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatAmount(_getIncreasedAmount(goalData))} / ${_formatAmount(goalData['amount'])}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isSuccess ? _successTextColor : _failedTextColor,
                  ),
                ),
                Text(
                  _formatDate(goalData['endDate'] ?? goalData['deadline']) ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isSuccess)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showGoalHistory(goalData),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _successTextColor,
                        side: BorderSide(color: _successTextColor),
                      ),
                      child: const Text(
                        '히스토리 보기',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => _showDeleteGoalDialog(goalData),
                    child: const Text(
                      '삭제',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCC4D4D),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _retryGoal(goalData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF616161),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '다시 도전하기',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 빈 목표 카드 위젯
  Widget _buildEmptyGoalCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: _buildEmptyGoalContent(),
      ),
    );
  }

  Widget _buildEmptyEndedCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: const [
            Icon(Icons.emoji_emotions_outlined, size: 40, color: Color(0xFF73AD13)),
            SizedBox(height: 16),
            Text(
              '종료된 목표가 없습니다.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '목표를 달성하거나 기간이 지나면 이곳에서 확인할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7A7A7A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGoalHistory(Map<String, dynamic> goalData) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('목표 히스토리'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('목표명: ${goalData['name'] ?? '-'}'),
              const SizedBox(height: 8),
              Text('달성 금액: ${_formatAmount(goalData['amount'])}'),
              const SizedBox(height: 8),
              Text('기간: ${_formatDate(goalData['startDate']) ?? '-'} ~ '
                  '${_formatDate(goalData['endDate'] ?? goalData['deadline']) ?? '-'}'),
              const SizedBox(height: 16),
              const Text(
                '상세 히스토리 기능은 추후 제공될 예정입니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _retryGoal(Map<String, dynamic> goalData) async {
    final int goalAmount = (goalData['amount'] as num?)?.toInt() ?? 0;
    if (goalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 금액 정보가 없어 다시 도전할 수 없습니다.')),
      );
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime? previousStart = _parseDate(goalData['startDate']);
    final DateTime? previousEnd =
        _parseDate(goalData['endDate'] ?? goalData['deadline']);
    final Duration duration =
        (previousStart != null && previousEnd != null && previousEnd.isAfter(previousStart))
            ? previousEnd.difference(previousStart)
            : const Duration(days: 30);

    final GoalPreset preset = GoalPreset(
      goalName: goalData['name'] as String?,
      goalAmount: goalAmount,
      monthlyAmount: (goalData['monthlyAmount'] as num?)?.toInt(),
      startDate: now,
      endDate: now.add(duration),
      targetAccountId: goalData['bank'] as String?,
      withdrawalAccountId: goalData['withdrawalAccount'] as String?,
      withdrawalDay: _parseWithdrawalDay(goalData['withdrawalDay']),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalAddScreen(
          user: widget.user,
          preset: preset,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _selectedTab = _GoalTab.ongoing;
      });
      await _loadGoalData();
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  int? _parseWithdrawalDay(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse('$value');
  }

  bool _isGoalSuccessful(Map<String, dynamic> goalData) {
    return _calculateProgressPercentage(goalData) >= 100;
  }

  bool _isGoalExpired(Map<String, dynamic> goalData) {
    final DateTime? deadline =
        _parseDate(goalData['endDate'] ?? goalData['deadline']);
    if (deadline == null) return false;

    final DateTime today = DateTime.now();
    final DateTime normalizedToday =
        DateTime(today.year, today.month, today.day);
    final DateTime normalizedDeadline =
        DateTime(deadline.year, deadline.month, deadline.day);

    return normalizedDeadline.isBefore(normalizedToday);
  }

  bool _isGoalEnded(Map<String, dynamic> goalData) {
    return _isGoalSuccessful(goalData) || _isGoalExpired(goalData);
  }

  List<Map<String, dynamic>> get _ongoingGoals =>
      _goalList.where((goal) => !_isGoalEnded(goal)).toList();

  List<Map<String, dynamic>> get _endedGoals =>
      _goalList.where(_isGoalEnded).toList();

  // 목표 데이터가 있을 때의 내용
  Widget _buildGoalContent(Map<String, dynamic> goalData) {
    double progressPercentage = _calculateProgressPercentage(goalData);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 목표 제목, D-Day, 연필 아이콘, 휴지통 아이콘
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    goalData['name'] ?? '목표명 없음',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _calculateDDay(goalData['endDate'] ?? goalData['deadline']),
                    style: const TextStyle(
                      color: Color(0xFF7D7D7D),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      // 목표 수정 화면으로 이동
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GoalUpdateScreen(
                            goalData: goalData,
                          ),
                        ),
                      );

                      // 목표가 성공적으로 수정되면 데이터 새로고침
                      if (result == true) {
                        _loadGoalData();
                      }
                    },
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF7D7D7D),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showDeleteGoalDialog(goalData),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFF7D7D7D),
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // 진행률 막대 그래프
        Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E8BFE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${progressPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF73AD13),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 증가한 금액 / 목표 금액과 시작 날짜
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatAmount(_getIncreasedAmount(goalData))} / ${_formatAmount(goalData['amount'])}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black,
              ),
            ),
            Text(
              _formatDate(goalData['startDate']) ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7D7D7D),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 응원 문구와 종료 날짜
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _getEncouragementMessage(goalData),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            Text(
              _formatDate(goalData['endDate']) ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7D7D7D),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 목표 수정 버튼
        Center(
          child: SizedBox(
            width: 120, // 원하는 너비 설정
            child: ElevatedButton(
              onPressed: () async {
                // 목표 금액 추가 화면으로 이동
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GoalAmountAddScreen(
                      goalData: goalData,
                    ),
                  ),
                );

                // 목표 금액이 성공적으로 추가되면 데이터 새로고침
                if (result == true) {
                  _loadGoalData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF73AD13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                minimumSize: const Size(0, 36), // 높이만 유지
              ),
              child: const Text(
                '목표 금액 추가',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 목표 데이터가 없을 때의 내용
  Widget _buildEmptyGoalContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [      
        const SizedBox(height: 56),
        Text(
          '목표를 설정해주세요',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 56),
      ],
    );
  }

  // 플러스 버튼 위젯
  Widget _buildAddButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF73AD13),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () async {
            // 목표 추가 화면으로 이동
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GoalAddScreen(),
              ),
            );
            
            // 목표가 성공적으로 저장되면 데이터 새로고침
            if (result == true) {
              _loadGoalData();
            }
          },
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}
