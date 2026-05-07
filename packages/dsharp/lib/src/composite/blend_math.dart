import 'dart:math';

import '../operations/pixel_helpers.dart';
import '../pixels/color.dart';
import 'blend_mode.dart';

/// Blends one source pixel over one destination pixel.
RgbaColor blendPixel(
  RgbaColor dest,
  RgbaColor source,
  BlendMode mode, {
  bool sourcePremultiplied = false,
}) {
  final s = _Pixel.fromColor(source, premultiplied: sourcePremultiplied);
  final d = _Pixel.fromColor(dest);
  return switch (mode) {
    BlendMode.clear => RgbaColor.transparent,
    BlendMode.source => _fromPremul(s.pr, s.pg, s.pb, s.a),
    BlendMode.over => _fromPremul(
      s.pr + (d.pr * (1 - s.a)),
      s.pg + (d.pg * (1 - s.a)),
      s.pb + (d.pb * (1 - s.a)),
      s.a + (d.a * (1 - s.a)),
    ),
    BlendMode.in_ => _fromPremul(s.pr * d.a, s.pg * d.a, s.pb * d.a, s.a * d.a),
    BlendMode.out => _fromPremul(
      s.pr * (1 - d.a),
      s.pg * (1 - d.a),
      s.pb * (1 - d.a),
      s.a * (1 - d.a),
    ),
    BlendMode.atop => _fromPremul(
      (s.pr * d.a) + (d.pr * (1 - s.a)),
      (s.pg * d.a) + (d.pg * (1 - s.a)),
      (s.pb * d.a) + (d.pb * (1 - s.a)),
      d.a,
    ),
    BlendMode.dest => dest,
    BlendMode.destOver => _fromPremul(
      d.pr + (s.pr * (1 - d.a)),
      d.pg + (s.pg * (1 - d.a)),
      d.pb + (s.pb * (1 - d.a)),
      d.a + (s.a * (1 - d.a)),
    ),
    BlendMode.destIn => _fromPremul(
      d.pr * s.a,
      d.pg * s.a,
      d.pb * s.a,
      d.a * s.a,
    ),
    BlendMode.destOut => _fromPremul(
      d.pr * (1 - s.a),
      d.pg * (1 - s.a),
      d.pb * (1 - s.a),
      d.a * (1 - s.a),
    ),
    BlendMode.destAtop => _fromPremul(
      (d.pr * s.a) + (s.pr * (1 - d.a)),
      (d.pg * s.a) + (s.pg * (1 - d.a)),
      (d.pb * s.a) + (s.pb * (1 - d.a)),
      s.a,
    ),
    BlendMode.xor => _fromPremul(
      (s.pr * (1 - d.a)) + (d.pr * (1 - s.a)),
      (s.pg * (1 - d.a)) + (d.pg * (1 - s.a)),
      (s.pb * (1 - d.a)) + (d.pb * (1 - s.a)),
      (s.a * (1 - d.a)) + (d.a * (1 - s.a)),
    ),
    _ => _artistic(s, d, mode),
  };
}

RgbaColor _artistic(_Pixel s, _Pixel d, BlendMode mode) {
  final blended = (
    r: _blendChannel(s.r, d.r, mode),
    g: _blendChannel(s.g, d.g, mode),
    b: _blendChannel(s.b, d.b, mode),
  );
  return _fromPremul(
    (blended.r * s.a * d.a) + (s.r * s.a * (1 - d.a)) + (d.r * d.a * (1 - s.a)),
    (blended.g * s.a * d.a) + (s.g * s.a * (1 - d.a)) + (d.g * d.a * (1 - s.a)),
    (blended.b * s.a * d.a) + (s.b * s.a * (1 - d.a)) + (d.b * d.a * (1 - s.a)),
    s.a + (d.a * (1 - s.a)),
  );
}

double _blendChannel(double s, double d, BlendMode mode) {
  return switch (mode) {
    BlendMode.add || BlendMode.saturate => min(1, s + d),
    BlendMode.multiply => s * d,
    BlendMode.screen => s + d - (s * d),
    BlendMode.overlay => d < 0.5 ? 2 * s * d : 1 - (2 * (1 - s) * (1 - d)),
    BlendMode.darken => min(s, d),
    BlendMode.lighten => max(s, d),
    BlendMode.colorDodge ||
    BlendMode.colourDodge => s >= 1 ? 1 : min(1, d / (1 - s)),
    BlendMode.colorBurn ||
    BlendMode.colourBurn => s <= 0 ? 0 : 1 - min(1, (1 - d) / s),
    BlendMode.hardLight => s < 0.5 ? 2 * s * d : 1 - (2 * (1 - s) * (1 - d)),
    BlendMode.softLight => (1 - (2 * s)) * d * d + (2 * s * d),
    BlendMode.difference => (d - s).abs(),
    BlendMode.exclusion => s + d - (2 * s * d),
    _ => s,
  };
}

RgbaColor _fromPremul(double red, double green, double blue, double alpha) {
  if (alpha <= 0) {
    return RgbaColor.transparent;
  }
  return RgbaColor(
    red: byteClamp(red * 255 / alpha),
    green: byteClamp(green * 255 / alpha),
    blue: byteClamp(blue * 255 / alpha),
    alpha: byteClamp(alpha * 255),
  );
}

final class _Pixel {
  const _Pixel({
    required this.r,
    required this.g,
    required this.b,
    required this.a,
    required this.pr,
    required this.pg,
    required this.pb,
  });

  factory _Pixel.fromColor(RgbaColor color, {bool premultiplied = false}) {
    final alpha = color.alpha / 255;
    final pr = color.red / 255;
    final pg = color.green / 255;
    final pb = color.blue / 255;
    return _Pixel(
      r: premultiplied && alpha > 0 ? pr / alpha : pr,
      g: premultiplied && alpha > 0 ? pg / alpha : pg,
      b: premultiplied && alpha > 0 ? pb / alpha : pb,
      a: alpha,
      pr: premultiplied ? pr : pr * alpha,
      pg: premultiplied ? pg : pg * alpha,
      pb: premultiplied ? pb : pb * alpha,
    );
  }

  final double r;
  final double g;
  final double b;
  final double a;
  final double pr;
  final double pg;
  final double pb;
}
