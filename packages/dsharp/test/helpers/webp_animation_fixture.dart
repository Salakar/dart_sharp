part of 'webp_lossless_fixture.dart';

/// Builds a small animated WebP whose frames are VP8L payloads.
Uint8List animatedVp8lWebp() {
  final frame1 = _vp8lPayload(
    width: 2,
    height: 1,
    red: 220,
    green: 10,
    blue: 20,
    alpha: 255,
  );
  final frame2 = _vp8lPayload(
    width: 2,
    height: 1,
    red: 20,
    green: 30,
    blue: 240,
    alpha: 255,
  );
  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(0x12)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(3)
    ..u24(0);
  _writeChunk(
    chunks,
    'ANIM',
    (_ByteWriter()
          ..u32(0xff050607)
          ..u16(3))
        .finish(),
  );
  _writeChunk(
    chunks,
    'ANMF',
    _animationFramePayload(
      x: 0,
      y: 0,
      width: 2,
      height: 1,
      durationMs: 10,
      dispose: true,
      blend: false,
      vp8l: frame1,
    ),
  );
  _writeChunk(
    chunks,
    'ANMF',
    _animationFramePayload(
      x: 2,
      y: 0,
      width: 2,
      height: 1,
      durationMs: 20,
      dispose: false,
      blend: false,
      vp8l: frame2,
    ),
  );
  final payload = chunks.finish();
  return (_ByteWriter()
        ..ascii('RIFF')
        ..u32(4 + payload.length)
        ..ascii('WEBP')
        ..bytes(payload))
      .finish();
}

/// Builds a VP8L animation that alpha-blends over a retained canvas.
Uint8List blendedAnimatedVp8lWebp() {
  final base = _vp8lPayload(
    width: 2,
    height: 1,
    red: 255,
    green: 0,
    blue: 0,
    alpha: 255,
  );
  final overlay = _vp8lPayload(
    width: 1,
    height: 1,
    red: 0,
    green: 0,
    blue: 255,
    alpha: 128,
  );
  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(0x12)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(1)
    ..u24(0);
  _writeChunk(
    chunks,
    'ANIM',
    (_ByteWriter()
          ..u32(0)
          ..u16(1))
        .finish(),
  );
  _writeChunk(
    chunks,
    'ANMF',
    _animationFramePayload(
      x: 0,
      y: 0,
      width: 2,
      height: 1,
      durationMs: 10,
      dispose: false,
      blend: false,
      vp8l: base,
    ),
  );
  _writeChunk(
    chunks,
    'ANMF',
    _animationFramePayload(
      x: 0,
      y: 0,
      width: 1,
      height: 1,
      durationMs: 10,
      dispose: false,
      blend: true,
      vp8l: overlay,
    ),
  );
  final payload = chunks.finish();
  return (_ByteWriter()
        ..ascii('RIFF')
        ..u32(4 + payload.length)
        ..ascii('WEBP')
        ..bytes(payload))
      .finish();
}

/// Builds an invalid animated WebP missing the required ANIM chunk.
Uint8List animatedVp8lWebpWithoutAnimHeader() {
  return _invalidAnimatedVp8lWebp(vp8xFlags: 0x02, includeAnim: false);
}

/// Builds an invalid animated WebP missing the VP8X animation flag.
Uint8List animatedVp8lWebpWithoutAnimationFlag() {
  return _invalidAnimatedVp8lWebp(vp8xFlags: 0, includeAnim: true);
}

/// Builds an invalid animated WebP missing all ANMF frames.
Uint8List animatedVp8lWebpWithoutFrames() {
  return _invalidAnimatedVp8lWebp(
    vp8xFlags: 0x02,
    includeAnim: true,
    includeFrame: false,
  );
}

/// Builds an invalid VP8L animation frame that also carries an ALPH chunk.
Uint8List animatedVp8lWebpWithAlphaChunk() {
  final frame = _vp8lPayload(
    width: 1,
    height: 1,
    red: 12,
    green: 34,
    blue: 56,
    alpha: 255,
  );
  final framePayload = _ByteWriter()
    ..u24(0)
    ..u24(0)
    ..u24(0)
    ..u24(0)
    ..u24(10)
    ..byte(2);
  _writeChunk(framePayload, 'ALPH', Uint8List.fromList(<int>[0, 255]));
  _writeChunk(framePayload, 'VP8L', frame);

  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(0x12)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(0)
    ..u24(0);
  _writeChunk(
    chunks,
    'ANIM',
    (_ByteWriter()
          ..u32(0)
          ..u16(1))
        .finish(),
  );
  _writeChunk(chunks, 'ANMF', framePayload.finish());
  final payload = chunks.finish();
  return (_ByteWriter()
        ..ascii('RIFF')
        ..u32(4 + payload.length)
        ..ascii('WEBP')
        ..bytes(payload))
      .finish();
}

Uint8List _invalidAnimatedVp8lWebp({
  required int vp8xFlags,
  required bool includeAnim,
  bool includeFrame = true,
}) {
  final frame = _vp8lPayload(
    width: 1,
    height: 1,
    red: 12,
    green: 34,
    blue: 56,
    alpha: 255,
  );
  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(vp8xFlags)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(0)
    ..u24(0);
  if (includeAnim) {
    _writeChunk(
      chunks,
      'ANIM',
      (_ByteWriter()
            ..u32(0)
            ..u16(1))
          .finish(),
    );
  }
  if (includeFrame) {
    _writeChunk(
      chunks,
      'ANMF',
      _animationFramePayload(
        x: 0,
        y: 0,
        width: 1,
        height: 1,
        durationMs: 10,
        dispose: false,
        blend: false,
        vp8l: frame,
      ),
    );
  }
  final payload = chunks.finish();
  return (_ByteWriter()
        ..ascii('RIFF')
        ..u32(4 + payload.length)
        ..ascii('WEBP')
        ..bytes(payload))
      .finish();
}

/// Builds an extended static WebP whose image payload is VP8L.
Uint8List extendedVp8lWebp({
  required int width,
  required int height,
  required int red,
  required int green,
  required int blue,
  required int alpha,
}) {
  final vp8l = _vp8lPayload(
    width: width,
    height: height,
    red: red,
    green: green,
    blue: blue,
    alpha: alpha,
  );
  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(alpha == 255 ? 0 : 0x10)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(width - 1)
    ..u24(height - 1);
  _writeChunk(chunks, 'VP8L', vp8l);
  final payload = chunks.finish();
  return (_ByteWriter()
        ..ascii('RIFF')
        ..u32(4 + payload.length)
        ..ascii('WEBP')
        ..bytes(payload))
      .finish();
}

Uint8List _vp8lPayload({
  required int width,
  required int height,
  required int red,
  required int green,
  required int blue,
  required int alpha,
}) {
  final bits = _BitWriter()
    ..write(width - 1, 14)
    ..write(height - 1, 14)
    ..write(alpha == 255 ? 0 : 1, 1)
    ..write(0, 3)
    ..write(0, 1)
    ..write(0, 1)
    ..write(0, 1);
  _writeSingleSymbolCode(bits, green);
  _writeSingleSymbolCode(bits, red);
  _writeSingleSymbolCode(bits, blue);
  _writeSingleSymbolCode(bits, alpha);
  _writeSingleSymbolCode(bits, 0);
  return Uint8List.fromList(<int>[0x2f, ...bits.finish()]);
}

Uint8List _animationFramePayload({
  required int x,
  required int y,
  required int width,
  required int height,
  required int durationMs,
  required bool dispose,
  required bool blend,
  required Uint8List vp8l,
}) {
  final out = _ByteWriter()
    ..u24(x ~/ 2)
    ..u24(y ~/ 2)
    ..u24(width - 1)
    ..u24(height - 1)
    ..u24(durationMs)
    ..byte((dispose ? 1 : 0) | (blend ? 0 : 2));
  _writeChunk(out, 'VP8L', vp8l);
  return out.finish();
}

void _writeChunk(_ByteWriter out, String name, Uint8List data) {
  out
    ..ascii(name)
    ..u32(data.length)
    ..bytes(data);
  if (data.length.isOdd) {
    out.byte(0);
  }
}
