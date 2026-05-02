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
class DragBoundaryUtils {
  // Private constructor to prevent instantiation
  DragBoundaryUtils._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inspector panel width as a fraction of screen width (40%)
  static const double inspectorPanelWidthFraction = 0.4;

  /// Escape gesture trigger threshold (pixels from screen edge)
  /// When dragging within this distance from any edge, escape gesture triggers
  static const double escapeGestureEdgeThreshold = 50.0;

  /// Modal safe zone boundary (pixels from panel edge)
  /// When dragging beyond this distance from the panel, the modal closes
  static const double modalSafeZoneThreshold = 100.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Determines if the drag position should trigger an escape gesture.
  ///
  /// The escape gesture is triggered when the user drags a component close to
  /// any screen edge (within [escapeGestureEdgeThreshold] pixels).
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
    if (dragPosition.dx < escapeGestureEdgeThreshold) {
      return true;
    }

    // Check if dragging near right edge
    if (dragPosition.dx > screenSize.width - escapeGestureEdgeThreshold) {
      return true;
    }

    // Check if dragging near top edge
    if (dragPosition.dy < escapeGestureEdgeThreshold) {
      return true;
    }

    // Check if dragging near bottom edge
    if (dragPosition.dy > screenSize.height - escapeGestureEdgeThreshold) {
      return true;
    }

    // Not near any edge
    return false;
  }

  /// Determines if the drag has exited the modal safe zone.
  ///
  /// The modal safe zone is the area around the inspector panel where dragging
  /// is considered "safe" and keeps the panel open. When the user drags beyond
  /// this zone (more than [modalSafeZoneThreshold] pixels to the left of the
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
    final panelLeftEdge = screenSize.width * (1.0 - inspectorPanelWidthFraction);

    // Calculate the safe zone boundary (to the left of the panel)
    final safeZoneBoundary = panelLeftEdge - modalSafeZoneThreshold;

    // Check if drag position is to the left of the safe zone boundary
    return dragPosition.dx < safeZoneBoundary;
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
  static double calculatePanelLeftEdge(Size screenSize) {
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
  static double calculatePanelWidth(Size screenSize) {
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
    final panelLeftEdge = calculatePanelLeftEdge(screenSize);
    return dragPosition.dx >= panelLeftEdge;
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
  static double distanceToNearestEdge(
    Offset dragPosition,
    Size screenSize,
  ) {
    final distanceToLeft = dragPosition.dx;
    final distanceToRight = screenSize.width - dragPosition.dx;
    final distanceToTop = dragPosition.dy;
    final distanceToBottom = screenSize.height - dragPosition.dy;

    // Return the minimum distance
    return [
      distanceToLeft,
      distanceToRight,
      distanceToTop,
      distanceToBottom,
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
    final distanceToLeft = dragPosition.dx;
    final distanceToRight = screenSize.width - dragPosition.dx;
    final distanceToTop = dragPosition.dy;
    final distanceToBottom = screenSize.height - dragPosition.dy;

    final minDistance = [
      distanceToLeft,
      distanceToRight,
      distanceToTop,
      distanceToBottom,
    ].reduce((a, b) => a < b ? a : b);

    if (minDistance == distanceToLeft) return 'left';
    if (minDistance == distanceToRight) return 'right';
    if (minDistance == distanceToTop) return 'top';
    return 'bottom';
  }
}
