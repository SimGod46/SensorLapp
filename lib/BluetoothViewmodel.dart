import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:sensor_lapp/HomePage.dart';
import 'package:sensor_lapp/SensorsViewmodel.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

class BluetoothManager extends ChangeNotifier{
  static BluetoothManager? _instance;

  BluetoothManager._(){
    startListeningToBluetoothState();
  }

  factory BluetoothManager() => _instance ??= BluetoothManager._();
  Location location = new Location();
  late bool _LocationServiceEnabled;
  late PermissionStatus _locationPermissionGranted;

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;

  final ValueNotifier<List<BluetoothDiscoveryResult>> _discoveryResultsNotifier = ValueNotifier([]);
  ValueNotifier<List<BluetoothDiscoveryResult>> get discoveryResultsNotifier => _discoveryResultsNotifier;

  List<BluetoothDiscoveryResult> _discoveryResults = List<BluetoothDiscoveryResult>.empty(growable: true);
  List<BluetoothDiscoveryResult> get discoveryResults => _discoveryResults;

  ValueNotifier<bool> isConnected = ValueNotifier(false);
  bool isDiscovering = false;
  BluetoothConnection? _connection;
  DateTime? lastMessageTime = DateTime.now();
  BluetoothState get bluetoothState => _bluetoothState;

  SensorsManager logicManager = SensorsManager();
  void startListeningToBluetoothState() {
    FlutterBluetoothSerial.instance.state.then((state) {
      _bluetoothState = state;
      notifyListeners();
    });

    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      _bluetoothState = state;
      notifyListeners();
      // Aquí puedes realizar acciones adicionales cuando cambie el estado de Bluetooth
    });
  }

  void bluetoothDeviceFound(BluetoothDiscoveryResult device){
    if(device.device.name != null){
        final existingIndex = _discoveryResults.indexWhere((element) => element.device.address == device.device.address);
        if (existingIndex >= 0){
          _discoveryResults[existingIndex] = device;
        }
        else{
          _discoveryResults.add(device);
        }
        _discoveryResultsNotifier.value = List.from(_discoveryResults); // Update ValueNotifier
        notifyListeners();
    }
  }

  void stopScan(){
    _discoveryResults = List<BluetoothDiscoveryResult>.empty(growable: true); // Reiniciar lista de valores...
    FlutterBluetoothSerial.instance.cancelDiscovery();
  }

  void actionScan(){
    _discoveryResults = List<BluetoothDiscoveryResult>.empty(growable: true);
    notifyListeners();    // Reiniciar lista de valores...

    _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      isDiscovering = true;
      bluetoothDeviceFound(r);
    });
    _streamSubscription!.onDone(() {
      isDiscovering = false;
      notifyListeners();
    });
  }

  Future<bool> checkBLPermissions() async {
    List<permissions.Permission> permissionsNeeded = [];
    if (await permissions.Permission.storage.isDenied) {
      permissionsNeeded.add(permissions.Permission.storage);
    }
    if (await permissions.Permission.notification.isDenied) {
      permissionsNeeded.add(permissions.Permission.notification);
    }
    if (await permissions.Permission.bluetooth.isDenied) {
      permissionsNeeded.add(permissions.Permission.bluetooth);
    }
    if (await permissions.Permission.bluetoothConnect.isDenied) {
      permissionsNeeded.add(permissions.Permission.bluetoothConnect);
    }
    if (await permissions.Permission.bluetoothScan.isDenied) {
      permissionsNeeded.add(permissions.Permission.bluetoothScan);
    }
    if (await permissions.Permission.locationWhenInUse.isDenied) {
      permissionsNeeded.add(permissions.Permission.locationWhenInUse);
    }

    Map<permissions.Permission, permissions.PermissionStatus> statuses = await permissionsNeeded.request();

    /*
    if (statuses.values.any((status) => status.isDenied)) {
      permissions.openAppSettings();
      return false;
    }
     */
    return true;
  }

  Future<bool> checkLocationService() async  {
    _LocationServiceEnabled = await location.serviceEnabled();
    if (!_LocationServiceEnabled) {
      _LocationServiceEnabled = await location.requestService();
      if (!_LocationServiceEnabled) {
        return false;
      }
    }
    return true;
  }

  Future<void> startBluetoothScan() async {
    var gpsEnabled = await checkLocationService();
    if(!gpsEnabled){
      return;
    }
    checkBLPermissions();
/*
    var permissionGranted = await checkBLPermissions();
    if(!permissionGranted){
      return;
    }
 */
    if (_bluetoothState.isEnabled) {
      await FlutterBluetoothSerial.instance.isDiscovering.then((onValue){
        if(onValue ?? false){
          FlutterBluetoothSerial.instance.cancelDiscovery().then((_){
            actionScan();
          });
        } else{
          actionScan();
        }
      });
    } else{
      future() async {
        await FlutterBluetoothSerial.instance.requestEnable();
      }

      future().then((aux) {
        if(_bluetoothState.isEnabled){
          startBluetoothScan();
        }
      });
    }
  }

  Future<void> connectToDevice(String deviceAdress, String? initMessage, BuildContext context) async {
    try {
      _connection = await BluetoothConnection.toAddress(deviceAdress);
      isConnected.value = true;
      notifyListeners();
      if(initMessage !=null){
        sendMessage(initMessage);
      }
      _connection!.input!.listen(onDataReceived).onDone(() {
        if (!isConnected.value) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        DisconnectDevice();
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => HomePage()),);
      });
    } catch (e) {
      print('Error al conectar: $e');
      isConnected.value = false;
      notifyListeners();
    }
  }

  Future<void> DisconnectDevice() async {
    try {
      await _connection?.finish().then((_){
        isConnected.value = false;
        notifyListeners();
      });
    } catch (e) {
      print('Error al desconectar: $e');
    }
  }

  Future<void> sendMessage(String message, {bool requiredEnd = false}) async {
    print("Trying to send: $message");
    var endMsg = "";
    if(requiredEnd){
      endMsg = "\r\n";
    }
    if (_connection != null && _connection!.isConnected) {
      try {
        DateTime _currentTime = DateTime.now();
        if( logicManager.lastMessageSended == "r" && message != "r"){
          lastMessageTime = _currentTime.add(Duration(seconds: 1, milliseconds: 500));//DateTime.now();
          logicManager.readingEnabled = false;
          await Future.delayed(Duration(seconds: 1, milliseconds: 500)); // espero 1.5 segundos
          logicManager.readingEnabled = true;
        }
        if(message == "r" && !logicManager.readingEnabled){
          return;
        }
        _currentTime = DateTime.now();
        if(_currentTime.isAfter(lastMessageTime!)){
          _connection!.output.add(Uint8List.fromList(utf8.encode(message + endMsg)));
          await _connection!.output.allSent;
          logicManager.setLastMessage(message);
        }
      } catch (e) {
        print('Error al enviar mensaje: $e');
      }
    } else {
      print('No hay conexión activa');
    }
  }

  void onDataReceived(Uint8List data) {
    data.forEach((byte) {
      logicManager.getByteFromBT(byte);
    });
  }

  void closeBluetooth(){
    print("Se ejecutó el close de BL");
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _streamSubscription?.cancel();
    _connection?.dispose();
  }

  @override
  void dispose() {
    super.dispose();
    print("Se ejecutó el dispose de BL");
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _streamSubscription?.cancel();
    _connection?.dispose();
  }
}