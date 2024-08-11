import 'dart:async';
import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' hide Intent;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:image/image.dart' as img;
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
 String _info = "";
  String _msj = '';
  bool connected = false;
  List<BluetoothInfo> items = [];
  List<String> _options = ["permission bluetooth granted", "bluetooth enabled", "connection status", "update info"];
  String _selectSize = "2";
  final _txtText = TextEditingController(text: "Write something here");
  bool _progress = false;
  String _msjprogress = "";

  String optionprinttype = "58 mm";
  List<String> options = ["58 mm", "80 mm"];
  
  // StreamSubscription? _sub;

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

    /*
    getBluetoots();
    */

    final receivedIntent = await ReceiveIntent.getInitialIntent(); //to get the Intent that started the Activity:
    setState(() { _initialIntent = receivedIntent; });
    

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.    
    if (!mounted) return;

    final bool result = await PrintBluetoothThermal.bluetoothEnabled;
    print("bluetooth enabled: $result");
    if (result) {
      _msj = "Bluetooth enabled, please search and connect";
    } else {
      _msj = "Bluetooth not enabled";
    }

    
  }

  
   Widget _buildFromIntent(String label, Intent? intent) {

    //example of how uri extras looks like
    // {android.intent.extra.TEXT:MAUI,abc,abc,abc}
    
    String recieved="extras: ${intent?.extra}";


    if((recieved).contains('MAUI')){
      //String uri = (recieved.split(':').last); //to take the double scope dots away
      String uri = (recieved.split('MAUI,').last); //to take part after MAUI,
      String finaluri= uri.substring(0, uri.length - 1); //to remove the curly brackets at the end ====>  abc,abc,abc
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
          title: const Text('Megax Thermal Printer'),
          actions: [
            PopupMenuButton(
              elevation: 3.2,
              //initialValue: _options[1],
              onCanceled: () {
                print('You have not chossed anything');
              },
              tooltip: 'Menu',
              onSelected: (Object select) async {
                String sel = select as String;
                if (sel == "permission bluetooth granted") {
                  bool status = await PrintBluetoothThermal.isPermissionBluetoothGranted;
                  setState(() {
                    _info = "permission bluetooth granted: $status";
                  });
                  //open setting permision if not granted permision
                } else if (sel == "bluetooth enabled") {
                  bool state = await PrintBluetoothThermal.bluetoothEnabled;
                  setState(() {
                    _info = "Bluetooth enabled: $state";
                  });
                } else if (sel == "update info") {
                  initPlatformState();
                } else if (sel == "connection status") {
                  final bool result = await PrintBluetoothThermal.connectionStatus;
                  connected = result;
                  setState(() {
                    _info = "connection status: $result";
                  });
                }
              },
              itemBuilder: (BuildContext context) {
                return _options.map((String option) {
                  return PopupMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList();
              },
            )
          ],
        ),



      body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Row(
                  children: [
                    Text("Type print"),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: optionprinttype,
                      items: options.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          optionprinttype = newValue!;
                        });
                      },
                    ),
                  ],
                ),

                Row(
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        this.getBluetoots();
                      },
                      child: Row(
                        children: [
                          Visibility(
                            visible: _progress,
                            child: SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator.adaptive(strokeWidth: 1, backgroundColor: Colors.white),
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(_progress ? _msjprogress : "Search"),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: connected ? this.disconnect : null,
                      child: Text("Disconnect"),
                    ),
                    /*
                    ElevatedButton(
                      onPressed: connected ? this.printTest("test") : null,
                      child: Text("Test"),
                    ), */
                  ],
                ),
                Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    child: ListView.builder(
                      itemCount: items.length > 0 ? items.length : 0,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () {
                            String mac = items[index].macAdress;
                            this.connect(mac);
                          },
                          title: Text('Name: ${items[index].name}'),
                          subtitle: Text("macAddress: ${items[index].macAdress}"),
                        );
                      },
                    )),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  child: Column(children: [
                    Text(""),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _txtText,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Text",
                            ),
                          ),
                        ),
                        SizedBox(width: 5),
                        DropdownButton<String>(
                          hint: Text('Size'),
                          value: _selectSize,
                          items: <String>['1', '2', '3', '4', '5'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: new Text(value),
                            );
                          }).toList(),
                          onChanged: (String? select) {
                            setState(() {
                              _selectSize = select.toString();
                            });
                          },
                        )
                      ],
                    ),
                    ElevatedButton(
                      onPressed: connected ? this.printWithoutPackage : null,
                      child: Text("Print"),
                    ),
                  ]),

             

                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
        
      
      ), 
    
    );
  }



  Future<void> getBluetoots() async {
    
    /*
    final List<BluetoothInfo> listResult = await PrintBluetoothThermal.pairedBluetooths;
     final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: "86:67:7A:EA:C3:8F");
      if(result ==true){
      }
    */
    setState(() {
      _progress = true;
      _msjprogress = "Wait";
      items = [];
    });
    final List<BluetoothInfo> listResult = await PrintBluetoothThermal.pairedBluetooths;

    await Future.forEach(listResult, (BluetoothInfo bluetooth) {
      String name = bluetooth.name;
      String mac = bluetooth.macAdress;
    });

    setState(() {
      _progress = false;
    });

    if (listResult.length == 0) {
      _msj = "There are no bluetoohs linked, go to settings and link the printer";
    } else {
      _msj = "Touch an item in the list to connect";
    }

    setState(() {
      items = listResult;
    });


  }




  Future<void> printTest(String uri) async {
    
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    //print("connection status: $conexionStatus");
    if (conexionStatus) {
      bool result = false;

    
     if((uri).contains(',')){   //this will be true if more than one image is in the uri
      //split further and call to print
      final splitImages= uri.split(',');
      for (int i = 0; i < splitImages.length; i++){
      List<int> ticket = await testTicket(splitImages[i]);
      result = await PrintBluetoothThermal.writeBytes(ticket); //----here is the printing order happening
      }
    }
    else{
      List<int> ticket = await testTicket(uri);
      result = await PrintBluetoothThermal.writeBytes(ticket); //----here is the printing order happening
      }

     
      
      print("print test result:  $result");
      if (result==true){

          SystemNavigator.pop();
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
    
    img.Image? image = img.decodeImage(bytesImg);

    
    //Using `ESC *`
    bytes += generator.image(image!);

    //bytes += generator.cut();
    return bytes;
  }

  
Future<void> printWithoutPackage() async {
    //impresion sin paquete solo de PrintBluetoothTermal
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      String text = _txtText.text.toString() + "\n";
      bool result = await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: int.parse(_selectSize), text: text));
      print("status print result: $result");
      setState(() {
        _msj = "printed status: $result";
      });
    } else {
      //no conectado, reconecte
      setState(() {
        _msj = "no connected device";
      });
      print("no connection");
    }
  }
  
Future<void> connect(String mac) async {
    setState(() {
      _progress = true;
      _msjprogress = "Connecting...";
      connected = false;
    });
    final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    print("state conected $result");
    if (result) connected = true;
    setState(() {
      _progress = false;
    });
  }

Future<void> disconnect() async {
    final bool status = await PrintBluetoothThermal.disconnect;
    setState(() {
      connected = false;
    });
    print("status disconnect $status");
  }

}