import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final List<Map<String, String>> _mockAccounts = [
    {'id': 'DNTS25-2002573', 'role': 'Admin', 'status': 'Active'},
    {'id': 'DNTS25-2001184', 'role': 'Technical Assistant', 'status': 'Active'},
    {'id': 'DNTS25-2003392', 'role': 'Technical Assistant', 'status': 'Offline'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TA ACCESS MANAGEMENT', style: TextStyle(letterSpacing: 2.0, fontSize: 14)),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Theme.of(context).dividerColor, height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(32.0),
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('DNTS ID')),
                DataColumn(label: Text('ROLE')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: _mockAccounts.map((account) {
                final String id = account['id'] ?? 'Unknown';
                final String role = account['role'] ?? 'Unknown';
                final String status = account['status'] ?? 'Unknown';
                return DataRow(
                  cells: [
                    DataCell(Text(id)),
                    DataCell(Text(role)),
                    DataCell(Text(status)),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: () {
                          // Future delete logic goes here
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Future create account dialog trigger goes here
        },
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        foregroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        label: const Text('NEW TA ACCOUNT', style: TextStyle(letterSpacing: 1.0)),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
