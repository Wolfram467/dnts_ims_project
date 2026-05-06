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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AssetOverviewSection(),
            const SizedBox(height: 24),
            // Remaining widgets in a grid for other dashboard modules
            GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _DashboardCard(title: 'Network Status'),
                _DashboardCard(title: 'Schedule Today'),
                _DashboardCard(title: 'Sit-In Activity'),
                _DashboardCard(title: 'Violations'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetOverviewSection extends StatelessWidget {
  const _AssetOverviewSection();

  // Hard limits
  static const int totalDesks = 332;
  static const int totalComponents = 1992; // 332 * 6 components

  // Mock deployed counts (to be connected to real data later)
  static const int deployedDesks = 300;
  static const int deployedComponents = 1750;

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
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ASSET OVERVIEW',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            _buildGlobalCapacity(),
            const SizedBox(height: 48),
            const Text(
              'COMPONENT DISTRIBUTION (6 SLOTS PER DESK)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildComponentBreakdown(),
            const SizedBox(height: 48),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LABORATORY SATURATION',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      _buildLaboratorySaturation(),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STATUS & HEALTH',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusGlance(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalCapacity() {
    return Row(
      children: [
        Expanded(child: _buildCapacityGauge('TOTAL WORKSTATIONS', deployedDesks, totalDesks, 'Desks Available')),
        const SizedBox(width: 32),
        Expanded(child: _buildCapacityGauge('TOTAL COMPONENTS', deployedComponents, totalComponents, 'Component Slots Open')),
      ],
    );
  }

  Widget _buildCapacityGauge(String title, int current, int max, String remainingLabel) {
    final double percentage = current / max;
    final int remaining = max - current;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black54)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$current',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w300, height: 1.0),
              ),
              const SizedBox(width: 8),
              Text(
                '/ $max',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.black54, height: 1.5),
              ),
              const Spacer(),
              Text(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: const Color(0xFFE5E7EB),
            color: Colors.black,
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text('$remaining $remainingLabel', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildComponentBreakdown() {
    // 6 components per desk: System Unit, Monitor, Keyboard, Mouse, SSD, AVR
    return Row(
      children: [
        Expanded(child: _buildComponentCard('System Unit', 300, totalDesks, Icons.computer)),
        const SizedBox(width: 12),
        Expanded(child: _buildComponentCard('Monitor', 290, totalDesks, Icons.desktop_windows)),
        const SizedBox(width: 12),
        Expanded(child: _buildComponentCard('Keyboard', 295, totalDesks, Icons.keyboard)),
        const SizedBox(width: 12),
        Expanded(child: _buildComponentCard('Mouse', 280, totalDesks, Icons.mouse)),
        const SizedBox(width: 12),
        Expanded(child: _buildComponentCard('SSD', 298, totalDesks, Icons.storage)),
        const SizedBox(width: 12),
        Expanded(child: _buildComponentCard('AVR', 285, totalDesks, Icons.power)),
      ],
    );
  }

  Widget _buildComponentCard(String name, int deployed, int max, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('$deployed / $max', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: deployed / max,
            backgroundColor: const Color(0xFFE5E7EB),
            color: Colors.black87,
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildLaboratorySaturation() {
    return Column(
      children: [
        _buildLabBar('Lab 1', 40, 48),
        const SizedBox(height: 12),
        _buildLabBar('Lab 2', 48, 48),
        const SizedBox(height: 12),
        _buildLabBar('Lab 3', 12, 46),
        const SizedBox(height: 12),
        _buildLabBar('Lab 4', 45, 46),
        const SizedBox(height: 12),
        _buildLabBar('Lab 5', 48, 48),
        const SizedBox(height: 12),
        _buildLabBar('Lab 6', 30, 48),
        const SizedBox(height: 12),
        _buildLabBar('Lab 7', 48, 48),
      ],
    );
  }

  Widget _buildLabBar(String labName, int deployed, int max) {
    final double percentage = deployed / max;
    final bool isFull = deployed == max;

    return Row(
      children: [
        SizedBox(width: 50, child: Text(labName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        const SizedBox(width: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: const Color(0xFFE5E7EB),
              color: isFull ? Colors.green.shade700 : Colors.black87,
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 80,
          child: Text(
            isFull ? '$deployed/$max (FULL)' : '$deployed/$max',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isFull ? FontWeight.bold : FontWeight.w500,
              color: isFull ? Colors.green.shade700 : Colors.black54,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusGlance() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          _buildStatusRow(Icons.check_circle, Colors.green.shade700, 'Active / Healthy', 1430),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          _buildStatusRow(Icons.build, Colors.orange.shade700, 'Under Maintenance', 15),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          _buildStatusRow(Icons.warning, Colors.red.shade700, 'Reported Missing', 5),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, Color color, String label, int count) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
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
