/// 자동이체 서비스
/// 목표 계좌로 자동 이체를 처리하는 서비스입니다.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

/// 자동이체 스케줄 처리 함수
Future<void> processAutoTransfers() async {
  try {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    debugPrint('자동이체 체크 시작: ${today.toString()}');
    
    // 오늘 날짜에 실행해야 하는 자동이체 목록 조회
    QuerySnapshot schedules = await FirebaseFirestore.instance
        .collection('auto_transfer_schedules')
        .where('nextExecutionDate', isLessThanOrEqualTo: Timestamp.fromDate(today))
        .get();
    
    debugPrint('실행할 자동이체 개수: ${schedules.docs.length}');
    
    for (var scheduleDoc in schedules.docs) {
      Map<String, dynamic> schedule = scheduleDoc.data() as Map<String, dynamic>;
      
      // 날짜 확인 (정확히 오늘인지 확인)
      Timestamp? nextExecutionDate = schedule['nextExecutionDate'] as Timestamp?;
      if (nextExecutionDate != null) {
        DateTime executionDate = nextExecutionDate.toDate();
        DateTime executionDateOnly = DateTime(executionDate.year, executionDate.month, executionDate.day);
        
        if (executionDateOnly.isAtSameMomentAs(today)) {
          await _executeTransfer(schedule, scheduleDoc.id);
        }
      }
    }
    
    debugPrint('자동이체 처리 완료');
  } catch (e) {
    debugPrint('자동이체 처리 오류: $e');
  }
}

/// 실제 이체 실행 및 가계부 내역 추가
Future<void> _executeTransfer(Map<String, dynamic> schedule, String scheduleId) async {
  try {
    String fromAccountId = schedule['fromAccountId'] as String? ?? '';
    String toAccountId = schedule['toAccountId'] as String? ?? '';
    int amount = (schedule['amount'] as num?)?.toInt() ?? 0;
    String userId = schedule['userId'] as String? ?? '';
    String? goalName = schedule['goalName'] as String?;
    
    debugPrint('자동이체 실행: $goalName, 금액: $amount');
    
    // 1. 출금 계좌에서 출금
    DocumentSnapshot fromAccount = await FirebaseFirestore.instance
        .collection('assets')
        .doc(fromAccountId)
        .get();
    
    if (!fromAccount.exists) {
      debugPrint('출금 계좌를 찾을 수 없습니다: $fromAccountId');
      return;
    }
    
    Map<String, dynamic> fromData = fromAccount.data() as Map<String, dynamic>;
    int fromBalance = (fromData['balance'] as num?)?.toInt() ?? 0;
    
    if (fromBalance < amount) {
      debugPrint('잔액 부족: 자동이체 실패. 잔액: $fromBalance, 필요: $amount');
      return;
    }
    
    // 출금 계좌 잔액 업데이트
    await FirebaseFirestore.instance
        .collection('assets')
        .doc(fromAccountId)
        .update({'balance': fromBalance - amount});
    
    debugPrint('출금 계좌 잔액 업데이트 완료: ${fromBalance - amount}');
    
    // 2. 목표 계좌에 입금
    DocumentSnapshot toAccount = await FirebaseFirestore.instance
        .collection('assets')
        .doc(toAccountId)
        .get();
    
    if (!toAccount.exists) {
      debugPrint('입금 계좌를 찾을 수 없습니다: $toAccountId');
      return;
    }
    
    Map<String, dynamic> toData = toAccount.data() as Map<String, dynamic>;
    int toBalance = (toData['balance'] as num?)?.toInt() ?? 0;
    
    // 입금 계좌 잔액 업데이트
    await FirebaseFirestore.instance
        .collection('assets')
        .doc(toAccountId)
        .update({'balance': toBalance + amount});
    
    debugPrint('입금 계좌 잔액 업데이트 완료: ${toBalance + amount}');
    
    Timestamp currentTime = Timestamp.now();
    
    // 3. 출금 계좌 거래 내역 추가
    await FirebaseFirestore.instance
        .collection('assets')
        .doc(fromAccountId)
        .collection('transactions')
        .add({
      'prevbalance': fromBalance,
      'spend': '-',
      'transamount': amount,
      'transpartner': '목표 자동이체',
      'transtime': currentTime,
    });
    
    // 4. 입금 계좌 거래 내역 추가
    await FirebaseFirestore.instance
        .collection('assets')
        .doc(toAccountId)
        .collection('transactions')
        .add({
      'prevbalance': toBalance,
      'spend': '+',
      'transamount': amount,
      'transpartner': '목표 자동이체',
      'transtime': currentTime,
    });
    
    // 5. 가계부(ledger)에 지출 내역 추가 (출금 계좌)
    await FirebaseFirestore.instance.collection('ledger').add({
      'userId': userId,
      'type': '지출',
      'amount': amount,
      'date': currentTime,
      'merchant': '목표 자동이체',
      'category': '목표',
      'paymentMethod': fromAccountId,
      'memo': goalName ?? '',
      'tags': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // 6. 가계부(ledger)에 수입 내역 추가 (입금 계좌)
    await FirebaseFirestore.instance.collection('ledger').add({
      'userId': userId,
      'type': '수입',
      'amount': amount,
      'date': currentTime,
      'merchant': '목표 자동이체',
      'category': '목표',
      'paymentMethod': toAccountId,
      'memo': goalName ?? '',
      'tags': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    debugPrint('가계부 내역 추가 완료');
    
    // 7. 다음 실행 날짜 업데이트 (다음 달)
    DateTime nextDate = DateTime.now().add(const Duration(days: 30));
    await FirebaseFirestore.instance
        .collection('auto_transfer_schedules')
        .doc(scheduleId)
        .update({'nextExecutionDate': Timestamp.fromDate(nextDate)});
    
    debugPrint('다음 실행 날짜 업데이트 완료: $nextDate');
    
  } catch (e) {
    debugPrint('자동이체 실행 오류: $e');
  }
}
