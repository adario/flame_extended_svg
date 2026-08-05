enum SvgCacheMode {
  integral,
  fixed;

  SvgCacheMode get next {
    switch (this) {
      case .integral:
        return .fixed;
      case .fixed:
        return .integral;
    }
  }

  bool get fixedRatio => this == .fixed;

  @override
  String toString() => super.toString().replaceAll('SvgCacheMode.', '');
}
