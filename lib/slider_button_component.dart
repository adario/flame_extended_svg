import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_extended_svg/rounded_rect_component.dart';
import 'package:flutter/foundation.dart';

class SliderButtonComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  SliderButtonComponent({
    required this.min,
    required this.max,
    double initialValue = 0,
    this.step,
    this.trackHeight = 10,
    this.thumbSize = 24,
    this.trackColor = const ui.Color(0xFF5E5E5E),
    this.thumbColor = const ui.Color(0xFFFFFFFF),
    this.activeTrackColor = const ui.Color(0xFFB3C7FF),
    this.activeThumbColor = const ui.Color(0xFF6FA8FF),
    this.labelSpacing = 12,
    this.minLabel,
    this.currentLabel,
    this.maxLabel,
    this.titleLabel,
    super.position,
    super.size,
    super.priority,
    super.anchor,
  }) : assert(min < max),
       assert(initialValue >= min && initialValue <= max),
       valueNotifier = ValueNotifier<double>(initialValue);

  final double min;
  final double max;
  final double? step;

  final double trackHeight;
  final double thumbSize;

  final ui.Color trackColor;
  final ui.Color thumbColor;
  final ui.Color activeTrackColor;
  final ui.Color activeThumbColor;
  final double labelSpacing;

  final TextComponent? minLabel;
  final TextComponent? currentLabel;
  final TextComponent? maxLabel;
  final TextComponent? titleLabel;

  final ValueNotifier<double> valueNotifier;

  double get value => valueNotifier.value;
  set value(double newValue) {
    final normalized = _normalizeValue(newValue);
    if (normalized == valueNotifier.value) {
      return;
    }
    valueNotifier.value = normalized;
  }

  bool _isDragging = false;

  late final RoundedRectComponent _track;
  late final RoundedRectComponent _thumb;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    valueNotifier.addListener(_handleValueChanged);

    _track = RoundedRectComponent()
      ..position = Vector2(0, 0)
      ..size = Vector2(size.x, trackHeight)
      ..anchor = Anchor.topLeft
      ..setColor(trackColor);
    add(_track);

    _thumb = RoundedRectComponent()
      ..position = Vector2(0, trackHeight / 2)
      ..size = Vector2(thumbSize, thumbSize)
      ..anchor = Anchor.center
      ..setColor(thumbColor);
    add(_thumb);

    if (minLabel != null) {
      final label = minLabel!;
      label.anchor = Anchor.topLeft;
      label.position = Vector2(0, trackHeight + labelSpacing);
      add(label);
    }

    if (currentLabel != null) {
      final label = currentLabel!;
      label.anchor = Anchor.topCenter;
      label.position = Vector2(size.x / 2, trackHeight + labelSpacing);
      add(label);
    }

    if (titleLabel != null) {
      final label = titleLabel!;
      label.anchor = Anchor.bottomCenter;
      label.position = Vector2(size.x / 2, -(trackHeight + labelSpacing));
      add(label);
    }

    if (maxLabel != null) {
      final label = maxLabel!;
      label.anchor = Anchor.topRight;
      label.position = Vector2(size.x, trackHeight + labelSpacing);
      add(label);
    }

    _handleValueChanged();
    _applyVisualFeedback();
  }

  @override
  void onRemove() {
    valueNotifier.removeListener(_handleValueChanged);
    super.onRemove();
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= 0 &&
        point.x <= size.x &&
        point.y >= 0 &&
        point.y <= trackHeight + thumbSize;
  }

  @override
  void onTapDown(TapDownEvent event) {
    _isDragging = true;
    _applyVisualFeedback();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _isDragging = false;
    _applyVisualFeedback();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _isDragging = false;
    _applyVisualFeedback();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    _applyVisualFeedback();
    _updateFromDrag(event.localPosition.x);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _updateFromDrag(event.localEndPosition.x);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;
    _applyVisualFeedback();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _isDragging = false;
    _applyVisualFeedback();
  }

  void _updateFromDrag(double dragX) {
    if (dragX.isNaN) {
      return;
    }

    final constrainedX = dragX.clamp(0.0, size.x);
    final normalized = constrainedX / size.x;
    final rawValue = min + (normalized * (max - min));
    value = rawValue;
  }

  void _handleValueChanged() {
    _syncThumbPosition();
    _syncLabels();
  }

  void _syncThumbPosition() {
    final visualThumbSize = _isDragging ? thumbSize + 2.0 : thumbSize;
    final ratio = (value - min) / (max - min);
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final x =
        (visualThumbSize / 2) + (clampedRatio * (size.x - visualThumbSize));
    _thumb.position = Vector2(x, trackHeight / 2);
  }

  void _applyVisualFeedback() {
    final trackColorToUse = _isDragging ? activeTrackColor : trackColor;
    final thumbColorToUse = _isDragging ? activeThumbColor : thumbColor;
    final visualGrow = _isDragging ? 2.0 : 0.0;

    _track.setColor(trackColorToUse);
    _thumb.setColor(thumbColorToUse);
    _thumb.size = Vector2(thumbSize + visualGrow, thumbSize + visualGrow);
    _syncThumbPosition();
  }

  void _syncLabels() {
    if (minLabel != null) {
      minLabel!.text = min.toStringAsFixed(0);
    }

    if (currentLabel != null) {
      currentLabel!.text = value.toStringAsFixed(0);
    }

    if (maxLabel != null) {
      maxLabel!.text = max.toStringAsFixed(0);
    }
  }

  double _normalizeValue(double candidate) {
    final bounded = candidate.clamp(min, max);

    if (step == null || step! <= 0) {
      return bounded;
    }

    final snappedSteps = ((bounded - min) / step!).round();
    final snapped = min + (snappedSteps * step!);
    return snapped.clamp(min, max);
  }
}
