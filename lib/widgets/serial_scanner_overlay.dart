import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class SerialScannerOverlay extends StatefulWidget {
  const SerialScannerOverlay({super.key});

  @override
  State<SerialScannerOverlay> createState() => _SerialScannerOverlayState();
}

class _SerialScannerOverlayState extends State<SerialScannerOverlay> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (exception) {
      debugPrint('Camera initialization error: $exception');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      final newTorchState = !_isTorchOn;
      await _cameraController!.setFlashMode(
        newTorchState ? FlashMode.torch : FlashMode.off,
      );
      setState(() {
        _isTorchOn = newTorchState;
      });
    } catch (e) {
      debugPrint('Error toggling torch: $e');
    }
  }

  Future<void> _takePictureForOcr() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      if (mounted) {
        Navigator.of(context).pop(image.path);
      }
    } catch (exception) {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final size = MediaQuery.of(context).size;
    final double scanWindowWidth = size.width * 0.7; 
    final double scanWindowHeight = 100;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),

          // Dark Overlay with Cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: scanWindowWidth,
                    height: scanWindowHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scan Window Border
          Align(
            alignment: Alignment.center,
            child: Container(
              width: scanWindowWidth,
              height: scanWindowHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // SIDEBAR CONTROLS
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 100,
              height: double.infinity,
              color: Colors.black.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: _isTorchOn ? Colors.yellow : Colors.white,
                      size: 32,
                    ),
                    onPressed: _toggleTorch,
                    tooltip: 'Toggle Flash',
                  ),

                  GestureDetector(
                    onTap: _takePictureForOcr,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _isCapturing
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Icon(Icons.camera_alt, color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
            ),
          ),

          // Top Instruction
          const Positioned(
            top: 40,
            left: 0,
            right: 100,
            child: Text(
              'ALIGN BARCODE OR SERIAL NUMBER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),

          // Bottom Hint
          const Positioned(
            bottom: 40,
            left: 0,
            right: 100,
            child: Text(
              'TAP CAMERA FOR TEXT SCANNING',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                letterSpacing: 1,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
