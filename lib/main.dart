import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flame_extended_svg/cancellable_button_component.dart';
import 'package:flame_extended_svg/rounded_rect_component.dart';
import 'package:flame_extended_svg/slider_button_component.dart';
import 'package:flame_extended_svg/svg_cache_mode.dart';
import 'package:flame_extended_svg/svg_cache_size.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame {
  static const _uiPriority = 1000;
  static const _hudPriority = 10000;
  static const _svgPriority = 1;

  late Svg svgInstance;
  late SvgComponent svgComponent;
  late Component svgContainer;
  late Component buttonContainer;
  late Component hudContainer;
  late FpsTextComponent fps;
  late TextComponent svgCache;

  var _masterAngle = 0.0;
  final int _minSvgComponents = 10;
  final int _maxSvgComponents = 500;
  int _numSvgs = 100;
  int get numSvgComponents => _numSvgs;
  int _currentSvg = 0;
  final List<String> _svgs = [
    'android',
    'cone',
    'pyramid',
    'prism',
    'spaceship',
    'spaceship_2',
    'spaceship_6',
    'robot',
    'rocket_ship',
    'tiger',
  ];
  String get svgFilename => _svgs[_currentSvg];
  String get svgPathname => '$svgFilename.svg';
  Size get svgPISize => svgInstance.pictureInfo.size;
  String get svgName =>
      '$svgFilename ${svgPISize.width.toInt()}x${svgPISize.height.toInt()}';

  Vector2 get center => Vector2(size.x * 0.5, size.y * 0.5);
  Vector2 get svgSize => (center * 0.5)..round();
  Vector2 get buttonSize => Vector2(90, 30);

  double get rotateAmplitude => pi * 2.0;
  double get rotateDuration => 2.0;

  late AdvancedButtonComponent sizeComponent;
  late TextComponent sizeText;
  late AdvancedButtonComponent modeComponent;
  late TextComponent modeText;
  late AdvancedButtonComponent svgButtonComponent;
  late TextComponent svgButtonText;
  late SliderButtonComponent sliderComponent;

  SvgCacheMode _mode = .integral;
  SvgCacheSize _size = .standard;

  TextRenderer get textRenderer => TextPaint(
    style: TextStyle(
      fontSize: 18,
      color: BasicPalette.white.color,
    ),
  );

  TextRenderer get textSubRenderer => TextPaint(
    style: TextStyle(
      fontSize: 16,
      color: BasicPalette.white.color,
    ),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadComponents(
      fixedRatio: _mode.fixedRatio,
      cacheSize: _size.quantity,
    );
  }

  @override
  void onHotReload() {
    super.onHotReload();
    _load();
  }

  static final Vector2 _zero = .zero();
  Vector2 _gameSize = MyGame._zero;

  @override
  void update(double dt) {
    super.update(dt);
    svgCache.text =
        'Cache #: ${svgInstance.cacheUsage}/${_size.quantityString}';
    if (_gameSize == MyGame._zero) {
      _gameSize = size;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    final differs = _gameSize != MyGame._zero && _gameSize != size;
    super.onGameResize(size);
    if (differs) {
      _adjustGameSize(size);
    }
  }

  void _adjustGameSize(Vector2 size) {
    _gameSize = size;
    _adjustHudComponents();
    _adjustButtons();
    _adjustSvgComponent();
    _adjustSvgs();
  }

  Future<void> _load({bool file = true}) async {
    _masterAngle = svgComponent.angle;
    remove(svgContainer);
    remove(hudContainer);
    remove(buttonContainer);
    final fixedRatio = svgInstance.fixedRatio;
    final cacheSize = svgInstance.cacheSize;
    svgInstance.dispose();
    await _loadComponents(
      fixedRatio: fixedRatio,
      cacheSize: cacheSize,
      file: file,
    );
  }

  Future<void> _applyMode() async {
    switch (_mode) {
      case .integral:
        svgInstance.fixedRatio = false;
      case .fixed:
        svgInstance.fixedRatio = true;
    }
    modeText.text = _mode.toString();
  }

  Future<void> _applySize() async {
    svgInstance.cacheSize = _size.quantity;
    sizeText.text = _size.toString();
  }

  Future<void> _applySvg() async {
    _masterAngle = svgComponent.angle;
    await _loadSvg(
      fixedRatio: svgInstance.fixedRatio,
      cacheSize: svgInstance.cacheSize,
    );
    svgButtonText.text = svgName;
  }

  Future _loadSvg({
    bool fixedRatio = false,
    int cacheSize = Svg.defaultCacheSize,
  }) async {
    svgInstance = await loadSvg(
      svgPathname,
      fixedRatio: fixedRatio,
      cacheSize: cacheSize,
    );
    final numChildren = children.length;
    if (numChildren > 2) {
      final svgs = svgContainer.children.toList(growable: false);
      svgs.forEach(
        (component) => (component as SvgComponent).svg = svgInstance,
      );
    }
  }

  Future _loadComponents({
    bool fixedRatio = false,
    int cacheSize = Svg.defaultCacheSize,
    bool file = true,
  }) async {
    if (file) {
      await _loadSvg(fixedRatio: fixedRatio, cacheSize: cacheSize);
    }

    addSvgComponent();
    addSvgs();
    addButtons();
    addHudComponents();
  }

  void addSvgComponent() {
    svgContainer = Component();
    add(svgContainer);
    final svg = SvgComponent(
      key: ComponentKey.named(svgFilename),
      svg: svgInstance,
      position: center,
      size: svgSize,
      angle: _masterAngle,
      anchor: .center,
    );
    svgContainer.add(svg);
    svgComponent = svg;

    final rotate = RotateEffect.by(
      rotateAmplitude,
      EffectController(
        duration: rotateDuration,
        infinite: true,
      ),
    );
    svg.add(rotate);
  }

  void _adjustSvgComponent() {
    svgComponent.position = center;
    svgComponent.size = svgSize;
  }

  void addHudComponents() {
    hudContainer = Component(priority: _hudPriority);
    add(hudContainer);

    fps = FpsTextComponent(
      decimalPlaces: 1,
      windowSize: 30,
      position: Vector2(10, size.y - 30),
      anchor: .bottomLeft,
      textRenderer: textRenderer,
    );
    hudContainer.add(fps);

    svgCache = TextComponent(
      text: '…',
      position: Vector2(size.x - 10, size.y - 30),
      anchor: .bottomRight,
      textRenderer: textRenderer,
    );
    hudContainer.add(svgCache);
  }

  void _adjustHudComponents() {
    fps.position = Vector2(10, size.y - 30);
    svgCache.position = Vector2(size.x - 10, size.y - 30);
  }

  void addButtons() {
    buttonContainer = Component(priority: _uiPriority);
    add(buttonContainer);

    final y = size.y * (kIsWeb ? 0.025 : 0.075);
    addSizeButton(y);
    addModeButton(y);
    addSvgButton(y);

    final sliderY = size.y * (kIsWeb ? 0.2 : 0.25);
    addSliderButton(sliderY);
  }

  void _adjustButtons() {
    final y = size.y * (kIsWeb ? 0.025 : 0.075);
    sizeComponent.position = Vector2(size.x - 20, y);
    sizeText.position = sizeComponent.position + Vector2(-buttonSize.x / 2, 30);
    modeComponent.position = Vector2(20, y);
    modeText.position = modeComponent.position + Vector2(buttonSize.x / 2, 30);
    svgButtonComponent.position = Vector2(center.x, y);
    svgButtonText.position = svgButtonComponent.position + Vector2(0, 30);

    final sliderY = size.y * (kIsWeb ? 0.2 : 0.25);
    sliderComponent.position = Vector2(center.x, sliderY);
    sliderComponent.size = Vector2(size.x * 0.75, 60);
  }

  void addSliderButton(double y) {
    sliderComponent = SliderButtonComponent(
      position: Vector2(center.x, y),
      size: Vector2(size.x * 0.75, 60),
      anchor: .center,
      labelSpacing: 8,
      min: _minSvgComponents.toDouble(),
      max: _maxSvgComponents.toDouble(),
      initialValue: numSvgComponents.toDouble(),
      step: 5,
      minLabel: TextComponent(
        text: '$_minSvgComponents',
        textRenderer: textSubRenderer,
      ),
      currentLabel: TextComponent(
        text: '$numSvgComponents',
        textRenderer: textSubRenderer,
      ),
      maxLabel: TextComponent(
        text: '$_maxSvgComponents',
        textRenderer: textSubRenderer,
      ),
      titleLabel: TextComponent(
        text: 'Components',
        textRenderer: textRenderer,
      ),
      valueListener: _sliderListener,
    );
    buttonContainer.add(sliderComponent);
  }

  Future<void> _sliderListener() async {
    final value = sliderComponent.value;
    final numSvgs = value.toInt();
    if (_numSvgs != numSvgs) {
      sliderComponent.currentLabel?.text = numSvgs.toString();
      _numSvgs = numSvgs;
      removeSvgs();
      addSvgs();
    }
  }

  void addSvgButton(double y) {
    svgButtonComponent = CancellableButtonComponent(
      position: Vector2(center.x, y),
      size: buttonSize,
      anchor: .topCenter,
      defaultLabel: TextComponent(
        text: 'Svg',
        textRenderer: textRenderer,
      ),
      defaultSkin: RoundedRectComponent()
        ..setColor(BasicPalette.darkGreen.color),
      downSkin: RoundedRectComponent()..setColor(BasicPalette.lightGreen.color),
      onReleased: () {
        _currentSvg = (_currentSvg + 1) % _svgs.length;
        _applySvg();
      },
    );
    buttonContainer.add(svgButtonComponent);
    svgButtonText = TextComponent(
      text: svgName,
      anchor: .topCenter,
      position: svgButtonComponent.position + Vector2(0, 30),
      textRenderer: textSubRenderer,
    );
    buttonContainer.add(svgButtonText);
  }

  void addModeButton(double y) {
    modeComponent = CancellableButtonComponent(
      position: Vector2(20, y),
      size: buttonSize,
      anchor: .topLeft,
      defaultLabel: TextComponent(
        text: 'Mode',
        textRenderer: textRenderer,
      ),
      defaultSkin: RoundedRectComponent()..setColor(BasicPalette.darkRed.color),
      downSkin: RoundedRectComponent()..setColor(BasicPalette.lightRed.color),
      onReleased: () {
        _mode = _mode.next;
        _applyMode();
      },
    );
    buttonContainer.add(modeComponent);
    modeText = TextComponent(
      text: '$_mode',
      anchor: .topCenter,
      position: modeComponent.position + Vector2(buttonSize.x / 2, 30),
      textRenderer: textSubRenderer,
    );
    buttonContainer.add(modeText);
  }

  void addSizeButton(double y) {
    sizeComponent = CancellableButtonComponent(
      position: Vector2(size.x - 20, y),
      size: buttonSize,
      anchor: .topRight,
      defaultLabel: TextComponent(
        text: 'Size',
        textRenderer: textRenderer,
      ),
      defaultSkin: RoundedRectComponent()
        ..setColor(BasicPalette.darkBlue.color),
      downSkin: RoundedRectComponent()..setColor(BasicPalette.lightBlue.color),
      onReleased: () {
        _size = _size.next;
        _applySize();
      },
    );
    buttonContainer.add(sizeComponent);
    sizeText = TextComponent(
      text: '$_size',
      anchor: .topCenter,
      position: sizeComponent.position + Vector2(-buttonSize.x / 2, 30),
      textRenderer: textSubRenderer,
    );
    buttonContainer.add(sizeText);
  }

  void removeSvgs() {
    svgContainer.removeWhere((component) => component != svgComponent);
  }

  void _adjustSvgs() {
    final center = this.center;
    final radius = (center.x + center.y) * 0.25;
    final step = rotateAmplitude / numSvgComponents.toDouble();
    final svgs = svgContainer.children.reversed().toList();
    final last = svgs.removeLast();
    assert(
      last == svgComponent,
      'Wrong master component: $svgComponent -> $last',
    );
    assert(svgs.length == _numSvgs, 'Wrong SVG #: $_numSvgs -> ${svgs.length}');

    var angle = step;
    for (final svg in svgs) {
      final isSvg = svg is SvgComponent;
      assert(isSvg, 'Wrong component: $svg');
      if (!isSvg) {
        continue;
      }
      svg.position = Vector2(
        center.x + (radius * cos(angle)),
        center.y + (radius * sin(angle)),
      );
      svg.size = svgSize;
      angle += step;
    }
  }

  void addSvgs() {
    final center = this.center;
    final radius = (center.x + center.y) * 0.25;
    final step = rotateAmplitude / numSvgComponents.toDouble();
    final sStep = 0.75 / numSvgComponents.toDouble();
    final aStep = 0.75 / numSvgComponents.toDouble();
    final rStep = (rotateDuration * 0.5) / numSvgComponents.toDouble();

    var delay = 0.0;
    var angle = step;
    var sScale = 1.0;
    var aScale = 1.0;
    final svgs = <SvgComponent>[];
    for (var i = 0; i < _numSvgs; ++i) {
      final position = Vector2(
        center.x + (radius * cos(angle)),
        center.y + (radius * sin(angle)),
      );

      final p = ui.Paint()..color = Colors.white.withValues(alpha: aScale);
      final s = SvgComponent(
        svg: svgInstance,
        position: position,
        size: svgSize,
        scale: Vector2.all(sScale),
        angle: angle + (pi * 0.5),
        anchor: .center,
        paint: p,
        priority: _numSvgs + _svgPriority - i,
      );
      svgs.add(s);
      final rotate = RotateEffect.by(
        rotateAmplitude,
        EffectController(
          duration: rotateDuration,
          startDelay: delay,
          infinite: true,
        ),
      );
      s.add(rotate);
      angle += step;
      delay += rStep;
      sScale -= sStep;
      aScale -= aStep;
    }
    svgContainer.addAll(svgs.reversed);
  }
}
