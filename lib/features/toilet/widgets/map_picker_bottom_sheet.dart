import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/services/location_service.dart';

class PickedMapLocation {
  final String locationName;
  final String address;
  final double latitude;
  final double longitude;

  const PickedMapLocation({
    required this.locationName,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class MapPickerBottomSheet extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;

  const MapPickerBottomSheet({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
  });

  static Future<PickedMapLocation?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    String? initialLocationName,
  }) {
    return showModalBottomSheet<PickedMapLocation>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MapPickerBottomSheet(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
        initialLocationName: initialLocationName,
      ),
    );
  }

  @override
  State<MapPickerBottomSheet> createState() => _MapPickerBottomSheetState();
}

class _MapPickerBottomSheetState extends State<MapPickerBottomSheet> {
  // Default center (Jakarta) if GPS not yet resolved
  late double _centerLat;
  late double _centerLng;
  int _zoom = 16;

  String _locationName = 'Mencari nama lokasi...';
  String _locationAddress = '';
  bool _isResolvingAddress = false;
  bool _isLocatingGps = false;

  Timer? _reverseGeocodeDebounce;
  Offset? _lastFocalPoint;

  @override
  void initState() {
    super.initState();
    _centerLat = widget.initialLatitude ?? -6.200000;
    _centerLng = widget.initialLongitude ?? 106.816666;
    if (widget.initialLocationName?.trim().isNotEmpty == true) {
      _locationName = widget.initialLocationName!.trim();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        _resolveLocationName(_centerLat, _centerLng);
      } else {
        _moveToCurrentGps();
      }
    });
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _moveToCurrentGps() async {
    if (!mounted) return;
    setState(() => _isLocatingGps = true);

    final res = await LocationService.getCurrentLocation();
    if (!mounted) return;

    setState(() => _isLocatingGps = false);

    if (res.success && res.latitude != null && res.longitude != null) {
      setState(() {
        _centerLat = res.latitude!;
        _centerLng = res.longitude!;
        _zoom = 17;
        if (res.placeName.isNotEmpty) {
          _locationName = res.placeName;
          _locationAddress = res.address;
        }
      });
      _resolveLocationName(_centerLat, _centerLng);
    } else {
      _resolveLocationName(_centerLat, _centerLng);
    }
  }

  void _scheduleReverseGeocode() {
    _reverseGeocodeDebounce?.cancel();
    setState(() => _isResolvingAddress = true);
    _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 450), () {
      _resolveLocationName(_centerLat, _centerLng);
    });
  }

  Future<void> _resolveLocationName(double lat, double lng) async {
    if (!mounted) return;
    setState(() => _isResolvingAddress = true);

    final suggestion = await LocationService.reverseGeocodeNominatim(lat, lng);
    if (!mounted) return;

    setState(() {
      _isResolvingAddress = false;
      if (suggestion != null) {
        _locationName = suggestion.shortName;
        _locationAddress = suggestion.displayName;
      } else if (_locationName == 'Mencari nama lokasi...') {
        _locationName = 'Lokasi Terpilih';
      }
    });
  }

  // Slippy map Web Mercator conversions
  double _lngToTileX(double lng, int zoom) {
    return ((lng + 180.0) / 360.0) * (1 << zoom);
  }

  double _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return (1.0 -
            math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) / math.pi) /
        2.0 *
        (1 << zoom);
  }

  double _tileXToLng(double tileX, int zoom) {
    return tileX / (1 << zoom) * 360.0 - 180.0;
  }

  double _tileYToLat(double tileY, int zoom) {
    final n = math.pi - 2.0 * math.pi * tileY / (1 << zoom);
    return 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  void _panByPixels(Offset delta) {
    const tileSize = 256.0;
    final currentTileX = _lngToTileX(_centerLng, _zoom);
    final currentTileY = _latToTileY(_centerLat, _zoom);

    final newTileX = currentTileX - (delta.dx / tileSize);
    final newTileY = currentTileY - (delta.dy / tileSize);

    final maxTiles = (1 << _zoom).toDouble();
    final clampedY = newTileY.clamp(0.0, maxTiles);

    setState(() {
      _centerLng = _tileXToLng(newTileX, _zoom).clamp(-180.0, 180.0);
      _centerLat = _tileYToLat(clampedY, _zoom).clamp(-85.0, 85.0);
    });
  }

  void _onTapMap(TapUpDetails details, Size viewportSize) {
    final centerOffset = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final tapOffset = details.localPosition;
    // Move map center to the tapped point
    final delta = centerOffset - tapOffset;
    _panByPixels(delta);
    _scheduleReverseGeocode();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Handle Bar & Header
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Lokasi di Peta 📍',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Geser atau ketuk peta untuk menaruh titik lokasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Interactive Map Viewport
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final viewportSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Slippy Tile Canvas
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: (details) {
                              _lastFocalPoint = details.localFocalPoint;
                            },
                            onScaleUpdate: (details) {
                              if (_lastFocalPoint != null) {
                                final delta =
                                    details.localFocalPoint - _lastFocalPoint!;
                                _lastFocalPoint = details.localFocalPoint;
                                if (delta.distance > 0.5) {
                                  _panByPixels(delta);
                                }
                              }
                            },
                            onScaleEnd: (_) {
                              _lastFocalPoint = null;
                              _scheduleReverseGeocode();
                            },
                            onTapUp: (details) =>
                                _onTapMap(details, viewportSize),
                            child: _buildTileGrid(viewportSize),
                          ),

                          // Center Pin Marker
                          IgnorePadding(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 34),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'Titik Lokasi',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 42,
                                      color: Color(0xFFFF3B30),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Right Floating Controls (Zoom In/Out & My GPS Location)
                          Positioned(
                            right: 12,
                            bottom: 14,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMapControlBtn(
                                  icon: Icons.add_rounded,
                                  onTap: () {
                                    if (_zoom < 18) {
                                      setState(() => _zoom++);
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                _buildMapControlBtn(
                                  icon: Icons.remove_rounded,
                                  onTap: () {
                                    if (_zoom > 5) {
                                      setState(() => _zoom--);
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildMapControlBtn(
                                  icon: Icons.my_location_rounded,
                                  color: const Color(0xFF0088FF),
                                  iconColor: Colors.white,
                                  isLoading: _isLocatingGps,
                                  onTap: _moveToCurrentGps,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // 3. Selected Location Name Footer & Confirm Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF7A00).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.place_rounded,
                            color: Color(0xFFFF7A00),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: _isResolvingAddress
                              ? const Text(
                                  'Mencari nama lokasi...',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _locationName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    if (_locationAddress.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _locationAddress,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isResolvingAddress
                          ? null
                          : () {
                              Navigator.of(context).pop(
                                PickedMapLocation(
                                  locationName: _locationName,
                                  address: _locationAddress,
                                  latitude: _centerLat,
                                  longitude: _centerLng,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Pilih Lokasi Ini',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileGrid(Size viewportSize) {
    const tileSize = 256.0;
    final centerTileX = _lngToTileX(_centerLng, _zoom);
    final centerTileY = _latToTileY(_centerLat, _zoom);

    final baseTileX = centerTileX.floor();
    final baseTileY = centerTileY.floor();

    final offsetX = (centerTileX - baseTileX) * tileSize;
    final offsetY = (centerTileY - baseTileY) * tileSize;

    final centerPixelX = viewportSize.width / 2;
    final centerPixelY = viewportSize.height / 2;

    final tilesX = (viewportSize.width / tileSize).ceil() + 2;
    final tilesY = (viewportSize.height / tileSize).ceil() + 2;

    final startDx = -(tilesX ~/ 2);
    final endDx = (tilesX ~/ 2) + 1;
    final startDy = -(tilesY ~/ 2);
    final endDy = (tilesY ~/ 2) + 1;

    final maxTileIndex = (1 << _zoom);
    final children = <Widget>[];

    for (int dx = startDx; dx <= endDx; dx++) {
      for (int dy = startDy; dy <= endDy; dy++) {
        final rawX = baseTileX + dx;
        final rawY = baseTileY + dy;
        if (rawY < 0 || rawY >= maxTileIndex) continue;

        final wrappedX = ((rawX % maxTileIndex) + maxTileIndex) % maxTileIndex;
        final left = centerPixelX - offsetX + (dx * tileSize);
        final top = centerPixelY - offsetY + (dy * tileSize);

        final url =
            'https://tile.openstreetmap.org/$_zoom/$wrappedX/$rawY.png';

        children.add(
          Positioned(
            left: left,
            top: top,
            width: tileSize,
            height: tileSize,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              headers: const {
                'User-Agent': 'DayTaleCoupleApp/1.0 (Flutter)',
              },
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE2E8F0),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      color: const Color(0xFFE2E8F0),
      child: Stack(children: children),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
    Color iconColor = const Color(0xFF1E293B),
    bool isLoading = false,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: iconColor,
                    ),
                  )
                : Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}

class IgnorePadding extends StatelessWidget {
  final Widget child;
  const IgnorePadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: child);
  }
}
