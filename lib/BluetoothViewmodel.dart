import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothManager extends ChangeNotifier{
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;

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

  void testCallbacks(){
    print("se llamó de nuevo a la funcion");
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
        notifyListeners();
    }
  }

  Future<void> startBluetoothScan() async {
    if (_bluetoothState.isEnabled) {
      _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
        isDiscovering = true;
        if (r.device.name != null) {
          bluetoothDeviceFound(r);
        }
      });

      _streamSubscription!.onDone(() {
        isDiscovering = false;
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

  Future<void> connectToDevice(BluetoothDiscoveryResult device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.device.address);
      isConnected = true;

      sendMessage("1");

      _connection!.input!.listen((Uint8List data) {
        // Lógica para manejar datos recibidos
      }).onDone(() {
        // Lógica para manejar la desconexión
      });
    } catch (e) {
      print('Error al conectar: $e');
      isConnected = false;
    }
  }

  Future<void> sendMessage(String message) async {
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
    int index = buffer.indexOf(13);
    if (~index != 0) {
        messages.add(
            backspacesCounter > 0 ?
            _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter) :
            _messageBuffer + dataString.substring(0, index),
        );
        if(isEndOfTransmission){
          if(lastMessageSended == "2"){
            saveListToCSV(messages);
          }
          messages.clear();
          isEndOfTransmission = false;
        }
        _messageBuffer = dataString.substring(index);
        //notifyListeners();
    } else {
      _messageBuffer = (
          backspacesCounter > 0 ?
          _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter) :
          _messageBuffer + dataString);
    }
  }

  @override
  void dispose() {
    super.dispose();
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _streamSubscription?.cancel();
    _connection?.dispose();
  }

  Future<void> saveListToCSV(List<String> messages) async {
    try {
      // Obtener el directorio de documentos del dispositivo
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;

      // Crear el archivo CSV
      File file = File('$path/lista.csv');

      List<List<dynamic>> csvData = [
        ['Text'], // Encabezados de las columnas
        for (var message in messages) [message]
      ];

      // Convertir los datos a formato CSV
      String csv = ListToCsvConverter().convert(csvData);

      // Escribir los datos al archivo CSV
      await file.writeAsString(csv);

      print('Archivo CSV guardado en: $path/lista.csv');
    } catch (e) {
      print('Error al guardar el archivo CSV: $e');
    }
  }
}