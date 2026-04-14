import 'dart:math' as math;
import 'package:flutter/material.dart';

class ZoomListener extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final double initialZoom;
  final void Function(double zoom) onZoomChanged;
  final void Function(DragEndDetails) onHorizontalDragEnd;
  final double minZoom;
  final double maxZoom;

  const ZoomListener({
    super.key,
    required this.child,
    required this.scrollController,
    required this.initialZoom,
    required this.onZoomChanged,
    required this.onHorizontalDragEnd,
    this.minZoom = 0.5,
    this.maxZoom = 5.0,
  });

  @override
  State<ZoomListener> createState() => _ZoomListenerState();
}

class _ZoomListenerState extends State<ZoomListener> {
  final Map<int, Offset> _pointers = {};
  double _initialDistance = 0.0;
  double _initialZoom = 1.0;
  bool _isTwoFingerScaling = false;

  double _distance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        _pointers[event.pointer] = event.position;
        if (_pointers.length == 2) {
          final points = _pointers.values.toList();
          _initialDistance = _distance(points[0], points[1]);
          _initialZoom = widget.initialZoom;
          _isTwoFingerScaling = true;
        }
      },
      onPointerMove: (event) {
        if (!_pointers.containsKey(event.pointer)) return;
        _pointers[event.pointer] = event.position;

        if (_pointers.length == 2) {
          final points = _pointers.values.toList();
          final newDistance = _distance(points[0], points[1]);
          if (_initialDistance <= 0) return;

          final scale = newDistance / _initialDistance;
          final oldZoom = widget.initialZoom;
          final newZoom = (_initialZoom * scale).clamp(widget.minZoom, widget.maxZoom);

          widget.onZoomChanged(newZoom);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final controller = widget.scrollController;
            if (!controller.hasClients) return;
            final max = controller.position.maxScrollExtent;
            final target = (controller.offset * (newZoom / oldZoom)).clamp(0.0, max);
            if ((controller.offset - target).abs() > 1.0) {
              controller.jumpTo(target);
            }
          });
        }
      },
      onPointerUp: (event) {
        _pointers.remove(event.pointer);
        if (_pointers.length < 2) {
          _isTwoFingerScaling = false;
          _initialDistance = 0;
        }
      },
      onPointerCancel: (event) {
        _pointers.remove(event.pointer);
        if (_pointers.length < 2) {
          _isTwoFingerScaling = false;
          _initialDistance = 0;
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: () {
          final oldZoom = widget.initialZoom;
          widget.onZoomChanged(1.0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final controller = widget.scrollController;
            if (!controller.hasClients) return;
            final max = controller.position.maxScrollExtent;
            final target = (controller.offset * (1.0 / oldZoom)).clamp(0.0, max);
            controller.jumpTo(target);
          });
        },
        onHorizontalDragEnd: (details) {
          if (_isTwoFingerScaling) return;
          widget.onHorizontalDragEnd(details);
        },
        child: widget.child,
      ),
    );
  }
}