import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  RawPixels raw2x2() {
    return rawRgba(2, 2, <int>[
      1,
      0,
      0,
      255,
      2,
      0,
      0,
      255,
      3,
      0,
      0,
      255,
      4,
      0,
      0,
      255,
    ]);
  }

  test(
    'flip, flop, and right-angle rotate move pixels deterministically',
    () async {
      final flipped = await pixels(
        ImagePipeline.fromRawPixels(raw2x2()).flip(),
      );
      final flopped = await pixels(
        ImagePipeline.fromRawPixels(raw2x2()).flop(),
      );
      final rotated = await pixels(
        ImagePipeline.fromRawPixels(raw2x2()).rotate(90),
      );

      expect(redBytes(flipped), <int>[3, 4, 1, 2]);
      expect(redBytes(flopped), <int>[2, 1, 4, 3]);
      expect(redBytes(rotated), <int>[3, 1, 4, 2]);
    },
  );

  test(
    'autoOrient hook records operation and leaves pixels unchanged',
    () async {
      final pipeline = ImagePipeline.fromRawPixels(raw2x2()).autoOrient();
      final image = await pixels(pipeline);

      expect(pipeline.operations, <String>['autoOrient']);
      expect(redBytes(image), <int>[1, 2, 3, 4]);
    },
  );

  test('autoOrient applies encoded EXIF orientation', () async {
    final jpeg = await ImagePipeline.fromRawPixels(
      rawRgb(3, 2, <int>[
        255,
        0,
        0,
        0,
        255,
        0,
        0,
        0,
        255,
        255,
        255,
        0,
        255,
        0,
        255,
        0,
        255,
        255,
      ]),
    ).jpeg().toBytes();
    final bytes = _withExifOrientation(jpeg, 6);

    final sourceMetadata = await ImagePipeline.fromBytes(bytes).metadata();
    final image = await ImagePipeline.fromBytes(
      bytes,
    ).autoOrient().toPixelImage();
    final orientedMetadata = await ImagePipeline.fromBytes(
      bytes,
    ).autoOrient().metadata();

    expect(sourceMetadata.width, 3);
    expect(sourceMetadata.height, 2);
    expect(sourceMetadata.orientation, 6);
    expect(image.width, 2);
    expect(image.height, 3);
    expect(orientedMetadata.width, 2);
    expect(orientedMetadata.height, 3);
    expect(orientedMetadata.orientation, isNull);
  });

  test(
    'arbitrary rotate expands bounds and affine validates matrices',
    () async {
      final rotated = await pixels(
        ImagePipeline.fromRawPixels(raw2x2()).rotate(45),
      );
      final affine = await pixels(
        ImagePipeline.fromRawPixels(
          raw2x2(),
        ).affine(const AffineOptions(a: 2, b: 0, c: 0, d: 2)),
      );

      expect(rotated.width, 3);
      expect(rotated.height, 3);
      expect(affine.width, 4);
      expect(affine.height, 4);
      expect(
        ImagePipeline.fromRawPixels(
          raw2x2(),
        ).affine(const AffineOptions(a: 1, b: 1, c: 1, d: 1)).toPixelImage(),
        throwsA(isA<OperationValidationException>()),
      );
    },
  );

  test('operation ordering is preserved with resize and extract', () async {
    final rotateThenExtract = await pixels(
      ImagePipeline.fromRawPixels(
        raw2x2(),
      ).rotate(90).extract(const Region(left: 0, top: 0, width: 1, height: 1)),
    );
    final extractThenRotate = await pixels(
      ImagePipeline.fromRawPixels(
        raw2x2(),
      ).extract(const Region(left: 0, top: 0, width: 1, height: 1)).rotate(90),
    );

    expect(firstBytes(rotateThenExtract), <int>[3, 0, 0, 255]);
    expect(firstBytes(extractThenRotate), <int>[1, 0, 0, 255]);
  });

  test('blur, median, dilate, and erode handle tiny edge pixels', () async {
    final raw = rawGray(3, 3, <int>[0, 0, 0, 0, 255, 0, 0, 0, 0]);
    final blurred = await pixels(ImagePipeline.fromRawPixels(raw).blur());
    final median = await pixels(ImagePipeline.fromRawPixels(raw).median());
    final dilated = await pixels(ImagePipeline.fromRawPixels(raw).dilate());
    final eroded = await pixels(ImagePipeline.fromRawPixels(raw).erode());

    expect(firstBytes(blurred)[4], 28);
    expect(firstBytes(median)[4], 0);
    expect(firstBytes(dilated)[0], 255);
    expect(firstBytes(eroded)[4], 0);
  });

  test('convolve supports scale and rejects invalid kernels', () async {
    final raw = rawGray(1, 1, <int>[20]);
    final convolved = await pixels(
      ImagePipeline.fromRawPixels(raw).convolve(
        const ConvolutionKernel(
          width: 1,
          height: 1,
          values: <num>[2],
          scale: 2,
        ),
      ),
    );

    expect(firstBytes(convolved), <int>[20]);
    expect(
      ImagePipeline.fromRawPixels(raw)
          .convolve(
            const ConvolutionKernel(width: 2, height: 1, values: <num>[1, 1]),
          )
          .toPixelImage(),
      throwsA(isA<OperationValidationException>()),
    );
  });
}

Uint8List _withExifOrientation(Uint8List jpeg, int orientation) {
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _jpegSegment(writer, 0xe1, _exifOrientation(orientation));
  writer.writeBytes(jpeg.sublist(2));
  return writer.toBytes();
}

void _jpegSegment(ByteWriter writer, int marker, List<int> data) {
  writer
    ..writeByte(0xff)
    ..writeByte(marker)
    ..writeUint16Be(data.length + 2)
    ..writeBytes(data);
}

Uint8List _exifOrientation(int orientation) {
  final writer = ByteWriter()
    ..writeAscii('Exif')
    ..writeUint16Be(0)
    ..writeAscii('II')
    ..writeUint16Le(42)
    ..writeUint32Le(8)
    ..writeUint16Le(1)
    ..writeUint16Le(0x0112)
    ..writeUint16Le(3)
    ..writeUint32Le(1)
    ..writeUint16Le(orientation)
    ..writeUint16Le(0)
    ..writeUint32Le(0);
  return writer.toBytes();
}
