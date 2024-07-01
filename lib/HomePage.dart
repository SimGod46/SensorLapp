import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
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
  late BluetoothManager _bluetoothManager;
  bool connectButtonPress = false;
  bool isDialogOpen = false;
  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  get deviceSelected => null;

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
  }

  Future<void> _showMyDialog(String titleText, String bodyText, VoidCallback onAccept) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titleText),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(bodyText),
                //Text('Would you like to approve of this message?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                onAccept();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
                    onPressed: (){
                      askBluetoothScan();
                    },
                  ),
                  SizedBox(height: 20),
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
                      _showMyDialog("Eliminar datos", "¿Estas seguro que desea elminar todos los datos de la tarjeta de memoria?",(){});
                      //;
                    },
                  ),
                  /*
                  ValueListenableBuilder(
                    valueListenable: _bluetoothManager.isDiscovering,
                    builder: (ctx, value, child) {
                      if (value && connectButtonPress) {
                        isDialogOpen = true;
                        Future.delayed(const Duration(seconds: 0), () {
                          showDialog(
                          context: ctx,
                          builder: (ctx) {
                            return Center(child: CircularProgressIndicator(),);
                          });});
                        } return const SizedBox();}
                  ),
                   */
                  ValueListenableBuilder(
                      valueListenable: _bluetoothManager.discoveryResultsNotifier,
                      builder: (ctx, value, child) {
                        if (value.isNotEmpty && connectButtonPress && !isDialogOpen) {
                        isDialogOpen = true;
                        Future.delayed(const Duration(seconds: 0), () {
                          showDialog(
                              context: ctx,
                              builder: (ctx) {
                                return DevicesPopUp(
                                  devicesNotifier: _bluetoothManager.discoveryResultsNotifier,
                                  onDismiss: () {
                                    _bluetoothManager.stopScan();
                                    isDialogOpen = false;
                                    connectButtonPress = false;
                                    Navigator.pop(context);
                                    },
                                  onConfirmation: (device) {
                                    _bluetoothManager.stopScan();
                                    _bluetoothManager.connectToDevice(device, "1");
                                    isDialogOpen = false;
                                    connectButtonPress = false;
                                    Navigator.pop(context);
                                  },
                                );
                              });
                        });}
                        return const SizedBox();
                  })
                ],
              )
          ),
        ],
      ),
    );
  }
}