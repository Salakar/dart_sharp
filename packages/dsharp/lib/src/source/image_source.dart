import 'dart:async';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import 'generated_image.dart';
import 'raw_pixels.dart';
import 'text_image.dart';

/// Web-safe source for image input.
sealed class ImageSource {
  const ImageSource();

  /// Creates a source from encoded image bytes.
  factory ImageSource.bytes(Uint8List bytes) = BytesImageSource;

  /// Creates a source from a byte buffer.
  factory ImageSource.byteBuffer(ByteBuffer buffer) {
    return BytesImageSource(buffer.asUint8List());
  }

  /// Creates a source from byte data.
  factory ImageSource.byteData(ByteData data) {
    return BytesImageSource(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  /// Creates a source from a byte stream.
  factory ImageSource.stream(Stream<List<int>> stream, {int? maxBytes}) {
    return StreamImageSource(stream, maxBytes: maxBytes);
  }

  /// Creates a source from raw pixels.
  factory ImageSource.raw(RawPixels pixels) = RawImageSource;

  /// Creates a source from decoded pixels.
  factory ImageSource.pixels(PixelImage image) = PixelImageSource;

  /// Creates a generated image source.
  factory ImageSource.create(CreateImage image) = GeneratedImageSource;

  /// Creates a text image source descriptor.
  factory ImageSource.text(TextImageRequest text) = TextImageSource;
}

/// Decoded pixel image source.
final class PixelImageSource extends ImageSource {
  /// Creates a decoded pixel source.
  const PixelImageSource(this.image);

  /// Decoded pixels.
  final PixelImage image;
}

/// Encoded image bytes.
final class BytesImageSource extends ImageSource {
  /// Creates a byte source with a defensive copy.
  BytesImageSource(Uint8List bytes) : _bytes = Uint8List.fromList(bytes);

  final Uint8List _bytes;

  /// Defensive copy of source bytes.
  Uint8List get bytes => Uint8List.fromList(_bytes);
}

/// Encoded image bytes supplied asynchronously.
final class StreamImageSource extends ImageSource {
  /// Creates a stream source.
  const StreamImageSource(this.stream, {this.maxBytes});

  /// Byte stream.
  final Stream<List<int>> stream;

  /// Optional maximum bytes allowed when buffering this stream.
  final int? maxBytes;

  /// Buffers this stream into a single byte list.
  Future<Uint8List> collectBytes() async {
    final builder = BytesBuilder(copy: false);
    var length = 0;
    await for (final chunk in stream) {
      length += chunk.length;
      final limit = maxBytes;
      if (limit != null && length > limit) {
        throw ImageLimitException(
          'Image byte stream exceeded the $limit byte limit.',
        );
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}

/// Raw pixel image source.
final class RawImageSource extends ImageSource {
  /// Creates a raw pixel source.
  const RawImageSource(this.pixels);

  /// Raw pixels.
  final RawPixels pixels;
}

/// Generated image source.
final class GeneratedImageSource extends ImageSource {
  /// Creates a generated image source.
  const GeneratedImageSource(this.image);

  /// Generated image descriptor.
  final CreateImage image;
}

/// Text image source descriptor.
final class TextImageSource extends ImageSource {
  /// Creates a text image source.
  const TextImageSource(this.text);

  /// Text rendering request.
  final TextImageRequest text;
}
