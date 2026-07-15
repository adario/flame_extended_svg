import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame with TapCallbacks {
  late Svg svgInstance;
  late SvgComponent svgComponent;
  late TextComponent svgCacheSize;
  int get numSvgs => 200;
  String get svgName => 'android.svg';

  Vector2 get center => Vector2(size.x * 0.5, size.y * 0.5);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadComponents();

    final position = center..y = size.y * 0.245;
    final t = TextComponent(
      text: 'Tap to switch cache',
      priority: 10000,
      position: position,
      anchor: Anchor.topCenter,
    );
    add(t);

    final r = RemoveEffect(delay: 3.5);
    t.add(r);
  }

  @override
  void onHotReload() {
    super.onHotReload();
    final c = children.toList();
    c.removeAt(0);
    removeAll(c);
    remove(svgComponent);
    svgInstance.dispose();
    _loadComponents();
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    svgInstance.useMap = !svgInstance.useMap;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final mode = svgInstance.useMap ? 'Map' : 'MemoryCache';
    svgCacheSize.text = '$mode #${svgInstance.cacheSize}';
  }

  Future _loadComponents() async {
    svgInstance = await loadSvg(svgName);
    final svg = SvgComponent(
      key: ComponentKey.named(svgName),
      svg: svgInstance,
      position: center,
      size: center * 0.5,
      priority: 1,
      anchor: Anchor.center,
    );
    add(svg);
    svgComponent = svg;

    final rotate = RotateEffect.by(
      pi * 2,
      EffectController(
        duration: 2,
        infinite: true,
      ),
    );
    svg.add(rotate);

    final fps = FpsTextComponent(
      decimalPlaces: 1,
      windowSize: 30,
      priority: 1000,
      position: Vector2(20, size.y - 30),
      anchor: Anchor.centerLeft,
    );
    add(fps);

    svgCacheSize = TextComponent(
      text: '(empty)',
      priority: 1000,
      position: Vector2(size.x - 20, size.y - 30),
      anchor: Anchor.centerRight,
    );
    add(svgCacheSize);

    addSvgs();
  }

  void addSvgs() {
    final center = this.center;
    final svgSize = center * 0.5;
    final radius = (center.x + center.y) * 0.25;
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
        size: svgSize,
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
