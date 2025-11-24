/// 관리자 퀴즈 관리 화면
/// 관리자가 일일 경제 퀴즈를 추가, 수정, 삭제할 수 있는 기능을 제공합니다.
library;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'admin_layout.dart';

class AdminQuizManagementScreen extends StatefulWidget {
  const AdminQuizManagementScreen({super.key});

  @override
  State<AdminQuizManagementScreen> createState() => _AdminQuizManagementScreenState();
}

class _AdminQuizManagementScreenState extends State<AdminQuizManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (index) => TextEditingController());
  final TextEditingController _pointsController = TextEditingController();
  int? _correctAnswerIndex; // 0-indexed
  bool _isLoading = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _addQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_correctAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정답을 선택해주세요.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool quizAddedSuccessfully = false; // 퀴즈 추가 성공 여부 플래그

    try {
      await FirebaseFirestore.instance.collection('daily_quizzes').add({
        'category': _categoryController.text.trim(),
        'question': _questionController.text.trim(),
        'options': _optionControllers.map((controller) => controller.text.trim()).toList(),
        'correctAnswerIndex': _correctAnswerIndex,
        'points': int.parse(_pointsController.text.trim()),
        'createdAt': Timestamp.now(),
      });

      quizAddedSuccessfully = true; // 성공 플래그 설정
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('퀴즈가 성공적으로 추가되었습니다!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error adding quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('퀴즈 추가 중 오류가 발생했습니다. 오류: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        // 로딩 상태를 먼저 해제하여 Form 위젯이 다시 화면에 나타나도록 합니다.
        setState(() {
          _isLoading = false;
        });

        // 퀴즈 추가가 성공했고, 위젯이 여전히 마운트된 상태라면 폼을 리셋합니다.
        // setState로 _isLoading이 false로 변경된 후, 다음 프레임에 Form 위젯이 그려집니다.
        // addPostFrameCallback을 사용하여 Form 위젯이 그려진 후 _resetForm을 호출합니다.
        if (quizAddedSuccessfully) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) { // 콜백 내에서도 mounted 확인
              _resetForm();
            }
          });
        }
      }
    }
  }

  Future<void> _deleteQuiz(String quizId) async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('퀴즈 삭제'),
          content: const Text('정말로 이 퀴즈를 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('daily_quizzes').doc(quizId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('퀴즈가 성공적으로 삭제되었습니다!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error deleting quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('퀴즈 삭제 중 오류가 발생했습니다.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _categoryController.clear();
    _questionController.clear();
    for (var controller in _optionControllers) {
      controller.clear();
    }
    _pointsController.clear();
    setState(() {
      _correctAnswerIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentMenu: '퀴즈 관리',
      title: '퀴즈 관리',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: '카테고리 (예: 주식, 부동산)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '카테고리를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        labelText: '퀴즈 질문',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '질문을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '보기 (4개 모두 입력해주세요)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextFormField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            labelText: '보기 ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '보기 ${index + 1}을(를) 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const Text(
                      '정답 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      children: List.generate(4, (index) {
                        return RadioListTile<int>(
                          title: Text('보기 ${index + 1}'),
                          value: index,
                          groupValue: _correctAnswerIndex,
                          onChanged: (int? value) {
                            setState(() {
                              _correctAnswerIndex = value;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pointsController,
                      decoration: const InputDecoration(
                        labelText: '획득 포인트',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '획득 포인트를 입력해주세요.';
                        }
                        if (int.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                '퀴즈 추가하기',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32), // Add spacing before quiz list
                    const Text(
                      '등록된 퀴즈 목록',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('daily_quizzes').orderBy('createdAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('오류: ${snapshot.error}');
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('등록된 퀴즈가 없습니다.'));
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot quizDoc = snapshot.data!.docs[index];
                            Map<String, dynamic> quizData = quizDoc.data() as Map<String, dynamic>;
                            List<String> options = List<String>.from(quizData['options'] ?? []);
                            int correctAnswerIndex = quizData['correctAnswerIndex'] ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '카테고리: ${quizData['category'] ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${quizData['points'] ?? 0}P',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '질문: ${quizData['question'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: List.generate(options.length, (optIndex) {
                                        return Text(
                                          '${optIndex + 1}. ${options[optIndex]}${optIndex == correctAnswerIndex ? ' (정답)' : ''}',
                                          style: TextStyle(
                                            color: optIndex == correctAnswerIndex ? Colors.green : Colors.black87,
                                            fontWeight: optIndex == correctAnswerIndex ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _deleteQuiz(quizDoc.id),
                                        icon: const Icon(Icons.delete, color: Colors.white),
                                        label: const Text('삭제', style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 