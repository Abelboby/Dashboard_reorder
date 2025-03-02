import 'package:flutter/material.dart';
import '../models/canvas_element.dart';

class CanvasState extends ChangeNotifier {
  List<CanvasElement> _elements = [];
  CanvasElement? _selectedElement;

  // Snapping configuration
  final double _snapThreshold = 10.0; // Distance in pixels to trigger snapping
  final double _gridSize = 20.0; // Size of the grid cells
  bool _snapToGridEnabled = true;
  bool _snapToElementsEnabled = true;

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

    // Only apply snapping if we're close enough to snap points
    bool shouldSnapX = false;
    bool shouldSnapY = false;
    double snappedX = newX;
    double snappedY = newY;

    // Check grid snapping
    if (_shouldSnapToGrid()) {
      double gridSnappedX = _snapToGrid(newX);
      double gridSnappedY = _snapToGrid(newY);

      if ((gridSnappedX - newX).abs() < _snapThreshold) {
        snappedX = gridSnappedX;
        shouldSnapX = true;
      }

      if ((gridSnappedY - newY).abs() < _snapThreshold) {
        snappedY = gridSnappedY;
        shouldSnapY = true;
      }
    }

    // Check element snapping
    if (_shouldSnapToElements()) {
      final otherElements = _elements.where((e) => e.id != id).toList();

      // Element edges
      final left = newX;
      final right = newX + element.width;
      final top = newY;
      final bottom = newY + element.height;
      final centerX = newX + element.width / 2;
      final centerY = newY + element.height / 2;

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
            _verticalGuideLines.add(otherLeft);
          } else if ((right - otherRight).abs() < _snapThreshold) {
            snappedX = otherRight - element.width;
            shouldSnapX = true;
            _verticalGuideLines.add(otherRight);
          } else if ((left - otherRight).abs() < _snapThreshold) {
            snappedX = otherRight;
            shouldSnapX = true;
            _verticalGuideLines.add(otherRight);
          } else if ((right - otherLeft).abs() < _snapThreshold) {
            snappedX = otherLeft - element.width;
            shouldSnapX = true;
            _verticalGuideLines.add(otherLeft);
          } else if ((centerX - otherCenterX).abs() < _snapThreshold) {
            snappedX = otherCenterX - element.width / 2;
            shouldSnapX = true;
            _verticalGuideLines.add(otherCenterX);
          }
        }
      }

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
            _horizontalGuideLines.add(otherTop);
          } else if ((bottom - otherBottom).abs() < _snapThreshold) {
            snappedY = otherBottom - element.height;
            shouldSnapY = true;
            _horizontalGuideLines.add(otherBottom);
          } else if ((top - otherBottom).abs() < _snapThreshold) {
            snappedY = otherBottom;
            shouldSnapY = true;
            _horizontalGuideLines.add(otherBottom);
          } else if ((bottom - otherTop).abs() < _snapThreshold) {
            snappedY = otherTop - element.height;
            shouldSnapY = true;
            _horizontalGuideLines.add(otherTop);
          } else if ((centerY - otherCenterY).abs() < _snapThreshold) {
            snappedY = otherCenterY - element.height / 2;
            shouldSnapY = true;
            _horizontalGuideLines.add(otherCenterY);
          }
        }
      }
    }

    // Update element position using snapped values only if we should snap
    updateElement(
      id,
      element.copyWith(
        x: shouldSnapX ? snappedX : newX,
        y: shouldSnapY ? snappedY : newY,
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
