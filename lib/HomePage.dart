import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'CalibrationPage.dart';
import 'SensorsViewmodel.dart';
import 'TerminalPage.dart';
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
    DrawerItemsState drawerItemsState = Provider.of<DrawerItemsState>(context);

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
                                  onPressDescargar: () {
                                    Fluttertoast.showToast(msg: "Descarga iniciada");
                                    _bluetoothManager.sendMessage("2");
                                    },
                                  onPressEliminar: () { DialogHelper.showMyDialog(context, "Eliminar datos", "¿Estas seguro que desea elminar todos los datos de la tarjeta de memoria?",(){Fluttertoast.showToast(msg: "Datos eliminados");_bluetoothManager.sendMessage("3");}); },
                                  onPressDesconectar: () {
                                    _bluetoothManager.sendMessage("9");
                                    _bluetoothManager.DisconnectDevice();
                                    Fluttertoast.showToast(msg: "Desconectado");
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

class DrawerItemsState extends ChangeNotifier{
  static DrawerItemsState? _instance;

  DrawerItemsState._(){
    //startListeningToBluetoothState();
  }

  factory DrawerItemsState() => _instance ??= DrawerItemsState._();

  List<List<String>> deviceInformation = List<List<String>>.empty(growable: true);
  List<MessageModel> terminalMessages = List<MessageModel>.empty(growable: true);

  //String currentPage = "";

  String realTimeReading = "No data";
  bool isOnTerminal = false;

  Map<String, bool> itemsVisibility = {
    "PH": false,
    "O2": false,
    "ORP": false,
    "EC": false,
  };

  Map<String, String> itemsAdress = {
    "PH": "",
    "O2": "",
    "ORP": "",
    "EC": "",
  };

  int sheetSize = 0;

  void addToTerminal(String sendedBy, String message){
    terminalMessages.add(
        MessageModel(fromName: "Local", message: message)
    );
    notifyListeners();
  }

  void clearTerminal(){
    terminalMessages.clear();
    notifyListeners();
  }

  void setRealTimeRead(String read){
    realTimeReading = read;
    notifyListeners();
  }

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

class SensorsAvailableCard extends StatelessWidget {
  final Map<String,bool> sensorsVisibility;

  const SensorsAvailableCard({
    Key? key,
    required this.sensorsVisibility,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DrawerItemsState drawerItemsState = Provider.of<DrawerItemsState>(context);
    BluetoothManager _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
    int trueCount = sensorsVisibility.values.where((value) => value).length;
    //drawerItemsState.setCurrentPage("Home");
    return
      BaseCard(
        cardTitle: 'Calibración',
        body:
        [Column(
          children:[
            if(trueCount<=0) ...[
              Center(
                  child: Text("No hay datos de sensores...")
              ),
              SizedBox(height: 20),
            ],
            ...sensorsVisibility.entries.where((entry)=> entry.value).map((entry)=>
                Column(
                    children:[
                      Center(
                          child:
                          ButtonCustom(
                            onPressed: (){
                              String? initMenuCode = drawerItemsState.itemsAdress[entry.key];
                              if (initMenuCode!= null) _bluetoothManager.sendMessage(initMenuCode);
                              Navigator.pushNamed(context, "/calibration", arguments: entry.key);
                            },
                            color: AppColors.secondaryColor,
                            text: entry.key,
                            fillWidth: true,
                            textColor: AppColors.primaryColor,)
                      ),
                      SizedBox(height: 20),
                    ]
                )
            )
          ],
        )],
      );
  }
}

class DeviceInfoCard extends StatelessWidget {
  final List<List<String>> deviceInfo;
  final VoidCallback onPressDescargar;
  final VoidCallback onPressEliminar;
  final VoidCallback onPressDesconectar;

  const DeviceInfoCard({
    Key? key,
    required this.deviceInfo,
    required this.onPressDescargar,
    required this.onPressEliminar,
    required this.onPressDesconectar,
  }): super(key: key);

  @override
  Widget build(BuildContext context) {
    return
      BaseCard(
          cardTitle: 'Estación',
          cardIcon: Icons.info_outline,
          body:
          [Column(
            children: deviceInfo.map((List<String> items) => gridItem(items[0], items[1])).toList(),//List.generate(6, (index) => gridItem(index)),
          ),
            SizedBox(height: 30),
            LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 300) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ButtonCustom(onPressed: (){onPressDescargar();}, color: AppColors.primaryColor, text: "Descargar"),
                        ButtonCustom(onPressed: (){onPressEliminar();}, color: AppColors.primaryColor, text: "Eliminar")
                      ],
                    );
                  } else{
                    return Column(
                      children: [
                        ButtonCustom(onPressed: (){onPressDescargar();}, color: AppColors.primaryColor, text: "Descargar", fillWidth: true,),
                        SizedBox(height: 20),
                        ButtonCustom(onPressed: (){onPressEliminar();}, color: AppColors.primaryColor, text: "Eliminar", fillWidth: true,)
                      ],
                    );
                  }
                }),
            SizedBox(height: 20),
            Center(
                child: ButtonCustom(onPressed: (){onPressDesconectar();}, color: AppColors.secondaryColor, text: "Desconectar", fillWidth: true, textColor: AppColors.primaryColor,)
            ),
          ]
      );
  }

  Widget gridItem(String itemName, String itemValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          itemName,
          style: TextStyle(
            fontSize: 18,
            color: AppColors.accentColor,
          ),
        ),
        Text(
          itemValue,
          style: TextStyle(
            fontSize: 18,
            color: AppColors.accentColor,
          ),
        ),
      ],
    );
  }
}
