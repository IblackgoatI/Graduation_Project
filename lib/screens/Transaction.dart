class Transaction {
  final String id;
  final String type; // '수입' 또는 '지출'
  final double amount;
  final DateTime date;
  final String merchant;
  final String category;
  final String paymentMethod;
  final String memo;
  final List<String> tags;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.merchant,
    this.category = '미분류',
    this.paymentMethod = '선택하세요',
    this.memo = '',
    this.tags = const [],
  });
}