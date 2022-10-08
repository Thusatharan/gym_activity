import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gym_act/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomePage(this.cameras);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String predOne = '';
  double confidence = 0;
  double index = 0;

  @override
  void initState() {
    super.initState();
    loadTfliteModel();
  }

  loadTfliteModel() async {
    String res;
    res = await Tflite.loadModel(
        model: "assets/model_unquant.tflite", labels: "assets/labels.txt");
    print(res);
  }

  setRecognitions(outputs) {
    print(outputs);

    if (outputs[0]['index'] == 0) {
      index = 0;
    } else if (outputs[0]['index'] == 1) {
      index = 1;
    } else {
      index = 2;
    }

    confidence = outputs[0]['confidence'];

    setState(() {
      predOne = outputs[0]['label'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/gymbg.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Text('Activity Analyzer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                    )),
              ),
              Camera(widget.cameras, setRecognitions),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        predOne,
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.0),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 16.0,
                                    ),
                                    Expanded(
                                      flex: 8,
                                      child: SizedBox(
                                        height: 32.0,
                                        child: Stack(
                                          children: [
                                            LinearProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.redAccent),
                                              value: confidence,
                                              backgroundColor: Colors.redAccent
                                                  .withOpacity(0.2),
                                              minHeight: 50.0,
                                            ),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                '${(confidence * 100).toStringAsFixed(0)} %',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 20.0),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),

                                // ElevatedButton(
                                //     onPressed: () => showDialog<String>(
                                //           context: context,
                                //           builder: (BuildContext context) =>
                                //               AlertDialog(
                                //             title: const Text(
                                //                 'Waiting for backend'),
                                //             content: const Text(
                                //                 'Connecting to backend'),
                                //             actions: <Widget>[
                                //               TextButton(
                                //                 onPressed: () => Navigator.pop(
                                //                     context, 'Cancel'),
                                //                 child: const Text('Cancel'),
                                //               ),
                                //               TextButton(
                                //                 onPressed: () => Navigator.pop(
                                //                     context, 'OK'),
                                //                 child: const Text('OK'),
                                //               ),
                                //             ],
                                //           ),
                                //         ),
                                //     child: Text('Details'))

                                ElevatedButton(
                                    onPressed: () =>
                                        createPost(context, confidence * 100),
                                    child: Text('Calorie'))
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Future<Calorie> createPost(context, double conf) async {
  Random rtime = new Random();
  int time = rtime.nextInt(100);
  final response = await http.post(
    Uri.parse('http://10.0.2.2:5000/watecalory'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'time': time,
      'jointmumant': 20,
    }),
  );

  if (response.statusCode == 200) {
    // If the server did return a 201 CREATED response,

    // then parse the JSON.
    var decodedRes = jsonDecode(response.body);
    print(
        '.......................................................................');
    print(decodedRes['response']);
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Calorie'),
        content: Text(
          decodedRes['response'],
          style: TextStyle(fontSize: 40, color: Colors.green),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    print(
        '.......................................................................');
    return Calorie.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 201 CREATED response,
    // then throw an exception.
    throw Exception('Failed to create value.');
  }
}

class Calorie {
  final int value;

  Calorie({this.value});

  factory Calorie.fromJson(Map<String, dynamic> json) {
    return Calorie(
      value: json['response'],
    );
  }
}
