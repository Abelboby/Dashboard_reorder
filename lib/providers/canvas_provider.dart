import 'package:flutter/material.dart';
import '../models/canvas_element.dart';

class CanvasState extends ChangeNotifier {
  List<CanvasElement> _elements = [];
  CanvasElement? _selectedElement;

  List<CanvasElement> get elements => _elements;
  CanvasElement? get selectedElement => _selectedElement;

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
    updateElement(
      id,
      element.copyWith(
        x: element.x + dx,
        y: element.y + dy,
      ),
    );
  }

  void resizeElement(String id, double width, double height) {
    final element = _elements.firstWhere((e) => e.id == id);
    updateElement(
      id,
      element.copyWith(
        width: width,
        height: height,
      ),
    );
  }

  void rotateElement(String id, double rotation) {
    final element = _elements.firstWhere((e) => e.id == id);
    updateElement(
      id,
      element.copyWith(
        rotation: rotation,
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
  }
}
