import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:memory_lane/src/api/location_service.dart';
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
  Set<Marker> markers = {};
  final LatLng _center = const LatLng(37.555133, 126.969311);
  final Completer<GoogleMapController> _controller = Completer();

  bool showSearch = false;

  void _onMapTapped(LatLng position) {
    _showInputDialog(position);
  }

  Future<XFile?> _getImage(ImageSource imageSource) async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    return pickedFile;
  }

  Future<void> _showInputDialog(LatLng position) async {
    XFile? image;
    bool isLoading = false;

    String title = '';
    String snippet = '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('기억 남기기'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.blue,
                              ),
                              onPressed: () async {
                                setState(() {
                                  isLoading = true;
                                });

                                XFile? pickedFile =
                                    await _getImage(ImageSource.gallery);

                                setState(() {
                                  isLoading = false;
                                  image = pickedFile;
                                });
                              },
                            ),
                            if (isLoading)
                              const CircularProgressIndicator()
                            else if (image != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.file(File(image!.path)),
                              ),
                          ],
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
                  ],
                ),
              ),
              actions: [
                _buildTextButton('취소', () {
                  Navigator.of(context).pop();
                }),
                _buildTextButton('등록하기', () {
                  _addMarker(position, title, snippet, image);
                  Navigator.of(context).pop();
                }),
              ],
            );
          },
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
            onTap: () => print(1)),
      );
      if (markers.length > 1) {
        LatLng previousPosition =
            markers.elementAt(markers.length - 2).position;
        polylines.add(Polyline(
          polylineId:
              PolylineId(position.toString() + previousPosition.toString()),
          points: [previousPosition, position],
          color: Colors.blue,
          width: 4,
        ));
      }
    });
  }

  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.not_listed_location_outlined),
              SizedBox(width: 4),
              Text(
                'Memory Lane',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  showSearch = !showSearch;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Visibility(
                    visible: showSearch,
                    child: TextFormField(
                      controller: _searchController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: ' Search your Place',
                      ),
                      onChanged: (value) {
                        print(value);
                      },
                    ),
                  ),
                ),
                Visibility(
                  visible: showSearch,
                  child: IconButton(
                    onPressed: () async {
                      var place = await LocationService()
                          .getPlace(_searchController.text);
                      _goToPlace(place);
                    },
                    icon: const Icon(Icons.search),
                  ),
                ),
              ],
            ),
            Expanded(
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                onTap: _onMapTapped,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 11.0,
                ),
                markers: markers,
                polylines: polylines,
              ),
            )
          ],
        ));
  }

  Future<void> _goToPlace(Map<String, dynamic> place) async {
    final double lat = place['geometry']['location']['lat'];
    final double lng = place['geometry']['location']['lng'];

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 12),
      ),
    );
  }
}
