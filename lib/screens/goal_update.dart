/// 목표 수정 화면
/// 기존 목표 정보를 수정하는 화면입니다.
library;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GoalUpdateScreen extends StatefulWidget {
  final User? user;
  final Map<String, dynamic> goalData;

  const GoalUpdateScreen({
    super.key,
    this.user,
    required this.goalData,
  });

  @override
  State<GoalUpdateScreen> createState() => _GoalUpdateScreenState();
}

class _GoalUpdateScreenState extends State<GoalUpdateScreen> {
  bool _isLoading = false;
  
  // 입력 데이터
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _goalAmountController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedAccountId;
  
  // 계좌 목록
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoadingAccounts = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadAccounts();
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }

  // 초기 데이터 설정
  void _initializeData() {
    _goalNameController.text = widget.goalData['name'] ?? '';
    
    int goalAmount = (widget.goalData['amount'] as num?)?.toInt() ?? 0;
    _goalAmountController.text = NumberFormat('#,###').format(goalAmount);
    
    // deadline 설정
    if (widget.goalData['deadline'] != null) {
      if (widget.goalData['deadline'] is Timestamp) {
        _selectedDate = (widget.goalData['deadline'] as Timestamp).toDate();
      } else if (widget.goalData['deadline'] is DateTime) {
        _selectedDate = widget.goalData['deadline'] as DateTime;
      }
    }
    
    // bank 설정
    _selectedAccountId = widget.goalData['bank'];
  }

  // 계좌 목록 로드
  Future<void> _loadAccounts() async {
    setState(() {
      _isLoadingAccounts = true;
    });

    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('assets')
            .where('userId', isEqualTo: currentUser.uid)
            .get();

        List<Map<String, dynamic>> accounts = [];
        for (var doc in querySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          accounts.add({
            'id': doc.id,
            'bank': data['bank'],
            'account': data['account'],
            'balance': data['balance'],
          });
        }

        setState(() {
          _accounts = accounts;
          _isLoadingAccounts = false;
        });
      }
    } catch (e) {
      debugPrint('계좌 목록 로드 오류: $e');
      setState(() {
        _isLoadingAccounts = false;
      });
    }
  }

  // 날짜 선택
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10년 후까지
      locale: const Locale('ko', 'KR'),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 목표 수정 저장
  Future<void> _updateGoal() async {
    // 입력 검증
    if (_goalNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표명을 입력해주세요.')),
      );
      return;
    }

    if (_goalAmountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 금액을 입력해주세요.')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 기간을 선택해주세요.')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계좌를 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // 목표 금액을 숫자로 변환
        int goalAmount = int.tryParse(_goalAmountController.text.trim().replaceAll(',', '')) ?? 0;
        
        if (goalAmount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('올바른 목표 금액을 입력해주세요.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // goal 컬렉션에서 해당 목표 문서 찾기
        QuerySnapshot goalQuery = await FirebaseFirestore.instance
            .collection('goal')
            .where('userId', isEqualTo: currentUser.uid)
            .where('name', isEqualTo: widget.goalData['name'])
            .where('amount', isEqualTo: widget.goalData['amount'])
            .where('deadline', isEqualTo: widget.goalData['deadline'])
            .where('bank', isEqualTo: widget.goalData['bank'])
            .get();

        if (goalQuery.docs.isNotEmpty) {
          // 목표 업데이트
          await FirebaseFirestore.instance
              .collection('goal')
              .doc(goalQuery.docs.first.id)
              .update({
            'name': _goalNameController.text.trim(),
            'amount': goalAmount,
            'deadline': Timestamp.fromDate(_selectedDate!),
            'bank': _selectedAccountId,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('목표가 성공적으로 수정되었습니다.')),
            );
            Navigator.pop(context, true); // 성공적으로 수정됨을 알림
          }
        }
      }
    } catch (e) {
      debugPrint('목표 수정 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목표 수정 중 오류가 발생했습니다.')),
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

  // 금액 포맷팅
  String _formatAmount(String value) {
    if (value.isEmpty) return '';
    
    // 숫자만 추출
    String numbersOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numbersOnly.isEmpty) return '';
    
    // 천 단위 구분자 추가
    int amount = int.parse(numbersOnly);
    return NumberFormat('#,###').format(amount);
  }

  // 선택된 계좌 정보 가져오기
  Map<String, dynamic>? _getSelectedAccount() {
    if (_selectedAccountId == null) return null;
    
    try {
      return _accounts.firstWhere((account) => account['id'] == _selectedAccountId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF73AD13),
        title: const Text(
          '목표 수정',
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 목표 수정 카드
                    _buildUpdateCard(),
                  ],
                ),
              ),
            ),
    );
  }

  // 목표 수정 카드
  Widget _buildUpdateCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 목표명
            _buildInputField(
              label: '목표명',
              controller: _goalNameController,
              hintText: '목표명을 입력해주세요',
            ),
            
            const SizedBox(height: 24),
            
            // 목표 금액
            _buildInputField(
              label: '목표 금액',
              controller: _goalAmountController,
              hintText: '목표 금액을 입력해주세요',
              isAmount: true,
            ),
            
            const SizedBox(height: 24),
            
            // 목표 기간
            _buildDateField(),
            
            const SizedBox(height: 24),
            
            // 계좌 선택
            _buildAccountField(),
            
            const SizedBox(height: 32),
            
            // 저장하기 버튼
            ElevatedButton(
              onPressed: _updateGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF73AD13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text(
                '저장하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 입력 필드 위젯
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isAmount = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isAmount ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF73AD13)),
            ),
            suffixText: isAmount ? '원' : null,
          ),
          onChanged: isAmount ? (value) {
            // 실시간으로 천 단위 구분자 추가
            String formatted = _formatAmount(value);
            if (formatted != value) {
              controller.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          } : null,
        ),
      ],
    );
  }

  // 날짜 선택 필드
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '목표 기간',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF73AD13),
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? DateFormat('yyyy년 MM월 dd일').format(_selectedDate!)
                      : '날짜 선택',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDate != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 계좌 선택 필드
  Widget _buildAccountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '계좌 선택',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showAccountSelectionDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance,
                  color: Color(0xFF73AD13),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getSelectedAccount()?['bank'] ?? '계좌 선택',
                    style: TextStyle(
                      fontSize: 16,
                      color: _getSelectedAccount() != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 계좌 선택 다이얼로그
  void _showAccountSelectionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '계좌를 선택해주세요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoadingAccounts)
                const Center(child: CircularProgressIndicator())
              else if (_accounts.isEmpty)
                const Center(
                  child: Text(
                    '등록된 계좌가 없습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    final account = _accounts[index];
                    final isSelected = _selectedAccountId == account['id'];
                    
                    return ListTile(
                      leading: const Icon(
                        Icons.account_balance,
                        color: Color(0xFF73AD13),
                      ),
                      title: Text(
                        account['bank'],
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text('${NumberFormat('#,###').format(account['balance'])}원'),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF73AD13),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedAccountId = account['id'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
