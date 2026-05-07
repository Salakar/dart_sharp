import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('package exposes initial capabilities without native dependencies', () {
    final capabilities = DsharpCapabilities.current;

    expect(capabilities.supportFor(ImageFormat.raw).canDecode, isTrue);
    expect(capabilities.supportFor(ImageFormat.raw).canEncode, isTrue);
    expect(capabilities.supportFor(ImageFormat.avif).canDecode, isFalse);
  });

  test('pipeline can be created from bytes and cloned immutably', () {
    final bytes = Uint8List.fromList(<int>[1, 2, 3]);
    final pipeline = ImagePipeline.fromBytes(bytes);
    final changed = pipeline.appendOperationForTesting('resize');

    bytes[0] = 9;

    expect(pipeline.operations, isEmpty);
    expect(changed.operations, <String>['resize']);
    expect(changed.clone().operations, <String>['resize']);
  });

  test('raw pixels validate layout', () {
    final pixels = RawPixels(
      bytes: Uint8List.fromList(<int>[255, 0, 0, 255]),
      width: 1,
      height: 1,
      channels: ChannelCount.four,
    );

    expect(pixels.expectedLength, 4);
    expect(ImagePipeline.fromRawPixels(pixels).source, isA<RawImageSource>());
  });

  test('invalid raw pixel length throws typed exception', () {
    expect(
      () => RawPixels(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        width: 1,
        height: 1,
        channels: ChannelCount.four,
      ),
      throwsA(isA<InvalidImageException>()),
    );
  });
}
