import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Utils.dart';
import 'BluetoothViewmodel.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late BluetoothManager _bluetoothManager;

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
    super.dispose();
  }

  void askBluetoothScan(){
    _bluetoothManager.startBluetoothScan();
  }

  @override
  Widget build(BuildContext context) {
    _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
    var drawerItemsState = Provider.of<DrawerItemsState>(context);

    return
      CustomScaffold(body:
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
                            PopScope(
                              canPop: false,
                              onPopInvoked: (bool didPop) async {
                                if (didPop) {
                                  return;
                                }
                                DialogHelper.showMyDialog(context, "¿Desconectar?", "Se desconectará el dispositivo", (){
                                  _bluetoothManager.sendMessage("9");
                                  _bluetoothManager.DisconnectDevice();
                                });
                              },
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                DeviceInfoCard(
                                  deviceInfo: drawerItemsState.deviceInformation,
                                  onPressDescargar: () { _bluetoothManager.sendMessage("2"); },
                                  onPressEliminar: () { DialogHelper.showMyDialog(context, "Eliminar datos", "¿Estas seguro que desea elminar todos los datos de la tarjeta de memoria?",(){_bluetoothManager.sendMessage("3");}); },
                                  onPressDesconectar: () {
                                    _bluetoothManager.sendMessage("9");
                                    _bluetoothManager.DisconnectDevice();
                                    },
                                ),
                                SensorsAvailableCard(sensorsVisibility: drawerItemsState.itemsVisibility),
                              ],
                            ));
                        } else{
                          return ButtonCustom(
                            color: AppColors.primaryColor,
                            icon: Icons.bluetooth_searching,
                            text: 'Conectar',
                            onPressed: (){
                              askBluetoothScan();
                              showDialog(
                                  context: ctx,
                                  builder: (ctx) {
                                    return DevicesPopUp(
                                      devicesNotifier: _bluetoothManager.discoveryResultsNotifier,
                                      onDismiss: () {
                                        Navigator.pop(context);
                                      },
                                      onConfirmation: (deviceAddr) {
                                        _bluetoothManager.connectToDevice(deviceAddr, "1", context);
                                        Navigator.pop(context);
                                      },
                                    );
                                  }).then((value) async {
                                _bluetoothManager.stopScan();
                                isDialogOpen = false;
                                print('Dialog closed');
                              });
                            },
                          );
                        }
                      }
                  ),
                ],
              )
            )
          ));
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
    //"Inicio": true,
    "PH": false,
    "O2": false,
    "ORP": false,
    "EC": false,
  };

  Map<String, String> itemsAdress = {
    //"Inicio": true,
    "PH": "",
    "O2": "",
    "ORP": "",
    "EC": "",
    //"Terminal": false,
  };

  int sheetSize = 0;

  void setItemVisibility(String item, bool isVisible) {
    if (itemsVisibility.containsKey(item)) {
      itemsVisibility[item] = isVisible;
      notifyListeners();
    }
  }
  void setItemAdress(String item, String addr) {
    if (itemsAdress.containsKey(item)) {
      itemsAdress[item] = addr;
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
