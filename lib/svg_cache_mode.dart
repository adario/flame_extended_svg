enum SvgCacheMode {
  legacy,
  integral,
  fixed;

  SvgCacheMode get next {
    switch (this) {
      case .legacy:
        return .integral;
      case .integral:
        return .fixed;
      case .fixed:
        return .legacy;
    }
  }

  @override
  String toString() => super.toString().replaceAll('SvgCacheMode.', '');
}
