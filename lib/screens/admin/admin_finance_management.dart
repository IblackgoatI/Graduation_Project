/// 관리자 금융상품 관리 화면
/// finance 컬렉션의 금융상품을 조회, 추가, 삭제하는 기능을 제공합니다.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'admin_layout.dart';

class AdminFinanceManagementScreen extends StatefulWidget {
  const AdminFinanceManagementScreen({super.key});

  @override
  State<AdminFinanceManagementScreen> createState() => _AdminFinanceManagementScreenState();
}

class _AdminFinanceManagementScreenState extends State<AdminFinanceManagementScreen> {
  bool _isLoading = false;

  // 금융상품 추가 함수 (Cloud Functions의 crawlFinance 함수 호출)
  Future<void> _addFinanceProducts() async {
    setState(() {
      _isLoading = true;
    });

    // 사용자에게 진행 중 메시지 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('금융상품을 추가하고 있습니다...'),
          duration: Duration(seconds: 5),
        ),
      );
    }

    try {
      // Cloud Functions의 crawlFinance 함수 호출
      const String functionUrl = 'https://asia-northeast3-graduation-5caa0.cloudfunctions.net/crawlFinance';
      
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 60), // Cloud Functions는 시간이 더 걸릴 수 있음
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
        },
      );

      // 응답 상태 코드 확인
      if (response.statusCode != 200) {
        throw Exception('Cloud Functions 호출 실패: 상태 코드 ${response.statusCode}');
      }

      // JSON 응답 파싱
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final message = responseData['message'] as String? ?? '완료';
      final processed = responseData['processed'] as List<dynamic>? ?? [];
      
      // 저장된 개수 계산
      final savedCount = processed.length;

      debugPrint('Cloud Functions 응답: $message');
      debugPrint('처리된 상품 수: $savedCount');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('금융상품 추가가 완료되었습니다 ($savedCount개)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 오류 발생 시 로그만 출력하고 사용자에게는 메시지 표시하지 않음
      debugPrint('금융상품 추가 중 오류 발생: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 금융상품 삭제 함수
  Future<void> _deleteFinanceProduct(String docId, String productName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('금융상품 삭제'),
          content: Text('해당 금융상품($productName)을 삭제하시겠습니까?'),
          actions: [
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

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('finance')
            .doc(docId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('금융상품이 삭제되었습니다.')),
          );
        }
      } catch (e) {
        // 오류 발생 시 로그만 출력하고 사용자에게는 메시지 표시하지 않음
        debugPrint('금융상품 삭제 중 오류 발생: $e');
      }
    }
  }

  // 금리 포맷팅 함수
  String _formatRate(dynamic rate) {
    if (rate == null) return '-';
    final raw = rate.toString().trim();
    if (raw.isEmpty) return '-';
    return raw.contains('%') ? raw : '$raw%';
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentMenu: '금융상품 관리',
      title: '금융상품 관리',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('finance')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    // 오류 발생 시에도 화면에 에러 메시지 표시하지 않음
                    debugPrint('금융상품 조회 중 오류 발생: ${snapshot.error}');
                    return const SizedBox.shrink();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '등록된 금융상품이 없습니다',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _addFinanceProducts,
                            icon: const Icon(Icons.add),
                            label: const Text('금융상품 추가하기'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final products = snapshot.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 첫 번째 카드에만 "금융상품 추가하기" 버튼 표시
                      if (products.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _addFinanceProducts,
                            icon: const Icon(Icons.add),
                            label: const Text('금융상품 추가하기'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final doc = products[index];
                            final data = doc.data() as Map<String, dynamic>;

                            final bankCompany = data['bankCompany']?.toString() ?? '알 수 없음';
                            final name = data['name']?.toString() ?? '상품명 없음';
                            final baseRate = _formatRate(data['base_rate']);
                            final maxRate = _formatRate(data['max_rate']);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bankCompany,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Text(
                                                '$baseRate (기본)',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Text(
                                                '$maxRate (최고)',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteFinanceProduct(
                                        doc.id,
                                        name,
                                      ),
                                      tooltip: '삭제',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

