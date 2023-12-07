import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageUtils {
  static Uint8List makeCircularIcon(Uint8List markerIcon) {
    final img.Image markerImage = img.decodeImage(markerIcon)!;
    final img.Image circularImage = img.copyCropCircle(markerImage);

    return Uint8List.fromList(img.encodePng(circularImage));
  }
}
