import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'expense_report_detail_screen.dart';

class MyCommentsScreen extends StatefulWidget {
  final User? user;
  const MyCommentsScreen({super.key, this.user});

  @override
  State<MyCommentsScreen> createState() => _MyCommentsScreenState();
}

class _MyCommentsScreenState extends State<MyCommentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myComments = [];

  @override
  void initState() {
    super.initState();
    _loadMyComments();
  }

  Future<void> _loadMyComments() async {
    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
            .collection('community')
            .get();

        List<Map<String, dynamic>> commentsList = [];

        for (var postDoc in postsSnapshot.docs) {
          // postData는 상세 이동 위해 반드시 넘김
          final postData = postDoc.data() as Map<String, dynamic>;
          final postId = postDoc.id;

          // 각 게시글의 댓글
          QuerySnapshot commentsSnapshot = await FirebaseFirestore.instance
              .collection('community')
              .doc(postDoc.id)
              .collection('comments')
              .orderBy('CreatedAt', descending: true)
              .get();

          for (var commentDoc in commentsSnapshot.docs) {
            Map<String, dynamic> commentData = commentDoc.data() as Map<String, dynamic>;
            commentData['id'] = commentDoc.id;
            commentData['postId'] = postId;
            commentData['postData'] = postData;

            // 내가 쓴 댓글
            if (commentData['writerUserid'] == currentUser.uid) {
              commentsList.add({...commentData, 'isReply': false});
            }

            // 대댓글까지 순회
            QuerySnapshot repliesSnapshot = await FirebaseFirestore.instance
                .collection('community')
                .doc(postDoc.id)
                .collection('comments')
                .doc(commentDoc.id)
                .collection('replies')
                .get();

            for (var replyDoc in repliesSnapshot.docs) {
              Map<String, dynamic> replyData = replyDoc.data() as Map<String, dynamic>;
              replyData['id'] = replyDoc.id;
              replyData['postId'] = postId;
              replyData['commentId'] = commentDoc.id;
              replyData['postData'] = postData;

              // 내가 쓴 대댓글
              if (replyData['writerUserid'] == currentUser.uid) {
                commentsList.add({...replyData, 'isReply': true});
              }
            }
          }
        }

        // 작성일 최신순 정렬(댓글과 replies 모두 공통)
        commentsList.sort((a, b) {
          DateTime dateA = (a['CreatedAt'] as Timestamp).toDate();
          DateTime dateB = (b['CreatedAt'] as Timestamp).toDate();
          return dateB.compareTo(dateA);
        });
        setState(() {
          _myComments = commentsList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('내가 쓴 댓글 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '내가 쓴 댓글',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF73AD13),
              ),
            )
          : _myComments.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMyComments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _myComments.length,
                    itemBuilder: (context, index) {
                      final comment = _myComments[index];
                      return _buildCommentCard(comment);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.comment,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '작성한 댓글이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '커뮤니티에서 첫 번째 댓글을 작성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final content = comment['Comment'] ?? '';
    final createdAt = comment['CreatedAt'] as Timestamp;
    final postData = (comment['postData'] as Map<String, dynamic>? ?? {})..['id'] = comment['postId'] ?? '';
    final postTitle = postData['Heading'] ?? '제목 없음';
    final postAuthor = postData['author_name'] ?? '익명';
    final isReply = comment['isReply'] == true;
    DateTime commentDate = createdAt.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseReportDetailScreen(
                postData: postData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 대댓글이면 표식
              if (isReply)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Text(
                        '(대댓글)',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              // 원글 정보
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.article,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '원글',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      postTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by $postAuthor',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _timeAgo(commentDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
