import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/canvas_element.dart';
import '../providers/canvas_provider.dart';

class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToolbarButton(
            context,
            icon: Icons.text_fields,
            label: 'Text',
            onPressed: () {
              context.read<CanvasState>().addElement(
                    CanvasElement(type: ElementType.text),
                  );
            },
          ),
          const SizedBox(width: 16),
          _buildToolbarButton(
            context,
            icon: Icons.image,
            label: 'Image',
            onPressed: () {
              context.read<CanvasState>().addElement(
                    CanvasElement(type: ElementType.image),
                  );
            },
          ),
          const SizedBox(width: 16),
          _buildToolbarButton(
            context,
            icon: Icons.square_outlined,
            label: 'Shape',
            onPressed: () {
              context.read<CanvasState>().addElement(
                    CanvasElement(type: ElementType.shape),
                  );
            },
          ),
          const SizedBox(width: 16),
          _buildToolbarButton(
            context,
            icon: Icons.clear,
            label: 'Clear',
            onPressed: () {
              context.read<CanvasState>().clearSelection();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          tooltip: label,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
