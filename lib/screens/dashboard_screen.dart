import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DNTS Command Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.black, height: 1),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: const [
            _DashboardCard(title: 'Asset Overview'),
            _DashboardCard(title: 'Network Status'),
            _DashboardCard(title: 'Schedule Today'),
            _DashboardCard(title: 'Sit-In Activity'),
            _DashboardCard(title: 'Violations'),
            _DashboardCard(title: 'Energy Usage'),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  const _DashboardCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Colors.black54,
              ),
            ),
            const Spacer(),
            Container(width: 32, height: 2, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
