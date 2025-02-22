//로그인 안한 메인 화면
import 'package:flutter/material.dart';

class MainScreenNotLogin extends StatelessWidget {
  const MainScreenNotLogin({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('금융 대시보드'),
      ),
      backgroundColor: const Color(0xFFF8F8F8), //메인 화면 배경색
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAccountCard(),
            const SizedBox(height: 16.0),
            _buildTotalAssetsCard(),
            const SizedBox(height: 16.0),
            _buildMonthlySpendingCard(),
            const SizedBox(height: 16.0),
            _buildMonthlyReportCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "입출금 계좌",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text(
              "계좌 미연결",
              style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8.0),
            const Text(
              "아직 자산이 연결되지 않았습니다.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF73AD13), // 버튼 색상을 73AD13으로 설정
                  minimumSize: const Size(400, 50), // 버튼의 크기 지정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // 버튼 모서리 둥글기
                  ),
                ),
                onPressed: () {
                  // 계좌 연결하기 버튼 동작
                },
                child: const Text(
                  "계좌 연결하러 가기",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAssetsCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "총 자산",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text(
              "자산 미연결",
              style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8.0),
            const Text(
              "아직 자산이 연결되지 않았습니다.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF73AD13), // 버튼 색상을 73AD13으로 설정
                  minimumSize: const Size(400, 50), // 버튼의 크기 지정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // 버튼 모서리 둥글기
                  ),
                ),
                onPressed: () {
                  // 계좌 연결하기 버튼 동작
                },
                child: const Text(
                  "계좌 연결하러 가기",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySpendingCard() {
    return SizedBox(
      width: double.infinity, // 부모 위젯의 너비에 맞춤
      child: Card(
        color: Colors.white, // 카드뷰 배경색을 FFFFFF(흰색)로 설정
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 기존 카드뷰와 동일한 패딩 적용
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "이번 달 지출 >",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              const Text(
                "0원",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20.0), // 섹션 간 간격
              const Text(
                "나의 고정지출 >",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              const Text(
                "0원",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMonthlyReportCard() {
    return SizedBox(
      width: double.infinity, // 부모 위젯의 너비에 맞춤
      child: Card(
        color: Colors.white, // 카드뷰 배경색을 FFFFFF(흰색)로 설정
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "부린이님의 1월 소비 리포트",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20.0),
              // 소비 그래프 영역
              Container(
                height: 150, // 그래프 높이
                color: Colors.grey[200], // 그래프 배경색 (임시)
                child: const Center(
                  child: Text(
                    "소비 그래프 영역",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              // 1월 총 소비 (부드러운 밑줄 추가)
              const Center(
                child: Text(
                  "1월 총 소비 0원",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.underline, // 밑줄 추가
                    decorationStyle: TextDecorationStyle.solid, // 부드러운 밑줄
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              // "아직 이번 달 소비 내역이 없습니다." (가운데 정렬)
              const Center(
                child: Text(
                  "아직 이번 달 소비 내역이 없습니다.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}