import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_colors.dart';

/// Pure Flutter Interactive Fit & Crop Dialog (WhatsApp / Instagram style)
/// Zero native plugin dependencies (works with hot reload and across all platforms).
/// Enforces boundary clamping, aspect ratio preservation, and auto-cover scale.
class ImageCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final String title;
  final bool isCircle;

  const ImageCropDialog({
    super.key,
    required this.imageBytes,
    this.title = 'Sesuaikan Foto Profil',
    this.isCircle = false,
  });

  /// Static helper to display the crop dialog and return the cropped [Uint8List] or null if cancelled
  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    String title = 'Sesuaikan Foto Profil',
    bool isCircle = false,
  }) {
    return Navigator.of(context).push<Uint8List>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, _, __) => ImageCropDialog(
          imageBytes: imageBytes,
          title: title,
          isCircle: isCircle,
        ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();

  ui.Image? _decodedImage;
  double _rawWidth = 1.0;
  double _rawHeight = 1.0;
  double _cropSize = 300.0;
  bool _isInitialized = false;

  int _rotationQuarterTurns = 0;
  bool _isExporting = false;
  bool _showGrid = true;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void dispose() {
    _transformController.dispose();
    _decodedImage?.dispose();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frameInfo = await codec.getNextFrame();
      if (!mounted) return;
      setState(() {
        _decodedImage = frameInfo.image;
        _rawWidth = frameInfo.image.width.toDouble();
        _rawHeight = frameInfo.image.height.toDouble();
      });
      _setupInitialTransform();
    } catch (e) {
      debugPrint('Error decoding image for crop: $e');
    }
  }

  /// Calculates proportional cover dimensions and centers the image
  void _setupInitialTransform() {
    if (_rawWidth <= 0 || _rawHeight <= 0) return;

    final isRotated90or270 = (_rotationQuarterTurns % 2 == 1);
    final effectiveWidth = isRotated90or270 ? _rawHeight : _rawWidth;
    final effectiveHeight = isRotated90or270 ? _rawWidth : _rawHeight;
    final aspectRatio = effectiveWidth / effectiveHeight;

    double w;
    double h;

    if (aspectRatio >= 1.0) {
      // Landscape or square: Height fits cropSize, Width expands proportionally
      h = _cropSize;
      w = _cropSize * aspectRatio;
    } else {
      // Portrait: Width fits cropSize, Height expands proportionally
      w = _cropSize;
      h = _cropSize / aspectRatio;
    }

    final double initialOffsetX = -(w - _cropSize) / 2.0;
    final double initialOffsetY = -(h - _cropSize) / 2.0;

    _transformController.value =
        Matrix4.translationValues(initialOffsetX, initialOffsetY, 0);

    setState(() {
      _isInitialized = true;
    });
  }

  void _resetTransform() {
    setState(() {
      _rotationQuarterTurns = 0;
    });
    _setupInitialTransform();
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
    _setupInitialTransform();
  }

  Future<void> _handleCropAndSave() async {
    if (_isExporting || _decodedImage == null) return;

    setState(() {
      _isExporting = true;
      _showGrid = false;
    });

    // Wait for frame rendering with grid hidden
    await WidgetsBinding.instance.endOfFrame;

    try {
      final boundary =
          _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Gagal memproses pemotongan gambar.');
      }

      // Capture at high resolution (3.0 pixel ratio)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Gagal mengekstrak data gambar.');
      }

      final croppedBytes = byteData.buffer.asUint8List();
      if (!mounted) return;
      Navigator.of(context).pop(croppedBytes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _showGrid = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double computedCropSize =
        (screenSize.width * 0.85).clamp(260.0, 340.0);

    if (_cropSize != computedCropSize) {
      _cropSize = computedCropSize;
      if (_isInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _setupInitialTransform();
        });
      }
    }

    final isRotated90or270 = (_rotationQuarterTurns % 2 == 1);
    final effectiveWidth = isRotated90or270 ? _rawHeight : _rawWidth;
    final effectiveHeight = isRotated90or270 ? _rawWidth : _rawHeight;
    final aspectRatio = effectiveWidth / effectiveHeight;

    double childWidth;
    double childHeight;

    if (aspectRatio >= 1.0) {
      childHeight = _cropSize;
      childWidth = _cropSize * aspectRatio;
    } else {
      childWidth = _cropSize;
      childHeight = _cropSize / aspectRatio;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopBar(),

            // Center Cropper Canvas
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Interactive Crop Viewport with RepaintBoundary
                    SizedBox(
                      width: _cropSize,
                      height: _cropSize,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. Captured area with image, transformations and strict boundary clamping
                          RepaintBoundary(
                            key: _cropKey,
                            child: ClipPath(
                              clipper: widget.isCircle
                                  ? _CircleClipper()
                                  : _SquareClipper(),
                              child: Container(
                                color: Colors.black,
                                width: _cropSize,
                                height: _cropSize,
                                child: !_isInitialized
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF0088FF),
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : InteractiveViewer(
                                        transformationController:
                                            _transformController,
                                        clipBehavior: Clip.none,
                                        panEnabled: !_isExporting,
                                        scaleEnabled: !_isExporting,
                                        minScale: 1.0,
                                        maxScale: 4.5,
                                        boundaryMargin: EdgeInsets.zero,
                                        child: SizedBox(
                                          width: childWidth,
                                          height: childHeight,
                                          child: RotatedBox(
                                            quarterTurns: _rotationQuarterTurns,
                                            child: Image.memory(
                                              widget.imageBytes,
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          // 2. Translucent Guide Overlay (Grid lines & subtle circle border)
                          if (!_isExporting)
                            IgnorePointer(
                              child: CustomPaint(
                                size: Size(_cropSize, _cropSize),
                                painter: _CropGridPainter(
                                  isCircle: widget.isCircle,
                                  showGrid: _showGrid,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gesture Hint
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.pinch_rounded,
                            color: Color(0xFF94A3B8),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Geser & cubit untuk menyesuaikan posisi',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Toolbar Controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cancel Button
          IconButton(
            onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Batal',
          ),

          // Title
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),

          // Done / Apply Button
          Container(
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.gradientBiru,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0088FF).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isExporting ? null : _handleCropAndSave,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Gunakan',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Rotate Button
          _buildActionButton(
            icon: Icons.rotate_right_rounded,
            label: 'Putar',
            onTap: _rotateClockwise,
          ),

          // Toggle Grid Button
          _buildActionButton(
            icon: _showGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
            label: 'Grid',
            isActive: _showGrid,
            onTap: () {
              setState(() {
                _showGrid = !_showGrid;
              });
            },
          ),

          // Reset Zoom & Transform Button
          _buildActionButton(
            icon: Icons.restart_alt_rounded,
            label: 'Reset',
            onTap: _resetTransform,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: _isExporting ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF0088FF).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF0088FF)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? const Color(0xFF38BDF8) : Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Circle Path Clipper for avatar mask
class _CircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Custom Square Path Clipper (Sharp corners, 0 border radius)
class _SquareClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Custom Painter for 3x3 Grid and Outer Border
class _CropGridPainter extends CustomPainter {
  final bool isCircle;
  final bool showGrid;

  _CropGridPainter({
    required this.isCircle,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF0088FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    if (isCircle) {
      // 1. Draw circular border
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2,
        borderPaint,
      );

      // 2. Draw 3x3 Grid inside circle if active
      if (showGrid) {
        final path = Path()
          ..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
        canvas.save();
        canvas.clipPath(path);

        // Vertical lines (1/3 and 2/3)
        canvas.drawLine(
          Offset(size.width / 3, 0),
          Offset(size.width / 3, size.height),
          gridPaint,
        );
        canvas.drawLine(
          Offset(size.width * 2 / 3, 0),
          Offset(size.width * 2 / 3, size.height),
          gridPaint,
        );

        // Horizontal lines (1/3 and 2/3)
        canvas.drawLine(
          Offset(0, size.height / 3),
          Offset(size.width, size.height / 3),
          gridPaint,
        );
        canvas.drawLine(
          Offset(0, size.height * 2 / 3),
          Offset(size.width, size.height * 2 / 3),
          gridPaint,
        );

        canvas.restore();
      }
    } else {
      // Square Border & Grid (Sharp corners, 0 border radius)
      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawRect(rect, borderPaint);

      if (showGrid) {
        canvas.save();
        canvas.clipRect(rect);

        canvas.drawLine(
          Offset(size.width / 3, 0),
          Offset(size.width / 3, size.height),
          gridPaint,
        );
        canvas.drawLine(
          Offset(size.width * 2 / 3, 0),
          Offset(size.width * 2 / 3, size.height),
          gridPaint,
        );

        canvas.drawLine(
          Offset(0, size.height / 3),
          Offset(size.width, size.height / 3),
          gridPaint,
        );
        canvas.drawLine(
          Offset(0, size.height * 2 / 3),
          Offset(size.width, size.height * 2 / 3),
          gridPaint,
        );

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CropGridPainter oldDelegate) {
    return oldDelegate.isCircle != isCircle || oldDelegate.showGrid != showGrid;
  }
}
