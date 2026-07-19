import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flame_extended_svg/rounded_rect_component.dart';
import 'package:flame_extended_svg/svg_cache_mode.dart';
import 'package:flame_extended_svg/svg_cache_size.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame with TapCallbacks {
  late Svg svgInstance;
  late SvgComponent svgComponent;
  late TextComponent svgCache;
  int get numSvgs => 200;
  String get svgName => 'android.svg';

  Vector2 get center => Vector2(size.x * 0.5, size.y * 0.5);

  late AdvancedButtonComponent sizeComponent;
  late TextComponent sizeText;
  late AdvancedButtonComponent modeComponent;
  late TextComponent modeText;

  SvgCacheMode _mode = .legacy;
  SvgCacheSize _size = .standard;

  TextRenderer get textRenderer => TextPaint(
    style: TextStyle(
      fontSize: 18,
      color: BasicPalette.white.color,
    ),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadComponents();
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
  void update(double dt) {
    super.update(dt);
    svgCache.text =
        'Cache #: ${svgInstance.cacheUsage}/${_size.quantityString}';
  }

  void _applyMode() {
    switch (_mode) {
      case .legacy:
        svgInstance.integralSize = false;
        svgInstance.fixedRatio = false;
      case .integral:
        svgInstance.integralSize = true;
        svgInstance.fixedRatio = false;
      case .fixed:
        svgInstance.integralSize = false;
        svgInstance.fixedRatio = true;
    }
    modeText.text = _mode.toString();
  }

  void _applySize() {
    svgInstance.cacheSize = _size.quantity;
    sizeText.text = _size.toString();
  }

  Future _loadComponents() async {
    svgInstance = await loadSvg(svgName);
    final svg = SvgComponent(
      key: ComponentKey.named(svgName),
      svg: svgInstance,
      position: center,
      size: center * 0.5,
      priority: 1,
      anchor: .center,
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
      position: Vector2(10, size.y - 30),
      anchor: .bottomLeft,
      textRenderer: textRenderer,
    );
    add(fps);

    svgCache = TextComponent(
      text: '…',
      priority: 1000,
      position: Vector2(size.x - 10, size.y - 30),
      anchor: .bottomRight,
      textRenderer: textRenderer,
    );
    add(svgCache);

    addSvgs();
    addButtons();
  }

  void addButtons() {
    final buttonSize = Vector2(90, 30);
    sizeComponent = AdvancedButtonComponent(
      priority: 10,
      position: Vector2(size.x - 20, size.y * 0.1),
      size: buttonSize,
      anchor: .topRight,
      defaultLabel: TextComponent(
        text: 'Size',
        textRenderer: textRenderer,
      ),
      defaultSkin: RoundedRectComponent()
        ..setColor(BasicPalette.darkBlue.color),
      onReleased: () {
        _size = _size.next;
        _applySize();
      },
    );
    add(sizeComponent);
    sizeText = TextComponent(
      text: '$_size',
      priority: sizeComponent.priority,
      anchor: .topCenter,
      position: sizeComponent.position + Vector2(-buttonSize.x / 2, 30),
      textRenderer: textRenderer,
    );
    add(sizeText);

    modeComponent = AdvancedButtonComponent(
      priority: 10,
      position: Vector2(20, size.y * 0.1),
      size: buttonSize,
      anchor: .topLeft,
      defaultLabel: TextComponent(
        text: 'Mode',
        textRenderer: textRenderer,
      ),
      defaultSkin: RoundedRectComponent()..setColor(BasicPalette.darkRed.color),
      onReleased: () {
        _mode = _mode.next;
        _applyMode();
      },
    );
    add(modeComponent);
    modeText = TextComponent(
      text: '$_mode',
      priority: modeComponent.priority,
      anchor: .topCenter,
      position: modeComponent.position + Vector2(buttonSize.x / 2, 30),
      textRenderer: textRenderer,
    );
    add(modeText);
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
        anchor: .center,
        paint: p,
      );
      add(s);
      angle += step;
      sScale -= sStep;
    }
  }
}
