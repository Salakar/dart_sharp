import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('sniffs AVIF and HEIF ISO BMFF brands', () {
    expect(_ftyp('avif'), ImageFormat.avif);
    expect(_ftyp('avis'), ImageFormat.avif);
    expect(_ftyp('mif1', compatible: <String>['avif']), ImageFormat.avif);
    expect(_ftyp('isom', compatible: <String>['heic']), ImageFormat.heif);
    expect(_ftyp('heix'), ImageFormat.heif);
    expect(_ftyp('msf1'), ImageFormat.heif);
  });

  test('sniffs strict JPEG XL signatures', () {
    expect(
      sniffImageFormat(Uint8List.fromList(<int>[0xff, 0x0a])),
      ImageFormat.jxl,
    );
    expect(
      sniffImageFormat(
        Uint8List.fromList(<int>[
          0x00,
          0x00,
          0x00,
          0x0c,
          0x4a,
          0x58,
          0x4c,
          0x20,
          0x0d,
          0x0a,
          0x87,
          0x0a,
        ]),
      ),
      ImageFormat.jxl,
    );
    expect(
      sniffImageFormat(Uint8List.fromList('xxxxJXL xxxx'.codeUnits)),
      ImageFormat.unknown,
    );
  });

  test('sniffs strict JPEG 2000 signatures', () {
    expect(
      sniffImageFormat(Uint8List.fromList(<int>[0xff, 0x4f, 0xff, 0x51])),
      ImageFormat.jp2,
    );
    expect(
      sniffImageFormat(
        Uint8List.fromList(<int>[
          0x00,
          0x00,
          0x00,
          0x0c,
          0x6a,
          0x50,
          0x20,
          0x20,
          0x0d,
          0x0a,
          0x87,
          0x0a,
        ]),
      ),
      ImageFormat.jp2,
    );
    expect(
      sniffImageFormat(Uint8List.fromList('xxxxjP  xxxx'.codeUnits)),
      ImageFormat.unknown,
    );
  });
}

ImageFormat _ftyp(String major, {List<String> compatible = const <String>[]}) {
  final bytes = <int>[];
  final size = 16 + compatible.length * 4;
  bytes
    ..addAll(<int>[
      (size >> 24) & 0xff,
      (size >> 16) & 0xff,
      (size >> 8) & 0xff,
      size & 0xff,
    ])
    ..addAll('ftyp'.codeUnits)
    ..addAll(major.codeUnits)
    ..addAll(<int>[0, 0, 0, 0]);
  for (final brand in compatible) {
    bytes.addAll(brand.codeUnits);
  }
  return sniffImageFormat(Uint8List.fromList(bytes));
}
