import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' show min;
import 'transaction_provider.dart';
import 'asset.dart'; // 자산 화면 import (계좌 연결 화면)
import 'asset.dart' as asset_screen; // _showLocalNotification 함수를 사용하기 위해 임포트
import 'fixed_expense_list_screen.dart';

class AssetDetailScreen extends StatefulWidget {
  final User? user;
  final int initialTabIndex; // 추가된 파라미터

  const AssetDetailScreen({
    super.key,
    this.user,
    this.initialTabIndex = 0, // 기본값 0으로 설정
  });

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  int _totalAssets = 0;
  int _savingsTotal = 0;
  int _depositTotal = 0;
  int _stocksTotal = 0;
  int _cashTotal = 0;
  List<Map<String, dynamic>> _assetAccounts = [];
  
  // 저축 목표 관련 변수 추가
  int _savingsGoalAmount = 0; // 저축 목표 금액
  Map<String, dynamic>? _selectedSavingAccount; // 선택된 저축 계좌
  bool _hasSavingGoal = false; // 저축 목표 존재 여부
  
  // 예산 금액과 지출 금액을 저장할 변수
  double _budgetAmount = 0.0; // 예산 금액
  double _expensesAmount = 0.0; // 지출 금액
  double _incomeAmount = 0.0; // 수입 금액 변수 추가
  bool _hasBudget = false;
  int _budgetPercentage = 0; // 예산이 수입에서 차지하는 비율

  // 1. 상태 변수 추가
  int _finalGoalAmount = 0; // Firestore의 goalAmount와 동기화될 변수

  // 알림 상태 추적 변수
  bool _notified50percent = false;
  bool _notified90percent = false;
  bool _notified100percent = false;

  // 고정 지출 관련 상태 변수
  List<Map<String, dynamic>> _fixedExpensesList = [];
  double _totalFixedExpenseAmount = 0.0;
  bool _isLoadingFixedExpenses = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 초기 탭 인덱스 설정
    _tabController.animateTo(widget.initialTabIndex);
    // 비동기 데이터 로드를 위한 별도 함수 호출
    _loadInitialData();
  }

  // 초기 데이터 로드를 위한 비동기 함수
  Future<void> _loadInitialData() async {
    // 자산 데이터 먼저 로드하고 기다림
    await _loadAssetData();
    // 예산 데이터 로드
    await _loadBudgetData();
    // 자산 데이터 로드가 완료된 후 저축 목표 데이터 로드
    await _loadSavingGoalData();
    // 고정 지출 데이터 로드
    await _loadFixedExpenseData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 자산 데이터 로드
  Future<void> _loadAssetData() async {
    // setState(() { // initState에서 호출 시 불필요할 수 있음
    //   _isLoading = true;
    // });

    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Firestore에서 사용자의 자산 정보 가져오기
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('assets')
            .where('userId', isEqualTo: currentUser.uid)
            .get();

        List<Map<String, dynamic>> accounts = [];
        int totalAssets = 0;
        int savingsTotal = 0;
        int depositTotal = 0;
        int stocksTotal = 0;
        int cashTotal = 0;

        for (var doc in querySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String assetType = data['assetType'] ?? 'savings'; // 기본값은 저축
          int balance = (data['balance'] as num).toInt();

          accounts.add({
            'id': doc.id,
            'bank': data['bank'],
            'account': data['account'],
            'balance': balance,
            'assetType': assetType,
            'iconColor': data['iconColor'] ?? 0xFF73AD13,
          });

          // 총 자산 계산
          totalAssets += balance;

          // 자산 유형별 합계 계산
          switch (assetType) {
            case 'savings':
              savingsTotal += balance;
              break;
            case 'deposit':
              depositTotal += balance;
              break;
            case 'stocks':
              stocksTotal += balance;
              break;
            case 'cash':
              cashTotal += balance;
              break;
          }
        }

        // _assetAccounts 업데이트는 setState 밖에서 수행 가능 (initState 단계)
        _assetAccounts = accounts;
        _totalAssets = totalAssets;
        _savingsTotal = savingsTotal;
        _depositTotal = depositTotal;
        _stocksTotal = stocksTotal;
        _cashTotal = cashTotal;

        // 모든 데이터 로드가 완료된 후 isLoading 상태 변경
        // if (mounted) { // initState에서는 mounted 체크 불필요
        //   setState(() {
        //     _isLoading = false;
        //   });
        // }
      } else {
        // if (mounted) {
        //   setState(() {
        //     _isLoading = false;
        //   });
        // }
      }
    } catch (e) {
      debugPrint('자산 정보 로드 오류: $e');
      // if (mounted) {
      //   setState(() {
      //     _isLoading = false;
      //   });
      // }
    } finally {
      // 모든 로직 완료 후 isLoading 상태 변경 (선택적)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 예산 데이터 로드
Future<void> _loadBudgetData() async {
  try {
    User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // 예산 문서 있는지 확인
      QuerySnapshot budgetQuery = await FirebaseFirestore.instance
          .collection('budget')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      double budgetAmount = 0.0;
      bool hasBudget = false;

      // 목표금액 가져오기 (Amount 1)
      if (budgetQuery.docs.isNotEmpty) {
        Map<String, dynamic> budgetData = budgetQuery.docs.first.data() as Map<String, dynamic>;
        budgetAmount = (budgetData['goalcost'] as num).toDouble();
        hasBudget = true;
      }

      // 이번 달 지출 (Amount 2)
      double expensesAmount = 0.0;
      
      // 이번달 가져오기
      DateTime now = DateTime.now();
      DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
      DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // 이번 달 지출 가져오는 쿼리문
      QuerySnapshot expensesQuery = await FirebaseFirestore.instance
          .collection('ledger')
          .where('userId', isEqualTo: currentUser.uid)
          .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
          .where('date', isLessThanOrEqualTo: lastDayOfMonth)
          .where('type', isEqualTo: '지출') // 지출만 필터링
          .get();

      // 지출 합계 계산
      for (var doc in expensesQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        expensesAmount += (data['amount'] as num).toDouble();
      }
      
      // 이번 달 수입 가져오기
      double incomeAmount = 0.0;
      
      // 수입 쿼리문 (같은 달의 수입 데이터)
      QuerySnapshot incomeQuery = await FirebaseFirestore.instance
          .collection('ledger')
          .where('userId', isEqualTo: currentUser.uid)
          .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
          .where('date', isLessThanOrEqualTo: lastDayOfMonth)
          .where('type', isEqualTo: '수입') // 수입만 필터링
          .get();
      
      // 수입 합계 계산
      for (var doc in incomeQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        incomeAmount += (data['amount'] as num).toDouble();
      }
      
      // 예산의 수입 대비 비율 계산
      int budgetPercentage = 0;
      if (incomeAmount > 0) {
        budgetPercentage = ((budgetAmount / incomeAmount) * 100).round();
      }

      if (mounted) {
        setState(() {
          _budgetAmount = budgetAmount;
          _expensesAmount = expensesAmount;
          _incomeAmount = incomeAmount;
          _hasBudget = hasBudget;
          _budgetPercentage = budgetPercentage;
        });
      }
    }
  } catch (e) {
    debugPrint('예산 정보 로드 오류: $e');
  }
}

  //  Firestore에 저장
  Future<void> _saveBudget(double amount) async {
    // 컨텍스트를 미리 저장
    final BuildContext currentContext = context;
    
    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // 예산 문서 있는지 확인
        QuerySnapshot budgetQuery = await FirebaseFirestore.instance
            .collection('budget')
            .where('userId', isEqualTo: currentUser.uid)
            .get();
            
        if (budgetQuery.docs.isEmpty) {
          // 예산 문서가 없으면 새로 생성
          await FirebaseFirestore.instance.collection('budget').add({
            'userId': currentUser.uid,
            'goalcost': amount,
            'createdAt': DateTime.now(),
          });
        } else {
          // 예산 문서가 있으면 새로 업데이트
          String docId = budgetQuery.docs.first.id;
          await FirebaseFirestore.instance.collection('budget').doc(docId).update({
            'goalcost': amount,
            'updatedAt': DateTime.now(),
          });
        }
        
        // 예산 저장 후 데이터 다시 로드
        await _loadBudgetData();
      }
    } catch (e) {
      debugPrint('예산 저장 오류: $e'); // 예산 저장 오류
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('예산 정보를 저장하는 중 오류가 발생했습니다.'))
        );
      }
    }
  }

  // 저축 목표 데이터 로드 함수 추가
  Future<void> _loadSavingGoalData() async {
    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        QuerySnapshot savingQuery = await FirebaseFirestore.instance
            .collection('saving')
            .where('userId', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        if (savingQuery.docs.isNotEmpty) {
          Map<String, dynamic> savingData = savingQuery.docs.first.data() as Map<String, dynamic>;
          String? selectedAccountId = savingData['selectedAccountId'];
          Map<String, dynamic>? selectedAccount;

          // Firestore에서 monthlyAmount와 goalAmount 읽기
          int monthlyAmountFromDB = (savingData['monthlyAmount'] as num?)?.toInt() ?? 0;
          int goalAmountFromDB = (savingData['goalAmount'] as num?)?.toInt() ?? 0;

          // 선택된 계좌 정보 찾기 (_assetAccounts가 로드된 후 실행됨)
          if (selectedAccountId != null && _assetAccounts.isNotEmpty) { // _assetAccounts 비어있는지 확인
            try {
              selectedAccount = _assetAccounts.firstWhere(
                (account) => account['id'] == selectedAccountId,
              );
            } catch (e) {
              debugPrint('선택된 저축 계좌를 찾을 수 없습니다 (ID: $selectedAccountId): $e');
              selectedAccount = null;
            }
          } else if (selectedAccountId != null && _assetAccounts.isEmpty) {
             debugPrint('저축 목표 로드 시 자산 정보(_assetAccounts)가 아직 로드되지 않았습니다.');
             selectedAccount = null;
          }

          // 알림 상태 플래그는 Firestore에서 로드하거나, 여기서는 초기화하지 않고 _saveSavingGoal에서 관리
          // bool notified50 = savingData['notified50percent'] ?? false;
          // bool notified90 = savingData['notified90percent'] ?? false;
          // bool notified100 = savingData['notified100percent'] ?? false;

          if (mounted) {
            setState(() {
              _savingsGoalAmount = monthlyAmountFromDB;
              _finalGoalAmount = goalAmountFromDB;
              _selectedSavingAccount = selectedAccount;
              _hasSavingGoal = true;
              // _notified50percent = notified50; // Firestore에서 로드하는 경우
              // _notified90percent = notified90;
              // _notified100percent = notified100;
            });
          }

          // 달성률 계산 및 알림 (데이터 로드 후 실행)
          if (_selectedSavingAccount != null && _finalGoalAmount > 0) {
            int currentBalance = (_selectedSavingAccount!['balance'] as num).toInt();
            double achievementRate = currentBalance / _finalGoalAmount;

            if (achievementRate >= 1.0 && !_notified100percent) {
              await asset_screen.showLocalNotification(
                '저축 목표 달성!',
                '축하합니다! 저축 목표의 100%를 달성했습니다!',
              );
              if (mounted) setState(() { _notified100percent = true; });
              // Firestore에 알림 상태 저장 로직 추가 가능
              // await FirebaseFirestore.instance.collection('saving').doc(savingQuery.docs.first.id).update({'notified100percent': true});
            } else if (achievementRate >= 0.9 && !_notified90percent) {
              await asset_screen.showLocalNotification(
                '저축 목표 90% 달성!',
                '저축 목표의 90%를 달성했습니다! 조금만 더 힘내세요!',
              );
              if (mounted) setState(() { _notified90percent = true; });
              // await FirebaseFirestore.instance.collection('saving').doc(savingQuery.docs.first.id).update({'notified90percent': true});
            } else if (achievementRate >= 0.5 && !_notified50percent) {
              await asset_screen.showLocalNotification(
                '저축 목표 50% 달성!',
                '저축 목표의 50%를 달성했습니다!',
              );
              if (mounted) setState(() { _notified50percent = true; });
              // await FirebaseFirestore.instance.collection('saving').doc(savingQuery.docs.first.id).update({'notified50percent': true});
            }
          }

        } else {
          if (mounted) {
            setState(() {
              _savingsGoalAmount = 0;
              _finalGoalAmount = 0;
              _selectedSavingAccount = null;
              _hasSavingGoal = false;
              _notified50percent = false; // 목표가 없으면 알림 상태도 초기화
              _notified90percent = false;
              _notified100percent = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('저축 목표 정보 로드 오류: $e');
      if (mounted) {
        setState(() {
          _savingsGoalAmount = 0;
          _finalGoalAmount = 0;
          _selectedSavingAccount = null;
          _hasSavingGoal = false;
          _notified50percent = false;
          _notified90percent = false;
          _notified100percent = false;
        });
      }
    }
  }

  // 저축 목표 저장 함수 추가
  Future<void> _saveSavingGoal() async {
    User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser; // currentUser 먼저 가져오기
    if (currentUser == null) {
       debugPrint('저축 목표 저장 오류: 사용자가 로그인되지 않았습니다.');
       if (mounted) { // mounted 확인 후 context 사용
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('로그인이 필요합니다.')),
         );
       }
       return;
    }

    try {
      QuerySnapshot savingQuery = await FirebaseFirestore.instance
          .collection('saving')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      String? selectedAccountId = _selectedSavingAccount?['id'];

      // 목표 금액이 변경될 수 있으므로, 알림 상태 플래그를 초기화합니다.
      // 단, 현재 잔액이 새 목표 금액에 대해 이미 특정 %를 넘었는지 여부에 따라
      // 선택적으로 리셋하는 더 정교한 로직을 고려할 수 있습니다.
      // 여기서는 단순화를 위해 목표 저장 시 관련 플래그를 초기화합니다.
      // 실제로는 _finalGoalAmount가 이전 값과 다를 때만 초기화하는 것이 더 좋을 수 있습니다.
      // bool goalAmountChanged = savingQuery.docs.isNotEmpty && (savingQuery.docs.first.data() as Map<String, dynamic>)['goalAmount'] != _finalGoalAmount;
      // if (goalAmountChanged) { // 또는 항상 초기화
      if (mounted) {
        setState(() {
          _notified50percent = false;
          _notified90percent = false;
          _notified100percent = false;
        });
      }
      // }

      Map<String, dynamic> dataToSave = {
        'monthlyAmount': _savingsGoalAmount,
        'goalAmount': _finalGoalAmount,
        'selectedAccountId': selectedAccountId,
        'updatedAt': FieldValue.serverTimestamp(),
        // 알림 상태도 함께 저장하는 것을 고려할 수 있습니다.
        // 'notified50percent': _notified50percent,
        // 'notified90percent': _notified90percent,
        // 'notified100percent': _notified100percent,
      };

      if (savingQuery.docs.isNotEmpty) {
        String docId = savingQuery.docs.first.id;
        await FirebaseFirestore.instance.collection('saving').doc(docId).update(dataToSave);
      } else {
        dataToSave['userId'] = currentUser.uid;
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('saving').add(dataToSave);
      }

      // 저장 후 데이터 다시 로드 및 상태 업데이트 (이 과정에서 _loadSavingGoalData 내부의 알림 로직이 실행됨)
      await _loadSavingGoalData();


      // 달성률 계산 및 알림 로직은 _loadSavingGoalData로 이동됨


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저축 목표가 저장되었습니다.')),
        );
      }

    } catch (e) {
      debugPrint('저축 목표 저장 오류: $e');
      // await 이후 mounted 확인
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( // context 직접 사용
          const SnackBar(content: Text('저축 목표 저장 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  // 고정 지출 데이터 로드 함수
  Future<void> _loadFixedExpenseData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFixedExpenses = true;
    });

    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('고정지출 데이터 로드 시작 - 사용자 ID: ${currentUser.uid}');
        
        // 실시간 업데이트를 위한 스트림 리스너 설정
        FirebaseFirestore.instance
            .collection('fixed_expenses')
            .where('userId', isEqualTo: currentUser.uid)
            .snapshots()
            .listen((snapshot) async {
          debugPrint('고정지출 데이터 변경 감지 - 문서 수: ${snapshot.docs.length}');

          List<Map<String, dynamic>> tempList = [];
          double tempTotalAmount = 0.0;

          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data();
            debugPrint('고정지출 데이터 처리: $data');
          
            tempTotalAmount += (data['amount'] as num).toDouble();

            String paymentMethodId = data['paymentMethod'] ?? '';
            String bankName = '출금 계좌 미설정';
            if (paymentMethodId.isNotEmpty) {
              try {
                DocumentSnapshot assetDoc = await FirebaseFirestore.instance
                    .collection('assets')
                    .doc(paymentMethodId)
                    .get();
                if (assetDoc.exists) {
                  bankName = (assetDoc.data() as Map<String, dynamic>)['bank'] ?? '은행 정보 없음';
                }
              } catch (e) {
                debugPrint('은행 정보 조회 오류 (ID: $paymentMethodId): $e');
              }
            }

            Timestamp? timestamp = data['date'] as Timestamp? ?? data['createdAt'] as Timestamp?;
            if (timestamp != null) {
              String formattedDate = DateFormat('d일').format(timestamp.toDate());
              tempList.add({
                'id': doc.id, // 문서 ID 추가
                'amount': (data['amount'] as num).toDouble(),
                'merchant': data['merchant'] ?? '정보 없음',
                'createdAtDay': formattedDate,
                'paymentBank': bankName,
              });
            } else {
              debugPrint('날짜 정보가 없는 고정지출 데이터 발견: $data');
            }
          }

          debugPrint('처리된 고정지출 목록: $tempList');
          debugPrint('총 고정지출 금액: $tempTotalAmount');

          if (mounted) {
            setState(() {
              _fixedExpensesList = tempList;
              _totalFixedExpenseAmount = tempTotalAmount;
              _isLoadingFixedExpenses = false;
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingFixedExpenses = false;
          });
        }
      }
    } catch (e) {
      debugPrint('고정지출 정보 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingFixedExpenses = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('자산', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 탭바
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '조회'),
                Tab(text: '목표'),
              ],
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorWeight: 2.0,
            ),
          ),

          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 조회 탭
                _buildViewTab(),

                // 목표 탭
                _buildGoalTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 자산 추가 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetScreen(
                user: widget.user ?? FirebaseAuth.instance.currentUser,
                previousRouteName: 'asset_detail_screen', // 현재 화면 경로 전달
              ),
            ),
          );

          // 임시로 스낵바 표시
          /*ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('자산 추가 기능 개발 중입니다')),
          );*/
        },
        backgroundColor: const Color(0xFF73AD13),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 조회 탭 위젯
  Widget _buildViewTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF73AD13)))
        : RefreshIndicator(
      onRefresh: _loadAssetData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 총 자산 표시
              _buildTotalAssetSection(),

              const SizedBox(height: 16.0),
              const Divider(),

              // 계좌 섹션
              _buildAccountSection('입출금', _savingsTotal, Icons.account_balance),
              _buildAccountSection('적금', _depositTotal, Icons.savings),
              _buildAccountSection('예금', _cashTotal, Icons.payment),
              _buildAccountSection('주식', _stocksTotal, Icons.trending_up),

              const SizedBox(height: 80.0), // FloatingActionButton 공간 확보
            ],
          ),
        ),
      ),
    );
  }

// 목표 탭 위젯 수정
  Widget _buildGoalTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 첫 번째 줄: 이번 달 수입 & 이번 달 저축
            Row(
              children: [
                // 이번 달 수입 카드
                Expanded(
                  child: _buildMonthlyIncomeCard(),
                ),
                const SizedBox(width: 16.0),
                // 이번 달 저축 카드
                Expanded(
                  child: _buildMonthlySavingsCard(),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // 두 번째 줄: 이번 달 지출 카드 (파이 차트) - 가로 전체
            _buildMonthlyExpenseCard(),

            const SizedBox(height: 16.0),

            // 세 번째 줄: 고정지출 & 이번 달 예산
            Row(
              children: [
                // 고정지출 카드
                Expanded(
                  child: _buildFixedExpenseCard(),
                ),
                const SizedBox(width: 16.0),
                // 이번 달 예산 카드
                Expanded(
                  child: _buildMonthlyBudgetCard(),
                ),
              ],
            ),

            const SizedBox(height: 80.0), // FloatingActionButton 공간 확보
          ],
        ),
      ),
    );
  }

// 공통 카드 스타일
  Widget _buildStandardCard({required Widget child, double height = 180}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: Colors.grey[50],
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

// 막대 그래프 위젯
  Widget _buildBarGraph(String month, double amount, Color color, double heightPercent) {
    // 수입 금액을 간단히 표시 (천 단위 구분)
    String amountDisplay = '';
    if (amount >= 10000) {
      final inMillions = amount / 10000;
      amountDisplay = '${inMillions.toStringAsFixed(1)}만';
    } else {
      amountDisplay = NumberFormat('#,###').format(amount);
    }

    return SizedBox(
      width: 35, // 너비 더 감소
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: '$month: $amountDisplay원',
            child: Container(
              width: 15, // 막대 너비 감소
              height: heightPercent > 0 ? min(heightPercent, 150) : 2, // 높이 제한
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
                bottom: Radius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4), // 간격 축소
          FittedBox( // 텍스트 오버플로우 방지
            fit: BoxFit.scaleDown,
            child: Text(
              month,
              style: TextStyle(
                fontSize: 8, // 텍스트 크기 감소
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

// 이번 달 수입 카드
  Widget _buildMonthlyIncomeCard() {
    // TransactionProvider에서 데이터 가져오기
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;
    
    // 현재 날짜 정보 가져오기
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // 최근 3개월의 연도와 월 계산
    List<Map<String, dynamic>> lastThreeMonths = [];
    for (int i = 0; i < 3; i++) {
      int month = currentMonth - i;
      int year = currentYear;
      if (month <= 0) {
        month += 12;
        year -= 1;
      }
      lastThreeMonths.add({
        'year': year,
        'month': month,
        'label': '$month월',
      });
    }
    // 가장 오래된 월이 먼저 오도록 뒤집기
    lastThreeMonths = lastThreeMonths.reversed.toList();
    
    // 각 월의 수입 계산
    List<double> monthlyIncomes = [];
    for (var monthData in lastThreeMonths) {
      int year = monthData['year'];
      int month = monthData['month'];
      
      // 해당 월의 수입 트랜잭션 필터링
      final monthlyTransactions = transactions.where((transaction) {
        return transaction.date.year == year && 
               transaction.date.month == month && 
               transaction.type == '수입';
      }).toList();
      
      // 해당 월의 총 수입 계산
      final totalIncome = monthlyTransactions.fold(0.0, 
          (total, transaction) => total + transaction.amount);
          
      monthlyIncomes.add(totalIncome);
    }
    
    // 그래프 높이 계산 (최대 수입을 기준으로 비율 계산)
    double maxIncome = monthlyIncomes.isNotEmpty ? 
        monthlyIncomes.reduce((curr, next) => curr > next ? curr : next) : 1.0;
    List<double> heightPercents = monthlyIncomes.map((income) => 
        maxIncome > 0 ? (income / maxIncome) * 90 : 0.0).toList();
    
    // 현재 월의 수입 (마지막 값)
    String currentMonthIncome = '';
    if (monthlyIncomes.isNotEmpty) {
      final lastIncome = monthlyIncomes.last;
      currentMonthIncome = '${NumberFormat.compact(locale: 'ko').format(lastIncome)}원';
      if (lastIncome >= 10000) {
        final inMillions = lastIncome / 10000;
        currentMonthIncome = '${inMillions.toStringAsFixed(0)}만원';
      }
    }

    // 월 이름 표시
    List<String> monthLabels = lastThreeMonths.map((data) => data['label'] as String).toList();
    
    return _buildStandardCard(
      height: 250, // 높이 더 증가
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 수입',
            style: TextStyle(
              fontSize: 14, // 제목 텍스트 크기 감소
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          
          // 막대 그래프와 월 표시를 포함하는 컨테이너
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBarGraph(
                    monthLabels[0], 
                    monthlyIncomes[0],
                    Color.fromRGBO(158, 158, 158, 0.3), 
                    heightPercents[0]
                  ),
                  const SizedBox(width: 12),
                  _buildBarGraph(
                    monthLabels[1], 
                    monthlyIncomes[1],
                    Color.fromRGBO(158, 158, 158, 0.3), 
                    heightPercents[1]
                  ),
                  const SizedBox(width: 12),
                  _buildBarGraph(
                    monthLabels[2], 
                    monthlyIncomes[2],
                    const Color(0xFF73AD13), 
                    heightPercents[2]
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              currentMonthIncome,
              style: TextStyle(
                fontSize: 12, // 금액 텍스트 크기 감소
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

// 이번 달 지출 카드 (도넛 차트)
  Widget _buildMonthlyExpenseCard() {
    // TransactionProvider에서 데이터 가져오기
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;
    
    // 현재 날짜 정보 가져오기
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // 이번 달 지출 트랜잭션 필터링
    final monthlyExpenses = transactions.where((transaction) {
      return transaction.date.year == currentYear && 
             transaction.date.month == currentMonth && 
             transaction.type == '지출';
    }).toList();
    
    // 카테고리별 지출 금액 계산
    Map<String, double> categoryExpenses = {};
    for (var transaction in monthlyExpenses) {
      final category = transaction.category.isEmpty ? '기타' : transaction.category;
      if (categoryExpenses.containsKey(category)) {
        categoryExpenses[category] = categoryExpenses[category]! + transaction.amount;
      } else {
        categoryExpenses[category] = transaction.amount;
      }
    }
    
    // 총 지출액 계산
    final totalExpense = monthlyExpenses.fold(
        0.0, (total, transaction) => total + transaction.amount);
    
    // 상위 4개 카테고리 선택 (또는 더 적은 경우 모든 카테고리)
    List<MapEntry<String, double>> sortedCategories = 
        categoryExpenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    
    List<MapEntry<String, double>> topCategories = [];
    double otherAmount = 0.0;
    
    if (sortedCategories.length <= 4) {
      topCategories = sortedCategories;
    } else {
      topCategories = sortedCategories.take(3).toList();
      // 나머지 카테고리 금액 합산
      otherAmount = sortedCategories.skip(3).fold(
          0.0, (total, entry) => total + entry.value);
      topCategories.add(MapEntry('기타', otherAmount));
    }
    
    // 퍼센트 계산
    final List<ChartCategory> chartData = [];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    
    if (totalExpense > 0) {
      for (int i = 0; i < topCategories.length; i++) {
        final category = topCategories[i];
        final percent = (category.value / totalExpense * 100).round();
        chartData.add(ChartCategory(
          name: category.key,
          amount: category.value,
          percent: percent,
          color: i < colors.length ? colors[i] : Colors.grey,
        ));
      }
    } else {
      // 지출이 없는 경우 기본 데이터
      chartData.add(ChartCategory(
        name: '지출 없음',
        amount: 0,
        percent: 100,
        color: Colors.grey,
      ));
    }
    
    // 금액 표시 포맷
    String expenseText = '0원';
    if (totalExpense > 0) {
      if (totalExpense >= 10000) {
        final inMillions = totalExpense / 10000;
        expenseText = '${inMillions.toStringAsFixed(0)}만원';
      } else {
        expenseText = '${NumberFormat('#,###').format(totalExpense)}원';
      }
    }
    
    return _buildStandardCard(
      height: 160, // 높이 약간 감소
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 지출',
            style: TextStyle(
              fontSize: 14, // 제목 텍스트 크기 감소
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // 도넛 차트와 범례
          Expanded(
            child: Row(
              children: [
                // 도넛 차트 - 크기 조정
                Expanded(
                  flex: 4, // 전체 너비의 40%
                  child: SizedBox(
                    height: 90, // 높이 제한
                    child: Center(
                      child: SizedBox(
                        width: 90, // 도넛 차트 크기 제한
                        height: 90,
                  child: CustomPaint(
                          painter: DonutChartPainter(categories: chartData),
                        ),
                      ),
                    ),
                  ),
                ),
                // 범례
                Expanded(
                  flex: 6, // 전체 너비의 60%
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end, // 오른쪽 정렬
                        children: chartData.map((category) => 
                          _buildLegendItem(
                            category.name, 
                            '${category.percent}%', 
                            category.color,
                          )
                        ).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: Text(
              expenseText,
              style: TextStyle(
                fontSize: 12, // 금액 텍스트 크기 감소
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 범례 아이템 위젯
  Widget _buildLegendItem(String label, String percentage, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞춤
      children: [
        Container(
          width: 8, // 범례 점 크기 감소
          height: 8, // 범례 점 크기 감소
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $percentage',
          style: TextStyle(
            fontSize: 10, // 범례 텍스트 크기 감소
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

// 고정지출 카드
  Widget _buildFixedExpenseCard() {
    return _buildStandardCard(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '고정지출',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          _isLoadingFixedExpenses
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF73AD13)))
              : _fixedExpensesList.isEmpty
                  ? const Text(
                      '고정지출을 추가하세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    )
                  : InkWell(
                      onTap: () {
                        if (_fixedExpensesList.isNotEmpty) {
                          _showFixedExpenseDetailsSheet();
                        }
                      },
                      child: Center( // 텍스트를 중앙 정렬하기 위해 Center 위젯 추가
                        child: Text(
                          '${_numberFormat(_totalFixedExpenseAmount.toInt())}원',
                          style: const TextStyle(
                            fontSize: 18, // 필요에 따라 폰트 크기 조절
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // 필요에 따라 색상 조절
                          ),
                        ),
                      ),
                    ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // 고정지출 추가 시트 표시
              _showFixedExpenseSheet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF73AD13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text(
              '고정지출 추가',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 고정지출 상세 내역 표시 시트
  void _showFixedExpenseDetailsSheet() {
    if (!mounted) return;
    final currentContext = context;

    showModalBottomSheet(
      context: currentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(currentContext).size.height * 0.6,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '고정 지출 상세 내역',
                      style: TextStyle(
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
                const SizedBox(height: 16),
                Expanded(
                  child: _fixedExpensesList.isEmpty
                      ? const Center(child: Text('표시할 고정 지출 내역이 없습니다.'))
                      : ListView.builder(
                          itemCount: _fixedExpensesList.length,
                          itemBuilder: (context, index) {
                            final expense = _fixedExpensesList[index];
                            return Dismissible(
                              key: Key(expense['id']),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('고정지출 삭제'),
                                      content: const Text('이 고정지출을 삭제하시겠습니까?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('취소'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text(
                                            '삭제',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onDismissed: (direction) {
                                _deleteFixedExpense(expense['id'], index);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: index < _fixedExpensesList.length - 1 
                                          ? Colors.grey.withOpacity(0.2) 
                                          : Colors.transparent,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    expense['merchant'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${expense['createdAtDay']} • ${expense['paymentBank']}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  trailing: Text(
                                    '${_numberFormat((expense['amount'] as double).toInt())}원',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 고정지출 추가 시트 표시
  void _showFixedExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '고정지출 내역찾기',
                    style: TextStyle(
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          '가계부에서',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FixedExpenseListScreen(),
                              ),
                            );
                            
                            // 고정지출이 추가되었다면 데이터 새로고침
                            if (result == true) {
                              _loadFixedExpenseData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF73AD13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            '내역찾기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          '고정지출 항목',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF73AD13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            '추가하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

// 이번 달 예산 카드
  Widget _buildMonthlyBudgetCard() {
    // 예산 초기화
    String budgetText = _hasBudget 
        ? (_budgetAmount >= 10000 
            ? '${(_budgetAmount / 10000).toStringAsFixed(1)}만원' 
            : '${_numberFormat(_budgetAmount.toInt())}원')
        : '예산을 설정하세요'; 
    
    // Calculate remaining budget
    double remainingBudget = _budgetAmount - _expensesAmount;
    remainingBudget = remainingBudget < 0 ? 0 : remainingBudget;
    
    String remainingText = _hasBudget
        ? '남은 예산: ${remainingBudget >= 10000 
            ? '${(remainingBudget / 10000).toStringAsFixed(1)}만원' 
            : '${_numberFormat(remainingBudget.toInt())}원'}'
        : '';
    
    // 예산 값이 있으면 "변경", 없으면 "설정"
    String buttonText = _hasBudget ? '월 예산 변경' : '월 예산 설정'; 
    
    return _buildStandardCard(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 예산',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // 예산과 지출을 보여주는 그래프
          Column(
            children: [
              Text(
                budgetText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _hasBudget 
                  ? _buildBudgetProgressBar(_expensesAmount / 10000, _budgetAmount / 10000)
                  : Container(height: 25),
              const SizedBox(height: 12),
              Text(
                remainingText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // 월 예산 변경 시트 표시
              _showMonthlyBudgetSettingSheet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF73AD13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              minimumSize: const Size(double.infinity, 36),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 월 예산 설정 시트 표시
  void _showMonthlyBudgetSettingSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      // 예산 금액 포맷팅
      String budgetText = _hasBudget 
          ? '${_numberFormat(_budgetAmount.toInt())}원' 
          : '0원';
      
      // 예산 비율 텍스트
      String percentageText = _incomeAmount > 0 
          ? '월 수입의 $_budgetPercentage%'
          : '월 수입이 없습니다';
      
      return Container(
        padding: const EdgeInsets.all(20),
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
          const Text(
                  '월 지출 예산 설정',
            style: TextStyle(
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
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                // 현재 시트를 닫고 예산 입력 다이얼로그 표시
                Navigator.pop(context);
                _showBudgetInputDialog();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '지출 예산',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            budgetText,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            percentageText,
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
          ElevatedButton(
            onPressed: () {
                  Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF73AD13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
                  minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
                  '저장',
              style: TextStyle(
                color: Colors.white,
                    fontSize: 16,
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
  
  // 예산 입력 다이얼로그 표시
  void _showBudgetInputDialog() {
  // 예산 금액 관리를 위한 변수
  String budgetInput = _hasBudget ? _budgetAmount.toInt().toString() : '0';
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // 입력된 금액을 포맷팅하여 표시
          String formattedBudget = '${_numberFormat(int.parse(budgetInput))}원';
          
          // 입력한 예산액의 수입 대비 퍼센트 계산
          String percentageText = '월 수입의 0%';
          if (_incomeAmount > 0 && budgetInput.isNotEmpty && budgetInput != '0') {
            double inputAmount = double.parse(budgetInput);
            int percentage = ((inputAmount / _incomeAmount) * 100).round();
            percentageText = '월 수입의 $percentage%';
          } else if (_incomeAmount <= 0) {
            percentageText = '월 수입이 없습니다';
          }
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom
            ),
            child: SizedBox(
              height: 500,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 제목 및 닫기 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '월 지출 예산을 입력해주세요.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context), // 변경 없이 닫기
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // 예산 금액 표시
                    Center(
                      child: Column(
                        children: [
                          Text(
                            formattedBudget,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            percentageText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                      
                      const SizedBox(height: 20),

                      // 숫자 키패드
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 첫 번째 줄: 1, 2, 3
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('1', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '1';
                                    }
                                  });
                                }),
                                _buildNumberButton('2', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '2';
                                    }
                                  });
                                }),
                                _buildNumberButton('3', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '3';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // 두 번째 줄: 4, 5, 6
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('4', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '4';
                                    }
                                  });
                                }),
                                _buildNumberButton('5', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '5';
                                    }
                                  });
                                }),
                                _buildNumberButton('6', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '6';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // 세 번째 줄: 7, 8, 9
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('7', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '7';
                                    }
                                  });
                                }),
                                _buildNumberButton('8', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '8';
                                    }
                                  });
                                }),
                                _buildNumberButton('9', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10) {
                                      budgetInput += '9';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // 네 번째 줄: 0, 백스페이스
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 50),
                                _buildNumberButton('0', onPressed: () {
                                  setState(() {
                                    if (budgetInput.length < 10 && budgetInput != '0') {
                                      budgetInput += '0';
                                    }
                                  });
                                }),
                                _buildBackspaceButton(onPressed: () {
                                  setState(() {
                                    if (budgetInput.isNotEmpty) {
                                      budgetInput = budgetInput.substring(0, budgetInput.length - 1);
                                      if (budgetInput.isEmpty) {
                                        budgetInput = '0';
                                      }
                                    }
                                  });
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 확인 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // 예산 입력값을 숫자로 변환
                            final currentContext = context;
                            double budgetAmount = double.parse(budgetInput);
                            await _saveBudget(budgetAmount);
                            
                            // 예산 저장 후 다이얼로그 표시
                            if (currentContext.mounted) {
                              Navigator.pop(currentContext);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF73AD13),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  // 숫자 버튼 위젯
  Widget _buildNumberButton(String number, {required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 백스페이스 버튼 위젯
  Widget _buildBackspaceButton({required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        child: const Icon(Icons.backspace_outlined, size: 24),
      ),
    );
  }

  // 커스텀 예산 진행 바 위젯
  Widget _buildBudgetProgressBar(double spent, double budget) {
    double progress = spent / budget;
    progress = progress.clamp(0.0, 1.0); // 1.0을 넘지 않도록 제한
    
    return Stack(
      children: [
        // 배경(전체 예산)
        Container(
          height: 25,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12.5),
          ),
        ),
        // 진행 바(사용된 예산)
        Container(
          height: 25,
          width: MediaQuery.of(context).size.width * 0.35 * progress, // 화면 너비에 비례하게 조정
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12.5),
          ),
          child: Center(
            child: Text(
              '$spent만원',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

// 이번 달 저축 카드
  Widget _buildMonthlySavingsCard() {
    // 선택된 계좌의 잔액 텍스트 (만 단위로 변환)
    String accountBalanceText = '0';
    if (_selectedSavingAccount != null) {
      int balance = _selectedSavingAccount!['balance'];
      double inTenThousand = balance / 10000.0;
      accountBalanceText = inTenThousand.toStringAsFixed(inTenThousand >= 10 ? 0 : 1);
    }

    // 최종 목표 금액 텍스트 (만 단위로 변환) - _finalGoalAmount 사용 (Firestore의 goalAmount와 동기화됨)
    String finalGoalText = '0';
    if (_finalGoalAmount > 0) {
      double inTenThousand = _finalGoalAmount / 10000.0;
      finalGoalText = inTenThousand.toStringAsFixed(inTenThousand >= 10 ? 0 : 1);
    }

    // 버튼 텍스트 설정
    String buttonText = _hasSavingGoal ? '월 목표 변경' : '월 목표 설정';

    return _buildStandardCard(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 저축',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // 저축 계좌 잔액과 목표 금액을 n원/n원 형식으로 표시
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 현재 저축 계좌 잔액 (회색)
                Text(
                  '$accountBalanceText만원',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  ' / ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                // 최종 목표 금액 (초록색)
                Text(
                  '$finalGoalText만원', // _finalGoalAmount가 goalAmount를 반영
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF73AD13),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // 월 저축 목표 설정 시트 표시
              _showMonthlySavingsGoalSheet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF73AD13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              minimumSize: const Size(double.infinity, 36),
            ),
            child: Text(
              buttonText, // 동적 버튼 텍스트 사용
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 월 저축 목표 설정 시트 표시
  void _showMonthlySavingsGoalSheet() {
    // 시트가 열릴 때 현재 상태를 기반으로 지역 변수 설정
    int currentMonthlySavingAmount = _savingsGoalAmount; // 월 저축액
    int currentFinalGoal = _finalGoalAmount; // 최종 목표액
    Map<String, dynamic>? currentSelectedAccount = _selectedSavingAccount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // StatefulBuilder를 사용하여 시트 내 상태 관리
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            // 목표 금액 텍스트 포맷팅
            String monthlyGoalAmountText = currentMonthlySavingAmount > 0
                ? '${_numberFormat(currentMonthlySavingAmount)}원'
                : '0원';
            
            String finalGoalAmountText = currentFinalGoal > 0
                ? '${_numberFormat(currentFinalGoal)}원'
                : '0원';

            // 수입 대비 퍼센트 계산 (월 저축액 기준)
            String percentageText = '월 수입의 0%';
            if (_incomeAmount > 0 && currentMonthlySavingAmount > 0) {
              int percentage = ((currentMonthlySavingAmount / _incomeAmount) * 100).round();
              percentageText = '월 수입의 $percentage%';
            } else if (_incomeAmount <= 0) {
              percentageText = '월 수입 없음';
            }

            // 계좌 정보 텍스트
            String accountBankText = '계좌 선택';
            String accountBalanceText = '';

            if (currentSelectedAccount != null) {
              accountBankText = currentSelectedAccount!['bank'];
              accountBalanceText = '잔액 ${_numberFormat(currentSelectedAccount!['balance'])}원';
            }

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '월 저축 목표 설정',
                          style: TextStyle(
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
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () async {
                        // 월 저축 금액 입력 다이얼로그
                        final result = await _showSavingsGoalInputDialog(currentMonthlySavingAmount);
                        if (result != null) {
                          setSheetState(() {
                            currentMonthlySavingAmount = result;
                          });
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '월 저축 금액',
                            style: TextStyle(fontSize: 16),
                          ),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    monthlyGoalAmountText, // 월 저축액 표시
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    percentageText,
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
                    InkWell(
                      onTap: () async {
                        // 계좌 선택 다이얼로그 표시 및 결과 받기
                        final result = await _showSelectSavingAccountDialog(currentSelectedAccount);
                        if (result != null) {
                          setSheetState(() {
                            currentSelectedAccount = result; // 시트 내 상태 업데이트
                          });
                        }
                      },
                      child: Row(
                        // ... 저축 계좌 UI ...
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '저축 계좌',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    accountBankText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    accountBalanceText,
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
                    InkWell(
                      onTap: () async {
                        // 목표 금액 입력 다이얼로그
                        final result = await _showFinalGoalInputDialog(currentFinalGoal);
                        if (result != null) {
                          setSheetState(() {
                            currentFinalGoal = result; // 시트 내 최종 목표액 업데이트
                          });
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '목표 금액',
                            style: TextStyle(fontSize: 16),
                          ),
                          Row(
                            children: [
                              Text(
                                finalGoalAmountText, // 최종 목표액 표시
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
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
                    ElevatedButton(
                      onPressed: () async {
                        // 시트 내의 임시 상태를 실제 상태 변수에 반영
                        final BuildContext currentContext = context;
                        
                        setState(() {
                          _savingsGoalAmount = currentMonthlySavingAmount; // 월 저축액 업데이트
                          _finalGoalAmount = currentFinalGoal; // 최종 목표액 업데이트
                          _selectedSavingAccount = currentSelectedAccount;
                        });
                        // Firestore에 저장
                        await _saveSavingGoal();
                        
                        // 비동기 작업 완료 후 context가 유효한지 확인
                        if (currentContext.mounted) {
                          Navigator.pop(currentContext);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF73AD13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        '저장',
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
          },
        );
      },
    );
  }

  // 저축 계좌 선택 다이얼로그 표시 (선택된 계좌 반환하도록 수정)
  Future<Map<String, dynamic>?> _showSelectSavingAccountDialog(Map<String, dynamic>? initialSelectedAccount) async {
    // 선택된 계좌를 추적하기 위한 Map (다이얼로그 내에서만 사용)
    Map<String, dynamic>? tempSelectedAccount = initialSelectedAccount;

    // 사용자의 계좌 정보 목록 준비
    List<Map<String, dynamic>> savingAccounts = _assetAccounts
        .where((account) => account['assetType'] == 'savings')
        .toList();

    List<Map<String, dynamic>> depositAccounts = _assetAccounts
        .where((account) => account['assetType'] == 'deposit')
        .toList();

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
                height: 500, // 필요시 높이 조절
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '월 저축 계좌를 설정해주세요.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context), // 선택 없이 닫기
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

                    // 입출금 계좌 목록
                    Expanded(
                      flex: savingAccounts.isEmpty ? 1 : 2,
                      child: savingAccounts.isEmpty
                          ? const Center(child: Text('등록된 입출금 계좌가 없습니다.'))
                          : ListView.builder(
                              itemCount: savingAccounts.length,
                              itemBuilder: (context, index) {
                                final account = savingAccounts[index];

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _buildAccountIcon(account),
                                  title: Text(
                                    account['bank'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text('${_numberFormat(account['balance'])}원'),
                                  trailing: Radio<String>( // Radio 버튼 사용
                                    value: account['id'],
                                    groupValue: tempSelectedAccount?['id'],
                                    onChanged: (String? value) {
                                      setDialogState(() {
                                        tempSelectedAccount = account;
                                      });
                                    },
                                    activeColor: const Color(0xFF73AD13),
                                  ),
                                  onTap: () { // ListTile 탭으로도 선택 가능
                                     setDialogState(() {
                                        tempSelectedAccount = account;
                                      });
                                  },
                                );
                              },
                            ),
                    ),

                    // 적금 계좌가 있을 때만 적금 섹션 표시
                    if (depositAccounts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        '적금',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const Divider(),

                      // 적금 계좌 목록
                      Expanded(
                        flex: 2,
                        child: ListView.builder(
                          itemCount: depositAccounts.length,
                          itemBuilder: (context, index) {
                            final account = depositAccounts[index];

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: _buildAccountIcon(account),
                              title: Text(
                                account['bank'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('${_numberFormat(account['balance'])}원'),
                              trailing: Radio<String>( // Radio 버튼 사용
                                value: account['id'],
                                groupValue: tempSelectedAccount?['id'],
                                onChanged: (String? value) {
                                  setDialogState(() {
                                     tempSelectedAccount = account;
                                  });
                                },
                              ), // Radio 위젯을 여기서 닫습니다.
                              onTap: () { // ListTile의 onTap 핸들러를 여기에 추가합니다.
                                 setDialogState(() {
                                    tempSelectedAccount = account;
                                  });
                              },
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // 확인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // 선택한 계좌를 결과로 반환하며 다이얼로그 닫기
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

  // 저축 목표 금액 입력 다이얼로그 표시 (입력된 금액 반환하도록 수정)
  Future<int?> _showSavingsGoalInputDialog(int initialAmount) async {
    // 저축 목표 금액 관리를 위한 변수 (다이얼로그 내에서만 사용)
    String goalInput = initialAmount > 0 ? initialAmount.toString() : '0';

    return await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 입력된 금액을 포맷팅하여 표시
            String formattedGoal = '0원';
            int currentAmount = 0;
            if (goalInput.isNotEmpty) {
              currentAmount = int.tryParse(goalInput) ?? 0;
              formattedGoal = '${_numberFormat(currentAmount)}원';
            }


            // 입력한 목표액의 수입 대비 퍼센트 계산
            String percentageText = '월 수입의 0%';
            if (_incomeAmount > 0 && currentAmount > 0) {
              int percentage = ((currentAmount / _incomeAmount) * 100).round();
              percentageText = '월 수입의 $percentage%';
            } else if (_incomeAmount <= 0) {
              percentageText = '월 수입 없음';
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom
              ),
              child: SizedBox(
                height: 500, // 필요시 높이 조절
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 제목 및 닫기 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '월 저축 목표를 입력해주세요.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context), // 변경 없이 닫기
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 목표 금액 표시
                      Center(
                        child: Column(
                          children: [
                            Text(
                              formattedGoal,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              percentageText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 숫자 키패드
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 첫 번째 줄: 1, 2, 3
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('1', onPressed: () {
                                  setDialogState(() {
                                    if (goalInput == '0') goalInput = ''; // 0일 때 초기화
                                    if (goalInput.length < 10) {
                                      goalInput += '1';
                                    }
                                  });
                                }),
                                _buildNumberButton('2', onPressed: () {
                                  setDialogState(() {
                                     if (goalInput == '0') goalInput = '';
                                    if (goalInput.length < 10) {
                                      goalInput += '2';
                                    }
                                  });
                                }),
                                _buildNumberButton('3', onPressed: () {
                                  setDialogState(() {
                                     if (goalInput == '0') goalInput = '';
                                    if (goalInput.length < 10) {
                                      goalInput += '3';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // 두 번째 줄: 4, 5, 6
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('4', onPressed: () {
                                  setDialogState(() {
                                     if (goalInput == '0') goalInput = '';
                                    if (goalInput.length < 10) {
                                      goalInput += '4';
                                    }
                                  });
                                }),
                                _buildNumberButton('5', onPressed: () {
                                  setDialogState(() {
                                     if (goalInput == '0') goalInput = '';
                                    if (goalInput.length < 10) {
                                      goalInput += '5';
                                    }
                                  });
                                }),
                                _buildNumberButton('6', onPressed: () {
                                  setDialogState(() {
                                     if (goalInput == '0') goalInput = '';
                                    if (goalInput.length < 10) {
                                      goalInput += '6';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // 세 번째 줄: 7, 8, 9
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('7', onPressed: () {
                                  setDialogState(() {
                                     if (goalInput == '0') goalInput = '';
                                    if (goalInput.length < 10) {
                                      goalInput += '7';
                                    }
                                  });
                                }),
                                _buildNumberButton('8', onPressed: () {
                                  setDialogState(() {
                                     if (goalInput == '0') goalInput = '';
                                    if (goalInput.length < 10) {
                                      goalInput += '8';
                                    }
                                  });
                                }),
                                _buildNumberButton('9', onPressed: () {
                                  setDialogState(() {
                                     if (goalInput == '0') goalInput = '';
                                    if (goalInput.length < 10) {
                                      goalInput += '9';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // 네 번째 줄: 0, 백스페이스
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 50), // 자리 맞춤용
                                _buildNumberButton('0', onPressed: () {
                                  setDialogState(() {
                                    // 0만 입력되어 있는 상태가 아니거나, 길이가 10 미만일 때만 0 추가
                                    if (goalInput != '0' && goalInput.length < 10) {
                                      goalInput += '0';
                                    }
                                  });
                                }),
                                _buildBackspaceButton(onPressed: () {
                                  setDialogState(() {
                                    if (goalInput.isNotEmpty) {
                                      goalInput = goalInput.substring(0, goalInput.length - 1);
                                      if (goalInput.isEmpty) {
                                        goalInput = '0'; // 비어있으면 0으로 설정
                                      }
                                    }
                                  });
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 확인 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // 입력된 금액을 int로 변환하여 결과로 반환
                            int amount = int.tryParse(goalInput) ?? 0;
                            Navigator.pop(context, amount);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF73AD13),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  // 목표 금액 입력 다이얼로그 함수 추가
  Future<int?> _showFinalGoalInputDialog(int initialAmount) async {
    String input = initialAmount > 0 ? initialAmount.toString() : '0';
    return await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String formatted = '0원';
            int current = 0;
            if (input.isNotEmpty) {
              current = int.tryParse(input) ?? 0;
              formatted = '${_numberFormat(current)}원';
            }
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom
              ),
              child: SizedBox(
                height: 500,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '목표 금액을 입력해주세요.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          formatted,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('1', onPressed: () {
                                  setDialogState(() {
                                    if (input == '0') input = '';
                                    if (input.length < 10) {
                                      input += '1';
                                    }
                                  });
                                }),
                                _buildNumberButton('2', onPressed: () {
                                  setDialogState(() {
                                    if (input == '0') input = '';
                                    if (input.length < 10) {
                                      input += '2';
                                    }
                                  });
                                }),
                                _buildNumberButton('3', onPressed: () {
                                  setDialogState(() {
                                    if (input == '0') input = '';
                                    if (input.length < 10) {
                                      input += '3';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // ... 나머지 키패드 행 동일하게 구현 ...
                            // 두 번째 줄: 4, 5, 6
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('4', onPressed: () {
                                  setDialogState(() {
                                    if (input == '0') input = '';
                                    if (input.length < 10) {
                                      input += '4';
                                    }
                                  });
                                }),
                                _buildNumberButton('5', onPressed: () {
                                  setDialogState(() {
                                    if (input == '0') input = '';
                                    if (input.length < 10) {
                                      input += '5';
                                    }
                                  });
                                }),
                                _buildNumberButton('6', onPressed: () {
                                  setDialogState(() {
                                    if (input == '0') input = '';
                                    if (input.length < 10) {
                                      input += '6';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // 세 번째 줄: 7, 8, 9
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('7', onPressed: () {
                                  setDialogState(() {
                                    if (input == '0') input = '';
                                    if (input.length < 10) {
                                      input += '7';
                                    }
                                  });
                                }),
                                _buildNumberButton('8', onPressed: () {
                                  setDialogState(() {
                                    if (input == '0') input = '';
                                    if (input.length < 10) {
                                      input += '8';
                                    }
                                  });
                                }),
                                _buildNumberButton('9', onPressed: () {
                                  setDialogState(() {
                                    if (input == '0') input = '';
                                    if (input.length < 10) {
                                      input += '9';
                                    }
                                  });
                                }),
                              ],
                            ),
                            // 마지막 줄: 0, 백스페이스
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 50), // 자리 맞춤용
                                _buildNumberButton('0', onPressed: () {
                                  setDialogState(() {
                                    if (input != '0') {
                                      if (input.length < 10) {
                                        input += '0';
                                      }
                                    }
                                  });
                                }),
                                _buildBackspaceButton(onPressed: () {
                                  setDialogState(() {
                                    if (input.isNotEmpty) {
                                      input = input.substring(0, input.length - 1);
                                      if (input.isEmpty) input = '0';
                                    }
                                  });
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            int amount = int.tryParse(input) ?? 0;
                            Navigator.pop(context, amount);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF73AD13),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 계좌 아이콘 위젯 (은행 아이콘 생성)
  Widget _buildAccountIcon(Map<String, dynamic> account) {
    // 여기에서 실제 은행 아이콘을 사용할 수 있습니다
    String bankName = account['bank'];
    Color iconColor = Color(account['iconColor'] ?? 0xFF73AD13);
    String iconLetter = bankName.isNotEmpty ? bankName[0] : '?';

    // 은행에 따른 아이콘 (가상의 예시)
    Map<String, Widget> bankIcons = {
      '하나': _buildBankIcon('하', const Color(0xFF00B8ED)),
      'KB': _buildBankIcon('K', const Color(0xFFFFBC00)),
      '카카오': _buildBankIcon('카', const Color(0xFFFFE600)),
    };

    // 등록된 은행 아이콘이 있으면 사용, 없으면 첫 글자로 아이콘 생성
    return bankIcons[bankName] ?? _buildBankIcon(iconLetter, iconColor);
  }

  // 은행 아이콘 위젯
  Widget _buildBankIcon(String letter, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).round()), // withOpacity 대신 withAlpha 사용
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // 총 자산 섹션
  Widget _buildTotalAssetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '부린이님의 총자산',
          style: TextStyle(
            fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${_numberFormat(_totalAssets)}원',
          style: const TextStyle(
                fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
          ],
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '계좌 잔금',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_numberFormat(_savingsTotal + _depositTotal + _cashTotal)}원',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '입출금',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_numberFormat(_savingsTotal)}원',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 계좌 섹션 빌더
  Widget _buildAccountSection(String title, int totalAmount, IconData iconData) {
    // 해당 타입의 계좌 필터링
    List<Map<String, dynamic>> accounts = _assetAccounts.where((account) {
      String type = account['assetType'] ?? 'savings';

      switch (title) {
        case '입출금':
          return type == 'savings';
        case '적금':
          return type == 'deposit';
        case '예금':
          return type == 'cash';
        case '주식':
          return type == 'stocks';
        default:
          return false;
      }
    }).toList();

    // 섹션 내 계좌가 없으면 섹션 자체를 표시하지 않음
    if (accounts.isEmpty && totalAmount == 0) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),

        // 섹션 제목
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_numberFormat(totalAmount)}원',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 계좌 목록
        ...accounts.map((account) => _buildAccountItem(account)),

        const SizedBox(height: 8.0),
        const Divider(),
      ],
    );
  }

  // 개별 계좌 아이템 빌더
  Widget _buildAccountItem(Map<String, dynamic> account) {
    Color iconColor = Color(account['iconColor'] ?? 0xFF73AD13);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // 뱅크 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                account['bank'].toString().substring(0, 1),
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

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
                Text(
                  _formatAccountNumber(account['account']),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 잔액
          Text(
            '${_numberFormat(account['balance'])}원',
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 계좌번호 포맷팅
  String _formatAccountNumber(String accountNumber) {
    // 숫자만 추출
    String numbers = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length > 8) {
      // 앞 4자리, 중간 부분은 "*"로 가리고, 마지막 4자리 표시
      return '${numbers.substring(0, 4)}****${numbers.substring(numbers.length - 4)}';
    } else if (numbers.length > 4) {
      // 짧은 계좌번호는 앞 2자리와 마지막 2자리만 표시
      return '${numbers.substring(0, 2)}**${numbers.substring(numbers.length - 2)}';
    } else {
      // 너무 짧으면 그대로 표시
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

  // 고정지출 삭제 함수 수정
  Future<void> _deleteFixedExpense(String docId, int index) async {
    try {
      // 먼저 UI에서 항목 제거
      setState(() {
        _fixedExpensesList.removeAt(index);
        // 총액 다시 계산
        _totalFixedExpenseAmount = _fixedExpensesList.fold(
          0.0,
          (sum, item) => sum + (item['amount'] as double),
        );
      });

      // 그 다음 Firestore에서 삭제
      await FirebaseFirestore.instance
          .collection('fixed_expenses')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('고정지출이 삭제되었습니다')),
        );
      }
    } catch (e) {
      debugPrint('고정지출 삭제 오류: $e');
      if (mounted) {
        // 삭제 실패 시 목록 다시 로드
        await _loadFixedExpenseData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('고정지출 삭제 중 오류가 발생했습니다')),
        );
      }
    }
  }
}

class ChartCategory {
  final String name;
  final double amount;
  final int percent;
  final Color color;
  
  ChartCategory({
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
  });
}

class DonutChartPainter extends CustomPainter {
  final List<ChartCategory> categories;
  
  DonutChartPainter({this.categories = const []});
  
  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.2;
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    double radius = (size.width - strokeWidth) / 2;
    Offset center = Offset(size.width / 2, size.height / 2);

    if (categories.isEmpty || categories.length == 1 && categories[0].name == '지출 없음') {
      // 데이터가 없거나 지출이 없는 경우, 회색 원 그리기
      paint.color = Colors.grey.withAlpha(76);
      canvas.drawCircle(center, radius, paint);
      return;
    }
    
    double startAngle = -0.5 * 3.14; // 12시 방향에서 시작
    
    for (var category in categories) {
      final sweepAngle = category.percent / 100 * 2 * 3.14;
      paint.color = category.color;
      
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
      false,
      paint,
    );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}