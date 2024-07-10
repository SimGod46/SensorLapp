import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'HomePage.dart';
import 'NotificationViewmodel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

String formatBytes(String bytesRaw, {int decimals = 2}) {
  int bytes = int.parse(bytesRaw);
  if (bytes <= 0) return "0 Bytes";
  const suffixes = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  int i = 0;
  double dbBytes = bytes.toDouble();

  while (dbBytes >= 1024) {
    dbBytes /= 1024;
    i++;
  }

  return "${dbBytes.toStringAsFixed(decimals)} ${suffixes[i]}";
}

class SensorsManager{
  getMessageFromBT(String lastMessageSended, List<String> currentMessages){
    DrawerItemsState drawerItemsState = DrawerItemsState();

    if(lastMessageSended == "1"){
      drawerItemsState.setItemVisibility("Terminal", true);
      try{
        List<String> initialNames = ['Versión Firmware', 'ID Dispositivo', 'Estado SD','Archivo', 'Espacio utilizado', 'Espacio total'];
        List<String> initialParams = currentMessages[0].split(", ");
        List<List<String>> combinedList = List.generate(
          initialParams.length,
          (index) {
            if(index == 4 || index == 5) return [initialNames[index], formatBytes(initialParams[index])];
            return [initialNames[index], initialParams[index]];
          },
        );
        drawerItemsState.setDeviceMetadata(combinedList);
        drawerItemsState.setFileSize(int.parse(initialParams[4]));
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
        }
      } catch(e){
        print('Error al parsear los senoses: $e');
      }
      // TODO: Configurar el tamaño del archivo
    }

    if(currentMessages.first!="OK"){
      return;
    }
    currentMessages = currentMessages.sublist(1);

    if(lastMessageSended == "2"){
      saveListToCSV(currentMessages);
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

      var status = await permissions.Permission.storage.status;
      if (!status.isGranted) {
        // If not we will ask for permission first
        status = await permissions.Permission.storage.request();
        if(!status.isGranted){
          return;
        }
      }

      // Escribir los datos al archivo CSV
      await file.writeAsString(csv);
      LocalNotificationService.display("Toca para abrir", "Archivo CSV creado: Sensorlapp_record_$formatedTime.csv", '$path/Sensorlapp_record_$formatedTime.csv');
    } catch (e) {
      print('Error al guardar el archivo CSV: $e');
    }
  }
}