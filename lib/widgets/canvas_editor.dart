import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/canvas_provider.dart';
import 'editable_element.dart';
import 'canvas_toolbar.dart';

class CanvasEditor extends StatelessWidget {
  const CanvasEditor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CanvasState(),
      child: const Column(
        children: [
          CanvasToolbar(),
          Expanded(
            child: CanvasArea(),
          ),
        ],
      ),
    );
  }
}

class CanvasArea extends StatelessWidget {
  const CanvasArea({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Clear selection when tapping on empty area
        context.read<CanvasState>().clearSelection();
      },
      child: Container(
        color: Colors.grey[200],
        child: Consumer<CanvasState>(
          builder: (context, canvasState, _) {
            return Stack(
              children: canvasState.elements.map((element) => EditableElement(element: element)).toList(),
            );
          },
        ),
      ),
    );
  }
}
