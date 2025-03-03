import 'package:flutter/material.dart';
import '../models/canvas_element.dart';
import 'dart:math' as math;

class CanvasState extends ChangeNotifier {
  List<CanvasElement> _elements = [];
  CanvasElement? _selectedElement;

  // Snapping configuration - further reduced threshold for even gentler snapping
  final double _snapThreshold =
      3.0; // Reduced from 5.0 to 3.0 for very gentle snapping
  final double _gridSize = 20.0; // Size of the grid cells
  bool _snapToGridEnabled = true;
  bool _snapToElementsEnabled = true;

  // Track last snap state to help with unsnapping
  bool _wasSnappedX = false;
  bool _wasSnappedY = false;
  double _lastSnapX = 0.0;
  double _lastSnapY = 0.0;
  int _breakAttemptCountX = 0;
  int _breakAttemptCountY = 0;

  // Snapping guide lines
  List<double> _horizontalGuideLines = [];
  List<double> _verticalGuideLines = [];

  List<CanvasElement> get elements => _elements;
  CanvasElement? get selectedElement => _selectedElement;
  List<double> get horizontalGuideLines => _horizontalGuideLines;
  List<double> get verticalGuideLines => _verticalGuideLines;
  bool get snapToGridEnabled => _snapToGridEnabled;
  bool get snapToElementsEnabled => _snapToElementsEnabled;

  void addElement(CanvasElement element) {
    _elements.add(element);
    notifyListeners();
  }

  void updateElement(String id, CanvasElement newElement) {
    final index = _elements.indexWhere((element) => element.id == id);
    if (index != -1) {
      _elements[index] = newElement;
      notifyListeners();
    }
  }

  void selectElement(String? id) {
    if (id == null) {
      _elements = _elements.map((element) {
        return element.copyWith(isSelected: false);
      }).toList();
      _selectedElement = null;
    } else {
      _elements = _elements.map((element) {
        return element.copyWith(isSelected: element.id == id);
      }).toList();
      _selectedElement = _elements.firstWhere(
        (element) => element.id == id,
        orElse: () => throw Exception('Element not found'),
      );
    }
    notifyListeners();
  }

  void moveElement(String id, double dx, double dy) {
    final element = _elements.firstWhere((e) => e.id == id);

    // Calculate new position
    double newX = element.x + dx;
    double newY = element.y + dy;

    // Clear previous guide lines
    _horizontalGuideLines = [];
    _verticalGuideLines = [];

    // Calculate movement velocity to detect faster movements - lower threshold
    double moveVelocity = math.sqrt(dx * dx + dy * dy);
    bool fastMovement =
        moveVelocity > 1.5; // Reduced from 3.0 to 1.5 for easier break away

    // Check if user is trying to break away from snap
    bool breakingSnapX = false;
    bool breakingSnapY = false;

    // Makes breaking from snaps extremely easy - any movement can break the snap
    if (_wasSnappedX) {
      // If any X movement or fast movement, break free
      if (dx != 0 || fastMovement) {
        _breakAttemptCountX++;
        // Break free on first attempt if movement is intentional
        if (_breakAttemptCountX >= 1 || fastMovement || dx.abs() > 1.0) {
          breakingSnapX = true;
          // Add a smaller boost to help break free but maintain control
          newX = element.x +
              (dx *
                  1.5); // Reduced from 3.0 to 1.5 for more controlled movement
          _breakAttemptCountX = 0; // Reset counter
        }
      }
    } else {
      _breakAttemptCountX = 0; // Reset when not snapped
    }

    if (_wasSnappedY) {
      // If any Y movement or fast movement, break free
      if (dy != 0 || fastMovement) {
        _breakAttemptCountY++;
        // Break free on first attempt if movement is intentional
        if (_breakAttemptCountY >= 1 || fastMovement || dy.abs() > 1.0) {
          breakingSnapY = true;
          // Add a smaller boost to help break free but maintain control
          newY = element.y +
              (dy *
                  1.5); // Reduced from 3.0 to 1.5 for more controlled movement
          _breakAttemptCountY = 0; // Reset counter
        }
      }
    } else {
      _breakAttemptCountY = 0; // Reset when not snapped
    }

    // Only apply snapping if we're not deliberately trying to break free
    bool shouldSnapX = false;
    bool shouldSnapY = false;
    double snappedX = newX;
    double snappedY = newY;

    // No snapping at all for fast movements
    if (fastMovement) {
      // Reset snap tracking on fast movements
      _wasSnappedX = false;
      _wasSnappedY = false;

      // Update element position without any snapping for fast movements
      updateElement(
        id,
        element.copyWith(
          x: newX,
          y: newY,
        ),
      );
      return; // Skip the rest of the method
    }

    // Reset snap tracking for normal movements
    bool previouslySnappedX = _wasSnappedX;
    bool previouslySnappedY = _wasSnappedY;
    _wasSnappedX = false;
    _wasSnappedY = false;

    // Only check for new snapping if we're not trying to break free and movement is small
    // This prevents snapping when user is making larger movements
    bool slowXMovement = dx.abs() < 1.2;
    bool slowYMovement = dy.abs() < 1.2;

    if (!breakingSnapX && !previouslySnappedX && slowXMovement) {
      // Check grid snapping for X
      if (_shouldSnapToGrid()) {
        double gridSnappedX = _snapToGrid(newX);

        if ((gridSnappedX - newX).abs() < _snapThreshold) {
          snappedX = gridSnappedX;
          shouldSnapX = true;
          _wasSnappedX = true;
          _lastSnapX = gridSnappedX;
        }
      }

      // Check element snapping for X
      if (_shouldSnapToElements() && !shouldSnapX) {
        final otherElements = _elements.where((e) => e.id != id).toList();

        // Element edges
        final left = newX;
        final right = newX + element.width;
        final centerX = newX + element.width / 2;

        // Check horizontal alignment
        for (final other in otherElements) {
          final otherLeft = other.x;
          final otherRight = other.x + other.width;
          final otherCenterX = other.x + other.width / 2;

          // Check various horizontal alignments
          if (!shouldSnapX) {
            if ((left - otherLeft).abs() < _snapThreshold) {
              snappedX = otherLeft;
              shouldSnapX = true;
              _wasSnappedX = true;
              _lastSnapX = otherLeft;
              _verticalGuideLines.add(otherLeft);
            } else if ((right - otherRight).abs() < _snapThreshold) {
              snappedX = otherRight - element.width;
              shouldSnapX = true;
              _wasSnappedX = true;
              _lastSnapX = otherRight - element.width;
              _verticalGuideLines.add(otherRight);
            } else if ((left - otherRight).abs() < _snapThreshold) {
              snappedX = otherRight;
              shouldSnapX = true;
              _wasSnappedX = true;
              _lastSnapX = otherRight;
              _verticalGuideLines.add(otherRight);
            } else if ((right - otherLeft).abs() < _snapThreshold) {
              snappedX = otherLeft - element.width;
              shouldSnapX = true;
              _wasSnappedX = true;
              _lastSnapX = otherLeft - element.width;
              _verticalGuideLines.add(otherLeft);
            } else if ((centerX - otherCenterX).abs() < _snapThreshold) {
              snappedX = otherCenterX - element.width / 2;
              shouldSnapX = true;
              _wasSnappedX = true;
              _lastSnapX = otherCenterX - element.width / 2;
              _verticalGuideLines.add(otherCenterX);
            }
          }
        }
      }
    }

    if (!breakingSnapY && !previouslySnappedY && slowYMovement) {
      // Check grid snapping for Y
      if (_shouldSnapToGrid()) {
        double gridSnappedY = _snapToGrid(newY);

        if ((gridSnappedY - newY).abs() < _snapThreshold) {
          snappedY = gridSnappedY;
          shouldSnapY = true;
          _wasSnappedY = true;
          _lastSnapY = gridSnappedY;
        }
      }

      // Check element snapping for Y
      if (_shouldSnapToElements() && !shouldSnapY) {
        final otherElements = _elements.where((e) => e.id != id).toList();

        // Element edges
        final top = newY;
        final bottom = newY + element.height;
        final centerY = newY + element.height / 2;

        // Check vertical alignment
        for (final other in otherElements) {
          final otherTop = other.y;
          final otherBottom = other.y + other.height;
          final otherCenterY = other.y + other.height / 2;

          // Check various vertical alignments
          if (!shouldSnapY) {
            if ((top - otherTop).abs() < _snapThreshold) {
              snappedY = otherTop;
              shouldSnapY = true;
              _wasSnappedY = true;
              _lastSnapY = otherTop;
              _horizontalGuideLines.add(otherTop);
            } else if ((bottom - otherBottom).abs() < _snapThreshold) {
              snappedY = otherBottom - element.height;
              shouldSnapY = true;
              _wasSnappedY = true;
              _lastSnapY = otherBottom - element.height;
              _horizontalGuideLines.add(otherBottom);
            } else if ((top - otherBottom).abs() < _snapThreshold) {
              snappedY = otherBottom;
              shouldSnapY = true;
              _wasSnappedY = true;
              _lastSnapY = otherBottom;
              _horizontalGuideLines.add(otherBottom);
            } else if ((bottom - otherTop).abs() < _snapThreshold) {
              snappedY = otherTop - element.height;
              shouldSnapY = true;
              _wasSnappedY = true;
              _lastSnapY = otherTop - element.height;
              _horizontalGuideLines.add(otherTop);
            } else if ((centerY - otherCenterY).abs() < _snapThreshold) {
              snappedY = otherCenterY - element.height / 2;
              shouldSnapY = true;
              _wasSnappedY = true;
              _lastSnapY = otherCenterY - element.height / 2;
              _horizontalGuideLines.add(otherCenterY);
            }
          }
        }
      }
    }

    // Update element position using snapped values only if we should snap
    updateElement(
      id,
      element.copyWith(
        x: breakingSnapX ? newX : (shouldSnapX ? snappedX : newX),
        y: breakingSnapY ? newY : (shouldSnapY ? snappedY : newY),
      ),
    );
  }

  void resizeElement(String id, double width, double height) {
    final element = _elements.firstWhere((e) => e.id == id);

    // Calculate new dimensions
    double newWidth = width;
    double newHeight = height;

    // Clear previous guide lines
    _horizontalGuideLines = [];
    _verticalGuideLines = [];

    // Apply grid snapping for dimensions
    if (_shouldSnapToGrid()) {
      newWidth = _snapToGrid(newWidth);
      newHeight = _snapToGrid(newHeight);
    }

    // Apply element snapping for dimensions
    if (_shouldSnapToElements()) {
      // Get other elements for snapping reference
      final otherElements = _elements.where((e) => e.id != id).toList();

      // Snap width and height to other elements' dimensions
      final snappedSize =
          _snapSizeToElements(element, otherElements, newWidth, newHeight);

      newWidth = snappedSize.width;
      newHeight = snappedSize.height;
    }

    updateElement(
      id,
      element.copyWith(
        width: newWidth,
        height: newHeight,
      ),
    );
  }

  void rotateElement(String id, double rotation) {
    final element = _elements.firstWhere((e) => e.id == id);

    // Snap rotation to common angles (0, 45, 90, 135, 180, 225, 270, 315 degrees)
    double snappedRotation = rotation;
    const List<double> commonAngles = [0, 45, 90, 135, 180, 225, 270, 315, 360];

    for (final angle in commonAngles) {
      if ((rotation - angle).abs() < 5) {
        snappedRotation = angle;
        break;
      }
    }

    // Normalize to 0-360 range
    snappedRotation = snappedRotation % 360;

    updateElement(
      id,
      element.copyWith(
        rotation: snappedRotation,
      ),
    );
  }

  void deleteElement(String id) {
    _elements.removeWhere((element) => element.id == id);
    if (_selectedElement?.id == id) {
      _selectedElement = null;
    }
    notifyListeners();
  }

  void clearSelection() {
    selectElement(null);
    // Also clear guide lines
    _horizontalGuideLines = [];
    _verticalGuideLines = [];
    notifyListeners();
  }

  void toggleSnapToGrid() {
    _snapToGridEnabled = !_snapToGridEnabled;
    notifyListeners();
  }

  void toggleSnapToElements() {
    _snapToElementsEnabled = !_snapToElementsEnabled;
    notifyListeners();
  }

  bool _shouldSnapToGrid() {
    return _snapToGridEnabled;
  }

  bool _shouldSnapToElements() {
    return _snapToElementsEnabled;
  }

  double _snapToGrid(double value) {
    // Snap to nearest grid line
    return (_gridSize * (value / _gridSize).round()).toDouble();
  }

  Offset _snapToElements(CanvasElement element, List<CanvasElement> others,
      double newX, double newY) {
    double snappedX = newX;
    double snappedY = newY;

    // Element edges
    final left = newX;
    final right = newX + element.width;
    final top = newY;
    final bottom = newY + element.height;
    final centerX = newX + element.width / 2;
    final centerY = newY + element.height / 2;

    // Check for horizontal alignment with other elements
    for (final other in others) {
      final otherLeft = other.x;
      final otherRight = other.x + other.width;
      final otherCenterX = other.x + other.width / 2;

      // Left edge alignment
      if ((left - otherLeft).abs() < _snapThreshold) {
        snappedX = otherLeft;
        _verticalGuideLines.add(otherLeft);
      }

      // Right edge alignment
      if ((right - otherRight).abs() < _snapThreshold) {
        snappedX = otherRight - element.width;
        _verticalGuideLines.add(otherRight);
      }

      // Left to right alignment
      if ((left - otherRight).abs() < _snapThreshold) {
        snappedX = otherRight;
        _verticalGuideLines.add(otherRight);
      }

      // Right to left alignment
      if ((right - otherLeft).abs() < _snapThreshold) {
        snappedX = otherLeft - element.width;
        _verticalGuideLines.add(otherLeft);
      }

      // Center alignment
      if ((centerX - otherCenterX).abs() < _snapThreshold) {
        snappedX = otherCenterX - element.width / 2;
        _verticalGuideLines.add(otherCenterX);
      }
    }

    // Check for vertical alignment with other elements
    for (final other in others) {
      final otherTop = other.y;
      final otherBottom = other.y + other.height;
      final otherCenterY = other.y + other.height / 2;

      // Top edge alignment
      if ((top - otherTop).abs() < _snapThreshold) {
        snappedY = otherTop;
        _horizontalGuideLines.add(otherTop);
      }

      // Bottom edge alignment
      if ((bottom - otherBottom).abs() < _snapThreshold) {
        snappedY = otherBottom - element.height;
        _horizontalGuideLines.add(otherBottom);
      }

      // Top to bottom alignment
      if ((top - otherBottom).abs() < _snapThreshold) {
        snappedY = otherBottom;
        _horizontalGuideLines.add(otherBottom);
      }

      // Bottom to top alignment
      if ((bottom - otherTop).abs() < _snapThreshold) {
        snappedY = otherTop - element.height;
        _horizontalGuideLines.add(otherTop);
      }

      // Center alignment
      if ((centerY - otherCenterY).abs() < _snapThreshold) {
        snappedY = otherCenterY - element.height / 2;
        _horizontalGuideLines.add(otherCenterY);
      }
    }

    return Offset(snappedX, snappedY);
  }

  Size _snapSizeToElements(CanvasElement element, List<CanvasElement> others,
      double newWidth, double newHeight) {
    double snappedWidth = newWidth;
    double snappedHeight = newHeight;

    // Check for width alignment with other elements
    for (final other in others) {
      // Width alignment
      if ((newWidth - other.width).abs() < _snapThreshold) {
        snappedWidth = other.width;
      }
    }

    // Check for height alignment with other elements
    for (final other in others) {
      // Height alignment
      if ((newHeight - other.height).abs() < _snapThreshold) {
        snappedHeight = other.height;
      }
    }

    return Size(snappedWidth, snappedHeight);
  }
}
