import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_posts_screen.dart';
import 'my_comments_screen.dart';
import 'account_list_screen.dart';

class AccountModel {
  final String bank;
  final String account;
  final int balance;
  final String owner;
  final bool certify;
  final String pnum;
  final String userId;

  AccountModel({
    required this.bank,
    required this.account,
    required this.balance,
    required this.owner,
    required this.certify,
    required this.pnum,
    required this.userId,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      bank: map['bank'] ?? '',
      account: map['account'] ?? '',
      balance: (map['balance'] as num?)?.toInt() ?? 0,
      owner: map['owner'] ?? '',
      certify: map['certify'] ?? false,
      pnum: map['pnum'] ?? '',
      userId: map['userId'] ?? '',
    );
  }
}

class MyPageScreen extends StatefulWidget {
  final User? user;
  const MyPageScreen({super.key, this.user});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = true;
  AccountModel? _accountModel;
  bool _accountLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadAccountInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Firestore에서 사용자 정보 가져오기
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? '사용자';
            _userEmail = currentUser.email ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _userName = currentUser.displayName ?? '사용자';
            _userEmail = currentUser.email ?? '';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('사용자 정보 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAccountInfo() async {
    try {
      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('assets')
            .where('userId', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final accountData = snapshot.docs.first.data() as Map<String, dynamic>;
          setState(() {
            _accountModel = AccountModel.fromMap(accountData);
            _accountLoading = false;
          });
        } else {
          setState(() {
            _accountLoading = false;
          });
        }
      } else {
        setState(() {
          _accountLoading = false;
        });
      }
    } catch (e) {
      debugPrint('계좌 정보 로드 오류: $e');
      setState(() {
        _accountLoading = false;
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
          '마이페이지',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF73AD13),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildUserProfileCard(),
                  const SizedBox(height: 16.0),
                  GestureDetector(
                    onTap: () async {
                      // 로그인 유저 정보 얻기
                      User? currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccountListScreen(userId: currentUser.uid),
                          ),
                        );
                      }
                    },
                    child: _buildAccountInfoCard(),
                  ),
                  const SizedBox(height: 16.0),
                  _buildMenuSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserProfileCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 프로필 이미지
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF73AD13).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.person,
                size: 40,
                color: Color(0xFF73AD13),
              ),
            ),
            const SizedBox(height: 16.0),
            // 사용자 이름
            Text(
              _userName.isNotEmpty ? _userName : '사용자',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8.0),
            // 이메일
            Text(
              _userEmail.isNotEmpty ? _userEmail : '이메일 정보 없음',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 내 계좌 정보 카드
  Widget _buildAccountInfoCard() {
    if (_accountLoading) {
      return const Card(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator(color: Color(0xFF73AD13))),
        ),
      );
    }
    if (_accountModel == null) {
      return Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Center(
            child: Text('연결된 계좌가 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ),
        ),
      );
    }
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Color(0xFF73AD13)),
                const SizedBox(width: 8),
                Text('내 계좌 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 28),
            Text('은행명  :  ${_accountModel!.bank}', style: TextStyle(fontSize: 15)),
            const SizedBox(height: 6),
            Text('계좌번호:  ${_accountModel!.account}', style: TextStyle(fontSize: 15)),
            const SizedBox(height: 6),
            Text('예금주  :  ${_accountModel!.owner}', style: TextStyle(fontSize: 15)),
            const SizedBox(height: 6),
            Text('현재잔액:  ${_formatAmount(_accountModel!.balance)} 원', style: TextStyle(fontSize: 15)),
            if (!_accountModel!.certify)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text('※ 인증되지 않은 계좌입니다.', style: TextStyle(color: Colors.red[400], fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
  String _formatAmount(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuCard(
          title: '내가 쓴 글',
          icon: Icons.article,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyPostsScreen(user: widget.user),
              ),
            );
          },
        ),
        const SizedBox(height: 12.0),
        _buildMenuCard(
          title: '내가 쓴 댓글',
          icon: Icons.comment,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyCommentsScreen(user: widget.user),
              ),
            );
          },
        ),
        const SizedBox(height: 12.0),
        _buildMenuCard(
          title: '계정 설정',
          icon: Icons.settings,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('계정 설정 기능은 준비 중입니다')),
            );
          },
        ),
        const SizedBox(height: 12.0),
        _buildMenuCard(
          title: '알림 설정',
          icon: Icons.notifications,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('알림 설정 기능은 준비 중입니다')),
            );
          },
        ),
        const SizedBox(height: 12.0),
        _buildMenuCard(
          title: '고객 지원',
          icon: Icons.support_agent,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('고객 지원 기능은 준비 중입니다')),
            );
          },
        ),
        const SizedBox(height: 12.0),
        _buildMenuCard(
          title: '개인정보 처리방침',
          icon: Icons.privacy_tip,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('개인정보 처리방침 기능은 준비 중입니다')),
            );
          },
        ),
        const SizedBox(height: 12.0),
        _buildMenuCard(
          title: '이용약관',
          icon: Icons.description,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이용약관 기능은 준비 중입니다')),
            );
          },
        ),
        const SizedBox(height: 24.0),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF73AD13).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF73AD13),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.logout,
            color: Colors.red,
            size: 20,
          ),
        ),
        title: const Text(
          '로그아웃',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
        onTap: () {
          _showLogoutDialog();
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
