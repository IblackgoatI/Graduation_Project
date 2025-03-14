import 'package:flutter/material.dart';
import 'transaction.dart';

class TransactionProvider with ChangeNotifier {
  final List<FinancialTransaction> _transactions = [];

  List<FinancialTransaction> get transactions => _transactions;

  // 수입과 지출의 총합 계산
  double get totalIncome => _transactions
      .where((transaction) => transaction.type == '수입')
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get totalExpense => _transactions
      .where((transaction) => transaction.type == '지출')
      .fold(0, (sum, transaction) => sum + transaction.amount);

  // 거래 추가
  void addTransaction(FinancialTransaction transaction) {
    _transactions.add(transaction);
    notifyListeners(); // 상태 변경 알림
  }

  void setTransactions(List<FinancialTransaction> newTransactions) {
    transactions.clear();  // 기존 리스트를 비움
    transactions.addAll(newTransactions);  // 새 트랜잭션을 추가
    notifyListeners();
  }

  void removeTransaction(String id) {
    _transactions.removeWhere((transaction) => transaction.id == id);
    notifyListeners();
  }

  // 특정 날짜의 거래 내역 가져오기
  List<FinancialTransaction> getTransactionsForDay(DateTime day) {
    return _transactions.where((transaction) {
      return transaction.date.year == day.year &&
          transaction.date.month == day.month &&
          transaction.date.day == day.day;
    }).toList();
  }
}