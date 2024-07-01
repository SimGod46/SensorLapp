import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:sensor_lapp/SensorsViewmodel.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

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

  bool isConnected = false;
  bool isDiscovering = false;
  bool isEndOfTransmission = false;
  BluetoothConnection? _connection;

  BluetoothState get bluetoothState => _bluetoothState;

  List<String> messages = List<String>.empty(growable: true);
  String _messageBuffer = '';
  String lastMessageSended = "";
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
    _discoveryResults = List<BluetoothDiscoveryResult>.empty(growable: true); // Reiniciar lista de valores...
    _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      isDiscovering = true;
      bluetoothDeviceFound(r);
    });
    _streamSubscription!.onDone(() {
      isDiscovering = false;
      notifyListeners();
    });
  }

  Future<bool> checkLocationService() async  {
    _LocationServiceEnabled = await location.serviceEnabled();
    if (!_LocationServiceEnabled) {
      _LocationServiceEnabled = await location.requestService();
      if (!_LocationServiceEnabled) {
        return false;
      }
    }

    _locationPermissionGranted = await location.hasPermission();
    if (_locationPermissionGranted == PermissionStatus.denied) {
      _locationPermissionGranted = await location.requestPermission();
      if (_locationPermissionGranted != PermissionStatus.granted) {
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

  Future<void> connectToDevice(BluetoothDiscoveryResult device, String? initMessage) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.device.address);
      isConnected = true;
      notifyListeners();
      if(initMessage !=null){
        sendMessage(initMessage);
      }

      _connection!.input!.listen(onDataReceived).onDone(() {
        if (!isConnected) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
      });
    } catch (e) {
      print('Error al conectar: $e');
      isConnected = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String message) async {
    print("Trying to send: $message");
    if (_connection != null && _connection!.isConnected) {
      try {
        _connection!.output.add(Uint8List.fromList(utf8.encode(message + "\r\n")));
        await _connection!.output.allSent;
        lastMessageSended=message;
        // Lógica adicional después de enviar el mensaje
      } catch (e) {
        print('Error al enviar mensaje: $e');
      }
    } else {
      print('No hay conexión activa');
    }
  }

  void onDataReceived(Uint8List data) {
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
      } else if(data[i] == 4){
        isEndOfTransmission = true;
      }else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13); // se busca el Carriage return, si no es carriage return, es otro mensaje...
    if (~index != 0) {
        messages.add(
            backspacesCounter > 0 ?
            _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter) :
            _messageBuffer + dataString.substring(0, index),
        );
        _messageBuffer = dataString.substring(index);
    } else {
      _messageBuffer = (
          backspacesCounter > 0 ?
          _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter) :
          _messageBuffer + dataString);
    }
    if(isEndOfTransmission){
      isEndOfTransmission = false;
      logicManager.getMessageFromBT(lastMessageSended, List.from(messages));
      messages.clear();
    }
  }

  @override
  void dispose() {
    super.dispose();
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _streamSubscription?.cancel();
    _connection?.dispose();
  }
}