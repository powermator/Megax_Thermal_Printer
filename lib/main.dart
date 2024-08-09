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
import 'dart:convert';

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
 StreamSubscription? _sub;
  
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

    getBluetoots();

    final receivedIntent = await ReceiveIntent.getInitialIntent(); //to get the Intent that started the Activity:
    
    setState(() { _initialIntent = receivedIntent; });
    
        
    if (!mounted) return;
  }

   Widget _buildFromIntent(String label, Intent? intent) {

    
    String recieved="extras: ${intent?.extra}";
    if((recieved).contains('MAUI')){
      String uri = (recieved.split(':').last); //to take the double scope dots away
      String finaluri= uri.substring(0, uri.length - 1); //to remove the curly brackets away
      printTest(finaluri);
     
      }
    
    
    
    return Center(
      child: Column(
        children: [
          Text(label),
          /*
          Text(
              "fromPackage: ${intent?.fromPackageName}\nfromSignatures: ${intent?.fromSignatures}"),
          Text(
              'action: ${intent?.action}\ndata: ${intent?.data}\ncategories: ${intent?.categories}'),
          Text("extras: ${intent?.extra}")
          */
        ],
      ),
    );
    
  }


  
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

    
     final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: "86:67:7A:EA:C3:8F");
      if(result ==true){
        
        }

  }




  Future<void> printTest(String uri) async {
    
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    //print("connection status: $conexionStatus");
    if (conexionStatus) {
      bool result = false;
      
        List<int> ticket = await testTicket(uri);
        result = await PrintBluetoothThermal.writeBytes(ticket); //----here is the printing order happening
       
      
      print("print test result:  $result");
      if (result==true){

          SystemNavigator.pop();
          //exit(0); //this will exit app
        }
    } else {
      print("print test conexionStatus: $conexionStatus");
      
      //throw Exception("Not device connected");
    }
  }


  Future<List<int>> testTicket(String uri) async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);
    
    bytes += generator.reset();


    final Uint8List bytesImg = base64.decode(uri.split(',').last);

    //final ByteData data = await rootBundle.load('assets/mylogo.jpg');    //---------------logo
    //final Uint8List bytesImg = data.buffer.asUint8List();

    img.Image? image = img.decodeImage(bytesImg);

    
    //Using `ESC *`
    bytes += generator.image(image!);


    bytes += generator.feed(1);
    //bytes += generator.cut();
    return bytes;
  }

/////////////////////////////////////////////////
//
/*
    Future<void> _initReceiveIntentit() async {
    // ... check initialIntent

    // Attach a listener to the stream
    _sub = ReceiveIntent.receivedIntentStream.listen((Intent? intent) {
      // Validate receivedIntent and warn the user, if it is not correct,
      
      String recieved="extras: ${intent?.extra}";
    if((recieved).contains('MAUI')){
      String uri = (recieved.split(':').last); //to take the double scope dots away
      String finaluri= uri.substring(0, uri.length - 1); //to remove the curly brackets away
      printTest(finaluri);
    }



    }, onError: (err) {
      // Handle exception
    });

    // NOTE: Don't forget to call _sub.cancel() in dispose()
  }
  */
  ///////////////////////////////////////////////////
  



}