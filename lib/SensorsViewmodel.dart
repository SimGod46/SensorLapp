import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'HomePage.dart';
import 'NotificationViewmodel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;
import 'package:fluttertoast/fluttertoast.dart';

import 'main.dart';

class MessageModel {
  final String timeStamp;
  final String fromName;
  final String message;

  MessageModel({
    String? timeStamp,
    required this.fromName,
    required this.message,
  }) : timeStamp = timeStamp ?? DateFormat('[HH:mm:ss]').format(DateTime.now());
}

String formatBytes(String bytesRaw, {int decimals = 1}) {
  int bytes = int.parse(bytesRaw);
  if (bytes <= 0) return "0 Bytes";
  const suffixes = ["b", "Kb", "Mb", "Gb", "Tb", "Pb", "Eb", "Zb", "Yb"];
  int i = 0;
  double dbBytes = bytes.toDouble();

  while (dbBytes >= 1024) {
    dbBytes /= 1024;
    i++;
  }

  return "${dbBytes.toStringAsFixed(decimals)} ${suffixes[i]}";
}

class SensorsManager{
  List<String> messages = List<String>.empty(growable: true);
  String _messageBuffer = "";
  String lastMessageSended = "";
  int bytesCount = 0;
  int notificationId = 0;
  bool readingEnabled = true;
  int fileSize = 0;
  int cardSize = 0;
  int percentCount = -1;

  //TODO: Revisar que pasa si envio un mensaje sin esperar a que termine la respuesta...

  setLastMessage(String message){
    DrawerItemsState drawerItemsState = DrawerItemsState();
    lastMessageSended = message;
    if( drawerItemsState.isOnTerminal){
      drawerItemsState.addToTerminal("Local", lastMessageSended);
    }
  }

  getByteFromBT(int byte){
    bytesCount++;
    if(lastMessageSended == "2"){
      if(bytesCount == 1){
        notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
      int progress = (bytesCount*100) ~/ fileSize;
      if(progress % 10 == 0 && progress != 100 && progress > percentCount){
        percentCount = progress;
        LocalNotificationService.displayProgress(notificationId, "Guardando archivo CSV", "Progreso: ${progress}%", progress);
      }
    }
    if (byte == 4 || byte == 13 || byte == 10) {
      if(_messageBuffer.isNotEmpty){
        messages.add(_messageBuffer);
        _messageBuffer = "";
      }
      if(byte == 4){
        bytesCount = 0;// Verificar si el byte es EOT
        getMessageFromBT(lastMessageSended, List.from(messages));
        messages.clear();  // Limpiar los mensajes después de manejarlos
      }
    } else {
      _messageBuffer += String.fromCharCode(byte);
    }
  }


  getMessageFromBT(String lastMessageSended, List<String> currentMessages){
    DrawerItemsState drawerItemsState = DrawerItemsState();
    if(drawerItemsState.isOnTerminal){
      drawerItemsState.addToTerminal("Remote", currentMessages.last);
    } else if(lastMessageSended == "1\r\n" || lastMessageSended == "3"){
      try{
        List<String> initialNames = ['Versión Firmware', 'ID Dispositivo', 'Estado SD','Archivo', 'Esp. usado', 'Esp. total'];
        List<String> initialParams = currentMessages[0].split(",");
        List<List<String>> combinedList = List.generate(
          initialParams.length,
          (index) {
            if(index == 4 || index == 5) return [initialNames[index], formatBytes(initialParams[index])];
            return [initialNames[index], initialParams[index]];
          },
        );
        drawerItemsState.setDeviceMetadata(combinedList);
        drawerItemsState.setFileSize(int.parse(initialParams[4]));
        fileSize = int.parse(initialParams[4]);
      } catch(e){
        print('Error al parsear tamaño del archivo: $e');
    }
      try {
        var listOfSensors = currentMessages[1].split(",");
        for (var sensor in listOfSensors) {
          var sensorAddress = sensor
              .split(":")
              .first;
          var sensorName = sensor
              .split(":")
              .last;
          drawerItemsState.setItemVisibility(sensorName, true);
          drawerItemsState.setItemAdress(sensorName, sensorAddress);
        }
      } catch(e){
        print('Error al parsear los sensores: $e');
      }

    } else if(lastMessageSended == "2"){
        saveListToCSV(currentMessages.sublist(1));
    } else if(lastMessageSended.toLowerCase() == "r"){
        drawerItemsState.setRealTimeRead(currentMessages.last);
    }
    else{
      print(currentMessages);
      Fluttertoast.showToast(
        msg: currentMessages.last,
        backgroundColor: Colors.white, // Color de fondo
        textColor: Colors.black, // Color del texto
        fontSize: 16.0, // Tamaño de la fuente
      );
    }
  }

  Future<void> saveListToCSV(List<String> messages) async {
    try {
      // Obtener el directorio de documentos del dispositivo
      final altDirectory = await getApplicationDocumentsDirectory();
      final directory = "/storage/emulated/0/Download";//await getDownloadsDirectory(); //getExternalStorageDirectory();//await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DOWNLOADS);//await getApplicationDocumentsDirectory();
      final path = directory ?? altDirectory.path;

      // Crear el archivo CSV
      DateFormat formatter = DateFormat('yyyy-MM-dd_HH_mm');
      DateTime now = DateTime.now();
      String formatedTime = formatter.format(now);
      File file = File('$path/Sensorlapp_record_$formatedTime.csv');

      List<List<dynamic>> csvData = [
        for (var message in messages) message.split(",")
      ];

      // Convertir los datos a formato CSV
      String csv = ListToCsvConverter().convert(csvData);


      var status = await permissions.Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        // If not we will ask for permission first
        Fluttertoast.showToast(msg: "Permisos de almacenamiento no entregados...");
        print("NO hay permisos garantizados para almacenamiento...");
        status = await permissions.Permission.manageExternalStorage.request();
        if(!status.isGranted){
          return;
        }
      }


      // Escribir los datos al archivo CSV
      await file.writeAsString(csv);
      LocalNotificationService.display(notificationId, "Toca para abrir", "Archivo CSV creado: Sensorlapp_record_$formatedTime.csv", '$path/Sensorlapp_record_$formatedTime.csv');
    } catch (e) {
      print('Error al guardar el archivo CSV: $e');
    }
  }
}