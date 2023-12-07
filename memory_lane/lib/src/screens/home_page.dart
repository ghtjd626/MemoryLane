import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:memory_lane/src/utils/image_utils.dart';
import 'package:memory_lane/src/widgets/custom_text_field.dart';
import 'dart:ui' as ui;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Set<Polyline> polylines = {};
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  final LatLng _center = const LatLng(37.555133, 126.969311);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMapTapped(LatLng position) {
    _showInputDialog(position);
  }

  Future<XFile?> _getImage(ImageSource imageSource) async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    return pickedFile;
  }

  Future<void> _showInputDialog(LatLng position) async {
    XFile? _image;
    final ImagePicker picker = ImagePicker();

    Future getImage(ImageSource imageSource) async {
      final XFile? pickedFile = await picker.pickImage(source: imageSource);
      if (pickedFile != null) {
        setState(() {
          _image = XFile(pickedFile.path);
        });
        setState(() {});
      }
    }

    String title = '';
    String snippet = '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('기억 남기기'),
          content: Column(
            children: [
              FutureBuilder<XFile?>(
                future: _getImage(ImageSource.gallery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data != null) {
                    _image = snapshot.data!;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.file(File(_image!.path)),
                    );
                  } else {
                    return const Text('Loading image...');
                  }
                },
              ),
              CustomTextField(
                labelText: '제목',
                onChanged: (value) => title = value,
              ),
              CustomTextField(
                labelText: '내용',
                onChanged: (value) => snippet = value,
              ),
            ],
          ),
          actions: [
            _buildTextButton('취소', () {
              Navigator.of(context).pop();
            }),
            _buildTextButton('등록하기', () {
              _addMarker(position, title, snippet, _image);
              Navigator.of(context).pop();
            }),
          ],
        );
      },
    );
  }

  Widget _buildTextButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Future getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        ?.buffer
        .asUint8List();
  }

  void _addMarker(
      LatLng position, String title, String snippet, XFile? image) async {
    Uint8List markerIcon;

    if (image != null) {
      final File imageFile = File(image.path);

      img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());
      img.Image resizedImage =
          img.copyResize(originalImage!, width: 100, height: 100);

      markerIcon = Uint8List.fromList(img.encodePng(resizedImage));
    } else {
      markerIcon = await getBytesFromAsset('assets/img/marker_icon.png', 150);
    }
    markerIcon = ImageUtils.makeCircularIcon(markerIcon);

    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
          infoWindow: InfoWindow(
            title: title,
            snippet: snippet,
          ),
          icon: BitmapDescriptor.fromBytes(markerIcon),
        ),
      );
      if (markers.length > 1) {
        LatLng previousPosition =
            markers.elementAt(markers.length - 2).position;
        polylines.add(Polyline(
          polylineId:
              PolylineId(position.toString() + previousPosition.toString()),
          points: [previousPosition, position],
          color: Colors.teal,
          width: 4,
        ));
      }
    });
  }

  Widget _buildTextField(String labelText, Function(String) onChanged) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(labelText: labelText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Lane'),
        backgroundColor: Colors.blue[700],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        onTap: _onMapTapped,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
        markers: markers,
        polylines: polylines,
      ),
    );
  }
}
