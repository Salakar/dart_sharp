# Dependency Review

This file records the Phase 3 dependency review for pure Dart image processing.

## image 4.8.0

- License: MIT, per `~/.pub-cache/hosted/pub.dev/image-4.8.0/LICENSE`.
- Purpose: pure Dart decode, encode, and pixel manipulation backend.
- Platform posture: package description states support for server and web apps.
- Boundary: backend classes are private implementation details and must not be
  exposed from `package:dsharp/dsharp.dart`.
- Notes: exported file helpers use conditional access inside the dependency;
  `dsharp` core must continue avoiding direct `dart:io` imports.

## archive 4.0.9

- License: MIT, per `~/.pub-cache/hosted/pub.dev/archive-4.0.9/LICENSE`.
- Purpose: future deep-zoom ZIP/container output and compression utilities.
- Platform posture: package supports memory encoders/decoders and should be
  wrapped so file access stays out of the core entrypoint.

## xml 6.6.1

- License: MIT, per `~/.pub-cache/hosted/pub.dev/xml-6.6.1/LICENSE`.
- Purpose: future XMP/SVG/XML metadata parsing.
- Platform posture: pure Dart parser suitable for core use after API wrapping.

## vector_math 2.3.0

- License: BSD-style with additional Zlib-notice portions, per
  `~/.pub-cache/hosted/pub.dev/vector_math-2.3.0/LICENSE`.
- Purpose: future affine and matrix math helpers.
- Boundary: do not expose dependency matrix types in the public API.
