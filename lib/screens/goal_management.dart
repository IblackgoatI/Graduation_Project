/// 목표 관리 화면
/// 사용자의 목표를 조회하고 관리하는 화면입니다.
library;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'goal_add.dart';
import 'goal_update.dart';

class GoalManagementScreen extends StatefulWidget {
  final User? user;

  const GoalManagementScreen({
    super.key,
    this.user,
  });

  @override
  State<GoalManagementScreen> createState() => _GoalManagementScreenState();
}

class _GoalManagementScreenState extends State<GoalManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _goalList = [];
  Map<String, int> _accountBalances = {};

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
    
    int accountBalance = _accountBalances[bankId] ?? 0;
    double percentage = (accountBalance / goalAmount) * 100;
    return percentage > 100 ? 100.0 : percentage;
  }

  // 응원 문구 생성 함수
  String _getEncouragementMessage(Map<String, dynamic> goalData) {
    double percentage = _calculateProgressPercentage(goalData);
    
    if (percentage < 50) {
      return '절반까지 얼마 안 남았습니다!';
    } else if (percentage < 80) {
      return '절반 도달했습니다!';
    } else if (percentage < 100) {
      return '거의 도달했습니다!';
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
            .where('deadline', isEqualTo: goalData['deadline'])
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
                      // 목표 카드들
                      if (_goalList.isNotEmpty) ...[
                        ..._goalList.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> goalData = entry.value;
                          bool isLast = index == _goalList.length - 1;
                          
                          return Column(
                            children: [
                              _buildGoalCard(goalData),
                              if (isLast) ...[
                                const SizedBox(height: 20),
                                // 플러스 버튼 (마지막 목표 카드 아래)
                                _buildAddButton(),
                              ] else
                                const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ] else ...[
                        // 목표가 없을 때
                        _buildEmptyGoalCard(),
                        const SizedBox(height: 20),
                        // 플러스 버튼
                        _buildAddButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
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

  // 목표 데이터가 있을 때의 내용
  Widget _buildGoalContent(Map<String, dynamic> goalData) {
    double progressPercentage = _calculateProgressPercentage(goalData);
    String? bankId = goalData['bank'];
    int accountBalance = bankId != null ? (_accountBalances[bankId] ?? 0) : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 목표 제목, D-Day, 휴지통 아이콘
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
                    _calculateDDay(goalData['deadline']),
                    style: const TextStyle(
                      color: Color(0xFF7D7D7D),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
        
        // 계좌 잔액 / 목표 금액
        Text(
          '${_formatAmount(accountBalance)} / ${_formatAmount(goalData['amount'])}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 응원 문구
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          
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
        
        const SizedBox(height: 8),
        
        // 목표 수정 버튼
        Center(
          child: SizedBox(
            width: 120, // 원하는 너비 설정
            child: ElevatedButton(
              onPressed: () async {
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF73AD13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                minimumSize: const Size(0, 36), // 높이만 유지
              ),
              child: const Text(
                '목표 수정',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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
