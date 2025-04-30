import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'expense_report_screen.dart';
import 'expense_report_detail_screen.dart';

class ExpenseReportWriteScreen extends StatefulWidget {
  const ExpenseReportWriteScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseReportWriteScreen> createState() => _ExpenseReportWriteScreenState();
}

class _ExpenseReportWriteScreenState extends State<ExpenseReportWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  bool _isUploading = false;
  bool _formChanged = false; // 폼 변경 여부
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _userName = '부린이님';
  Map<String, dynamic>? _reportData; // 소비 리포트 데이터 저장용 변수
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    
    // 텍스트 필드 리스너 추가
    _titleController.addListener(_updateFormState);
    _contentController.addListener(_updateFormState);
  }
  
  @override
  void dispose() {
    _titleController.removeListener(_updateFormState);
    _contentController.removeListener(_updateFormState);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      if (_currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(_currentUser!.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['Name'] != null) {
            setState(() {
              _userName = userData['Name'];
            });
          }
        }
      }
    } catch (e) {
      print('사용자 정보 로드 중 오류 발생: $e');
    }
  }
  
  // 소비 리포트 화면으로 이동
  Future<void> _navigateToExpenseReport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpenseReportScreen(),
      ),
    );
    
    // 리포트 데이터가 반환되면 저장
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _reportData = result;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('소비 리포트가 불러와졌습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // 리포트 글 업로드
  Future<void> _uploadReport() async {
    // 제목이나 내용이 비어있는지 확인
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목과 내용을 모두 입력해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // 소비 리포트가 첨부되지 않았다면 사용자에게 확인
    if (_reportData == null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('소비 리포트 미첨부'),
          content: const Text('소비 리포트가 첨부되지 않았습니다. 계속 진행하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('계속 진행'),
            ),
          ],
        ),
      );
      
      if (confirm != true) {
        return;
      }
    }
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      if (_currentUser != null) {
        // 현재 월 정보 가져오기
        String currentMonth = DateFormat('M').format(DateTime.now());
        
        // 문서 ID를 위한 랜덤 숫자 생성
        final random = DateTime.now().millisecondsSinceEpoch;
        
        // 게시글 데이터 준비
        final postData = {
          'Heading': _titleController.text.trim(),
          'Content': _contentController.text.trim(),
          'userId': _currentUser!.uid,
          'author_name': _userName,
          'Month': currentMonth,
          'writeNumber': random.toString(),
          'report_data': _reportData,
          'created_at': Timestamp.now(),
        };
        
        // Firestore의 community 컬렉션에 데이터 저장
        final docRef = await FirebaseFirestore.instance.collection('community').add(postData);
        
        // 저장된 문서 ID 가져오기
        final savedDoc = await docRef.get();
        final savedData = savedDoc.data() ?? {};
        savedData['id'] = docRef.id;
        
        // 업로드 후 상세 화면으로 이동
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseReportDetailScreen(
                postData: savedData,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('리포트 업로드 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리포트 업로드 중 오류가 발생했습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // 폼 상태 업데이트
  void _updateFormState() {
    setState(() {
      _formChanged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentMonth = DateFormat('M월').format(DateTime.now());
    
    // 제목과 내용이 비어있는지 확인하는 변수
    bool isFormValid = _titleController.text.trim().isNotEmpty && 
                       _contentController.text.trim().isNotEmpty;
                       
    // 작성하기 버튼 활성화 조건 - 제목과 내용은 필수, 소비 리포트는 필수 아님
    bool canSubmit = isFormValid;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('소비 리포트 공유하기'),
        backgroundColor: Colors.grey[50],
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 메인 콘텐츠
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 레이블
                  const Text(
                    '제목',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 제목 입력 필드
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: '제목을 입력해주세요',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLength: 50, // 제목 최대 길이
                  ),
                  const SizedBox(height: 16),
                  
                  // 내용 레이블
                  const Text(
                    '내용',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 내용 입력 필드
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: '내용을 입력해주세요',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: 10, // 여러 줄 입력 가능
                    maxLength: 500, // 내용 최대 길이
                  ),
                  const SizedBox(height: 24),
                  
                  // 소비 리포트 불러오기 버튼
                  Center(
                    child: Column(
                      children: [
                        // 소비 리포트 상태 표시
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _reportData != null ? Colors.green.withAlpha(26) : Colors.grey.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _reportData != null ? Icons.check_circle : Icons.info_outline,
                                size: 16,
                                color: _reportData != null ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _reportData != null 
                                    ? '소비 리포트가 첨부되었습니다' 
                                    : '소비 리포트를 첨부해주세요',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _reportData != null ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 소비 리포트 불러오기 버튼
                        InkWell(
                          onTap: _navigateToExpenseReport,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload_outlined,
                                  size: 32,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '불러오기',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // 하단 버튼을 위한 여백
                ],
              ),
            ),
          ),
          
          // 업로드 중 로딩 표시
          if (_isUploading)
            Container(
              color: Colors.black.withAlpha(77),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      
      // 하단 버튼 영역
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(51),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 취소 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide.none,
                ),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 16),
            
            // 내용 내기 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: _isUploading ? null : (canSubmit ? _uploadReport : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide.none,
                ),
                child: const Text('작성하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 