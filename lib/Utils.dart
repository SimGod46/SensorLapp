import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF2C2C2C);
  static const Color secondaryColor = Color(0xFFE3E3E3);
  static const Color accentColor = Color(0xFF7C7C7C);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  //static const Color textColor = Color(0xFF2C2C2C);
}

class ButtonCustom extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;
  final IconData? icon;
  final String text;
  final Color textColor;
  final bool enabled;
  final bool fillWidth;

  ButtonCustom({
    required this.onPressed,
    required this.color,
    this.icon,
    required this.text,
    this.textColor = Colors.white,
    this.enabled = true,
    this.fillWidth = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? color : AppColors.secondaryColor,
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8.0),
        splashColor: Colors.white.withAlpha(100),
        highlightColor: Colors.white.withAlpha(150),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisSize: fillWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if(icon!=null) Icon(icon, color: Colors.white),
              SizedBox(width: 8),
              Text(text, style: TextStyle(color: enabled ? textColor : Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class DevicesPopUp extends StatefulWidget {
  final ValueNotifier<List<BluetoothDiscoveryResult>> devicesNotifier;
  final VoidCallback onDismiss;
  final Function(String) onConfirmation;

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
          onPressed: deviceSelected != null ? () => widget.onConfirmation(deviceSelected!.device.address) : null,
          child: Text('Aceptar'),
        ),
      ],
    );
  }
}

class DialogHelper {
  static Future<void> showMyDialog(BuildContext context, String titleText, String bodyText, VoidCallback onAccept) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titleText),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(bodyText),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                onAccept();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class MyCustomCard extends StatelessWidget {
  final List<List<String>> deviceInfo;

  const MyCustomCard({
    required this.deviceInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4.0,
      margin: EdgeInsets.all(30.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                "Dispositivo",
                  style: TextStyle(
                    fontSize: 30,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Icon(Icons.info_outline, color: AppColors.primaryColor,),
              ],
            ),
            SizedBox(height: 15),
            Column(
              children: deviceInfo.map((List<String> items) => gridItem(items[0], items[1])).toList(),//List.generate(6, (index) => gridItem(index)),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ButtonCustom(onPressed: (){}, color: AppColors.primaryColor, text: "Descargar"),
                ButtonCustom(onPressed: (){}, color: AppColors.primaryColor, text: "Eliminar")
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: ButtonCustom(onPressed: (){}, color: AppColors.secondaryColor, text: "Desconectar", fillWidth: true, textColor: AppColors.primaryColor,)
            ),
          ],
        ),
      ),
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

class MyCustomCard2 extends StatelessWidget {
  const MyCustomCard2({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4.0,
      margin: EdgeInsets.all(30.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  "Sensores",
                  style: TextStyle(
                    fontSize: 30,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                //Spacer(),
                //Icon(Icons.info_outline, color: AppColors.primaryColor,),
              ],
            ),
            SizedBox(height: 15),
            Column(
              children:[
                Center(
                    child: ButtonCustom(onPressed: (){}, color: AppColors.secondaryColor, text: "PH", fillWidth: true, textColor: AppColors.primaryColor,)
                ),
                SizedBox(height: 20),
                Center(
                    child: ButtonCustom(onPressed: (){}, color: AppColors.secondaryColor, text: "EC", fillWidth: true, textColor: AppColors.primaryColor,)
                ),
                SizedBox(height: 20),
                Center(
                    child: ButtonCustom(onPressed: (){}, color: AppColors.secondaryColor, text: "ORP", fillWidth: true, textColor: AppColors.primaryColor,)
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}