
/// 자동이체 서비스
/// 목표 계좌로 자동 이체를 처리하는 서비스입니다.
library;
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
      final String scheduleType = (schedule['type'] as String?) ?? 'goal';
      
      // 날짜 확인 (정확히 오늘인지 확인)
      Timestamp? nextExecutionDate = schedule['nextExecutionDate'] as Timestamp?;
      if (nextExecutionDate != null) {
        DateTime executionDate = nextExecutionDate.toDate();
        DateTime executionDateOnly = DateTime(executionDate.year, executionDate.month, executionDate.day);
        
        if (executionDateOnly.isAtSameMomentAs(today)) {
          if (scheduleType == 'saving') {
            await _executeSavingTransfer(schedule, scheduleDoc.id);
          } else {
            await _executeGoalTransfer(schedule, scheduleDoc.id);
          }
        }
      }
    }
    
    debugPrint('자동이체 처리 완료');
  } catch (e) {
    debugPrint('자동이체 처리 오류: $e');
  }
}

/// 실제 이체 실행 및 가계부 내역 추가
Future<void> _executeGoalTransfer(Map<String, dynamic> schedule, String scheduleId) async {
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
    final int withdrawalDay = (schedule['withdrawalDay'] as num?)?.toInt() ?? DateTime.now().day;
    DateTime nextDate = _calculateNextExecutionDate(withdrawalDay);
    await FirebaseFirestore.instance
        .collection('auto_transfer_schedules')
        .doc(scheduleId)
        .update({'nextExecutionDate': Timestamp.fromDate(nextDate)});
    
    debugPrint('다음 실행 날짜 업데이트 완료: $nextDate');
    
  } catch (e) {
    debugPrint('자동이체 실행 오류: $e');
  }
}

Future<void> _executeSavingTransfer(Map<String, dynamic> schedule, String scheduleId) async {
  try {
    final String userId = schedule['userId'] as String? ?? '';
    if (userId.isEmpty) {
      debugPrint('저축 자동이체 실패: 사용자 정보 없음');
      return;
    }

    final QuerySnapshot savingQuery = await FirebaseFirestore.instance
        .collection('saving')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (savingQuery.docs.isEmpty) {
      debugPrint('저축 자동이체 실패: saving 문서 없음');
      return;
    }

    final DocumentSnapshot savingDoc = savingQuery.docs.first;
    final Map<String, dynamic> savingData = savingDoc.data() as Map<String, dynamic>;

    final String accountId = (savingData['account'] as String?) ?? '';
    final int amount = (savingData['amount'] as num?)?.toInt() ?? 0;
    final int currentBalance = (savingData['balance'] as num?)?.toInt() ?? 0;

    if (accountId.isEmpty || amount <= 0) {
      debugPrint('저축 자동이체 생략: 계좌 또는 금액이 유효하지 않음');
      return;
    }

    final int newBalance = currentBalance + amount;
    await savingDoc.reference.update({
      'balance': newBalance,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final Timestamp currentTime = Timestamp.now();
    await FirebaseFirestore.instance.collection('ledger').add({
      'userId': userId,
      'type': '지출',
      'amount': amount,
      'date': currentTime,
      'merchant': '저축',
      'category': '저축',
      'paymentMethod': accountId,
      'memo': '저축',
      'tags': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    final int scheduledDay = (schedule['scheduledDay'] as num?)?.toInt() ??
        (savingData['auto_transfer_date'] as num?)?.toInt() ??
        DateTime.now().day;
    final DateTime nextDate = _calculateNextExecutionDate(scheduledDay);

    await FirebaseFirestore.instance
        .collection('auto_transfer_schedules')
        .doc(scheduleId)
        .update({
      'nextExecutionDate': Timestamp.fromDate(nextDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('저축 자동이체 완료: balance=$newBalance');
  } catch (e) {
    debugPrint('저축 자동이체 실행 오류: $e');
  }
}

DateTime _calculateNextExecutionDate(int day) {
  final DateTime now = DateTime.now();
  try {
    final DateTime thisMonthLastDay = DateTime(now.year, now.month + 1, 0);
    final int clampedDay = day.clamp(1, thisMonthLastDay.day).toInt();
    DateTime candidate = DateTime(now.year, now.month, clampedDay);
    if (!candidate.isBefore(now)) {
      return candidate;
    }

    final DateTime nextMonth = DateTime(now.year, now.month + 1, 1);
    final DateTime nextMonthLastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0);
    final int nextClampedDay = day.clamp(1, nextMonthLastDay.day).toInt();
    return DateTime(nextMonth.year, nextMonth.month, nextClampedDay);
  } catch (e) {
    debugPrint('자동이체 다음 실행일 계산 오류: $e');
    return DateTime(now.year, now.month + 1, 1);
  }
}
