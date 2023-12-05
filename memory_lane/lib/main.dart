import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Lane',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
              _buildTextField('제목', (value) => title = value),
              _buildTextField('내용', (value) => snippet = value),
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

  Widget _buildTextField(String labelText, Function(String) onChanged) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(labelText: labelText),
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
      markerIcon = await getBytesFromAsset('assets/img/marker_icon.png', 100);
    }
    markerIcon = _makeCircularIcon(markerIcon);

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
    });
  }

  Uint8List _makeCircularIcon(Uint8List markerIcon) {
    final img.Image markerImage = img.decodeImage(markerIcon)!;
    final img.Image circularImage = img.copyCropCircle(markerImage);

    return Uint8List.fromList(img.encodePng(circularImage));
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
      ),
    );
  }
}
