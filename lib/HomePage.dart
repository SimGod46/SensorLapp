import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
    var drawerItemsState = Provider.of<DrawerItemsState>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: AppColors.primaryColor),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Image.asset('assets/logo_cmas.png'),
            ),
          ),
        ],
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ValueListenableBuilder(
                      valueListenable: _bluetoothManager.isConnected,
                      builder: (ctx, value, child){
                        if(value){
                          return
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MyCustomCard(
                                  deviceInfo: drawerItemsState.deviceInformation
                                ),
                                MyCustomCard2(),
                                TerminalCard(),
                              ],
                            );
                        } else{
                          return ButtonCustom(
                            color: AppColors.primaryColor,
                            icon: Icons.bluetooth_searching,
                            text: 'Conectar',
                            onPressed: (){
                              askBluetoothScan();
                            },
                          );
                        }
                        return const SizedBox();
                      }
                  ),
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
                                    Navigator.pop(context);
                                    },
                                  onConfirmation: (deviceAddr) {
                                    _bluetoothManager.connectToDevice(deviceAddr, "1");
                                    Navigator.pop(context);
                                  },
                                );
                              }).then((value) async {
                                _bluetoothManager.stopScan();
                                isDialogOpen = false;
                                connectButtonPress = false;
                                print('Dialog closed');
                          });
                        });}
                        return const SizedBox();
                  })
                ],
              )
            )
          )],
      ),
    );
  }
}

class DrawerItemsState extends ChangeNotifier {
  static DrawerItemsState? _instance;

  DrawerItemsState._(){
    //startListeningToBluetoothState();
  }

  factory DrawerItemsState() => _instance ??= DrawerItemsState._();

  List<List<String>> deviceInformation = List<List<String>>.empty(growable: true);

  Map<String, bool> itemsVisibility = {
    "Inicio": true,
    "Terminal": false,
    "PH": false,
    "O2": false,
    "ORP": false,
    "EC": false,
  };

  int sheetSize = 0;

  void setItemVisibility(String item, bool isVisible) {
    if (itemsVisibility.containsKey(item)) {
      itemsVisibility[item] = isVisible;
      notifyListeners();
    }
  }
  void setFileSize(int size) {
      sheetSize = size;
      notifyListeners();
  }
  void setDeviceMetadata(List<List<String>> data){
    deviceInformation = data;
  }
}
