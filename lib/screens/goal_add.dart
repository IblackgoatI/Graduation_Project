/// 목표 입력 화면
/// 4단계로 나누어 목표 정보를 입력받는 화면입니다.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GoalPreset {
  final String? goalName;
  final int? goalAmount;
  final int? monthlyAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? targetAccountId;
  final String? withdrawalAccountId;
  final int? withdrawalDay;

  const GoalPreset({
    this.goalName,
    this.goalAmount,
    this.monthlyAmount,
    this.startDate,
    this.endDate,
    this.targetAccountId,
    this.withdrawalAccountId,
    this.withdrawalDay,
  });
}

class GoalAddScreen extends StatefulWidget {
  final User? user;
  final GoalPreset? preset;

  const GoalAddScreen({
    super.key,
    this.user,
    this.preset,
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
  final TextEditingController _withdrawalDateController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedAccountId;
  String? _selectedWithdrawalAccountId;
  
  // 계좌 목록
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    _applyPresetIfNeeded();
    _loadAccounts();
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _goalAmountController.dispose();
    _monthlyAmountController.dispose();
    _withdrawalDateController.dispose();
    super.dispose();
  }

  // 계좌 목록 로드
  Future<void> _loadAccounts() async {
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
        });
      }
    } catch (e) {
      debugPrint('계좌 목록 로드 오류: $e');
    }
  }

  void _applyPresetIfNeeded() {
    final GoalPreset? preset = widget.preset;
    if (preset == null) return;

    if ((preset.goalName ?? '').isNotEmpty) {
      _goalNameController.text = preset.goalName!;
    }
    if (preset.goalAmount != null && preset.goalAmount! > 0) {
      _goalAmountController.text =
          NumberFormat('#,###').format(preset.goalAmount!);
    }
    if (preset.monthlyAmount != null && preset.monthlyAmount! > 0) {
      _monthlyAmountController.text =
          NumberFormat('#,###').format(preset.monthlyAmount!);
    }
    if (preset.withdrawalDay != null && preset.withdrawalDay! > 0) {
      _withdrawalDateController.text = '${preset.withdrawalDay}';
    }

    _startDate = preset.startDate ?? _startDate;
    _endDate = preset.endDate ?? _endDate;
    _selectedAccountId = preset.targetAccountId ?? _selectedAccountId;
    _selectedWithdrawalAccountId =
        preset.withdrawalAccountId ?? _selectedWithdrawalAccountId;
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
        const SnackBar(content: Text('목표 계좌를 선택해주세요.')),
      );
      return;
    }

    if (_selectedWithdrawalAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출금 계좌를 선택해주세요.')),
      );
      return;
    }

    if (_withdrawalDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출금 날짜를 입력해주세요.')),
      );
      return;
    }

    int withdrawalDay = int.tryParse(_withdrawalDateController.text.trim()) ?? 0;
    if (withdrawalDay < 1 || withdrawalDay > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출금 날짜는 1일부터 31일 사이로 입력해주세요.')),
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

        // 목표 계좌의 현재 잔액 조회
        int initialBalance = 0;
        if (_selectedAccountId != null) {
          try {
            DocumentSnapshot assetDoc = await FirebaseFirestore.instance
                .collection('assets')
                .doc(_selectedAccountId)
                .get();
            
            if (assetDoc.exists) {
              Map<String, dynamic> assetData = assetDoc.data() as Map<String, dynamic>;
              initialBalance = (assetData['balance'] as num?)?.toInt() ?? 0;
            }
          } catch (e) {
            debugPrint('초기 잔액 조회 오류: $e');
          }
        }

        // Firestore에 목표 저장
        DocumentReference goalDocRef = await FirebaseFirestore.instance.collection('goal').add({
          'userId': currentUser.uid,
          'name': _goalNameController.text.trim(),
          'amount': goalAmount,
          'monthlyAmount': monthlyAmount,
          'startDate': Timestamp.fromDate(_startDate!),
          'endDate': Timestamp.fromDate(_endDate!),
          'bank': _selectedAccountId,
          'withdrawalAccount': _selectedWithdrawalAccountId,
          'withdrawalDay': withdrawalDay,
          'initialBalance': initialBalance, // 목표 설정 시점의 잔액 저장
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 자동이체 스케줄 등록
        await _scheduleAutoTransfer(goalDocRef.id, currentUser.uid, monthlyAmount, withdrawalDay);

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

  // 자동이체 스케줄 등록 함수
  Future<void> _scheduleAutoTransfer(String goalId, String userId, int amount, int withdrawalDay) async {
    try {
      DateTime nextExecutionDate = _calculateNextExecutionDate(withdrawalDay);
      
      await FirebaseFirestore.instance.collection('auto_transfer_schedules').add({
        'goalId': goalId,
        'userId': userId,
        'fromAccountId': _selectedWithdrawalAccountId, // 출금 계좌
        'toAccountId': _selectedAccountId, // 목표 계좌
        'amount': amount,
        'withdrawalDay': withdrawalDay,
        'nextExecutionDate': Timestamp.fromDate(nextExecutionDate),
        'goalName': _goalNameController.text.trim(),
        'type': 'goal',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('자동이체 스케줄 등록 완료: $goalId');
    } catch (e) {
      debugPrint('자동이체 스케줄 등록 오류: $e');
    }
  }

  // 다음 실행 날짜 계산 (출금날짜 기준으로 다음 달 날짜 계산)
  DateTime _calculateNextExecutionDate(int withdrawalDay) {
    DateTime now = DateTime.now();
    DateTime nextDate;
    
    try {
      // 출금 날짜가 현재 날짜보다 이전이면 다음 달로 설정
      if (DateTime(now.year, now.month, withdrawalDay).isBefore(now)) {
        // 다음 달로 이동
        DateTime nextMonth = DateTime(now.year, now.month + 1, 1);
        // 해당 월의 마지막 날짜 확인
        DateTime lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0);
        int actualDay = withdrawalDay > lastDayOfNextMonth.day ? lastDayOfNextMonth.day : withdrawalDay;
        nextDate = DateTime(nextMonth.year, nextMonth.month, actualDay);
      } else {
        // 이번 달 해당 날짜 사용
        DateTime thisMonthLastDay = DateTime(now.year, now.month + 1, 0);
        int actualDay = withdrawalDay > thisMonthLastDay.day ? thisMonthLastDay.day : withdrawalDay;
        nextDate = DateTime(now.year, now.month, actualDay);
      }
    } catch (e) {
      debugPrint('날짜 계산 오류: $e');
      // 에러 발생 시 기본값으로 현재 날짜 다음 달 1일
      nextDate = DateTime(now.year, now.month + 1, 1);
    }
    
    return nextDate;
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
              
              // 목표 계좌 선택
              InkWell(
                onTap: () async {
                  final result = await _showSelectAccountDialog(_selectedAccountId, '목표 계좌');
                  if (result != null) {
                    setState(() {
                      _selectedAccountId = result['id'];
                    });
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '목표 계좌',
                      style: TextStyle(fontSize: 16),
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _getAccountDisplayName(_selectedAccountId),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedAccountId != null)
                              Text(
                                '잔액 ${_getAccountBalance(_selectedAccountId)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 출금 계좌 선택
              InkWell(
                onTap: () async {
                  final result = await _showSelectAccountDialog(_selectedWithdrawalAccountId, '출금 계좌');
                  if (result != null) {
                    setState(() {
                      _selectedWithdrawalAccountId = result['id'];
                    });
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '출금 계좌',
                      style: TextStyle(fontSize: 16),
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _getAccountDisplayName(_selectedWithdrawalAccountId),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedWithdrawalAccountId != null)
                              Text(
                                '잔액 ${_getAccountBalance(_selectedWithdrawalAccountId)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 출금 날짜 선택
              const Text(
                '출금 날짜',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _withdrawalDateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '1-31 사이의 날짜를 입력해주세요',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF73AD13)),
                  ),
                  suffixText: '일',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: (value) {
                  // 입력값 검증은 실시간으로 처리하지 않고 저장 시에만 처리
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
    Map<String, dynamic>? selectedWithdrawalAccount;
    
    if (_selectedAccountId != null) {
      try {
        selectedAccount = _accounts.firstWhere((account) => account['id'] == _selectedAccountId);
      } catch (e) {
        selectedAccount = null;
      }
    }
    
    if (_selectedWithdrawalAccountId != null) {
      try {
        selectedWithdrawalAccount = _accounts.firstWhere((account) => account['id'] == _selectedWithdrawalAccountId);
      } catch (e) {
        selectedWithdrawalAccount = null;
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
          child: SingleChildScrollView(
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
              
              // 목표 계좌 선택
              _buildConfirmField(
                label: '목표 계좌',
                value: selectedAccount != null ? selectedAccount['bank'] : '선택되지 않음',
              ),
              
              const SizedBox(height: 16),
              
              // 출금 계좌 선택
              _buildConfirmField(
                label: '출금 계좌',
                value: selectedWithdrawalAccount != null ? selectedWithdrawalAccount['bank'] : '선택되지 않음',
              ),
              
              const SizedBox(height: 16),
              
              // 출금 날짜
              _buildConfirmField(
                label: '출금 날짜',
                value: _withdrawalDateController.text.trim().isEmpty ? '입력되지 않음' : '${_withdrawalDateController.text.trim()}일',
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
      ),
    );
  }

  // 계좌 선택 다이얼로그 표시
  Future<Map<String, dynamic>?> _showSelectAccountDialog(String? initialSelectedAccountId, String title) async {
    Map<String, dynamic>? tempSelectedAccount;
    
    if (initialSelectedAccountId != null) {
      try {
        tempSelectedAccount = _accounts.firstWhere((acc) => acc['id'] == initialSelectedAccountId);
      } catch (e) {
        tempSelectedAccount = null;
      }
    }

    return await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$title를 설정해주세요.',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '입출금',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const Divider(),

                    // 계좌 목록
                    Expanded(
                      child: _accounts.isEmpty
                          ? const Center(child: Text('등록된 계좌가 없습니다.'))
                          : ListView.builder(
                              itemCount: _accounts.length,
                              itemBuilder: (context, index) {
                                final account = _accounts[index];

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _buildAccountIcon(account),
                                  title: Text(
                                    account['bank'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text('${NumberFormat('#,###').format(account['balance'])}원'),
                                  trailing: Radio<String>(
                                    value: account['id'],
                                    groupValue: tempSelectedAccount?['id'],
                                    onChanged: (String? value) {
                                      setDialogState(() {
                                        tempSelectedAccount = account;
                                      });
                                    },
                                    activeColor: const Color(0xFF73AD13),
                                  ),
                                  onTap: () {
                                    setDialogState(() {
                                      tempSelectedAccount = account;
                                    });
                                  },
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 10),

                    // 확인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, tempSelectedAccount);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF73AD13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 계좌 아이콘 위젯
  Widget _buildAccountIcon(Map<String, dynamic> account) {
    String bankName = account['bank'];
    Color iconColor = Color(account['iconColor'] ?? 0xFF73AD13);
    String iconLetter = bankName.isNotEmpty ? bankName[0] : '?';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withAlpha((0.2 * 255).round()),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          iconLetter,
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // 계좌 표시 이름 가져오기
  String _getAccountDisplayName(String? accountId) {
    if (accountId == null) return '계좌 선택';
    
    try {
      final account = _accounts.firstWhere((acc) => acc['id'] == accountId);
      return account['bank'];
    } catch (e) {
      return '계좌 선택';
    }
  }

  // 계좌 잔액 가져오기
  String _getAccountBalance(String? accountId) {
    if (accountId == null) return '';
    
    try {
      final account = _accounts.firstWhere((acc) => acc['id'] == accountId);
      return '${NumberFormat('#,###').format(account['balance'])}원';
    } catch (e) {
      return '';
    }
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
