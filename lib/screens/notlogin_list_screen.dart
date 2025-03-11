import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart'; // TransactionProvider import
import 'transaction.dart'; // Transaction 클래스 import
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // 로케일 초기화를 위해 추가

class NotloginListScreen extends StatefulWidget {
  const NotloginListScreen({super.key});

  @override
  _NotloginListScreenState createState() => _NotloginListScreenState();
}

class _NotloginListScreenState extends State<NotloginListScreen> {
  bool _showTags = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR', null); // 한국어 로케일 초기화
  }

  @override
  Widget build(BuildContext context) {
    final transactions = Provider.of<TransactionProvider>(context).transactions;

    // 날짜별로 그룹화하기
    Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in transactions) {
      String formattedDate = DateFormat('d일 EEEE', 'ko_KR').format(transaction.date);
      if (!groupedTransactions.containsKey(formattedDate)) {
        groupedTransactions[formattedDate] = [];
      }
      groupedTransactions[formattedDate]!.add(transaction);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text(
                '태그 표시',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                decoration: BoxDecoration(
                  color: _showTags ? Colors.green : Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: _showTags ? Colors.green : Colors.grey,
                    width: 1.0,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showTags = !_showTags;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.check,
                      size: 18.0,
                      color: _showTags ? Colors.white : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: groupedTransactions.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      entry.key, // 날짜 한 번만 출력
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  ...entry.value.map((transaction) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(26),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 40,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  transaction.merchant,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  '${transaction.type == '수입' ? '+' : '-'}${transaction.amount.toString()}원',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: transaction.type == '수입' ? const Color(0xFF73AD13) : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 태그 표시
                          if (_showTags && transaction.tags.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Wrap(
                                spacing: 8.0,
                                children: transaction.tags.map((tag) {
                                  return Chip(
                                    label: Text(tag),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}