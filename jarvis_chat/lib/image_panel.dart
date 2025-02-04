import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ImagePanel extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback? onRemove;

  const ImagePanel(this.bytes, {super.key, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  child: Image.memory(bytes),
                );
              },
            );
          },
          child: SizedBox(
            height: 80.0,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                margin: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.grey[700]!.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
              child: InkWell(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    ).animate().scale(
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
        );
  }
}
