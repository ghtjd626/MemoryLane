import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerData {
  final LatLng position;
  final String title;
  final String snippet;
  final Uint8List? image;

  MarkerData({
    required this.position,
    required this.title,
    required this.snippet,
    this.image,
  });
}
