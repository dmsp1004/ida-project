import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userType = authProvider.userType;

    return Scaffold(
      appBar: AppBar(
        title: const Text('아이다 - 홈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 계정 유형 표시
            _buildUserTypeCard(userType),
            const SizedBox(height: 24),

            // 관리자 계정인 경우 관리자 전용 메뉴
            if (userType == 'ADMIN')
              _buildAdminMenu(context)
            // 일반 계정인 경우 일반 사용자 메뉴
            else
              _buildUserMenu(context, userType),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(String? userType) {
    late String typeText;
    late Color typeColor;

    if (userType == 'ADMIN') {
      typeText = '관리자 계정';
      typeColor = Colors.red;
    } else if (userType == 'PARENT') {
      typeText = '부모님 계정';
      typeColor = Colors.blue;
    } else {
      typeText = '시터 계정';
      typeColor = Colors.green;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: typeColor.withOpacity(0.5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              userType == 'ADMIN'
                  ? Icons.admin_panel_settings
                  : userType == 'PARENT'
                  ? Icons.family_restroom
                  : Icons.child_care,
              size: 64,
              color: typeColor,
            ),
            const SizedBox(height: 16),
            Text(
              typeText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '로그인에 성공했습니다!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMenuButton(
          context,
          title: '사용자 관리',
          icon: Icons.people,
          color: Colors.purple,
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('사용자 관리 기능 구현 예정입니다')));
          },
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          title: '매칭 관리',
          icon: Icons.supervised_user_circle,
          color: Colors.orange,
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('매칭 관리 기능 구현 예정입니다')));
          },
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          title: '통계 보기',
          icon: Icons.bar_chart,
          color: Colors.teal,
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('통계 기능 구현 예정입니다')));
          },
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          title: '서비스 설정',
          icon: Icons.settings,
          color: Colors.indigo,
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('서비스 설정 기능 구현 예정입니다')));
          },
        ),
      ],
    );
  }

  Widget _buildUserMenu(BuildContext context, String? userType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMenuButton(
          context,
          title: '프로필 보기',
          icon: Icons.person,
          color: Colors.blue,
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('프로필 보기 기능 구현 예정입니다')));
          },
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          title: userType == 'PARENT' ? '시터 찾기' : '일자리 찾기',
          icon: userType == 'PARENT' ? Icons.search : Icons.work,
          color: Colors.green,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${userType == 'PARENT' ? '시터 찾기' : '일자리 찾기'} 기능 구현 예정입니다',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          title: '내 예약 관리',
          icon: Icons.calendar_today,
          color: Colors.amber,
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('예약 관리 기능 구현 예정입니다')));
          },
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
