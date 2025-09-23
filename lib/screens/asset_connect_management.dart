import 'package:flutter/material.dart';

class AssetConnectManagementScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? accounts;
  final String? accountType;

  const AssetConnectManagementScreen({
    super.key,
    this.accounts,
    this.accountType,
  });

  @override
  State<AssetConnectManagementScreen> createState() => _AssetConnectManagementScreenState();
}

class _AssetConnectManagementScreenState extends State<AssetConnectManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연결 관리'),
        backgroundColor: const Color(0xFF73AD13),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          '연결 관리 화면\n(개발 예정)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

