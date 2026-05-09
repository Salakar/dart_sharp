import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('renders text descriptors as deterministic RGBA pixels', () async {
    final image = await ImagePipeline.text(
      const TextImageRequest(text: 'A', width: 10, height: 8, hasRgba: true),
    ).toPixelImage();

    expect(image.width, 10);
    expect(image.height, 8);
    expect(image.channels, ChannelCount.four);
    expect(_pixel(image, 0, 0), <int>[0, 0, 0, 0]);
    expect(_pixel(image, 1, 0), <int>[0, 0, 0, 255]);
    expect(_pixel(image, 4, 6), <int>[0, 0, 0, 255]);
  });

  test('text rendering supports wrapping and alignment', () async {
    final image = await ImagePipeline.text(
      const TextImageRequest(
        text: 'A A',
        width: 9,
        align: TextAlign.center,
        wrap: TextWrap.word,
        hasRgba: true,
      ),
    ).toPixelImage();

    expect(image.width, 9);
    expect(image.height, 15);
    expect(_pixel(image, 0, 0), <int>[0, 0, 0, 0]);
    expect(_pixel(image, 3, 0), <int>[0, 0, 0, 255]);
    expect(_pixel(image, 3, 8), <int>[0, 0, 0, 255]);
  });

  test('text rendering can produce RGB pixels and encoded output', () async {
    final pipeline = ImagePipeline.text(
      const TextImageRequest(text: 'Hi', wrap: TextWrap.none),
    );
    final image = await pipeline.toPixelImage();
    final encoded = await pipeline.png().toBytesWithInfo();

    expect(image.channels, ChannelCount.three);
    expect(_pixel(image, 1, 1), <int>[255, 255, 255]);
    expect(_pixel(image, 0, 0), <int>[0, 0, 0]);
    expect(encoded.info.format, ImageFormat.png);
    expect(encoded.info.width, image.width);
    expect(encoded.info.height, image.height);
  });
}

List<int> _pixel(PixelImage image, int x, int y) {
  final bytes = image.firstFrameBytes();
  final channels = image.channels.value;
  final offset = (y * image.width + x) * channels;
  return bytes.sublist(offset, offset + channels);
}
