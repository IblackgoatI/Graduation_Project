import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssetConnectManagementScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? accounts;
  final String? accountType;

  const AssetConnectManagementScreen({
    super.key,
    this.accounts,
    this.accountType,
  });

  @override
  State<AssetConnectManagementScreen> createState() => _AssetConnectManagementScreenState();
}

class _AssetConnectManagementScreenState extends State<AssetConnectManagementScreen> {
  List<Map<String, dynamic>> _userAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAccounts();
  }

  // 현재 유저의 자산 계좌 목록 로드
  Future<void> _loadUserAccounts() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Firestore에서 사용자의 자산 정보 가져오기
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
            'assetType': data['assetType'] ?? 'savings',
            'iconColor': data['iconColor'] ?? 0xFF73AD13,
          });
        }

        setState(() {
          _userAccounts = accounts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('자산 정보 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 계좌 삭제 함수
  Future<void> _deleteAccount(String accountId) async {
    try {
      await FirebaseFirestore.instance
          .collection('assets')
          .doc(accountId)
          .delete();

      // 로컬 상태에서도 제거
      setState(() {
        _userAccounts.removeWhere((account) => account['id'] == accountId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계좌가 해지되었습니다')),
        );
      }
    } catch (e) {
      debugPrint('계좌 해지 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계좌 해지 중 오류가 발생했습니다')),
        );
      }
    }
  }

  // 계좌 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog(String accountId, String bankName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('계좌 해지'),
          content: Text('$bankName 계좌를 해지하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                '해지',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount(accountId);
              },
            ),
          ],
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
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Text(
          iconLetter,
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // 계좌번호 포맷팅
  String _formatAccountNumber(String accountNumber) {
    String numbers = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length > 8) {
      return '${numbers.substring(0, 4)}****${numbers.substring(numbers.length - 4)}';
    } else if (numbers.length > 4) {
      return '${numbers.substring(0, 2)}**${numbers.substring(numbers.length - 2)}';
    } else {
      return numbers;
    }
  }

  // 숫자 포맷 (천 단위 콤마)
  String _numberFormat(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('계좌 해지'),
        backgroundColor: const Color(0xFF73AD13),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF73AD13)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 입출금 텍스트
                  const Text(
                    '입출금',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 8.0),
                  
                  // 구분선
                  const Divider(
                    color: Colors.grey,
                    thickness: 0.5,
                  ),
                  
                  const SizedBox(height: 16.0),
                  
                  // 계좌 목록
                  Expanded(
                    child: _userAccounts.isEmpty
                        ? const Center(
                            child: Text(
                              '등록된 계좌가 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _userAccounts.length,
                            itemBuilder: (context, index) {
                              final account = _userAccounts[index];
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16.0),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // 계좌 아이콘
                                    _buildAccountIcon(account),
                                    
                                    const SizedBox(width: 16.0),
                                    
                                    // 계좌 정보
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            account['bank'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            _formatAccountNumber(account['account']),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            '${_numberFormat(account['balance'])}원',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // 휴지통 아이콘
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        _showDeleteConfirmDialog(
                                          account['id'],
                                          account['bank'],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

