import 'package:flutter/material.dart';
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
  late BluetoothManager _bluetoothManager ;// = Provider.of<BluetoothManager>(context);
  bool connectButtonPress = false;

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
      _bluetoothManager.startListeningToBluetoothState();
      _bluetoothManager.testCallbacks();
    });
    // Get current state
    //
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
          if (_bluetoothManager.discoveryResults.isNotEmpty && connectButtonPress) // TODO: Verificar que se haya presionado el botón
            DevicesPopUp(
              devicesList: _bluetoothManager.discoveryResults,
              onDismiss: () {
                //discoveryResults = List.empty(growable: true);
                connectButtonPress = false;},
              onConfirmation: (device) {
                _bluetoothManager.connectToDevice(device);
                connectButtonPress = false;
              },
            ),
        ],
      ),
    );
  }
}