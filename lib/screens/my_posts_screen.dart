import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'expense_report_detail_screen.dart';

class MyPostsScreen extends StatefulWidget {
  final User? user;
  const MyPostsScreen({super.key, this.user});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myPosts = [];

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  Future<void> _loadMyPosts() async {
    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // 현재 사용자가 작성한 게시글 조회
        QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
            .collection('community')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('created_at', descending: true)
            .get();

        List<Map<String, dynamic>> postsList = [];
        for (var doc in postsSnapshot.docs) {
          Map<String, dynamic> postData = doc.data() as Map<String, dynamic>;
          postData['id'] = doc.id;
          postsList.add(postData);
        }

        setState(() {
          _myPosts = postsList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('내가 쓴 글 로드 오류: $e');
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
          '내가 쓴 글',
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
          : _myPosts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMyPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _myPosts.length,
                    itemBuilder: (context, index) {
                      final post = _myPosts[index];
                      return _buildPostCard(post);
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
            Icons.post_add,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '작성한 글이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '커뮤니티에서 첫 번째 글을 작성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final title = post['Heading'] ?? '제목 없음';
    final content = post['content'] ?? '';
    final createdAt = post['created_at'];
    final authorName = post['author_name'] ?? '익명';
    
    DateTime postDate;
    if (createdAt is Timestamp) {
      postDate = createdAt.toDate();
    } else if (createdAt is String) {
      postDate = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else {
      postDate = DateTime.now();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          // 게시글 상세 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseReportDetailScreen(
                postData: post,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF73AD13).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: const Text(
                      '소비 리포트',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF73AD13),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _timeAgo(postDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4.0),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    authorName,
                    style: TextStyle(
                      fontSize: 13,
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
