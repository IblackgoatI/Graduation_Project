import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionDetailScreen extends StatefulWidget {
  final FinancialTransaction transaction;

  const TransactionDetailScreen({Key? key, required this.transaction}) : super(key: key);

  @override
  TransactionDetailScreenState createState() => TransactionDetailScreenState();
}

class TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    // 금액 표시 형식 설정
    String amountText = '${widget.transaction.type == '수입' ? '+' : '-'}${NumberFormat('#,###').format(widget.transaction.amount)}원';
    String formattedDate = DateFormat('yyyy년 M월 d일 a h:mm', 'ko_KR')
        .format(widget.transaction.date)
        .replaceAll('AM', '오전')
        .replaceAll('PM', '오후');

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 140.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(51),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    // 금액 표시
                    Center(
                      child: Text(
                        amountText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.transaction.type == '수입' ? Colors.green : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    _buildDetailRow('분류', widget.transaction.type),
                    const SizedBox(height: 24.0),
                    _buildDetailRow('카테고리', widget.transaction.category),
                    const SizedBox(height: 24.0),
                    _buildDetailRow('거래처', widget.transaction.merchant),
                    const SizedBox(height: 24.0),
                    _buildDetailRow('결제수단', widget.transaction.paymentMethod.isNotEmpty ? widget.transaction.paymentMethod : '없음'),
                    const SizedBox(height: 24.0),
                    _buildDetailRow('날짜', formattedDate),
                    const SizedBox(height: 24.0),
                    _buildDetailRow('메모', widget.transaction.memo.isNotEmpty ? widget.transaction.memo : '없음'),
                    const SizedBox(height: 24.0),
                    _buildTagsSection(widget.transaction.tags),
                    const SizedBox(height: 40.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // 수정 화면으로 이동하는 코드
                              // Navigator.push(...);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text('수정'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _showDeleteConfirmation();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text('삭제'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 상세 정보 행 위젯
  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // 태그 섹션 위젯
  Widget _buildTagsSection(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '태그',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          children: tags.map((tag) {
            return Chip(
              label: Text(tag),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('거래 내역 삭제'),
          content: const Text('이 거래 내역을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                _deleteTransaction();
                Navigator.pop(context); // 다이얼로그 닫기
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // 거래 내역 삭제 메서드
  Future<void> _deleteTransaction() async {
    try {
      // Firestore에서 해당 문서 삭제
      await _firestore.collection('ledger').doc(widget.transaction.id).delete();

      // 화면 닫기
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래 내역이 삭제되었습니다.')),
        );
        Navigator.pop(context, true); // true를 반환하여 목록 화면에서 새로고침을 트리거
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
}