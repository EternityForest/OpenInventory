import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

Future<PermissionStatus> _getCameraPermission() async {
  var status = await Permission.camera.status;
  if (!status.isGranted) {
    final result = await Permission.camera.request();
    return result;
  } else {
    return status;
  }
}

class MyDialog extends StatefulWidget {
  const MyDialog(this.prompt, this.initialValue, {Key? key, this.barcodes: false}) : super(key: key);

  final String prompt;
  final String initialValue;
  final bool barcodes;

  @override
  _MyDialogState createState() => new _MyDialogState();
}

class _MyDialogState extends State<MyDialog> {
  var temp = '';
  bool hasCamera = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final txtkey = ObjectKey("txtval");

  @override
  void initState() {
    super.initState();
    temp = widget.initialValue;

    _getCameraPermission().then((value) {
      if (value.isGranted) {
        setState(() {
          hasCamera = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Question"),
      content: Column(children: [
        Visibility(
            visible: hasCamera && widget.barcodes,
            child: Expanded(
              flex: 5,
              child: QRView(
                formatsAllowed: [BarcodeFormat.qrcode,
                BarcodeFormat.code128,
                BarcodeFormat.upcA,
                BarcodeFormat.upcE,
                BarcodeFormat.upcEanExtension,
                BarcodeFormat.ean8,
                BarcodeFormat.ean13,
                BarcodeFormat.code39,
                BarcodeFormat.code93],
                key: qrKey,
                onQRViewCreated: (QRViewController controller) {
                  controller.scannedDataStream.listen((scanData) {
                    if(scanData.code != null)
                      {
                        Navigator.of(context).pop(scanData.code);
                      }
                    // setState(() {
                    //   temp = scanData.code ?? '';
                    // });
                  });
                },
              ),
            )),
        TextFormField(
            key: txtkey,
            onChanged: (value) {
            temp = value;
          },
          initialValue: temp,
          decoration: InputDecoration(labelText: widget.prompt),
        )
      ]),
      actions: <Widget>[
        ElevatedButton(
          child: const Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
        ElevatedButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(temp);
          },
        ),
      ],
    );
  }
}

Future<String?> textPrompt(NavigatorState navigator, String prompt,
    {String initialValue: '', bool barcodes: false}) async {
  return await navigator.push(
    MaterialPageRoute(builder: (context) => MyDialog(prompt, initialValue,barcodes: barcodes,)),
  );
}
