import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/canvas_element.dart';
import '../providers/canvas_provider.dart';

class EditableElement extends StatelessWidget {
  final CanvasElement element;

  const EditableElement({
    Key? key,
    required this.element,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: element.x,
      top: element.y,
      child: GestureDetector(
        onTap: () {
          context.read<CanvasState>().selectElement(element.id);
        },
        onPanUpdate: (details) {
          if (element.isSelected) {
            context.read<CanvasState>().moveElement(
                  element.id,
                  details.delta.dx,
                  details.delta.dy,
                );
          }
        },
        child: Transform.rotate(
          angle: element.rotation * (math.pi / 180),
          child: ElementContainer(element: element),
        ),
      ),
    );
  }
}

class ElementContainer extends StatelessWidget {
  final CanvasElement element;

  const ElementContainer({
    Key? key,
    required this.element,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: element.width,
          height: element.height,
          decoration: BoxDecoration(
            border: element.isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: _buildElementContent(),
        ),
        if (element.isSelected) ..._buildHandles(context),
      ],
    );
  }

  Widget _buildElementContent() {
    switch (element.type) {
      case ElementType.text:
        return const Center(child: Text('Text Element'));
      case ElementType.image:
        return const Center(child: Text('Image Element'));
      case ElementType.shape:
        return Container(
          color: Colors.blue[200],
        );
    }
  }

  List<Widget> _buildHandles(BuildContext context) {
    return [
      // Resize handle - bottom right
      Positioned(
        right: -5,
        bottom: -5,
        child: GestureDetector(
          onPanUpdate: (details) {
            final newWidth = element.width + details.delta.dx;
            final newHeight = element.height + details.delta.dy;
            context.read<CanvasState>().resizeElement(
                  element.id,
                  newWidth.clamp(50.0, double.infinity),
                  newHeight.clamp(50.0, double.infinity),
                );
          },
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.blue,
              border: Border.all(color: Colors.white, width: 1),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),

      // Rotation handle - top center
      Positioned(
        top: -20,
        left: element.width / 2 - 5,
        child: GestureDetector(
          onPanUpdate: (details) {
            // Calculate the center of the element
            final centerX = element.width / 2;
            final centerY = element.height / 2;

            // Calculate the angle between the center and the current position
            final dx = details.localPosition.dx - centerX;
            final dy = details.localPosition.dy - centerY + 20;
            final angle = math.atan2(dy, dx) * (180 / math.pi);

            // Update the rotation
            context.read<CanvasState>().rotateElement(
                  element.id,
                  angle + 90, // Add 90 degrees to make it point upwards by default
                );
          },
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.green,
              border: Border.all(color: Colors.white, width: 1),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),

      // Delete handle - top right
      Positioned(
        top: -5,
        right: -5,
        child: GestureDetector(
          onTap: () {
            context.read<CanvasState>().deleteElement(element.id);
          },
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: Colors.red,
              border: Border.all(color: Colors.white, width: 1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ];
  }
}
