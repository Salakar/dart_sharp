/// Blend modes supported by compositing.
enum BlendMode {
  /// Clear source and destination.
  clear,

  /// Replace destination with source.
  source,

  /// Source over destination.
  over,

  /// Source inside destination.
  in_,

  /// Source outside destination.
  out,

  /// Source atop destination.
  atop,

  /// Keep destination.
  dest,

  /// Destination over source.
  destOver,

  /// Destination inside source.
  destIn,

  /// Destination outside source.
  destOut,

  /// Destination atop source.
  destAtop,

  /// Exclusive-or alpha composition.
  xor,

  /// Saturating channel addition.
  add,

  /// Saturating channel addition alias.
  saturate,

  /// Multiply channels.
  multiply,

  /// Screen channels.
  screen,

  /// Overlay channels.
  overlay,

  /// Darken channels.
  darken,

  /// Lighten channels.
  lighten,

  /// Color dodge.
  colorDodge,

  /// British spelling alias for color dodge.
  colourDodge,

  /// Color burn.
  colorBurn,

  /// British spelling alias for color burn.
  colourBurn,

  /// Hard light.
  hardLight,

  /// Soft light.
  softLight,

  /// Difference.
  difference,

  /// Exclusion.
  exclusion,
}
