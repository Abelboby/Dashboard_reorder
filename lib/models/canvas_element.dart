import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ElementType {
  text,
  image,
  shape,
}

class CanvasElement {
  final String id;
  final ElementType type;
  double x;
  double y;
  double width;
  double height;
  double rotation;
  bool isSelected;

  CanvasElement({
    String? id,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.width = 100,
    this.height = 100,
    this.rotation = 0,
    this.isSelected = false,
  }) : id = id ?? const Uuid().v4();

  CanvasElement copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    bool? isSelected,
  }) {
    return CanvasElement(
      id: id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
