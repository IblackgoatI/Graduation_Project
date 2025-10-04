/// 목표 입력 화면
/// 4단계로 나누어 목표 정보를 입력받는 화면입니다.
library;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GoalAddScreen extends StatefulWidget {
  final User? user;

  const GoalAddScreen({
    super.key,
    this.user,
  });

  @override
  State<GoalAddScreen> createState() => _GoalAddScreenState();
}

class _GoalAddScreenState extends State<GoalAddScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  
  // 입력 데이터
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _goalAmountController = TextEditingController();
  final TextEditingController _monthlyAmountController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedAccountId;
  
  // 계좌 목록
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoadingAccounts = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _goalAmountController.dispose();
    _monthlyAmountController.dispose();
    super.dispose();
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

  // 다음 단계로 이동
  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    }
  }

  // 이전 단계로 이동
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  // 시작 날짜 선택
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10년 후까지
      locale: const Locale('ko', 'KR'),
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  // 종료 날짜 선택
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10년 후까지
      locale: const Locale('ko', 'KR'),
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // 목표 저장
  Future<void> _saveGoal() async {
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

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시작 날짜와 종료 날짜를 모두 선택해주세요.')),
      );
      return;
    }

    if (_monthlyAmountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('월 납입 금액을 입력해주세요.')),
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
        int monthlyAmount = int.tryParse(_monthlyAmountController.text.trim().replaceAll(',', '')) ?? 0;
        
        if (goalAmount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('올바른 목표 금액을 입력해주세요.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (monthlyAmount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('올바른 월 납입 금액을 입력해주세요.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Firestore에 목표 저장
        await FirebaseFirestore.instance.collection('goal').add({
          'userId': currentUser.uid,
          'name': _goalNameController.text.trim(),
          'amount': goalAmount,
          'monthlyAmount': monthlyAmount,
          'startDate': Timestamp.fromDate(_startDate!),
          'endDate': Timestamp.fromDate(_endDate!),
          'bank': _selectedAccountId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('목표가 성공적으로 저장되었습니다.')),
          );
          Navigator.pop(context, true); // 성공적으로 저장됨을 알림
        }
      }
    } catch (e) {
      debugPrint('목표 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목표 저장 중 오류가 발생했습니다.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF73AD13),
        title: Text(
          '목표 추가 (${_currentStep + 1}/5)',
          style: const TextStyle(
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
          : Column(
              children: [
                // 진행 표시기
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 5,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF73AD13)),
                  ),
                ),
                
                // 단계별 입력 폼
                Expanded(
                  child: _currentStep == 4 
                    ? _buildStepContent()  // 5단계는 패딩 없이
                    : _currentStep == 3
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildStepContent(),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildStepContent(),
                        ),
                ),
                
                // 하단 버튼
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousStep,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF73AD13)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              '이전',
                              style: TextStyle(
                                color: Color(0xFF73AD13),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentStep == 4 ? _saveGoal : _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF73AD13),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _currentStep == 4 ? '저장' : '다음',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // 단계별 입력 폼
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1(); // 목표명
      case 1:
        return _buildStep2(); // 목표 금액
      case 2:
        return _buildStep3(); // 목표 기간
      case 3:
        return _buildStep4(); // 계좌 선택 및 월 납입 금액
      case 4:
        return _buildStep5(); // 입력 내용 확인
      default:
        return _buildStep1();
    }
  }

  // 1단계: 목표명 입력
  Widget _buildStep1() {
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
            const Text(
              '목표명',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _goalNameController,
              decoration: const InputDecoration(
                hintText: '목표명을 입력해주세요',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF73AD13)),
                ),
              ),
              maxLength: 50,
            ),
          ],
        ),
      ),
    );
  }

  // 2단계: 목표 금액 입력
  Widget _buildStep2() {
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
            const Text(
              '목표 금액',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _goalAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '목표 금액을 입력해주세요',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF73AD13)),
                ),
                suffixText: '원',
              ),
              onChanged: (value) {
                // 실시간으로 천 단위 구분자 추가
                String formatted = _formatAmount(value);
                if (formatted != value) {
                  _goalAmountController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 3단계: 목표 기간 선택 (시작 날짜와 종료 날짜)
  Widget _buildStep3() {
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
            const Text(
              '목표 기간',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // 시작 날짜
            const Text(
              '시작 날짜',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectStartDate,
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
                      _startDate != null
                          ? DateFormat('yyyy년 MM월 dd일').format(_startDate!)
                          : '시작 날짜 선택',
                      style: TextStyle(
                        fontSize: 16,
                        color: _startDate != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 종료 날짜
            const Text(
              '종료 날짜',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectEndDate,
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
                      _endDate != null
                          ? DateFormat('yyyy년 MM월 dd일').format(_endDate!)
                          : '종료 날짜 선택',
                      style: TextStyle(
                        fontSize: 16,
                        color: _endDate != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4단계: 계좌 선택 및 월 납입 금액
  Widget _buildStep4() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              '계좌 선택 및 월 납입 금액 입력',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // 계좌 선택
            const Text(
              '계좌 선택',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingAccounts)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF73AD13),
                ),
              )
            else if (_accounts.isEmpty)
              const Center(
                child: Text(
                  '등록된 계좌가 없습니다.\n먼저 계좌를 등록해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: _accounts.length,
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  final isSelected = _selectedAccountId == account['id'];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? const Color(0xFF73AD13) : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance,
                        color: Color(0xFF73AD13),
                      ),
                      title: Text(
                        account['bank'],
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
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
                      },
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 24),
            
            // 월 납입 금액
            const Text(
              '월 납입 금액',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _monthlyAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '월 납입 금액을 입력해주세요',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF73AD13)),
                ),
                suffixText: '원',
              ),
              onChanged: (value) {
                // 실시간으로 천 단위 구분자 추가
                String formatted = _formatAmount(value);
                if (formatted != value) {
                  _monthlyAmountController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
            ),
            ],
          ),
        ),
      ),
    );
  }

  // 5단계: 입력 내용 확인
  Widget _buildStep5() {
    // 선택된 계좌 정보 가져오기
    Map<String, dynamic>? selectedAccount;
    if (_selectedAccountId != null) {
      try {
        selectedAccount = _accounts.firstWhere((account) => account['id'] == _selectedAccountId);
      } catch (e) {
        selectedAccount = null;
      }
    }

    return SizedBox(
      width: 360,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              '입력 내용 확인',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // 목표명
            _buildConfirmField(
              label: '목표명',
              value: _goalNameController.text.trim().isEmpty ? '입력되지 않음' : _goalNameController.text.trim(),
            ),
            
            const SizedBox(height: 16),
            
            // 목표 금액
            _buildConfirmField(
              label: '목표 금액',
              value: _goalAmountController.text.trim().isEmpty ? '입력되지 않음' : '${_goalAmountController.text.trim()}원',
            ),
            
            const SizedBox(height: 16),
            
            // 시작 날짜
            _buildConfirmField(
              label: '시작 날짜',
              value: _startDate != null ? DateFormat('yyyy년 MM월 dd일').format(_startDate!) : '선택되지 않음',
            ),
            
            const SizedBox(height: 16),
            
            // 종료 날짜
            _buildConfirmField(
              label: '종료 날짜',
              value: _endDate != null ? DateFormat('yyyy년 MM월 dd일').format(_endDate!) : '선택되지 않음',
            ),
            
            const SizedBox(height: 16),
            
            // 계좌 선택
            _buildConfirmField(
              label: '계좌 선택',
              value: selectedAccount != null ? selectedAccount['bank'] : '선택되지 않음',
            ),
            
            const SizedBox(height: 16),
            
            // 월 납입 금액
            _buildConfirmField(
              label: '월 납입 금액',
              value: _monthlyAmountController.text.trim().isEmpty ? '입력되지 않음' : '${_monthlyAmountController.text.trim()}원',
            ),
            ],
          ),
        ),
      ),
    );
  }

  // 확인 필드 위젯
  Widget _buildConfirmField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
  
}
