import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'expense_report_write_screen.dart';

// 파이 차트 커스텀 페인터
class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> sections;
  
  PieChartPainter({required this.sections});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    var startAngle = -90 * 3.14 / 180; // -90도(12시 방향)에서 시작
    
    // 파이 차트 섹션 그리기
    for (var section in sections) {
      final percent = (section['percent'] as num).toDouble();
      final sweepAngle = percent * 2 * 3.14; // 라디안 각도로 변환
      
      final paint = Paint()
        ..color = section['color'] as Color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // 섹션 경계선 그리기
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        strokePaint,
      );
      
      startAngle += sweepAngle;
    }
    
    // 가운데 흰색 원 그리기 (도넛 차트 효과)
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PieChartPainter) {
      return oldDelegate.sections != sections;
    }
    return true;
  }
}

class ExpenseReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> postData;

  const ExpenseReportDetailScreen({
    Key? key,
    required this.postData,
  }) : super(key: key);

  @override
  State<ExpenseReportDetailScreen> createState() => _ExpenseReportDetailScreenState();
}

class _ExpenseReportDetailScreenState extends State<ExpenseReportDetailScreen> {
  String _authorName = '';
  bool _isLoading = false;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmittingComment = false;
  bool _isSubmittingReply = false;
  List<Map<String, dynamic>> _comments = [];
  int _commentLength = 0;
  int _replyLength = 0;
  String? _selectedCommentId; // 대댓글 작성 중인 댓글의 ID

  @override
  void initState() {
    super.initState();
    _loadAuthorInfo();
    _loadComments();
    _commentController.addListener(_updateCommentLength);
    _replyController.addListener(_updateReplyLength);
  }
  
  @override
  void dispose() {
    _commentController.removeListener(_updateCommentLength);
    _replyController.removeListener(_updateReplyLength);
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _updateCommentLength() {
    setState(() {
      _commentLength = _commentController.text.length;
    });
  }

  void _updateReplyLength() {
    setState(() {
      _replyLength = _replyController.text.length;
    });
  }

  Future<void> _loadAuthorInfo() async {
    try {
      // 먼저 author_name 필드가 있는지 확인
      if (widget.postData.containsKey('author_name') && widget.postData['author_name'] != null) {
        setState(() {
          _authorName = widget.postData['author_name'];
          _isLoading = false;
        });
        return;
      }
      
      // author_name이 없는 경우에만 Firebase에서 가져오기
      if (widget.postData['userId'] != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.postData['userId'])
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['Name'] != null) {
            setState(() {
              _authorName = userData['Name'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('작성자 정보 로드 중 오류 발생: $e');
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // 댓글 목록 불러오기
  Future<void> _loadComments() async {
    try {
      final String postId = widget.postData['id'];
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('community')
          .doc(postId)
          .collection('comments')
          .orderBy('CreatedAt', descending: false)
          .get();
      
      final List<Map<String, dynamic>> commentsList = [];
      for (var doc in commentsSnapshot.docs) {
        Map<String, dynamic> comment = doc.data();
        comment['id'] = doc.id;
        
        // 댓글 작성자 정보 가져오기
        if (comment['writerUserid'] != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(comment['writerUserid'])
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null && userData['Name'] != null) {
              comment['writerName'] = userData['Name'];
            } else {
              comment['writerName'] = '익명';
            }
          } else {
            comment['writerName'] = '익명';
          }
        } else {
          comment['writerName'] = '익명';
        }

        // 대댓글 가져오기
        final repliesSnapshot = await FirebaseFirestore.instance
            .collection('community')
            .doc(postId)
            .collection('comments')
            .doc(doc.id)
            .collection('replies')
            .orderBy('CreatedAt', descending: false)
            .get();

        List<Map<String, dynamic>> replies = [];
        for (var replyDoc in repliesSnapshot.docs) {
          Map<String, dynamic> reply = replyDoc.data();
          reply['id'] = replyDoc.id;

          // 대댓글 작성자 정보 가져오기
          if (reply['writerUserid'] != null) {
            final replyUserDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(reply['writerUserid'])
                .get();

            if (replyUserDoc.exists) {
              final userData = replyUserDoc.data();
              if (userData != null && userData['Name'] != null) {
                reply['writerName'] = userData['Name'];
              } else {
                reply['writerName'] = '익명';
              }
            } else {
              reply['writerName'] = '익명';
            }
          } else {
            reply['writerName'] = '익명';
          }

          replies.add(reply);
        }

        comment['replies'] = replies;
        commentsList.add(comment);
      }
      
      if (mounted) {
        setState(() {
          _comments = commentsList;
        });
      }
    } catch (e) {
      print('댓글 로드 중 오류 발생: $e');
    }
  }
  
  // 댓글 작성 함수
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글 내용을 입력해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_commentController.text.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글은 100자를 초과할 수 없습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmittingComment = true;
    });
    
    try {
      final String postId = widget.postData['id'];
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요합니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // 댓글 데이터 생성
      final commentData = {
        'Comment': _commentController.text.trim(),
        'writerUserid': currentUser.uid,
        'CreatedAt': Timestamp.now(),
      };
      
      // Firestore에 댓글 저장
      await FirebaseFirestore.instance
          .collection('community')
          .doc(postId)
          .collection('comments')
          .add(commentData);
      
      // 댓글 입력창 초기화
      _commentController.clear();
      
      // 댓글 목록 새로고침
      await _loadComments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글이 작성되었습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('댓글 작성 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글 작성 중 오류가 발생했습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  // 게시글 삭제 함수
  Future<void> _deletePost(BuildContext context) async {
    try {
      // 삭제 확인 다이얼로그 표시
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('게시글 삭제'),
            content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
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

      // 사용자가 삭제를 확인한 경우
      if (confirm == true) {
        // 현재 로그인한 사용자 확인
        final User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('로그인이 필요합니다.');
        }

        // 게시글 작성자 확인
        if (widget.postData['userId'] != currentUser.uid) {
          throw Exception('자신의 게시글만 삭제할 수 있습니다.');
        }

        // Firestore에서 게시글 삭제
        await FirebaseFirestore.instance
            .collection('community')
            .doc(widget.postData['id'])
            .delete();

        // 연결된 소비 리포트도 함께 삭제 (report_id 필드가 있는 경우)
        if (widget.postData.containsKey('report_id') && widget.postData['report_id'] != null) {
          String reportId = widget.postData['report_id'];
          await FirebaseFirestore.instance
              .collection('report')
              .doc(reportId)
              .delete();
        }

        // 삭제 성공 메시지 표시
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('게시글이 삭제되었습니다.')),
          );
          
          // 커뮤니티 화면으로 돌아가기
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 게시글 수정 함수
  Future<void> _editPost(BuildContext context) async {
    try {
      // 수정 화면으로 이동
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExpenseReportWriteScreen(
            isEditing: true,
            postData: widget.postData,
          ),
        ),
      );

      // 수정이 완료되면 화면 새로고침
      if (result == true && mounted) {
        // 게시글 데이터 새로고침
        final updatedPost = await FirebaseFirestore.instance
            .collection('community')
            .doc(widget.postData['id'])
            .get();

        if (updatedPost.exists) {
          setState(() {
            widget.postData.clear();
            widget.postData.addAll(updatedPost.data()!);
            widget.postData['id'] = updatedPost.id;
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 댓글 삭제 함수
  Future<void> _deleteComment(String commentId) async {
    try {
      // 삭제 확인 다이얼로그 표시
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('댓글 삭제'),
            content: const Text('정말로 이 댓글을 삭제하시겠습니까?'),
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
        // Firestore에서 댓글 삭제
        await FirebaseFirestore.instance
            .collection('community')
            .doc(widget.postData['id'])
            .collection('comments')
            .doc(commentId)
            .delete();

        // 댓글 목록 새로고침
        await _loadComments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글이 삭제되었습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 댓글 수정 함수
  Future<void> _editComment(Map<String, dynamic> comment) async {
    final TextEditingController editController = TextEditingController(text: comment['Comment']);
    int editLength = comment['Comment'].length; // 초기 글자수 설정
    
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder( // StatefulBuilder 추가
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('댓글 수정'),
                content: TextField(
                  controller: editController,
                  onChanged: (value) {
                    setState(() {
                      editLength = value.length;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요 (최대 100자)',
                    border: const OutlineInputBorder(),
                    counterText: '$editLength/100',
                    counterStyle: TextStyle(
                      color: editLength >= 100 ? Colors.red : Colors.grey,
                    ),
                  ),
                  maxLength: 100,
                  maxLines: 3,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (editLength > 100) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('댓글은 100자를 초과할 수 없습니다'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop(editController.text);
                    },
                    child: const Text('수정'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result != null && result.trim().isNotEmpty) {
        if (result.length > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('댓글은 100자를 초과할 수 없습니다'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // Firestore에서 댓글 수정
        await FirebaseFirestore.instance
            .collection('community')
            .doc(widget.postData['id'])
            .collection('comments')
            .doc(comment['id'])
            .update({
          'Comment': result.trim(),
          'updated_at': Timestamp.now(),
        });

        // 댓글 목록 새로고침
        await _loadComments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글이 수정되었습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 댓글 메뉴 표시 함수
  void _showCommentMenu(Map<String, dynamic> comment) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != comment['writerUserid']) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('수정'),
                onTap: () {
                  Navigator.pop(context);
                  _editComment(comment);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteComment(comment['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 대댓글 작성 함수
  Future<void> _submitReply(String commentId) async {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대댓글 내용을 입력해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_replyController.text.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대댓글은 100자를 초과할 수 없습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingReply = true;
    });

    try {
      final String postId = widget.postData['id'];
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요합니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 대댓글 데이터 생성
      final replyData = {
        'Comment': _replyController.text.trim(),
        'writerUserid': currentUser.uid,
        'CreatedAt': Timestamp.now(),
      };

      // Firestore에 대댓글 저장
      await FirebaseFirestore.instance
          .collection('community')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .add(replyData);

      // 대댓글 입력창 초기화
      _replyController.clear();
      setState(() {
        _selectedCommentId = null;
      });

      // 댓글 목록 새로고침
      await _loadComments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대댓글이 작성되었습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('대댓글 작성 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대댓글 작성 중 오류가 발생했습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReply = false;
        });
      }
    }
  }

  // 대댓글 삭제 함수
  Future<void> _deleteReply(String commentId, String replyId) async {
    try {
      // 삭제 확인 다이얼로그 표시
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('대댓글 삭제'),
            content: const Text('정말로 이 대댓글을 삭제하시겠습니까?'),
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
        // Firestore에서 대댓글 삭제
        await FirebaseFirestore.instance
            .collection('community')
            .doc(widget.postData['id'])
            .collection('comments')
            .doc(commentId)
            .collection('replies')
            .doc(replyId)
            .delete();

        // 댓글 목록 새로고침
        await _loadComments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('대댓글이 삭제되었습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 대댓글 수정 함수
  Future<void> _editReply(String commentId, Map<String, dynamic> reply) async {
    final TextEditingController editController = TextEditingController(text: reply['Comment']);
    int editLength = reply['Comment'].length;

    try {
      final result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('대댓글 수정'),
                content: TextField(
                  controller: editController,
                  onChanged: (value) {
                    setState(() {
                      editLength = value.length;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '대댓글을 입력하세요 (최대 100자)',
                    border: const OutlineInputBorder(),
                    counterText: '$editLength/100',
                    counterStyle: TextStyle(
                      color: editLength >= 100 ? Colors.red : Colors.grey,
                    ),
                  ),
                  maxLength: 100,
                  maxLines: 3,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (editLength > 100) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('대댓글은 100자를 초과할 수 없습니다'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop(editController.text);
                    },
                    child: const Text('수정'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result != null && result.trim().isNotEmpty) {
        // Firestore에서 대댓글 수정
        await FirebaseFirestore.instance
            .collection('community')
            .doc(widget.postData['id'])
            .collection('comments')
            .doc(commentId)
            .collection('replies')
            .doc(reply['id'])
            .update({
          'Comment': result.trim(),
          'updated_at': Timestamp.now(),
        });

        // 댓글 목록 새로고침
        await _loadComments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('대댓글이 수정되었습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 대댓글 메뉴 표시 함수
  void _showReplyMenu(String commentId, Map<String, dynamic> reply) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != reply['writerUserid']) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('수정'),
                onTap: () {
                  Navigator.pop(context);
                  _editReply(commentId, reply);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteReply(commentId, reply['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 좋아요 토글 함수
  Future<void> _toggleLike(String commentId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다')),
        );
        return;
      }

      final commentRef = FirebaseFirestore.instance
          .collection('community')
          .doc(widget.postData['id'])
          .collection('comments')
          .doc(commentId);

      final commentDoc = await commentRef.get();
      final likes = List<String>.from(commentDoc.data()?['likes'] ?? []);

      if (likes.contains(currentUser.uid)) {
        // 좋아요 취소
        likes.remove(currentUser.uid);
      } else {
        // 좋아요 추가
        likes.add(currentUser.uid);
      }

      await commentRef.update({'likes': likes});
      await _loadComments(); // 댓글 목록 새로고침
    } catch (e) {
      print('좋아요 토글 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아요 처리 중 오류가 발생했습니다')),
      );
    }
  }

  // 댓글 카드 위젯 수정
  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final timestamp = comment['CreatedAt'] as Timestamp;
    final dateTime = timestamp.toDate();
    final formattedDate = DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
    final replies = comment['replies'] as List<Map<String, dynamic>>? ?? [];
    final likes = List<String>.from(comment['likes'] ?? []);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked = currentUser != null && likes.contains(currentUser.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 댓글 작성자 및 시간
          Row(
            children: [
              Text(
                comment['writerName'] ?? '익명',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (FirebaseAuth.instance.currentUser?.uid == comment['writerUserid'])
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () => _showCommentMenu(comment),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 댓글 내용
          Text(
            comment['Comment'] ?? '',
            style: const TextStyle(
              fontSize: 14,
            ),
          ),

          // 좋아요 및 답글 버튼 행
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 좋아요 버튼
              TextButton.icon(
                onPressed: () => _toggleLike(comment['id']),
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: isLiked ? Colors.red : Colors.grey[600],
                ),
                label: Text(
                  likes.length.toString(),
                  style: TextStyle(
                    color: isLiked ? Colors.red : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 16),
              // 답글 버튼
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCommentId = _selectedCommentId == comment['id'] ? null : comment['id'];
                    _replyController.clear();
                  });
                },
                icon: const Icon(Icons.reply, size: 16),
                label: Text(_selectedCommentId == comment['id'] ? '취소' : '답글'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          // 대댓글 작성 폼 - 세로 크기 줄이기
          if (_selectedCommentId == comment['id'])
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: '답글을 입력하세요',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        counterText: '$_replyLength/100',
                        counterStyle: TextStyle(
                          color: _replyLength >= 100 ? Colors.red : Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                      maxLength: 100,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _isSubmittingReply
                        ? null
                        : () => _submitReply(comment['id']),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                    child: _isSubmittingReply
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('확인', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),

          // 대댓글 목록
          if (replies.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8, left: 16),
              child: Column(
                children: replies.map<Widget>((reply) {
                  final replyTimestamp = reply['CreatedAt'] as Timestamp;
                  final replyDateTime = replyTimestamp.toDate();
                  final replyFormattedDate = DateFormat('yyyy.MM.dd HH:mm').format(replyDateTime);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              reply['writerName'] ?? '익명',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              replyFormattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                            if (FirebaseAuth.instance.currentUser?.uid == reply['writerUserid'])
                              IconButton(
                                icon: const Icon(Icons.more_vert, size: 16),
                                onPressed: () => _showReplyMenu(comment['id'], reply),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reply['Comment'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // report_data는 이제 {'categories': ..., 'total_expense': ..., 'month_text': ...} 구조를 가짐
    final reportDataMap = widget.postData['report_data'] as Map<String, dynamic>?;
    
    // totalAmount는 report_data 안의 total_expense 사용
    final totalAmount = reportDataMap?['total_expense'] ?? 0;
    final formattedAmount = NumberFormat('#,###').format(totalAmount);
    
    // month는 report_data 안의 month_text 또는 postData의 Month 필드 사용
    final reportMonthText = reportDataMap?['month_text'] ?? widget.postData['Month'] ?? DateFormat('M월').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('소비 리포트 게시판'),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        actions: [
          // 현재 로그인한 사용자가 게시글 작성자인 경우에만 수정/삭제 버튼 표시
          if (FirebaseAuth.instance.currentUser?.uid == widget.postData['userId']) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editPost(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deletePost(context),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    const Text(
                      '제목',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.postData['Heading'] ?? '제목 없음',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 내용
                    const Text(
                      '내용',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.postData['Content'] ?? '내용 없음',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 작성자 이름
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '작성자: $_authorName',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // 소비 리포트 카드
                    _buildExpenseReportCard(reportDataMap, reportMonthText, formattedAmount), // reportDataMap과 reportMonthText 전달
                    
                    const SizedBox(height: 24),
                    
                    // 댓글 섹션 헤더
                    const Text(
                      '댓글',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // 댓글 입력
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: '댓글을 입력하세요 (최대 100자)',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                counterText: '$_commentLength/100',
                                counterStyle: TextStyle(
                                  color: _commentLength >= 100 ? Colors.red : Colors.grey,
                                ),
                              ),
                              maxLength: 100,
                              maxLines: 3,
                            ),
                          ),
                          TextButton(
                            onPressed: _isSubmittingComment ? null : _submitComment,
                            child: _isSubmittingComment
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('확인'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 댓글 목록
                    _comments.isEmpty
                        ? Center(
                            child: Text(
                              '첫 번째 댓글을 남겨보세요',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              return _buildCommentCard(_comments[index]);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildExpenseReportCard(Map<String, dynamic>? reportData, String displayMonth, String displayFormattedAmount) {
    if (reportData == null) {
      return const Center(
        child: Text('소비 리포트 데이터가 없습니다'),
      );
    }

    // totalAmount는 reportData에서 직접 가져오거나, 이미 계산된 displayFormattedAmount 사용 가능
    // final totalAmount = reportData['total_expense'] ?? 0;
    // final formattedAmount = NumberFormat('#,###').format(totalAmount);
    
    final categories = reportData['categories'] as Map<String, dynamic>? ?? {};
    // final month = widget.postData['Month'] ?? '1'; // displayMonth 사용으로 변경
    
    // 카테고리 데이터를 금액 기준으로 정렬
    List<MapEntry<String, dynamic>> sortedCategories = [];
    if (categories.isNotEmpty) {
      sortedCategories = categories.entries.toList()
        ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    }

    // 파이 차트용 색상 정의
    final colors = [
      Colors.red[300]!,
      Colors.yellow[300]!,
      Colors.purple[300]!,
      Colors.blue[300]!,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 소비 리포트 헤더
          Row(
            children: [
              Text(
                '${_authorName}님의 $displayMonth 소비 리포트', // displayMonth 사용
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 파이 차트 - 중앙 배치
          Center(
            child: Container(
              height: 160,
              width: 160,
              child: _buildPieChart(reportData, categories, displayMonth, displayFormattedAmount), // displayMonth, displayFormattedAmount 전달
            ),
          ),
          const SizedBox(height: 24),
          
          // 카테고리 헤더
          const Row(
            children: [
              Text(
                '카테고리별 지출',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 카테고리 목록 - 스크롤 형식으로 변경
          Container(
            constraints: BoxConstraints(
              // 화면 크기에 맞게 동적으로 높이 제한
              maxHeight: MediaQuery.of(context).size.height * 0.25,
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero, // 패딩 제거
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final entry = sortedCategories[index];
                final color = colors[index % colors.length];
                final categoryName = entry.key;
                final amount = (entry.value is int) ? entry.value.toDouble() : (entry.value as num).toDouble();
                final totalReportExpense = reportData['total_expense'] ?? 0; // reportData에서 총액 다시 참조
                final percent = totalReportExpense > 0 ? amount / totalReportExpense * 100 : 0;
                
                // 카테고리 아이콘 매핑
                IconData categoryIcon;
                switch (categoryName) {
                  case '식비':
                    categoryIcon = Icons.restaurant;
                    break;
                  case '문화생활':
                  case '문화 생활':
                    categoryIcon = Icons.videogame_asset;
                    break;
                  case '쇼핑':
                    categoryIcon = Icons.shopping_bag;
                    break;
                  case '교통':
                    categoryIcon = Icons.directions_car;
                    break;
                  case '미용':
                  case '뷰티':
                    categoryIcon = Icons.spa;
                    break;
                  case '의료':
                    categoryIcon = Icons.medical_services;
                    break;
                  case '음행':
                  case '카페':
                    categoryIcon = Icons.local_cafe;
                    break;
                  default:
                    categoryIcon = Icons.category;
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // 카테고리 아이콘
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withAlpha(50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          categoryIcon,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // 카테고리 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${percent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 금액
                      SizedBox(
                        width: 100, // 금액 영역의 최대 너비 설정
                        child: FittedBox(
                          alignment: Alignment.centerRight,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${NumberFormat('#,###').format(amount)}원',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 파이 차트 위젯
  Widget _buildPieChart(Map<String, dynamic> reportData, Map<String, dynamic> categories, String displayMonth, String displayFormattedAmount) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              '${displayMonth} 총 소비', // displayMonth 사용
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${displayFormattedAmount}원', // displayFormattedAmount 사용
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    // 총 금액
    final totalAmount = reportData['total_expense'] ?? 0; // reportData에서 직접 가져옴
    
    // 카테고리 데이터 변환
    List<Map<String, dynamic>> sections = [];
    
    // 색상 정의
    final colors = [
      Colors.red[300]!,
      Colors.yellow[300]!,
      Colors.purple[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.teal[300]!,
      Colors.pink[300]!,
    ];
    
    int colorIndex = 0;
    categories.forEach((key, value) {
      final amount = (value is int) ? value.toDouble() : (value as num).toDouble();
      final percent = totalAmount > 0 ? amount / totalAmount : 0.0;
      
      sections.add({
        'name': key,
        'color': colors[colorIndex % colors.length],
        'percent': percent,
        'amount': amount,
      });
      
      colorIndex++;
    });
    
    // 비율 순으로 섹션 정렬
    sections.sort((a, b) => ((b['percent'] as num).toDouble()).compareTo((a['percent'] as num).toDouble()));
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: CustomPaint(
            size: const Size(120, 120),
            painter: PieChartPainter(sections: sections),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${displayMonth} 총 소비: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${displayFormattedAmount}원',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}