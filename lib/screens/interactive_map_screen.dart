import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InteractiveMapScreen extends StatefulWidget {
  final String userRole;

  const InteractiveMapScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  final TransformationController _transformationController =
      TransformationController();
  List<Map<String, dynamic>> _assets = [];
  bool _isLoading = true;

  // Fixed dimensions for perfect alignment
  static const double deskWidth = 50.0;
  static const double deskHeight = 35.0;
  static const double deskMargin = 1.0;
  static const double aisleHeight = 45.0; // Global aisle size - physical walkways between blocks
  static const double labPadding = 16.0; // Uniform padding inside all lab containers
  static const double labBorderWidth = 1.0; // Border width
  
  // Calculate exact vertical positions for alignment
  // Each block is: (rows * (deskHeight + 2*deskMargin))
  // Block of 2 rows = 2 * (35 + 2) = 74px
  static const double blockHeight2Rows = 74.0;
  static const double blockHeight1Row = 37.0;
  
  // Account for padding and border in slot calculations
  // When a lab starts, it adds: labPadding (top) + labBorderWidth (top border)
  static const double labTopOffset = labPadding + labBorderWidth;
  
  // Slot positions (Y-coordinates from top of Wing B)
  // All labs start with the same top offset, so alignment is maintained
  static const double slot1Y = 0.0; // L1-B1 and L3-B1 start here
  static const double slot3Y = slot1Y + labTopOffset + (2 * blockHeight2Rows) + (2 * aisleHeight) + labPadding + labBorderWidth; // L1-B3 and L4-B1
  static const double slot4Y = slot3Y + labTopOffset + blockHeight2Rows + aisleHeight; // L2-B1 and L4-B2
  static const double slot5Y = slot4Y + labTopOffset + blockHeight2Rows + aisleHeight; // L2-B2 and L5-B1

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('serialized_assets')
          .select('*')
          .order('dnts_serial');

      setState(() {
        _assets = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assets: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showWorkstationDetails(String deskLabel) {
    final asset = _assets.firstWhere(
      (a) => a['dnts_serial']?.toString().contains(deskLabel) ?? false,
      orElse: () => {},
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              deskLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            if (asset.isEmpty)
              Text(
                'Empty Workstation',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              )
            else ...[
              _buildInfoRow('Serial', asset['dnts_serial'] ?? 'N/A'),
              _buildInfoRow('Category', asset['category'] ?? 'N/A'),
              _buildInfoRow('Status', asset['status'] ?? 'N/A'),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black, width: 1),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildDesk(String deskLabel, {bool isPillar = false}) {
    return GestureDetector(
      onTap: isPillar ? null : () => _showWorkstationDetails(deskLabel),
      child: Container(
        width: deskWidth,
        height: deskHeight,
        margin: const EdgeInsets.all(deskMargin),
        decoration: BoxDecoration(
          color: isPillar ? Colors.grey.shade400 : Colors.white,
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Center(
          child: Text(
            isPillar ? '' : deskLabel,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(int labNum, int rows, int cols, int blockIndex, int deskCounter, List<String>? pillars) {
    int currentDesk = deskCounter;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (rowIndex) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(cols, (colIndex) {
            final isPillar = pillars?.contains('R${rowIndex + 1}C${colIndex + 1}') ?? false;
            final deskLabel = isPillar ? '' : 'L${labNum}_T${currentDesk.toString().padLeft(2, '0')}';
            if (!isPillar) currentDesk++;
            return _buildDesk(deskLabel, isPillar: isPillar);
          }),
        );
      }),
    );
  }

  Widget _buildLab(String labName, int labNum, List<List<int>> blockConfigs, {bool showLabel = true}) {
    int deskCounter = 1;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label sits in the aisle space (45px total height)
        if (showLabel)
          SizedBox(
            height: aisleHeight,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  labName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        // Lab Container with walls (1px border) and uniform padding
        Container(
          padding: const EdgeInsets.all(16.0), // Strict uniform padding
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: blockConfigs.asMap().entries.map((entry) {
              final blockIndex = entry.key;
              final config = entry.value;
              final rows = config[0];
              final cols = config[1];
              
              List<String>? pillars;
              if (labNum == 3 && blockIndex == 1) {
                pillars = ['R1C1', 'R1C2'];
              } else if (labNum == 4 && blockIndex == 1) {
                pillars = ['R2C1', 'R2C2'];
              }

              final block = _buildBlock(labNum, rows, cols, blockIndex, deskCounter, pillars);
              
              // Update desk counter
              final totalDesks = rows * cols;
              final pillarCount = pillars?.length ?? 0;
              deskCounter += (totalDesks - pillarCount);

              return Padding(
                padding: EdgeInsets.only(bottom: blockIndex < blockConfigs.length - 1 ? aisleHeight : 0),
                child: block,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CT1 Floor Plan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_out),
                      onPressed: () {
                        final matrix = _transformationController.value.clone();
                        matrix.scale(0.8);
                        _transformationController.value = matrix;
                      },
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 1),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.zoom_in),
                      onPressed: () {
                        final matrix = _transformationController.value.clone();
                        matrix.scale(1.2);
                        _transformationController.value = matrix;
                      },
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 1),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadAssets,
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 1),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : InteractiveViewer(
                    transformationController: _transformationController,
                    constrained: false,
                    minScale: 0.3,
                    maxScale: 2.5,
                    boundaryMargin: const EdgeInsets.all(200),
                    child: Container(
                      color: Colors.grey.shade100,
                      padding: const EdgeInsets.all(40),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Wing A (Left): Lab 6 & Lab 7
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLab('Lab 6', 6, [
                                [2, 10],
                                [2, 10],
                                [1, 8],
                              ]),
                              SizedBox(height: aisleHeight), // Aisle between labs
                              _buildLab('Lab 7', 7, [
                                [2, 6],
                                [2, 6],
                                [2, 6],
                                [2, 6],
                              ], showLabel: false), // No label, continues from Lab 6
                            ],
                          ),

                          const SizedBox(width: 60),

                          // Wing B (Right): Absolute positioning for perfect alignment
                          SizedBox(
                            width: 1200, // Wide enough for both columns
                            height: 1400, // Tall enough for all labs
                            child: Stack(
                              children: [
                                // Lab 1 - Left column, starts at slot1Y
                                Positioned(
                                  left: 0,
                                  top: slot1Y,
                                  child: _buildLab('Lab 1', 1, [
                                    [2, 8],
                                    [2, 8],
                                    [2, 8],
                                  ]),
                                ),

                                // Lab 3 - Right column, starts at slot1Y (same as Lab 1)
                                Positioned(
                                  left: 500,
                                  top: slot1Y,
                                  child: _buildLab('Lab 3', 3, [
                                    [2, 12],
                                    [2, 12],
                                  ]),
                                ),

                                // Lab 2 - Left column, starts at slot4Y
                                Positioned(
                                  left: 0,
                                  top: slot4Y,
                                  child: _buildLab('Lab 2', 2, [
                                    [2, 8],
                                    [2, 8],
                                    [2, 8],
                                  ]),
                                ),

                                // Lab 4 - Right column, starts at slot3Y (aligned with L1-B3)
                                Positioned(
                                  left: 500,
                                  top: slot3Y,
                                  child: _buildLab('Lab 4', 4, [
                                    [2, 12],
                                    [2, 12],
                                  ]),
                                ),

                                // Lab 5 - Right column, starts at slot5Y (aligned with L2-B2)
                                Positioned(
                                  left: 500,
                                  top: slot5Y,
                                  child: _buildLab('Lab 5', 5, [
                                    [2, 12],
                                    [2, 12],
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
