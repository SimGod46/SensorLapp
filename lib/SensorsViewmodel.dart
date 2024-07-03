import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'HomePage.dart';
import 'NotificationViewmodel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;


class SensorsManager{
  getMessageFromBT(String lastMessageSended, List<String> currentMessages){
    DrawerItemsState drawerItemsState = DrawerItemsState();

    if(lastMessageSended == "1"){
      drawerItemsState.setItemVisibility("Terminal", true);

      var listOfSensors = currentMessages.first.split(",");
      for(var sensor in listOfSensors){
        var sensorAddress = sensor.split(":").first;
        var sensorName = sensor.split(":").last;
        drawerItemsState.setItemVisibility(sensorName, true);
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