import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

enum SvgMode {
  standard,
  integral,
  fixed;

  SvgMode get next {
    switch (this) {
      case .standard:
        return .integral;
      case .integral:
        return .fixed;
      case .fixed:
        return .standard;
    }
  }
}

class MyGame extends FlameGame with TapCallbacks {
  late Svg svgInstance;
  late SvgComponent svgComponent;
  late TextComponent svgCacheSize;
  int get numSvgs => 200;
  String get svgName => 'android.svg';

  Vector2 get center => Vector2(size.x * 0.5, size.y * 0.5);

  late ToggleButtonComponent typeComponent;
  late AdvancedButtonComponent modeComponent;

  SvgMode _mode = .standard;

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
    final mode = _mode.toString().replaceAll('SvgMode.', '');
    final type = svgInstance.useMap ? 'Map' : 'MemoryCache';
    svgCacheSize.text = '$type ($mode) #${svgInstance.cacheSize}';
  }

  void _applyMode() {
    switch (_mode) {
      case .standard:
        svgInstance.integralSize = false;
        svgInstance.fixedRatio = false;
      case .integral:
        svgInstance.integralSize = true;
        svgInstance.fixedRatio = false;
      case .fixed:
        svgInstance.integralSize = false;
        svgInstance.fixedRatio = true;
    }
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
      position: Vector2(10, size.y - 30),
      anchor: Anchor.bottomLeft,
      textRenderer: textRenderer,
    );
    add(fps);

    svgCacheSize = TextComponent(
      text: '(empty)',
      priority: 1000,
      position: Vector2(size.x - 10, size.y - 30),
      anchor: Anchor.bottomRight,
      textRenderer: textRenderer,
    );
    add(svgCacheSize);

    addSvgs();
    addButtons();
  }

  void addButtons() {
    final buttonSize = Vector2(90, 30);
    const typeText = 'Type';
    typeComponent = ToggleButtonComponent(
      priority: 10,
      position: Vector2(20, size.y * 0.1),
      size: buttonSize,
      anchor: Anchor.topLeft,
      defaultLabel: TextComponent(
        text: typeText,
        textRenderer: textRenderer,
      ),
      defaultSelectedLabel: TextComponent(
        text: typeText,
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 20,
            color: BasicPalette.white.color,
          ),
        ),
      ),
      defaultSkin: RoundedRectComponent()
        ..setColor(
          const Color.fromRGBO(0, 0, 200, 1),
        ),
      defaultSelectedSkin: RoundedRectComponent()
        ..setColor(
          const Color.fromRGBO(0, 0, 200, 1),
        ),
      onSelectedChanged: (value) {
        svgInstance.useMap = !svgInstance.useMap;
      },
    );
    add(typeComponent);

    const modeText = 'Mode';
    modeComponent = AdvancedButtonComponent(
      priority: 10,
      position: Vector2(size.x - 20, size.y * 0.1),
      size: buttonSize,
      anchor: Anchor.topRight,
      defaultLabel: TextComponent(
        text: modeText,
        textRenderer: textRenderer,
      ),
      defaultSkin: RoundedRectComponent()
        ..setColor(
          const Color.fromRGBO(200, 0, 0, 1),
        ),
      onReleased: () {
        _mode = _mode.next;
        _applyMode();
      },
    );
    add(modeComponent);
  }

  void removeButtons() {
    remove(typeComponent);
    remove(modeComponent);
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

class RoundedRectComponent extends PositionComponent with HasPaint {
  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        0,
        0,
        width,
        height,
        topLeft: Radius.circular(height),
        topRight: Radius.circular(height),
        bottomRight: Radius.circular(height),
        bottomLeft: Radius.circular(height),
      ),
      paint,
    );
  }
}
