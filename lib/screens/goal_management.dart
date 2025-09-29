/// 목표 관리 화면
/// 사용자의 목표를 조회하고 관리하는 화면입니다.
library;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  Map<String, dynamic>? _goalData;
  String? _bankName;

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
        // goal 컬렉션에서 현재 사용자의 목표 조회
        QuerySnapshot goalQuery = await FirebaseFirestore.instance
            .collection('goal')
            .where('userId', isEqualTo: currentUser.uid)
            .get();

        if (goalQuery.docs.isNotEmpty) {
          Map<String, dynamic> goalData = goalQuery.docs.first.data() as Map<String, dynamic>;
          String? bankId = goalData['bank'];
          
          // bank 필드가 있으면 assets 컬렉션에서 은행명 조회
          if (bankId != null) {
            try {
              DocumentSnapshot assetDoc = await FirebaseFirestore.instance
                  .collection('assets')
                  .doc(bankId)
                  .get();
              
              if (assetDoc.exists) {
                Map<String, dynamic> assetData = assetDoc.data() as Map<String, dynamic>;
                _bankName = assetData['bank'] ?? '은행 정보 없음';
              } else {
                _bankName = '은행 정보 없음';
              }
            } catch (e) {
              debugPrint('은행 정보 조회 오류: $e');
              _bankName = '은행 정보 없음';
            }
          }

          if (mounted) {
            setState(() {
              _goalData = goalData;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _goalData = null;
              _bankName = null;
              _isLoading = false;
            });
          }
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

  // 날짜 포맷팅 함수
  String _formatDate(dynamic date) {
    if (date == null) return '날짜 미설정';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return '날짜 형식 오류';
    }
    
    return DateFormat('yyyy년 MM월 dd일').format(dateTime);
  }

  // 금액 포맷팅 함수
  String _formatAmount(dynamic amount) {
    if (amount == null) return '0원';
    
    int amountInt = (amount as num).toInt();
    return NumberFormat('#,###원').format(amountInt);
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
                      // 목표 카드
                      _buildGoalCard(),
                      
                      const SizedBox(height: 20),
                      
                      // 플러스 버튼
                      _buildAddButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // 목표 카드 위젯
  Widget _buildGoalCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: _goalData != null
            ? _buildGoalContent()
            : _buildEmptyGoalContent(),
      ),
    );
  }

  // 목표 데이터가 있을 때의 내용
  Widget _buildGoalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 목표 제목
        Text(
          _goalData!['name'] ?? '목표명 없음',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 목표 금액
        Row(
          children: [
            const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF73AD13),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '목표 금액: ${_formatAmount(_goalData!['amount'])}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 은행 정보
        if (_bankName != null) ...[
          Row(
            children: [
              const Icon(
                Icons.account_balance,
                color: Color(0xFF73AD13),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '은행: $_bankName',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        
        // 마감일
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: Color(0xFF73AD13),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '마감일: ${_formatDate(_goalData!['deadline'])}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
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
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            // TODO: 목표 추가 화면으로 이동
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('목표 추가 기능 개발 중입니다')),
            );
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
