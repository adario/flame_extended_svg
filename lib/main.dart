import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame {
  late Svg svgInstance;
  int get numSvgs => 200;
  String get svgName => 'spaceship.svg';

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadComponents();
  }

  @override
  Future<void> onHotReload() async {
    final c = children.toList();
    c.removeAt(0);
    removeAll(c);

    svgInstance.dispose();
    await _loadComponents();
    super.onHotReload();
  }

  Future _loadComponents() async {
    final extents = Vector2(size.x * 0.5, size.y * 0.5);
    svgInstance = await loadSvg(svgName);
    final svg = SvgComponent(
      key: ComponentKey.named(svgName),
      svg: svgInstance,
      position: Vector2(size.x * 0.5, size.y * 0.5),
      size: extents * 0.5,
      priority: 1,
      anchor: Anchor.center,
    );
    add(svg);
    final t = FpsTextComponent(
      decimalPlaces: 1,
      windowSize: 30,
      priority: 1000,
      position: Vector2(30, size.y - 30),
    );
    add(t);

    final rotate = RotateEffect.by(
      pi * 2,
      EffectController(
        duration: 2,
        infinite: true,
      ),
    );
    svg.add(rotate);

    _addSvgs(svgInstance, extents);
  }

  void _addSvgs(Svg svgInstance, Vector2 extents) {
    final center = Vector2(size.x * 0.5, size.y * 0.5);
    final radius = (extents.x + extents.y) * 0.25;
    final step = (pi * 2.0) / numSvgs.toDouble();
    final sStep = 0.5 / numSvgs.toDouble();

    var angle = 0.0;
    var sScale = 1.0;
    for (var i = 0; i < numSvgs; ++i) {
      final position = Vector2(
        center.x + (radius * cos(angle)),
        center.y + (radius * sin(angle)),
      );

      final p = ui.Paint()..color = Colors.white.withValues(alpha: sScale);
      final s = SvgComponent(
        svg: svgInstance,
        position: position,
        size: extents * 0.5,
        scale: Vector2.all(sScale),
        angle: angle + (pi * 0.5),
        anchor: Anchor.center,
        paint: p,
      );
      add(s);
      angle += step;
      sScale -= sStep;
    }
  }
}
