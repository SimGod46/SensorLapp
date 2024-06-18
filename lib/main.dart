/*
import 'package:flutter/material.dart';

import './MainPage.dart';

void main() => runApp(new ExampleApplication());

class ExampleApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainPage());
  }
}
*/

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'BackgroundCollectingTask.dart';

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

void main() {
  runApp(Datapp());
}

class Datapp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Datapp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF005377), // Cambia el color del texto del botón
            //backgroundColor: Colors.orange, // Cambia el color de fondo del botón
          ),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateColor.resolveWith((states) => Color(0xFF005377)), // Cambia el color del radio button
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  bool isConnected = false;

  bool connectButtonPress = false;
  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;

  //Discovery...
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> discoveryResults = List<BluetoothDiscoveryResult>.empty(growable: true);
  bool isDiscovering = false;

  //Connection
  static final clientID = 0;
  BluetoothConnection? connection;
  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  //bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;
  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> startBluetoothScan() async {
    if(_bluetoothState.isEnabled){
      _startDiscovery();
      /*
      final BluetoothDevice? selectedDevice = null;
      if (selectedDevice != null) {
        print('Discovery -> selected ' + selectedDevice.address);
      } else {
        print('Discovery -> no device selected');
      }
       */
    }
  }

  void _startDiscovery() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
          isDiscovering = true;
          if(r.device.name != null){
            setState(() {
              final existingIndex =
              discoveryResults.indexWhere((element) => element.device.address == r.device.address);
              if (existingIndex >= 0)
                discoveryResults[existingIndex] = r;
              else
                discoveryResults.add(r);
            });
          }
        });

    _streamSubscription!.onDone(() {
      setState(() {
        isDiscovering = false;
      });
    });
  }

  void askBluetoothScan(){
    connectButtonPress = true;
    checkBluetoothState();
  }

  void checkBluetoothState(){
    if(!_bluetoothState.isEnabled){
      future() async {
          await FlutterBluetoothSerial.instance.requestEnable();
      }
      future().then((aux) {
        if(_bluetoothState.isEnabled){
          startBluetoothScan();
        }
        setState(() {});
      });
    } else{
      startBluetoothScan();
    }
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
          0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

  void connectBluetooth(BluetoothDiscoveryResult server){
    BluetoothConnection.toAddress(server.device.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnected = true;
        //isConnecting = false;
        //isDisconnecting = false;
      });
      _sendMessage("1"); // Test de conexión
      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });

    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
      appBar: AppBar(
        title: Text('Datapplol'),
      ),
       */
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/screen_background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ButtonCustom(
                  color: Color(0xFF005377),
                  icon: Icons.bluetooth_searching,
                  text: 'CONECTAR',
                  enabled: true,
                  onPressed: askBluetoothScan,
                ),
                const SizedBox(height: 20),
                ButtonCustom(
                  color: Color(0xFF27273F),
                  icon: Icons.archive,
                  text: 'IMPORTAR',
                  enabled: isConnected,
                  onPressed: () {
                    _sendMessage("2");
                  },
                ),
                SizedBox(height: 20),
                ButtonCustom(
                  color: Color(0xFF06A77D),
                  icon: Icons.delete,
                  text: 'ELIMINAR',
                  enabled: isConnected,
                  onPressed: () {
                    // Lógica para eliminar
                  },
                ),
              ],
            )
          ),
          if (isDiscovering && connectButtonPress)
            Center(
              child: CircularProgressIndicator(),
            ),
          if (discoveryResults.isNotEmpty && connectButtonPress) // TODO: Verificar que se haya presionado el botón
            DevicesPopUp(
              devicesList: discoveryResults,
              onDismiss: () {
                discoveryResults = List.empty(growable: true);
                connectButtonPress = false;},
              onConfirmation: (device) {
                connectBluetooth(device);
                connectButtonPress = false;
              },
            ),
        ],
      ),
    );
  }
}

class ButtonCustom extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;
  final IconData icon;
  final String text;
  final bool enabled;

  ButtonCustom({required this.onPressed, required this.color, required this.icon, required this.text, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}

class DevicesPopUp extends StatefulWidget {
  final List<BluetoothDiscoveryResult> devicesList;
  final VoidCallback onDismiss;
  final Function(BluetoothDiscoveryResult) onConfirmation;

  DevicesPopUp({
    required this.devicesList,
    required this.onDismiss,
    required this.onConfirmation,
  });

  @override
  _DevicesPopUpState createState() => _DevicesPopUpState();
}

class _DevicesPopUpState extends State<DevicesPopUp> {
  BluetoothDiscoveryResult? deviceSelected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Dispositivos cercanos'),
      content: Container(
        height: 300,
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: ListBody(
            children: widget.devicesList.map((device) {
              return RadioListTile<BluetoothDiscoveryResult>(
                title: Text(device.device.name ?? 'Dispositivo sin nombre'),
                value: device,
                groupValue: deviceSelected,
                onChanged: (BluetoothDiscoveryResult? value) {
                  setState(() {
                    deviceSelected = value;
                  });
                },
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onDismiss,
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: deviceSelected != null ? () => widget.onConfirmation(deviceSelected!) : null,
          //style: TextButton.styleFrom(foregroundColor: Color(0xBB005377)),
          child: Text('Aceptar'),
        ),
      ],
    );
  }
}
