/// 관리자 댓글 관리 화면
/// 모든 게시물의 댓글을 조회하고, 검색 및 삭제 기능을 제공합니다.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminCommentsScreen extends StatelessWidget {
  const AdminCommentsScreen({super.key});

  Future<String> _fetchWriterName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['Name'] ?? '알 수 없음';
      }
      return '알 수 없음';
    } catch (e) {
      debugPrint('Error fetching writer name: $e');
      return '오류 발생';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('댓글 관리'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '댓글 검색',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // 검색 기능 구현
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('검색'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community')
                    .snapshots(),
                builder: (context, postsSnapshot) {
                  if (postsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!postsSnapshot.hasData || postsSnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('게시물이 없습니다.'));
                  }

                  final posts = postsSnapshot.data!.docs;
                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, postIndex) {
                      final post = posts[postIndex];
                      final postData = post.data() as Map<String, dynamic>;
                      
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('community')
                            .doc(post.id)
                            .collection('comments')
                            .orderBy('CreatedAt', descending: true)
                            .snapshots(),
                        builder: (context, commentsSnapshot) {
                          if (commentsSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!commentsSnapshot.hasData || commentsSnapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final comments = commentsSnapshot.data!.docs;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '게시물: ${postData['title'] ?? '제목 없음'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              ...comments.map((comment) {
                                final data = comment.data() as Map<String, dynamic>;
                                final timestamp = data['CreatedAt'] as Timestamp;
                                final dateTime = timestamp.toDate();
                                final formattedDate = DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
                                final writerUserId = data['writerUserid'] as String?;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(data['Comment'] ?? ''),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        FutureBuilder<String>(
                                          future: writerUserId != null ? _fetchWriterName(writerUserId) : Future.value('알 수 없음'),
                                          builder: (context, nameSnapshot) {
                                            if (nameSnapshot.connectionState == ConnectionState.waiting) {
                                              return const Text('작성자: 로딩 중...');
                                            }
                                            return Text('작성자: ${nameSnapshot.data ?? '알 수 없음'}');
                                          },
                                        ),
                                        Text('작성일: $formattedDate'),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        // 삭제 확인 다이얼로그
                                        final bool? confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('댓글 삭제'),
                                              content: const Text('이 댓글을 삭제하시겠습니까?'),
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
                                            // 댓글 삭제
                                            await comment.reference.delete();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('댓글이 삭제되었습니다.')),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('오류가 발생했습니다: $e')),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        },
                      );
                    },
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