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
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'BackgroundCollectingTask.dart';
import 'DiscoveryPage.dart';

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
  List<BluetoothDevice> devicesList = [];
  bool isLoading = false;
  bool isConnected = false;
  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;

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
      final BluetoothDevice? selectedDevice =
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return DiscoveryPage();
          },
        ),
      );

      if (selectedDevice != null) {
        print('Discovery -> selected ' + selectedDevice.address);
      } else {
        print('Discovery -> no device selected');
      }
    }
  }

  void askBluetoothScan(){
  checkBluetoothState();
    setState(() {
      isLoading = true;
    });
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
                  onPressed: askBluetoothScan,
                  color: Color(0xFF005377),
                  icon: Icons.bluetooth_searching,
                  text: 'CONECTAR',
                  enabled: true,
                ),
                const SizedBox(height: 20),
                ButtonCustom(
                  onPressed: () {
                    // Lógica para importar
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Sample test"),
                        content: Text("aqui deberia aparecer algo asi como confirmar, no sé no me acuerdo..."),
                        actions: [
                          TextButton(
                            child: Text("CANCEL"),
                            onPressed: () => Navigator.pop(context)
                          ),
                          TextButton(
                            child: Text("OK"),
                            onPressed: () => Navigator.pop(context)
                          )
                        ]
                      )
                    );
                  },
                  color: Color(0xFF27273F),
                  icon: Icons.archive,
                  text: 'IMPORTAR',
                  enabled: isConnected,
                ),
                SizedBox(height: 20),
                ButtonCustom(
                  onPressed: () {
                    // Lógica para eliminar
                  },
                  color: Color(0xFF06A77D),
                  icon: Icons.delete,
                  text: 'ELIMINAR',
                  enabled: isConnected,
                ),
              ],
            )
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
          if (!isLoading && devicesList.isNotEmpty)
            DevicesPopUp(
              devicesList: devicesList,
              onDismiss: () {},
              onConfirmation: (device) {
                // Lógica de conexión al dispositivo
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

class DevicesPopUp extends StatelessWidget {
  final List<BluetoothDevice> devicesList;
  final VoidCallback onDismiss;
  final Function(BluetoothDevice) onConfirmation;

  DevicesPopUp({required this.devicesList, required this.onDismiss, required this.onConfirmation});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Dispositivos cercanos'),
      content: Container(
        height: 200.0, // Fija la altura del contenedor
        width: double.maxFinite, // Ajusta el ancho a las necesidades
        child: SingleChildScrollView(
          child: ListBody(
            children: devicesList.map((device) {
              return ListTile(
                title: Text("ALo"),
                onTap: () {
                  onConfirmation(device);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text('Cancelar'),
        ),
      ],
    );
  }
}
