import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/spatial_manager.dart';

/// Provider for the SpatialManager domain service.
final spatialManagerProvider = Provider<SpatialManager>((ref) {
  return SpatialManager();
});
