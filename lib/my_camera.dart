import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class MyCamera extends StatefulWidget {
  const MyCamera({Key? key}) : super(key: key);

  @override
  State<MyCamera> createState() => _MyCameraState();
}

class _MyCameraState extends State<MyCamera> {
  String dirPath = '';
  File? imageFile;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    // gellery

    return await Geolocator.getCurrentPosition();
  }

// show image
  _initialImageView() {
    if (imageFile == null) {
      return const Text(
        'No Image Selected...',
        style: TextStyle(fontSize: 20.0),
      );
    } else {
      return Card(
        child: Image.file(imageFile!, width: 400.0, height: 400),
      );
    }
  }

  _openGellery(BuildContext context) async {
    var picture = await ImagePicker().pickImage(source: ImageSource.camera);
    var bytes = await picture!.readAsBytes();
    var tags = await readExifFromBytes(bytes);

    setState(
      () {
        imageFile = File(picture.path);
        dirPath = picture.path;
        print('path : ');
        print("dirPath $dirPath");
        print("tags ::::: $tags");
      },
    );
  }

// image details
  Future<String> getExifFromFile() async {
    if (imageFile == null) {
      return "";
    }

    var bytes = await imageFile!.readAsBytes();
    var tags = await readExifFromBytes(bytes);
    var sb = StringBuffer();

    tags.forEach((k, v) {
      sb.write("$k: $v \n");
    });

    return sb.toString().isEmpty ? "No Location Found!" : sb.toString();
  }

// alert dilog
  Future<void> _showChoiceDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Take Image From...'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                //gellery
                GestureDetector(
                  child: const Text('Gellery'),
                  onTap: () {
                    _determinePosition();
                    _openGellery(context);
                    Navigator.of(context).pop();
                  },
                ),
                const Padding(padding: EdgeInsets.all(8.0)),

                //camera
                // GestureDetector(
                //   child: const Text('Camera'),
                //   onTap: () {
                //     // _openCamera(context);
                //     Navigator.of(context).pop();
                //   },
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Image'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _initialImageView(),
              Column(
                children: [
                  FutureBuilder(
                    future: getExifFromFile(),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data != null) {
                          return Text(snapshot.data ?? "");
                        } else {
                          return CircularProgressIndicator();
                        }
                      }
                      return Container();
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30.0),
                    width: 250.0,
                    child: FlatButton(
                      child: const Text(
                        'Select Image',
                        style: TextStyle(color: Colors.white, fontSize: 16.0),
                      ),
                      onPressed: () {
                        _showChoiceDialog(context);
                      },
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
