/// 관리자 게시물 관리 화면 
/// 모든 게시물을 조회하고, 검색 및 삭제 기능을 제공합니다.
library;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../expense_report_detail_screen.dart';
import 'admin_layout.dart';

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentMenu: '게시물 관리',
      title: '게시물 관리',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '게시물 검색',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text;
                    });
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('검색'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('게시물이 없습니다.'));
                  }
                  
                  var posts = snapshot.data!.docs;
                  
                  // 검색 필터링
                  if (_searchQuery.isNotEmpty) {
                    posts = posts.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final heading = (data['Heading'] ?? '').toString().toLowerCase();
                      final content = (data['Content'] ?? '').toString().toLowerCase();
                      final author = (data['author_name'] ?? '').toString().toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      return heading.contains(query) || 
                             content.contains(query) || 
                             author.contains(query);
                    }).toList();
                  }

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('제목')),
                        DataColumn(label: Text('작성자')),
                        DataColumn(label: Text('작성일')),
                        DataColumn(label: Text('작업')),
                      ],
                      rows: posts.map((post) {
                        final data = post.data() as Map<String, dynamic>;
                        final timestamp = data['created_at'] as Timestamp?;
                        final dateTime = timestamp?.toDate() ?? DateTime.now();
                        final formattedDate = DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
                        final authorName = data['author_name'] ?? '알 수 없음';
                        final heading = data['Heading'] ?? '제목 없음';

                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: Text(
                                  heading,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(authorName)),
                            DataCell(Text(formattedDate)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, size: 18),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ExpenseReportDetailScreen(
                                            postData: {...data, 'id': post.id},
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('게시물 삭제'),
                                          content: const Text('이 게시물을 삭제하시겠습니까?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('community')
                                                    .doc(post.id)
                                                    .delete();
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('게시물이 삭제되었습니다.')),
                                                  );
                                                }
                                              },
                                              child: const Text('삭제', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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