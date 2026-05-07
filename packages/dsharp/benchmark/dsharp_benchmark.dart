import 'dart:math';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dsharp/dsharp.dart';

import '../test/helpers/generated_fixtures.dart';

Future<void> main(List<String> args) async {
  final benchmarks = <AsyncBenchmarkBase>[
    JpegResizeBenchmark(),
    PngRgbaResizeBenchmark(),
    RandomResizeBenchmark(),
    RawOperationBenchmark(),
    CompositeBenchmark(),
  ];
  if (args.contains('--smoke')) {
    for (final benchmark in benchmarks) {
      await benchmark.setup();
      await benchmark.run();
      await benchmark.teardown();
    }
    return;
  }
  for (final benchmark in benchmarks) {
    await benchmark.report();
  }
}

final class JpegResizeBenchmark extends AsyncBenchmarkBase {
  JpegResizeBenchmark() : super('jpeg_decode_resize_encode');

  late List<int> _bytes;

  @override
  Future<void> setup() async {
    _bytes = await ImagePipeline.fromRawPixels(
      GeneratedFixtures.gradient(width: 128, height: 96),
    ).jpeg().toBytes();
  }

  @override
  Future<void> run() async {
    await ImagePipeline.fromBytes(Uint8List.fromList(_bytes))
        .resize(const ResizeOptions(width: 72, height: 54, fit: ResizeFit.fill))
        .jpeg()
        .toBytes();
  }
}

final class PngRgbaResizeBenchmark extends AsyncBenchmarkBase {
  PngRgbaResizeBenchmark() : super('png_rgba_resize');

  @override
  Future<void> run() async {
    await ImagePipeline.fromRawPixels(
          GeneratedFixtures.gradient(width: 128, height: 96),
        )
        .premultiplyAlpha()
        .resize(const ResizeOptions(width: 72, height: 54, fit: ResizeFit.fill))
        .png()
        .toBytes();
  }
}

final class RandomResizeBenchmark extends AsyncBenchmarkBase {
  RandomResizeBenchmark() : super('random_dimension_resize');

  final _random = Random(7);

  @override
  Future<void> run() async {
    final size = 32 + _random.nextInt(64);
    await ImagePipeline.fromRawPixels(
          GeneratedFixtures.gradient(width: 96, height: 96),
        )
        .resize(ResizeOptions(width: size, height: size, fit: ResizeFit.fill))
        .toBytes();
  }
}

final class RawOperationBenchmark extends AsyncBenchmarkBase {
  RawOperationBenchmark() : super('raw_operation_chain');

  @override
  Future<void> run() async {
    await ImagePipeline.fromRawPixels(
      GeneratedFixtures.gradient(width: 96, height: 96),
    ).negate().blur().normalize().toBytes();
  }
}

final class CompositeBenchmark extends AsyncBenchmarkBase {
  CompositeBenchmark() : super('composite_over');

  @override
  Future<void> run() async {
    final overlay = PixelImage.fromRawPixels(GeneratedFixtures.alphaGrid());
    await ImagePipeline.fromRawPixels(
          GeneratedFixtures.gradient(width: 96, height: 96),
        )
        .composite(<CompositeLayer>[
          CompositeLayer(image: overlay, left: 16, top: 16, tile: true),
        ])
        .png()
        .toBytes();
  }
}
