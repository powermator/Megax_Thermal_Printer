import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' hide Intent;
import 'package:print_bluetooth_thermal/post_code.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal_windows.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receive_intent/receive_intent.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  /// Constructor of MyApp widget.
  const MyApp({Key? key}) : super(key: key);
  
  @override
  _MyAppState createState() => _MyAppState();
}




class _MyAppState extends State<MyApp> {
 Intent? _initialIntent;
  
  List<BluetoothInfo> items = [];
 
  
  String optionprinttype = "58 mm";
  List<String> options = ["58 mm", "80 mm"];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }



  Future<void> initPlatformState() async {
    
  
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
          statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
        return;
      }                       }
    } on PlatformException {    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.

    final receivedIntent = await ReceiveIntent.getInitialIntent();
    if (!mounted) return;

     setState(() {
      _initialIntent = receivedIntent;
    });


    getBluetoots();
    

  }

   Widget _buildFromIntent(String label, Intent? intent) {

    String recieved="extras: ${intent?.extra}";
    if((recieved).contains('MAUI')){
      printTest();
     
      }
    
    return Center(
      child: Column(
        children: [
          Text(label),
          Text(
              "fromPackage: ${intent?.fromPackageName}\nfromSignatures: ${intent?.fromSignatures}"),
          Text(
              'action: ${intent?.action}\ndata: ${intent?.data}\ncategories: ${intent?.categories}'),
          Text("extras: ${intent?.extra}")
        ],
      ),
    );
  }


  @override
   @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFromIntent("INITIAL", _initialIntent),
              StreamBuilder<Intent?>(
                stream: ReceiveIntent.receivedIntentStream,
                builder: (context, snapshot) =>
                    _buildFromIntent("STREAMED", snapshot.data),
              )
            ],
          ),
        ),
      ),
    );
  }



  Future<void> getBluetoots() async {
    
    final List<BluetoothInfo> listResult = await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      items = listResult;
    });


     final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: "86:67:7A:EA:C3:8F");
      if(result ==true){
        //printTest();
        }

  }




  Future<void> printTest() async {
    /*if (kDebugMode) {
      bool result = await PrintBluetoothThermalWindows.writeBytes(bytes: "Hello \n".codeUnits);
      return;
    }*/

    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    //print("connection status: $conexionStatus");
    if (conexionStatus) {
      bool result = false;
      if (Platform.isWindows) {
        List<int> ticket = await testWindows();
        result = await PrintBluetoothThermalWindows.writeBytes(bytes: ticket);
      } else {
        List<int> ticket = await testTicket();
        result = await PrintBluetoothThermal.writeBytes(ticket);
        
      }
      print("print test result:  $result");
      if (result==true){
          exit(0); //this will exit app
        }
    } else {
      print("print test conexionStatus: $conexionStatus");
      
      //throw Exception("Not device connected");
    }
  }


  Future<List<int>> testTicket() async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);
    //bytes += generator.setGlobalFont(PosFontType.fontA);
    bytes += generator.reset();

    final ByteData data = await rootBundle.load('assets/mylogo.jpg');
    final Uint8List bytesImg = data.buffer.asUint8List();
    img.Image? image = img.decodeImage(bytesImg);

    if (Platform.isIOS) {
      // Resizes the image to half its original size and reduces the quality to 80%
      //final resizedImage = img.copyResize(image!, width: image.width ~/ 1.3, height: image.height ~/ 1.3, interpolation: img.Interpolation.nearest);
      final resizedImage = img.copyResize(image!, width: image.width  , height: image.height , interpolation: img.Interpolation.nearest);
      final bytesimg = Uint8List.fromList(img.encodeJpg(image ));
      image = img.decodeImage(bytesimg);
    }

    //Using `ESC *`
    bytes += generator.image(image!);


    bytes += generator.feed(2);
    //bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> testWindows() async {
    List<int> bytes = [];

    bytes += PostCode.text(text: "Size compressed", fontSize: FontSize.compressed);
    bytes += PostCode.text(text: "Size normal", fontSize: FontSize.normal);
    bytes += PostCode.text(text: "Bold", bold: true);
    bytes += PostCode.text(text: "Inverse", inverse: true);
    bytes += PostCode.text(text: "AlignPos right", align: AlignPos.right);
    bytes += PostCode.text(text: "Size big", fontSize: FontSize.big);
    bytes += PostCode.enter();

    //List of rows
    bytes += PostCode.row(texts: ["PRODUCT", "VALUE"], proportions: [60, 40], fontSize: FontSize.compressed);
    for (int i = 0; i < 3; i++) {
      bytes += PostCode.row(texts: ["Item $i", "$i,00"], proportions: [60, 40], fontSize: FontSize.compressed);
    }

    bytes += PostCode.line();

    bytes += PostCode.barcode(barcodeData: "123456789");
    bytes += PostCode.qr("123456789");

    bytes += PostCode.enter(nEnter: 5);

    return bytes;
  }

  Future<void> printWithoutPackage() async {
    //impresion sin paquete solo de PrintBluetoothTermal
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      String text =  "\n";
      bool result = await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 2, text: text));
      print("status print result: $result");
      
      setState(() {
        
      });
    } else {
      //no conectado, reconecte
      setState(() {
        
      });
      print("no conectado");
    }
  }

/*
  Future<void> _initReceiveIntent() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      final receivedIntent = await ReceiveIntent.getInitialIntent();
      // Validate receivedIntent and warn the user, if it is not correct,
      // but keep in mind it could be `null` or "empty"(`receivedIntent.isNull`).
      
    } on PlatformException {
      // Handle exception
    }
  }
*/


}