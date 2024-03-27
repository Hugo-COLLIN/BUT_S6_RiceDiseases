import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:empty_widget/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paddy_disease_classifier/data.dart';
import 'package:url_launcher/url_launcher.dart';
import '../process/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets.dart';
import '../process/utils.dart';
import 'predictions.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _resultString;
  Map _resultDict = {
    "label": "None",
    "confidences": [
      {"label": "None", "confidence": 0.0},
      {"label": "None", "confidence": 0.0},
      {"label": "None", "confidence": 0.0}
    ]
  };

  String _latency = "N/A";

  File? imageURI; // Show on image widget on app
  Uint8List? imgBytes; // Store img to be sent for api inference
  bool isClassifying = false;

  String parseResultsIntoString(Map results) {
    return """
    ${results['confidences'][0]['label']} - ${(results['confidences'][0]['confidence'] * 100.0).toStringAsFixed(2)}% \n
    ${results['confidences'][1]['label']} - ${(results['confidences'][1]['confidence'] * 100.0).toStringAsFixed(2)}% \n
    ${results['confidences'][2]['label']} - ${(results['confidences'][2]['confidence'] * 100.0).toStringAsFixed(2)}% """;
  }

  clearInferenceResults() {
    _resultString = "";
    _latency = "N/A";
    _resultDict = {
      "label": "None",
      "confidences": [
        {"label": "None", "confidence": 0.0},
        {"label": "None", "confidence": 0.0},
        {"label": "None", "confidence": 0.0}
      ]
    };
  }

  // Nouvelle fonction pour classifier l'image
  Future<void> classifyImage() async {
    if (imageURI == null) return;

    setState(() {
      isClassifying = true;
    });

    imgBytes = await imageURI!.readAsBytes();
    String base64Image = "data:image/png;base64," + base64Encode(imgBytes!);

    try {
      Stopwatch stopwatch = Stopwatch()..start();
      final result = await classifyRiceImage(base64Image);

      setState(() {
        _resultString = parseResultsIntoString(result);
        _resultDict = result;
        _latency = stopwatch.elapsed.inMilliseconds.toString();
        isClassifying = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PredictionsPage(
            imageURI: imageURI!,
            resultDict: _resultDict,
            latency: _latency,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isClassifying = false;
      });
      // Handle error
    }
  }

  Widget buildTakeAPictureButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton.extended(
          heroTag: "btn1",
          icon: const Icon(Icons.camera),
          label: const Text("Camera"),
          onPressed: () async {
            final XFile? pickedFile =
            await ImagePicker().pickImage(source: ImageSource.camera);

            if (pickedFile != null) {
              setState(() {
                clearInferenceResults();
              });

              File croppedFile = await cropImage(pickedFile);
              final imgFile = File(croppedFile.path);

              setState(() {
                imageURI = imgFile;
                isClassifying = false;
              });
              classifyImage();
            }
          },
        ),
        const SizedBox(width: 10), // Ajoute un espace de 10 pixels entre les boutons
        FloatingActionButton.extended(
          heroTag: "btn2",
          icon: const Icon(Icons.image),
          label: const Text("Gallery"),
          onPressed: () async {
            final XFile? pickedFile =
            await ImagePicker().pickImage(source: ImageSource.gallery);

            if (pickedFile != null) {
              setState(() {
                clearInferenceResults();
              });

              File croppedFile = await cropImage(pickedFile);
              final imgFile = File(croppedFile.path);

              setState(() {
                imageURI = imgFile;
                isClassifying = false;
              });
              classifyImage();
            }
          },
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final List<Widget> imageSliders = imgList
        .map((item) => Container(
              margin: const EdgeInsets.all(5.0),
              child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                  child: Stack(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () async {
                          context.loaderOverlay.show();

                          String imgUrl = imgList[imgList.indexOf(item)];

                          final imgFile = await getImage(imgUrl);

                          setState(() {
                            imageURI = imgFile;
                            isClassifying = false;
                            clearInferenceResults();
                          });
                          context.loaderOverlay.hide();
                          classifyImage();
                        },
                        child: CachedNetworkImage(
                          imageUrl: item,
                          fit: BoxFit.fill,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      Positioned(
                        bottom: 0.0,
                        left: 0.0,
                        right: 0.0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(200, 0, 0, 0),
                                Color.fromARGB(0, 0, 0, 0)
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20.0),
                          child: Text(
                            'GT: ${imgList[imgList.indexOf(item)].split('/').reversed.elementAt(1)}', // get the class name from url
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
            ))
        .toList();

    return LoaderOverlay(
      child: Scaffold(

        appBar: AppBar(
          title: Text(widget.title),
        ),

        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 16),
              Center(
                  child: Text("Take a picture:",
                      style: Theme.of(context).textTheme.titleLarge)),
              Row(
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: buildTakeAPictureButtons(),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                  child: Text("Or select a sample:",
                      style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(height: 8),
              CarouselSlider(
                options: CarouselOptions(
                  height: 180,
                  autoPlay: true,
                  viewportFraction: 0.4,
                  enlargeCenterPage: false,
                  enlargeStrategy: CenterPageEnlargeStrategy.height,
                ),
                items: imageSliders,
              ),
              Row(
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Linkify(
                      onOpen: (link) async {
                        if (await canLaunchUrl(Uri.parse(link.url))) {
                          await launchUrl(Uri.parse(link.url));
                        } else {
                          throw 'Could not launch $link';
                        }
                      },
                      text:
                          "Based on \"Rice Diseases\" : https://dicksonneoh.com",
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
