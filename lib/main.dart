import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:sensor_lapp/BluetoothViewmodel.dart';
import 'HomePage.dart';
import 'NotificationViewmodel.dart';

void main() {
  runApp(Datapp());
}

Future backgroundHandler(String msg) async {}

class Datapp extends StatefulWidget {
  const Datapp({Key? key}) : super(key: key);
  @override
  State<Datapp> createState() => _Datapp();
}

class _Datapp extends State<Datapp> {
  @override
  void initState() {
    super.initState();
    // Initialise  localnotification
    LocalNotificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BluetoothManager(),
      child: MaterialApp(
        title: 'Datapp',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF005377), // Cambia el color del texto del botón
            ),
          ),
          radioTheme: RadioThemeData(
            fillColor: WidgetStateColor.resolveWith((states) => Color(0xFF005377)), // Cambia el color del radio button
          ),
        ),
        home: HomePage(),
      ),
    );
  }
}

class DevicesPopUp extends StatefulWidget {
  final ValueNotifier<List<BluetoothDiscoveryResult>> devicesNotifier;
  final VoidCallback onDismiss;
  final Function(BluetoothDiscoveryResult) onConfirmation;

  DevicesPopUp({
    required this.devicesNotifier,
    required this.onDismiss,
    required this.onConfirmation,
  });

  @override
  _DevicesPopUpState createState() => _DevicesPopUpState();
}

class _DevicesPopUpState extends State<DevicesPopUp> {
  BluetoothDiscoveryResult? deviceSelected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Dispositivos cercanos'),
      content:
    ValueListenableBuilder<List<BluetoothDiscoveryResult>>(
    valueListenable: widget.devicesNotifier,
    builder: (context, devicesList, child) {
      return Container(
        height: 300,
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: ListBody(
            children: widget.devicesNotifier.value.map((device) {
              return RadioListTile<BluetoothDiscoveryResult>(
                title: Text(device.device.name ?? 'Dispositivo sin nombre'),
                value: device,
                groupValue: deviceSelected,
                onChanged: (BluetoothDiscoveryResult? value) {
                  setState(() {
                    deviceSelected = value;
                  });
                },
              );
            }).toList(),
          ),
        ),
      );}),
      actions: [
        TextButton(
          onPressed: widget.onDismiss,
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: deviceSelected != null ? () => widget.onConfirmation(deviceSelected!) : null,
          child: Text('Aceptar'),
        ),
      ],
    );
  }
}
