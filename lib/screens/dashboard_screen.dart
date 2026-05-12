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
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).dividerColor, height: 1),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ASSET OVERVIEW',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            _buildGlobalCapacity(context),
            const SizedBox(height: 48),
            Text(
              'COMPONENT DISTRIBUTION (6 SLOTS PER DESK)',
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.5, 
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            _buildComponentBreakdown(context),
            const SizedBox(height: 48),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LABORATORY SATURATION',
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.5, 
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLaboratorySaturation(context),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS & HEALTH',
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.5, 
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusGlance(context),
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

  Widget _buildGlobalCapacity(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCapacityGauge(context, 'TOTAL WORKSTATIONS', deployedDesks, totalDesks, 'Desks Available')),
        const SizedBox(width: 32),
        Expanded(child: _buildCapacityGauge(context, 'TOTAL COMPONENTS', deployedComponents, totalComponents, 'Component Slots Open')),
      ],
    );
  }

  Widget _buildCapacityGauge(BuildContext context, String title, int current, int max, String remainingLabel) {
    final double percentage = current / max;
    final int remaining = max - current;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 1.5, 
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
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
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w300, 
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), 
                  height: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
            color: Theme.of(context).colorScheme.onSurface,
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            '$remaining $remainingLabel', 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w500, 
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentBreakdown(BuildContext context) {
    // 6 components per desk: System Unit, Monitor, Keyboard, Mouse, SSD, AVR
    return Row(
      children: [
        Expanded(child: _buildComponentCard(context, 'System Unit', 300, totalDesks, Icons.computer)),
        const SizedBox(width: 12),
        Expanded(child: _buildComponentCard(context, 'Monitor', 290, totalDesks, Icons.desktop_windows)),
        const SizedBox(width: 12),
        Expanded(child: _buildComponentCard(context, 'Keyboard', 295, totalDesks, Icons.keyboard)),
        const SizedBox(width: 12),
        Expanded(child: _buildComponentCard(context, 'Mouse', 280, totalDesks, Icons.mouse)),
        const SizedBox(width: 12),
        Expanded(child: _buildComponentCard(context, 'SSD', 298, totalDesks, Icons.storage)),
        const SizedBox(width: 12),
        Expanded(child: _buildComponentCard(context, 'AVR', 285, totalDesks, Icons.power)),
      ],
    );
  }

  Widget _buildComponentCard(BuildContext context, String name, int deployed, int max, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            size: 20, 
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '$deployed / $max', 
            style: TextStyle(
              fontSize: 12, 
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: deployed / max,
            backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
            color: Theme.of(context).colorScheme.onSurface,
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildLaboratorySaturation(BuildContext context) {
    return Column(
      children: [
        _buildLabBar(context, 'Lab 1', 40, 48),
        const SizedBox(height: 12),
        _buildLabBar(context, 'Lab 2', 48, 48),
        const SizedBox(height: 12),
        _buildLabBar(context, 'Lab 3', 12, 46),
        const SizedBox(height: 12),
        _buildLabBar(context, 'Lab 4', 45, 46),
        const SizedBox(height: 12),
        _buildLabBar(context, 'Lab 5', 48, 48),
        const SizedBox(height: 12),
        _buildLabBar(context, 'Lab 6', 30, 48),
        const SizedBox(height: 12),
        _buildLabBar(context, 'Lab 7', 48, 48),
      ],
    );
  }

  Widget _buildLabBar(BuildContext context, String labName, int deployed, int max) {
    final double percentage = deployed / max;
    final bool isFull = deployed == max;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = isFull 
        ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
        : Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        SizedBox(width: 50, child: Text(labName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        const SizedBox(width: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
              color: statusColor,
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
              color: isFull 
                  ? (isDark ? Colors.green.shade400 : Colors.green.shade700) 
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusGlance(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        children: [
          _buildStatusRow(
            Icons.check_circle, 
            isDark ? Colors.green.shade400 : Colors.green.shade700, 
            'Active / Healthy', 
            1430,
          ),
          Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
          _buildStatusRow(
            Icons.build, 
            isDark ? Colors.orange.shade400 : Colors.orange.shade700, 
            'Under Maintenance', 
            15,
          ),
          Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
          _buildStatusRow(
            Icons.warning, 
            isDark ? Colors.red.shade400 : Colors.red.shade700, 
            'Reported Missing', 
            5,
          ),
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
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const Spacer(),
            Container(width: 32, height: 2, color: Theme.of(context).colorScheme.onSurface),
          ],
        ),
      ),
    );
  }
}
