/// 목표 수정 화면
/// 기존 목표 정보를 수정하는 화면입니다.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _initializeData();
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

  // 초기 데이터 설정
  void _initializeData() {
    _goalNameController.text = widget.goalData['name'] ?? '';
    
    int goalAmount = (widget.goalData['amount'] as num?)?.toInt() ?? 0;
    _goalAmountController.text = NumberFormat('#,###').format(goalAmount);
    
    // 시작 날짜와 종료 날짜 설정
    if (widget.goalData['startDate'] != null) {
      if (widget.goalData['startDate'] is Timestamp) {
        _startDate = (widget.goalData['startDate'] as Timestamp).toDate();
      } else if (widget.goalData['startDate'] is DateTime) {
        _startDate = widget.goalData['startDate'] as DateTime;
      }
    }
    
    if (widget.goalData['endDate'] != null) {
      if (widget.goalData['endDate'] is Timestamp) {
        _endDate = (widget.goalData['endDate'] as Timestamp).toDate();
      } else if (widget.goalData['endDate'] is DateTime) {
        _endDate = widget.goalData['endDate'] as DateTime;
      }
    }
    
    // 기존 deadline 필드가 있는 경우 종료 날짜로 설정 (하위 호환성)
    if (_endDate == null && widget.goalData['deadline'] != null) {
      if (widget.goalData['deadline'] is Timestamp) {
        _endDate = (widget.goalData['deadline'] as Timestamp).toDate();
      } else if (widget.goalData['deadline'] is DateTime) {
        _endDate = widget.goalData['deadline'] as DateTime;
      }
    }
    
    // bank 설정
    _selectedAccountId = widget.goalData['bank'];
    
    // 월 납입 금액 설정
    int monthlyAmount = (widget.goalData['monthlyAmount'] as num?)?.toInt() ?? 0;
    if (monthlyAmount > 0) {
      _monthlyAmountController.text = NumberFormat('#,###').format(monthlyAmount);
    }
    
    // 출금 계좌 설정
    _selectedWithdrawalAccountId = widget.goalData['withdrawalAccount'];
    
    // 출금 날짜 설정
    int withdrawalDay = widget.goalData['withdrawalDay'] ?? 0;
    if (withdrawalDay > 0) {
      _withdrawalDateController.text = withdrawalDay.toString();
    }
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

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시작 날짜와 종료 날짜를 모두 선택해주세요.')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 계좌를 선택해주세요.')),
      );
      return;
    }

    if (_monthlyAmountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('월 납입 금액을 입력해주세요.')),
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
        // 목표 금액과 월 납입 금액을 숫자로 변환
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

        // goal 컬렉션에서 해당 목표 문서 찾기
        QuerySnapshot goalQuery = await FirebaseFirestore.instance
            .collection('goal')
            .where('userId', isEqualTo: currentUser.uid)
            .where('name', isEqualTo: widget.goalData['name'])
            .where('amount', isEqualTo: widget.goalData['amount'])
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
            'monthlyAmount': monthlyAmount,
            'startDate': Timestamp.fromDate(_startDate!),
            'endDate': Timestamp.fromDate(_endDate!),
            'bank': _selectedAccountId,
            'withdrawalAccount': _selectedWithdrawalAccountId,
            'withdrawalDay': withdrawalDay,
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
            
            // 목표 계좌 선택
            _buildAccountField('목표 계좌', _selectedAccountId, (accountId) {
              setState(() {
                _selectedAccountId = accountId;
              });
            }),
            
            const SizedBox(height: 24),
            
            // 월 납입 금액
            _buildInputField(
              label: '월 납입 금액',
              controller: _monthlyAmountController,
              hintText: '월 납입 금액을 입력해주세요',
              isAmount: true,
            ),
            
            const SizedBox(height: 24),
            
            // 출금 계좌 선택
            _buildAccountField('출금 계좌', _selectedWithdrawalAccountId, (accountId) {
              setState(() {
                _selectedWithdrawalAccountId = accountId;
              });
            }),
            
            const SizedBox(height: 24),
            
            // 출금 날짜
            _buildWithdrawalDateField(),
            
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
          style: const TextStyle(
            fontSize: 14,
          ),
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

  // 날짜 선택 필드 (시작 날짜와 종료 날짜)
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
        
        // 시작 날짜
        const Text(
          '시작 날짜',
          style: TextStyle(
            fontSize: 14,
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
                    fontSize: 14,
                    color: _startDate != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 종료 날짜
        const Text(
          '종료 날짜',
          style: TextStyle(
            fontSize: 14,
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
                    fontSize: 14,
                    color: _endDate != null ? Colors.black87 : Colors.grey,
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
  Widget _buildAccountField(String label, String? selectedAccountId, Function(String) onAccountSelected) {
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
        InkWell(
          onTap: () async {
            final result = await _showSelectAccountDialog(selectedAccountId, label);
            if (result != null) {
              onAccountSelected(result['id']);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '',
                style: TextStyle(fontSize: 16),
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getAccountDisplayName(selectedAccountId),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selectedAccountId != null)
                        Text(
                          '잔액 ${_getAccountBalance(selectedAccountId)}',
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
      ],
    );
  }

  // 출금 날짜 필드
  Widget _buildWithdrawalDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '출금 날짜',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
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
        ),
      ],
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
}
