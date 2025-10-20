import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 계좌 모델 재정의 (간단히 복붙, 향후 통합 가능)
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

class AccountListScreen extends StatelessWidget {
  final String userId;
  const AccountListScreen({super.key, required this.userId});

  Future<List<AccountModel>> _fetchAccounts() async {
    final query = await FirebaseFirestore.instance
        .collection('assets')
        .where('userId', isEqualTo: userId)
        .get();
    return query.docs
        .map((doc) => AccountModel.fromMap(doc.data()))
        .toList();
  }

  String _formatAmount(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '내 계좌 목록',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.5,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<AccountModel>>(
        future: _fetchAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF73AD13)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('연결된 계좌가 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            );
          }
          final accounts = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: accounts.length,
            separatorBuilder: (context, idx) => const SizedBox(height: 16),
            itemBuilder: (context, idx) {
              final acc = accounts[idx];
              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance, color: Color(0xFF73AD13)),
                          const SizedBox(width: 8),
                          Text(
                            acc.bank,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      Text('계좌번호 :  ${acc.account}', style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 5),
                      Text('예금주   :  ${acc.owner}', style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 5),
                      Text('잔액      :  ${_formatAmount(acc.balance)} 원', style: const TextStyle(fontSize: 15)),
                      if (!acc.certify)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('※ 인증되지 않은 계좌입니다.', style: TextStyle(color: Colors.red[400], fontSize: 13)),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
