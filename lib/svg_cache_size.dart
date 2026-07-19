import 'package:flame_svg/flame_svg.dart';

enum SvgCacheSize {
  standard,
  medium,
  large,
  huge,
  unlimited;

  SvgCacheSize get next {
    switch (this) {
      case .standard:
        return .medium;
      case .medium:
        return .large;
      case .large:
        return .huge;
      case .huge:
        return .unlimited;
      case .unlimited:
        return .standard;
    }
  }

  int get quantity {
    switch (this) {
      case .standard:
        return Svg.defaultCacheSize;
      case .medium:
        return 50;
      case .large:
        return 100;
      case .huge:
        return 250;
      case .unlimited:
        return Svg.unlimitedCacheSize;
    }
  }

  String get quantityString {
    switch (this) {
      case .unlimited:
        return '∞';
      default:
        return '$quantity';
    }
  }

  @override
  String toString() => super.toString().replaceAll('SvgCacheSize.', '');
}
