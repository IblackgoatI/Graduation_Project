import 'package:flutter/material.dart';

class AssetScreen extends StatefulWidget {
  const AssetScreen({Key? key}) : super(key: key);

  @override
  _AssetScreenState createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  TextEditingController _accountController = TextEditingController();
  String? _selectedBank;

  final List<Map<String, dynamic>> _banks = [
    {'name': 'KB국민은행', 'icon': 'assets/banks/KB_Square.png'},
    {'name': 'NH농협은행', 'icon': 'assets/banks/NH_Square.png'},
    {'name': '카카오뱅크', 'icon': 'assets/banks/Kakao_Square.png'},
    {'name': '신한은행', 'icon': 'assets/banks/Shinhan_Square.png'},
    {'name': '지역농협', 'icon': 'assets/banks/LocalNH_Square.png'},
    {'name': '하나은행', 'icon': 'assets/banks/Hana_Square.png'},
    {'name': '새마을금고', 'icon': 'assets/banks/MG_Square.png'},
    {'name': '우리은행', 'icon': 'assets/banks/Woori_Square.png'},
    {'name': 'IBK기업은행', 'icon': 'assets/banks/IBK_Square.png'},
    {'name': '케이뱅크', 'icon': 'assets/banks/Kbank_Square.png'},
    {'name': '신협은행', 'icon': 'assets/banks/Sinhyup_Square.png'},
    {'name': 'SC제일은행', 'icon': 'assets/banks/SC_Square.png'},
    {'name': '수협은행', 'icon': 'assets/banks/Sh_Square.png'},
    {'name': '수협중앙회', 'icon': 'assets/banks/ShMid_Square.png'},
    {'name': '광주은행', 'icon': 'assets/banks/Gwangju_Square.png'},
    {'name': '전북은행', 'icon': 'assets/banks/Jeonbuk_Square.png'},
    {'name': '제주은행', 'icon': 'assets/banks/Jeju_Square.png'},
    {'name': '한국산업은행', 'icon': 'assets/banks/KDB_Square.png'},
    {'name': 'BNK부산은행', 'icon': 'assets/banks/Busan_Square.png'},
    {'name': 'BNK경남은행', 'icon': 'assets/banks/Kyungnam_Square.png'},
    {'name': 'iM뱅크', 'icon': 'assets/banks/IM_Square.png'},
  ];

  void _showBankSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 높이 조절 가능하게 설정
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, // 전체 화면의 70% 높이
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "은행 목록",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      shrinkWrap: true, // 스크롤 가능하게 설정
                      physics: NeverScrollableScrollPhysics(), // GridView 자체 스크롤 비활성화
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 4개씩 가로 배치
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1 / 1.2,
                      ),
                      itemCount: _banks.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBank = _banks[index]['name'];
                            });
                            Navigator.pop(context);
                          },
                          child: Column(
                            children: [
                              Image.asset(
                                _banks[index]['icon'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 4),
                              Text(
                                _banks[index]['name'],
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "자산 본인인증",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "자산을 연결하기위한 본인인증이에요.\n주로 사용하는 은행 계좌를 입력해주세요.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "계좌번호를 입력 해주세요.",
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _showBankSelection,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedBank ?? "은행을 선택 해주세요.",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {},
                    child: Text("나중에 하기", style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedBank != null ? Color(0xFF49AD13) : Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _selectedBank != null ? () {} : null,
                    child: Text("확인하기", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
