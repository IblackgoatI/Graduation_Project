import 'package:flutter/material.dart';

class NotloginAddTransactionScreen extends StatelessWidget {
  const NotloginAddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가계부 작성'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: '거래처'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: '금액'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField(
              items: const [
                DropdownMenuItem(value: '수입', child: Text('수입')),
                DropdownMenuItem(value: '지출', child: Text('지출')),
              ],
              onChanged: (value) {},
              decoration: const InputDecoration(labelText: '분류'),
            ),
            ElevatedButton(
              onPressed: () {
                // 저장 로직 추가
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}