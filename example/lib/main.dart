import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:liveness/liveness.dart';

void main() {
  runApp(DemoLivenessApp());
}

class DemoLivenessApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        DefaultMaterialLocalizations.delegate,
      ],
      home: DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  @override
  _DemoPageState createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      Liveness.isDeviceSupportLiveness().then((isSupported) async {
        try {
          await Liveness.initLiveness();
          setState(() {
            _canDetectLiveness = isSupported ?? false;
          });
        } catch (e) {
          _showError(e,);
        }
      },);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Liveness App',),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0,),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0,),
                child: Container(
                  alignment: Alignment.center,
                  constraints: BoxConstraints.loose(
                    Size.square( _bitmap != null ? 300.0 : 0.0, ),
                  ),
                  child: Builder(
                    builder: (_) {
                      if (_bitmap == null) {
                        return Container();
                      }
                      return Image.memory(_bitmap!, fit: BoxFit.cover,);
                    },
                  ),
                ),
              ),
            ),
            RaisedButton(
              child: Text("Start Liveness Detection",),
              onPressed: _canDetectLiveness ? _startLivenessDetection : null,
            ),
            _canDetectLiveness ? Container() : Padding(
              padding: const EdgeInsets.all(16.0,),
              child: Text(
                "Your device doesn't support Liveness Detection",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.0, color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canDetectLiveness = false;
  Uint8List? _bitmap;

  void _startLivenessDetection() {
    Liveness.detectLiveness().then((result) {
      print("Base64 Result: ${result.base64String}",);
      setState(() {
        _bitmap = result.bitmap;
      });
    },).catchError((e) {
      _showError(e,);
    },);
  }

  void _showError(var e) {
    if (e is LivenessException) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(e.code,),
          content: Text(e.message,),
          actions: <Widget>[
            FlatButton(
              child: Text("Close",),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(LivenessException.ERROR_UNDEFINED,),
          content: Text(e.toString(),),
          actions: <Widget>[
            FlatButton(
              child: Text("Close",),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }
}