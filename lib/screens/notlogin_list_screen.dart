import 'package:flutter/material.dart';

class NotloginListScreen extends StatefulWidget {
  const NotloginListScreen({super.key});

  @override
  _NotloginListScreenState createState() => _NotloginListScreenState();
}

class _NotloginListScreenState extends State<NotloginListScreen> {
  // 태그 표시 상태를 전체적으로 관리하는 변수
  bool _showTags = true;

  @override
  Widget build(BuildContext context) {
    // 임시 데이터
    final List<Map<String, dynamic>> transactions = [
      {
        'date': '15일 수요일',
        'items': [
          {'description': 'KFC 부천역', 'amount': -22000, 'tags': ['#KFC', '#차간', '#점심']},
          {'description': '스타벅스 부천역점', 'amount': -7800, 'tags': ['#스벅', '#카페']},
        ],
      },
      {
        'date': '14일 화요일',
        'items': [
          {'description': '용돈', 'amount': 50000, 'tags': ['#1월말']},
          {'description': '사나푸드 부천대점', 'amount': -5200, 'tags': []},
        ],
      },
      {
        'date': '13일 월요일',
        'items': [
          {'description': '교통카드', 'amount': -49800, 'tags': []},
        ],
      },
    ];

    return Column(
      children: [
        // 상단 헤더 부분 (태그 표시 체크박스)
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
        // 내역 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final date = transactions[index]['date'];
              final items = transactions[index]['items'] as List<dynamic>;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 표시
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  // 거래 내역
                  ...items.map((item) {
                    final description = item['description'];
                    final amount = item['amount'];
                    final tags = (item['tags'] as List<dynamic>).cast<String>();

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
                          // 거래 설명과 금액
                          Container(
                            height: 40,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  '${amount >= 0 ? '+' : ''}${amount.toString()}원',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: amount >= 0 ? Color(0xFF73AD13) : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 태그 - 전체 태그 표시 설정에 따라 표시하고 애니메이션 적용
                          if (tags.isNotEmpty)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _showTags
                                  ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: AnimatedOpacity(
                                  opacity: _showTags ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Wrap(
                                    spacing: 4.0,
                                    children: tags.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              )
                                  : Container(),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}