import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final querySnapshot = await _firestore.collection('Users').get();
      
      setState(() {
        _users = querySnapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'email': data['email'] ?? '이메일 없음',
                'displayName': data['Name'] ?? data['displayName'] ?? '이름 없음',
                'createdAt': data['CreatedAt'] ?? data['createdAt'],
                'age': data['Age']?.toString() ?? '미기입',
                'phone': data['PNum'] ?? '미기입',
                'gender': _getGenderText(data['Sex']),
                'userId': data['userId'] ?? doc.id,
              };
            })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사용자 목록을 불러오는 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    
    final searchLower = _searchQuery.toLowerCase();
    return _users.where((user) {
      final email = user['email']?.toString().toLowerCase() ?? '';
      final displayName = user['displayName']?.toString().toLowerCase() ?? '';
      
      // 이메일 또는 이름으로 검색
      return email.contains(searchLower) || 
             displayName.contains(searchLower) ||
             email.split('@').first.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '이메일 또는 이름으로 검색',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _isLoading = true;
                    });
                    _loadUsers();
                  },
                  tooltip: '새로고침',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildUserList(),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '알 수 없음';
    try {
      if (timestamp is Timestamp) {
        return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
      } else if (timestamp is String) {
        return timestamp;
      }
      return '알 수 없음';
    } catch (e) {
      return '알 수 없음';
    }
  }

  String _getGenderText(dynamic gender) {
    if (gender == null) return '미기입';
    if (gender is String) {
      return {'M': '남성', 'F': '여성', 'male': '남성', 'female': '여성'}[gender] ?? gender;
    }
    return gender.toString();
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Text('표시할 회원이 없습니다.'),
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final email = user['email'] ?? '이메일 없음';
        final displayName = user['displayName'] ?? '이름 없음';
        final phone = user['phone'] ?? '미기입';
        final age = user['age'] ?? '미기입';
        final gender = user['gender'] ?? '미기입';
        final createdAt = _formatDate(user['createdAt']);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text('$displayName (${user['userId']})'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📧 $email'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('📱 $phone', style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    Text('👤 $gender', style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    Text('🎂 $age세', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('📅 가입일: $createdAt', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            onTap: () {
              // Show user details in a dialog
              _showUserDetails(user);
            },
          ),
        );
      },
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['displayName'] ?? '사용자 정보'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('이메일', user['email'] ?? '없음'),
              _buildDetailRow('이름', user['displayName'] ?? '없음'),
              _buildDetailRow('가입일', 
                user['createdAt'] != null 
                  ? (user['createdAt'] as Timestamp).toDate().toString().substring(0, 19)
                  : '알 수 없음'
              ),
              const SizedBox(height: 16),
              const Text('추가 정보', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              _buildDetailRow('UID', user['id'] ?? '없음'),
              _buildDetailRow('이메일 인증 여부', 
                user['emailVerified'] == true ? '예' : '아니오'),
              _buildDetailRow('마지막 로그인', 
                user['lastSignInTime']?.toString() ?? '알 수 없음'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
