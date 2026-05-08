import 'dart:async';
import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('byte source defensively copies Uint8List input', () {
    final bytes = Uint8List.fromList(<int>[1, 2, 3]);
    final source = ImageSource.bytes(bytes) as BytesImageSource;

    bytes[0] = 9;
    final copy = source.bytes;
    copy[1] = 8;

    expect(source.bytes, <int>[1, 2, 3]);
  });

  test('byte data source respects offset and length', () {
    final all = Uint8List.fromList(<int>[0, 1, 2, 3, 4]);
    final data = ByteData.sublistView(all, 1, 4);
    final source = ImageSource.byteData(data) as BytesImageSource;

    expect(source.bytes, <int>[1, 2, 3]);
  });

  test('stream source buffers chunks within limit', () async {
    final source =
        ImageSource.stream(
              Stream<List<int>>.fromIterable(<List<int>>[
                <int>[1, 2],
                <int>[3],
              ]),
              maxBytes: 3,
            )
            as StreamImageSource;

    expect(await source.collectBytes(), <int>[1, 2, 3]);
  });

  test('stream source enforces max byte limit', () {
    final source =
        ImageSource.stream(
              Stream<List<int>>.fromIterable(<List<int>>[
                <int>[1, 2],
                <int>[3],
              ]),
              maxBytes: 2,
            )
            as StreamImageSource;

    expect(source.collectBytes, throwsA(isA<ImageLimitException>()));
  });

  test('pipeline input limits apply across web-safe sources', () async {
    final encoded = await ImagePipeline.create(
      const CreateImage(
        width: 2,
        height: 1,
        channels: 4,
        background: RgbaColor.white,
      ),
    ).png().toBytes();

    await expectLater(
      ImagePipeline.fromBytes(
        encoded,
        limits: InputSafetyLimits(maxBytes: encoded.length - 1),
      ).metadata(),
      throwsA(isA<ImageLimitException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(
        encoded,
        limits: const InputSafetyLimits(maxPixels: 1),
      ).metadata(),
      throwsA(isA<ImageLimitException>()),
    );
    await expectLater(
      ImagePipeline.fromStream(
        Stream<List<int>>.fromIterable(<List<int>>[encoded]),
        limits: const InputSafetyLimits(maxBytes: 2),
      ).toPixelImage(),
      throwsA(isA<ImageLimitException>()),
    );
    await expectLater(
      ImagePipeline.fromRawPixels(
        _raw(),
        limits: const InputSafetyLimits(maxPixels: 0),
      ).toPixelImage(),
      throwsA(isA<ImageLimitException>()),
    );
    await expectLater(
      ImagePipeline.create(
        const CreateImage(
          width: 2,
          height: 1,
          channels: 4,
          background: RgbaColor.white,
        ),
        limits: const InputSafetyLimits(maxPixels: 1),
      ).toPixelImage(),
      throwsA(isA<ImageLimitException>()),
    );
  });

  test('pipeline accepts byte buffer, byte data, and stream sources', () async {
    final encoded = await ImagePipeline.fromRawPixels(_raw()).png().toBytes();
    final byteDataBytes = Uint8List.fromList(<int>[9, ...encoded, 9]);
    final byteData = ByteData.sublistView(
      byteDataBytes,
      1,
      byteDataBytes.length - 1,
    );
    final stream = Stream<List<int>>.fromIterable(<List<int>>[
      encoded.sublist(0, 8),
      encoded.sublist(8),
    ]);

    final fromBuffer = await ImagePipeline.fromByteBuffer(
      Uint8List.fromList(encoded).buffer,
    ).toPixelImage();
    final fromData = await ImagePipeline.fromByteData(byteData).toPixelImage();
    final fromStream = await ImagePipeline.fromStream(stream).toPixelImage();

    expect(fromBuffer.firstFrameBytes(), _raw().bytes);
    expect(fromData.firstFrameBytes(), _raw().bytes);
    expect(fromStream.firstFrameBytes(), _raw().bytes);
  });

  test('channel count validates integer input', () {
    expect(ChannelCount.fromInt(3), ChannelCount.three);
    expect(
      () => ChannelCount.fromInt(5),
      throwsA(isA<OperationValidationException>()),
    );
  });

  test('text source stores future renderer descriptor', () {
    final source =
        ImageSource.text(
              const TextImageRequest(
                text: 'hello',
                width: 120,
                align: TextAlign.center,
              ),
            )
            as TextImageSource;

    expect(source.text.text, 'hello');
    expect(source.text.width, 120);
    expect(source.text.align, TextAlign.center);
  });
}

RawPixels _raw() {
  return RawPixels(
    bytes: Uint8List.fromList(<int>[10, 20, 30, 255]),
    width: 1,
    height: 1,
    channels: ChannelCount.four,
  );
}
