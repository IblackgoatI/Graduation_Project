import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCommentsScreen extends StatelessWidget {
  const AdminCommentsScreen({super.key});

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
                stream: FirebaseFirestore.instance.collection('community').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('게시물이 없습니다.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final post = snapshot.data!.docs[index];
                      final postData = post.data() as Map<String, dynamic>;
                      
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('community')
                            .doc(post.id)
                            .collection('comments')
                            .orderBy('CreatedAt', descending: true)
                            .snapshots(),
                        builder: (context, commentSnapshot) {
                          if (commentSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!commentSnapshot.hasData || commentSnapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final comments = commentSnapshot.data!.docs;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '게시물: ${postData['author_name'] ?? '제목 없음'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              ...comments.map((comment) {
                                final commentData = comment.data() as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(commentData['Comment'] ?? '내용 없음'),
                                    subtitle: Text('작성자: ${commentData['writerName'] ?? '알 수 없음'}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('댓글 삭제'),
                                            content: const Text('이 댓글을 삭제하시겠습니까?'),
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
                                                      .collection('comments')
                                                      .doc(comment.id)
                                                      .delete();
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('삭제'),
                                              ),
                                            ],
                                          ),
                                        );
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