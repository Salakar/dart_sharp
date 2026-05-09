import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossless_fixture.dart';
import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('rejects VP8 WebP with invalid frame tag fields', () async {
    final nonKeyFrame = solidVp8Webp(width: 1, height: 1);
    nonKeyFrame[20] |= 1;
    final unsupportedVersion = solidVp8Webp(width: 1, height: 1);
    unsupportedVersion[20] |= 0x08;
    final hiddenKeyFrame = solidVp8Webp(width: 1, height: 1);
    hiddenKeyFrame[20] &= 0xef;
    final oversizedFirstPartition = solidVp8Webp(width: 1, height: 1);
    oversizedFirstPartition[20] |= 0xe0;
    oversizedFirstPartition[21] = 0xff;
    oversizedFirstPartition[22] = 0x7f;

    final cases = <(Uint8List, Matcher)>[
      (nonKeyFrame, isA<UnsupportedCodecException>()),
      (unsupportedVersion, isA<UnsupportedCodecException>()),
      (hiddenKeyFrame, isA<InvalidImageException>()),
      (oversizedFirstPartition, isA<InvalidImageException>()),
    ];

    for (final (bytes, matcher) in cases) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(matcher),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(matcher),
      );
    }
  });

  test('rejects VP8 WebP with zero frame dimensions', () async {
    for (final zeroWidth in <bool>[true, false]) {
      final bytes = solidVp8Webp(width: 1, height: 1);
      final offset = zeroWidth ? 26 : 28;
      bytes[offset] = 0;
      bytes[offset + 1] = 0;

      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects VP8L WebP with unsupported version', () async {
    final bytes = solidVp8lWebp(
      width: 1,
      height: 1,
      red: 1,
      green: 2,
      blue: 3,
      alpha: 255,
    );
    final words = ByteData.sublistView(bytes);
    words.setUint32(
      21,
      words.getUint32(21, Endian.little) | (1 << 29),
      Endian.little,
    );

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects static ALPH chunks after VP8 image data', () async {
    final ordered = alphaSolidVp8Webp(width: 1, height: 1, alpha: <int>[127]);
    final reordered = Uint8List.fromList(<int>[
      ...ordered.sublist(0, 30),
      ...ordered.sublist(40),
      ...ordered.sublist(30, 40),
    ]);

    await expectLater(
      ImagePipeline.fromBytes(reordered).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(reordered).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects non-zero top-level chunk padding bytes', () async {
    final bytes = alphaSolidVp8Webp(width: 2, height: 1, alpha: <int>[0, 255]);
    _poisonFirstChunkPadding(bytes, 'ALPH', start: 12, end: _riffEnd(bytes));

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects malformed static ALPH chunk headers', () async {
    final reservedFlags = alphaSolidVp8Webp(
      width: 1,
      height: 1,
      alpha: <int>[127],
    );
    final reservedAlpha = _firstChunk(
      reservedFlags,
      'ALPH',
      start: 12,
      end: _riffEnd(reservedFlags),
    );
    reservedFlags[reservedAlpha.start] |= 0x80;

    final unsupportedCompression = alphaSolidVp8Webp(
      width: 1,
      height: 1,
      alpha: <int>[127],
    );
    final compressionAlpha = _firstChunk(
      unsupportedCompression,
      'ALPH',
      start: 12,
      end: _riffEnd(unsupportedCompression),
    );
    unsupportedCompression[compressionAlpha.start] |= 0x02;

    for (final bytes in <Uint8List>[reservedFlags, unsupportedCompression]) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects static VP8 alpha flag and chunk mismatches', () async {
    final alphaFlagWithoutChunk = extendedSolidVp8Webp(width: 1, height: 1);
    alphaFlagWithoutChunk[20] |= 0x10;
    final alphaChunkWithoutFlag = alphaSolidVp8Webp(
      width: 1,
      height: 1,
      alpha: <int>[127],
    );
    alphaChunkWithoutFlag[20] &= 0xef;

    for (final bytes in <Uint8List>[
      alphaFlagWithoutChunk,
      alphaChunkWithoutFlag,
    ]) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects static VP8L alpha flag and payload mismatches', () async {
    final alphaFlagWithoutPayloadAlpha = extendedVp8lWebp(
      width: 1,
      height: 1,
      red: 1,
      green: 2,
      blue: 3,
      alpha: 255,
    );
    alphaFlagWithoutPayloadAlpha[20] |= 0x10;
    final payloadAlphaWithoutFlag = extendedVp8lWebp(
      width: 1,
      height: 1,
      red: 1,
      green: 2,
      blue: 3,
      alpha: 127,
    );
    payloadAlphaWithoutFlag[20] &= 0xef;

    for (final bytes in <Uint8List>[
      alphaFlagWithoutPayloadAlpha,
      payloadAlphaWithoutFlag,
    ]) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects animation frame ALPH chunks after VP8 image data', () async {
    final ordered = animatedVp8Webp(width: 1, height: 1, alpha: <int>[127]);
    final reordered = Uint8List.fromList(<int>[
      ...ordered.sublist(0, 68),
      ...ordered.sublist(78),
      ...ordered.sublist(68, 78),
    ]);

    await expectLater(
      ImagePipeline.fromBytes(reordered).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(reordered).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects non-zero animation frame chunk padding bytes', () async {
    final bytes = animatedVp8Webp(width: 2, height: 1, alpha: <int>[0, 255]);
    final frame = _firstChunk(bytes, 'ANMF', start: 12, end: _riffEnd(bytes));
    _poisonFirstChunkPadding(
      bytes,
      'ALPH',
      start: frame.start + 16,
      end: frame.end,
    );

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects malformed animation frame ALPH chunk headers', () async {
    final bytes = animatedVp8Webp(width: 1, height: 1, alpha: <int>[127]);
    final frame = _firstChunk(bytes, 'ANMF', start: 12, end: _riffEnd(bytes));
    final alpha = _firstChunk(
      bytes,
      'ALPH',
      start: frame.start + 16,
      end: frame.end,
    );
    bytes[alpha.start] |= 0x80;

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animation alpha flag and frame mismatches', () async {
    final alphaFlagWithoutFrameAlpha = animatedVp8Webp(width: 1, height: 1);
    alphaFlagWithoutFrameAlpha[20] |= 0x10;
    final frameAlphaWithoutFlag = animatedVp8Webp(
      width: 1,
      height: 1,
      alpha: <int>[127],
    );
    frameAlphaWithoutFlag[20] &= 0xef;

    for (final bytes in <Uint8List>[
      alphaFlagWithoutFrameAlpha,
      frameAlphaWithoutFlag,
    ]) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects VP8X chunks that are not first', () async {
    final imageBeforeVp8x = extendedSolidVp8Webp(width: 1, height: 1);
    final alphaBeforeVp8x = alphaSolidVp8Webp(
      width: 1,
      height: 1,
      alpha: <int>[127],
    );
    final cases = <Uint8List>[
      Uint8List.fromList(<int>[
        ...imageBeforeVp8x.sublist(0, 12),
        ...imageBeforeVp8x.sublist(30),
        ...imageBeforeVp8x.sublist(12, 30),
      ]),
      Uint8List.fromList(<int>[
        ...alphaBeforeVp8x.sublist(0, 12),
        ...alphaBeforeVp8x.sublist(30, 40),
        ...alphaBeforeVp8x.sublist(12, 30),
        ...alphaBeforeVp8x.sublist(40),
      ]),
    ];

    for (final bytes in cases) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects duplicate WebP required chunks', () async {
    final duplicateVp8x = _insertChunkAfter(
      extendedSolidVp8Webp(width: 1, height: 1),
      'VP8X',
      'VP8X',
      <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    );
    final duplicateAnim = _insertChunkAfter(
      animatedVp8Webp(width: 1, height: 1),
      'ANIM',
      'ANIM',
      <int>[0, 0, 0, 0, 0, 0],
    );

    for (final bytes in <Uint8List>[duplicateVp8x, duplicateAnim]) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects VP8X chunks with invalid length', () async {
    final bytes = extendedSolidVp8Webp(width: 1, height: 1);
    ByteData.sublistView(bytes).setUint32(16, 9, Endian.little);

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects VP8X chunks with reserved bytes', () async {
    for (final offset in <int>[21, 22, 23]) {
      final bytes = extendedSolidVp8Webp(width: 1, height: 1);
      bytes[offset] = 1;

      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects extended metadata chunks without VP8X', () async {
    for (final type in <String>['ICCP', 'EXIF', 'XMP ']) {
      final bytes = _appendChunk(solidVp8Webp(width: 1, height: 1), type, <int>[
        1,
      ]);

      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects ICCP chunks after image data', () async {
    final staticAfterImage = _appendChunk(
      extendedSolidVp8Webp(width: 1, height: 1),
      'ICCP',
      <int>[1],
    );
    staticAfterImage[20] |= 0x20;

    final animatedAfterFrame = _appendChunk(
      animatedVp8Webp(width: 1, height: 1),
      'ICCP',
      <int>[1],
    );
    animatedAfterFrame[20] |= 0x20;

    final animatedAfterAnim = _insertChunkAfter(
      animatedVp8Webp(width: 1, height: 1),
      'ANIM',
      'ICCP',
      <int>[1],
    );
    animatedAfterAnim[20] |= 0x20;
    final staticAfterAlpha = _insertChunkAfter(
      alphaSolidVp8Webp(width: 1, height: 1, alpha: <int>[127]),
      'ALPH',
      'ICCP',
      <int>[1],
    );
    staticAfterAlpha[20] |= 0x20;

    for (final bytes in <Uint8List>[
      staticAfterImage,
      animatedAfterFrame,
      animatedAfterAnim,
      staticAfterAlpha,
    ]) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects duplicate WebP metadata chunks', () async {
    final duplicateProfile = _insertChunkAfter(
      _insertChunkAfter(
        extendedSolidVp8Webp(width: 1, height: 1),
        'VP8X',
        'ICCP',
        <int>[1],
      ),
      'ICCP',
      'ICCP',
      <int>[2],
    );
    duplicateProfile[20] |= 0x20;
    final duplicateExif = _appendChunk(
      _appendChunk(extendedSolidVp8Webp(width: 1, height: 1), 'EXIF', <int>[1]),
      'EXIF',
      <int>[2],
    );
    duplicateExif[20] |= 0x08;
    final duplicateXmp = _appendChunk(
      _appendChunk(extendedSolidVp8Webp(width: 1, height: 1), 'XMP ', <int>[1]),
      'XMP ',
      <int>[2],
    );
    duplicateXmp[20] |= 0x04;

    for (final bytes in <Uint8List>[
      duplicateProfile,
      duplicateExif,
      duplicateXmp,
    ]) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects VP8X metadata flag and chunk mismatches', () async {
    for (final (flag, type) in <(int, String)>[
      (0x20, 'ICCP'),
      (0x08, 'EXIF'),
      (0x04, 'XMP '),
    ]) {
      final flagWithoutChunk = extendedSolidVp8Webp(width: 1, height: 1);
      flagWithoutChunk[20] |= flag;
      final chunkWithoutFlag = _appendChunk(
        extendedSolidVp8Webp(width: 1, height: 1),
        type,
        <int>[1],
      );

      for (final bytes in <Uint8List>[flagWithoutChunk, chunkWithoutFlag]) {
        await expectLater(
          ImagePipeline.fromBytes(bytes).metadata(),
          throwsA(isA<InvalidImageException>()),
        );
        await expectLater(
          ImagePipeline.fromBytes(bytes).toPixelImage(),
          throwsA(isA<InvalidImageException>()),
        );
      }
    }
  });

  test('rejects animation frames before ANIM header', () async {
    final ordered = animatedVp8Webp(width: 1, height: 1);
    final reordered = Uint8List.fromList(<int>[
      ...ordered.sublist(0, 30),
      ...ordered.sublist(44),
      ...ordered.sublist(30, 44),
    ]);

    await expectLater(
      ImagePipeline.fromBytes(reordered).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(reordered).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animation frames with reserved flag bits', () async {
    final bytes = animatedVp8Webp(width: 1, height: 1);
    bytes[67] |= 0x04;

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects ANIM chunks with invalid length', () async {
    final ordered = animatedVp8Webp(width: 1, height: 1);
    final bytes = Uint8List(ordered.length + 2)
      ..setAll(0, ordered.sublist(0, 34))
      ..setAll(38, ordered.sublist(38, 44))
      ..setAll(44, <int>[0, 0])
      ..setAll(46, ordered.sublist(44));
    final words = ByteData.sublistView(bytes);
    words.setUint32(4, ordered.length - 6, Endian.little);
    words.setUint32(34, 8, Endian.little);

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects extended VP8 WebP with mismatched canvas dimensions', () async {
    final bytes = extendedSolidVp8Webp(width: 1, height: 1);
    bytes[24] = 1;

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test(
    'rejects extended VP8L WebP with mismatched canvas dimensions',
    () async {
      final bytes = extendedVp8lWebp(
        width: 1,
        height: 1,
        red: 1,
        green: 2,
        blue: 3,
        alpha: 255,
      );
      bytes[27] = 1;

      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    },
  );
}

Uint8List _appendChunk(Uint8List webp, String type, List<int> payload) {
  final chunk = _chunkBytes(type, payload);
  final out = Uint8List(webp.length + chunk.length)
    ..setAll(0, webp)
    ..setAll(webp.length, chunk);
  ByteData.sublistView(out).setUint32(4, out.length - 8, Endian.little);
  return out;
}

Uint8List _insertChunkAfter(
  Uint8List webp,
  String afterType,
  String type,
  List<int> payload,
) {
  final riffEnd = _riffEnd(webp);
  final after = _firstChunk(webp, afterType, start: 12, end: riffEnd);
  final offset = after.end + (after.length.isOdd ? 1 : 0);
  final chunk = _chunkBytes(type, payload);
  final out = Uint8List(webp.length + chunk.length)
    ..setAll(0, webp.sublist(0, offset))
    ..setAll(offset, chunk)
    ..setAll(offset + chunk.length, webp.sublist(offset));
  ByteData.sublistView(out).setUint32(4, out.length - 8, Endian.little);
  return out;
}

Uint8List _chunkBytes(String type, List<int> payload) {
  final padding = payload.length.isOdd ? 1 : 0;
  final out = Uint8List(8 + payload.length + padding);
  out.setAll(0, type.codeUnits);
  final words = ByteData.sublistView(out);
  words.setUint32(4, payload.length, Endian.little);
  out.setAll(8, payload);
  return out;
}

({int start, int end, int length}) _firstChunk(
  Uint8List bytes,
  String type, {
  required int start,
  required int end,
}) {
  final words = ByteData.sublistView(bytes);
  var offset = start;
  while (offset + 8 <= end) {
    final chunkType = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = words.getUint32(offset + 4, Endian.little);
    final payloadStart = offset + 8;
    final payloadEnd = payloadStart + length;
    if (payloadEnd > end) {
      break;
    }
    if (chunkType == type) {
      return (start: payloadStart, end: payloadEnd, length: length);
    }
    offset = payloadEnd + (length.isOdd ? 1 : 0);
  }
  throw StateError('No $type chunk found.');
}

void _poisonFirstChunkPadding(
  Uint8List bytes,
  String type, {
  required int start,
  required int end,
}) {
  final chunk = _firstChunk(bytes, type, start: start, end: end);
  if (chunk.length.isEven || chunk.end >= end) {
    throw StateError('No $type padding byte found.');
  }
  bytes[chunk.end] = 1;
}

int _riffEnd(Uint8List bytes) =>
    8 + ByteData.sublistView(bytes).getUint32(4, Endian.little);
