import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부린이님', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              Text('5:13 PM', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Icon(Icons.access_time, size: 16),
              SizedBox(width: 4),
              Icon(Icons.bluetooth, size: 16),
              SizedBox(width: 4),
              Icon(Icons.wifi, size: 16),
              SizedBox(width: 4),
              Icon(Icons.signal_cellular_4_bar, size: 16),
              SizedBox(width: 4),
              Icon(Icons.battery_full, size: 16),
              SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 탭바
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: Colors.black,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: '게시판'),
              Tab(text: '지출 비교'),
            ],
          ),

          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 게시판 탭
                _buildBoardContent(),

                // 지출 비교 탭
                const Center(child: Text('지출 비교 내용')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 월간 절약왕 TOP 3
            _buildTopSaverSection(),
            const SizedBox(height: 24),

            // 20대 부린이님을 위한 커뮤니티
            _buildCommunitySection(),
            const SizedBox(height: 24),

            // 소비 리포트 공유하기 버튼
            _buildShareButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSaverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '월간 절약왕 TOP 3',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRankingItem(1, '대부린', '😊'),
        _buildRankingItem(2, '부린이', '🙂'),
        _buildRankingItem(3, '부린2', '😎'),
      ],
    );
  }

  Widget _buildRankingItem(int rank, String name, String emoji) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BC34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('정보 보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '20대 부린이님을 위한 커뮤니티',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPostItem(
          profileImage: 'assets/profile1.jpg',
          nickname: '보노보노',
          timeAgo: '11시간 전',
          content: '이번 달 식비 절약 성공! 여러분도 해보세요 😄\n'
              '인스타해요. 머리부터 발끝까지 소비를 줄여보려고 콘텐츠 새봤고 실\n'
              '단체할인, 셋끼니 다 잘짜 골라서 14만 9천원에 완료했습니다.\n'
              '➡️ 마지막 식비 절약 꿀팁\n'
              '1.집 주식만 미리 계획하기\n'
              '✓ 효율적으로 외식까지도 배달용 서비스는 절 중이기 위해...',
        ),
        const SizedBox(height: 16),
        _buildPostItem(
          profileImage: 'assets/profile2.jpg',
          nickname: '케이마',
          timeAgo: '13시간 전',
          content: '이번 달 용돈비용 절약 성공! 👏🏼\n'
              '이번 달엔 조금 더 신경써서 소비했는데 마음으로 계획대로 쭉이\n'
              '했어요. 월리가 낮아지려면 습관화 해야겠죠!\n'
              '✨ 이번 달 가계부 정리 방법\n'
              '1.돈과 가치까지 기다리기🔍\n'
              '✓ 사고 싶은 제품이 있었지만 바로 지르지 않고, 세일 기간을...',
        ),
      ],
    );
  }

  Widget _buildPostItem({
    required String profileImage,
    required String nickname,
    required String timeAgo,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(profileImage),
                onBackgroundImageError: (exception, stackTrace) {
                  // 이미지 로드 실패 시 기본 아이콘 표시
                  debugPrint('이미지 로드 오류: $exception');
                },
                child: const Icon(Icons.person), // 기본 아이콘
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '더보기',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8BC34A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          '소비 리포트 공유하기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}