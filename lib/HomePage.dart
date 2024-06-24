import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'Utils.dart';
import 'TerminalPage.dart';
import 'BluetoothViewmodel.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late BluetoothManager _bluetoothManager;// = Provider.of<BluetoothManager>(context);
  bool connectButtonPress = false;
  bool isDialogOpen = false;
  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _bluetoothManager.dispose();
    super.dispose();
  }

  void askBluetoothScan(){
    connectButtonPress = true;
    _bluetoothManager.startBluetoothScan();
    //discoveryResults = _bluetoothManager.discoveryResults;
  }

  @override
  Widget build(BuildContext context) {
    _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
    if (_bluetoothManager.discoveryResults.isNotEmpty && connectButtonPress && !isDialogOpen){
      isDialogOpen = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return DevicesPopUp(
                devicesList: _bluetoothManager.discoveryResults,
                onDismiss: () {
                  //discoveryResults = List.empty(growable: true);
                  isDialogOpen = false;
                  connectButtonPress = false;
                  Navigator.pop(context);
                  },
                onConfirmation: (device) {
                  _bluetoothManager.connectToDevice(device);
                  isDialogOpen = false;
                  connectButtonPress = false;
                  Navigator.pop(context);
                },
              );
            }
        );
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Datapp'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: const Text("Inicio"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Datapp()),
                );
              },
            ),
            ListTile(
              title: const Text("Terminal"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TerminalPage()),
                );
              },
            ),
            ListTile(
              title: const Text("PH"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("O2"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("ORP"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
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
                    enabled: _bluetoothManager.isConnected,
                    onPressed: () {
                      _bluetoothManager.sendMessage("2");
                    },
                  ),
                  SizedBox(height: 20),
                  ButtonCustom(
                    color: Color(0xFF06A77D),
                    icon: Icons.delete,
                    text: 'ELIMINAR',
                    enabled: _bluetoothManager.isConnected,
                    onPressed: () {
                      // Lógica para eliminar
                    },
                  ),
                ],
              )
          ),

          if (_bluetoothManager.isDiscovering&& connectButtonPress)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}