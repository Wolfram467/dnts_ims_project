import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 3A: PURE MATH/LOGIC EXTRACTION
// Boundary detection utilities for the "Omni-Directional Break-Away" modal
// and "Spatial Reset" escape gesture.
//
// These are pure mathematical evaluations with no side effects.
// ═══════════════════════════════════════════════════════════════════════════

/// Pure utility class for drag boundary detection and escape gesture logic.
/// Contains no state, no UI rendering, only mathematical calculations.
class DragBoundaryCalculator {
  // Private constructor to prevent instantiation
  DragBoundaryCalculator._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inspector panel width as a fraction of screen width (40%)
  static const double inspectorPanelWidthFraction = 0.4;

  /// Escape gesture trigger threshold (pixels from screen edge)
  /// When dragging within this distance from any edge, escape gesture triggers
  static const double escapeGestureEdgeThresholdPixels = 50.0;

  /// Modal safe zone boundary (pixels from panel edge)
  /// When dragging beyond this distance from the panel, the modal closes
  static const double modalSafeZoneThresholdPixels = 100.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Determines if the drag position should trigger an escape gesture.
  ///
  /// The escape gesture is triggered when the user drags a component close to
  /// any screen edge (within [escapeGestureEdgeThresholdPixels] pixels).
  ///
  /// This is part of the "Omni-Directional Break-Away" pattern, allowing users
  /// to quickly exit the inspector panel by dragging toward any edge.
  ///
  /// **Parameters:**
  /// - [dragPosition]: Current position of the drag cursor in screen coordinates
  /// - [screenSize]: Size of the screen/viewport
  ///
  /// **Returns:**
  /// - `true` if the drag is within the edge threshold (escape should trigger)
  /// - `false` otherwise
  ///
  /// **Pure function:** No side effects, deterministic output.
  static bool shouldTriggerEscapeGesture(
    Offset dragPosition,
    Size screenSize,
  ) {
    // Check if dragging near left edge
    if (dragPosition.dx < escapeGestureEdgeThresholdPixels) {
      return true;
    }

    // Check if dragging near right edge
    if (dragPosition.dx > screenSize.width - escapeGestureEdgeThresholdPixels) {
      return true;
    }

    // Check if dragging near top edge
    if (dragPosition.dy < escapeGestureEdgeThresholdPixels) {
      return true;
    }

    // Check if dragging near bottom edge
    if (dragPosition.dy > screenSize.height - escapeGestureEdgeThresholdPixels) {
      return true;
    }

    // Not near any edge
    return false;
  }

  /// Determines if the drag has exited the modal safe zone.
  ///
  /// The modal safe zone is the area around the inspector panel where dragging
  /// is considered "safe" and keeps the panel open. When the user drags beyond
  /// this zone (more than [modalSafeZoneThresholdPixels] pixels to the left of the
  /// panel), the modal should close.
  ///
  /// This implements the "Break-Away" behavior where dragging far enough from
  /// the panel causes it to dismiss.
  ///
  /// **Parameters:**
  /// - [dragPosition]: Current position of the drag cursor in screen coordinates
  /// - [screenSize]: Size of the screen/viewport
  ///
  /// **Returns:**
  /// - `true` if the drag has exited the safe zone (modal should close)
  /// - `false` if still within the safe zone
  ///
  /// **Pure function:** No side effects, deterministic output.
  static bool hasExitedModalSafeZone(
    Offset dragPosition,
    Size screenSize,
  ) {
    // Calculate the left edge of the inspector panel
    final panelLeftEdgeX = screenSize.width * (1.0 - inspectorPanelWidthFraction);

    // Calculate the safe zone boundary (to the left of the panel)
    final safeZoneBoundaryX = panelLeftEdgeX - modalSafeZoneThresholdPixels;

    // Check if drag position is to the left of the safe zone boundary
    return dragPosition.dx < safeZoneBoundaryX;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculates the left edge X coordinate of the inspector panel.
  ///
  /// **Parameters:**
  /// - [screenSize]: Size of the screen/viewport
  ///
  /// **Returns:**
  /// - X coordinate of the panel's left edge in screen coordinates
  ///
  /// **Pure function:** No side effects, deterministic output.
  static double calculatePanelLeftEdgeX(Size screenSize) {
    return screenSize.width * (1.0 - inspectorPanelWidthFraction);
  }

  /// Calculates the width of the inspector panel in pixels.
  ///
  /// **Parameters:**
  /// - [screenSize]: Size of the screen/viewport
  ///
  /// **Returns:**
  /// - Width of the panel in pixels
  ///
  /// **Pure function:** No side effects, deterministic output.
  static double calculatePanelWidthPixels(Size screenSize) {
    return screenSize.width * inspectorPanelWidthFraction;
  }

  /// Determines if a drag position is within the inspector panel bounds.
  ///
  /// **Parameters:**
  /// - [dragPosition]: Current position of the drag cursor in screen coordinates
  /// - [screenSize]: Size of the screen/viewport
  ///
  /// **Returns:**
  /// - `true` if the drag is within the panel area
  /// - `false` otherwise
  ///
  /// **Pure function:** No side effects, deterministic output.
  static bool isWithinPanelBounds(
    Offset dragPosition,
    Size screenSize,
  ) {
    final panelLeftEdgeX = calculatePanelLeftEdgeX(screenSize);
    return dragPosition.dx >= panelLeftEdgeX;
  }

  /// Determines if a drag position is in the main canvas area (left of panel).
  ///
  /// **Parameters:**
  /// - [dragPosition]: Current position of the drag cursor in screen coordinates
  /// - [screenSize]: Size of the screen/viewport
  ///
  /// **Returns:**
  /// - `true` if the drag is in the canvas area (left of panel)
  /// - `false` otherwise
  ///
  /// **Pure function:** No side effects, deterministic output.
  static bool isInCanvasArea(
    Offset dragPosition,
    Size screenSize,
  ) {
    return !isWithinPanelBounds(dragPosition, screenSize);
  }

  /// Calculates the distance from a drag position to the nearest screen edge.
  ///
  /// Useful for implementing progressive visual feedback based on proximity
  /// to edges (e.g., fade effects, haptic feedback intensity).
  ///
  /// **Parameters:**
  /// - [dragPosition]: Current position of the drag cursor in screen coordinates
  /// - [screenSize]: Size of the screen/viewport
  ///
  /// **Returns:**
  /// - Distance in pixels to the nearest edge
  ///
  /// **Pure function:** No side effects, deterministic output.
  static double distanceToNearestEdgePixels(
    Offset dragPosition,
    Size screenSize,
  ) {
    final distanceToLeftEdgePixels = dragPosition.dx;
    final distanceToRightEdgePixels = screenSize.width - dragPosition.dx;
    final distanceToTopEdgePixels = dragPosition.dy;
    final distanceToBottomEdgePixels = screenSize.height - dragPosition.dy;

    // Return the minimum distance
    return [
      distanceToLeftEdgePixels,
      distanceToRightEdgePixels,
      distanceToTopEdgePixels,
      distanceToBottomEdgePixels,
    ].reduce((a, b) => a < b ? a : b);
  }

  /// Determines which edge is closest to the drag position.
  ///
  /// **Parameters:**
  /// - [dragPosition]: Current position of the drag cursor in screen coordinates
  /// - [screenSize]: Size of the screen/viewport
  ///
  /// **Returns:**
  /// - One of: 'left', 'right', 'top', 'bottom'
  ///
  /// **Pure function:** No side effects, deterministic output.
  static String nearestEdge(
    Offset dragPosition,
    Size screenSize,
  ) {
    final distanceToLeftEdgePixels = dragPosition.dx;
    final distanceToRightEdgePixels = screenSize.width - dragPosition.dx;
    final distanceToTopEdgePixels = dragPosition.dy;
    final distanceToBottomEdgePixels = screenSize.height - dragPosition.dy;

    final minDistancePixels = [
      distanceToLeftEdgePixels,
      distanceToRightEdgePixels,
      distanceToTopEdgePixels,
      distanceToBottomEdgePixels,
    ].reduce((a, b) => a < b ? a : b);

    if (minDistancePixels == distanceToLeftEdgePixels) return 'left';
    if (minDistancePixels == distanceToRightEdgePixels) return 'right';
    if (minDistancePixels == distanceToTopEdgePixels) return 'top';
    return 'bottom';
  }
}
