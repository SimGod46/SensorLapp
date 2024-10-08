import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';

import 'BluetoothViewmodel.dart';
import 'CalibrationPage.dart';
import 'HomePage.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF2C2C2C);
  static const Color secondaryColor = Color(0xFFE3E3E3);
  static const Color accentColor = Color(0xFF7C7C7C);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  //static const Color textColor = Color(0xFF2C2C2C);
}

class SensorCommand {
  final String comand;
  final String hint;
  final bool hasInput;
  final String? waitText;

  SensorCommand({
    required this.comand,
    required this.hint,
    this.hasInput = true,
    this.waitText = null,
  });
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
              child:
              widget.devicesNotifier.value.isNotEmpty ?
              SingleChildScrollView( child:
                ListBody(
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
              ) :
              Center(child: CircularProgressIndicator(color: AppColors.primaryColor,strokeWidth: 6.0,)),
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

class AlertPageCustom extends StatefulWidget {
  final bool enabledInput;
  final String hintText;
  final extController;

  AlertPageCustom({
    this.enabledInput = true,
    required this.hintText,
    required this.extController,
  });

  @override
  _AlertPageCustom createState() => _AlertPageCustom();
}

class _AlertPageCustom extends State<AlertPageCustom> {
  @override
  Widget build(BuildContext context) {
    return
      widget.enabledInput ?
      Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 0,horizontal: 16),child:
          Text("Ingrese el valor de la solución de calibración:"),
        ),
        SizedBox(height: 20,),
        Padding(padding: const EdgeInsets.symmetric(vertical: 0,horizontal: 16),
            child: TextField(
                controller: widget.extController,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                )
        ),
      ],
    ) :
    Center(
      child: Text("Calibre el dispositivo en el aire..."),
    );
  }
}

class MultiStepAlertDialog extends StatefulWidget {
  final List<SensorCommand> commands;
  final String measureUnit;
  final Function(BuildContext, String) onNextPage;

  MultiStepAlertDialog({
    required this.commands,
    required this.onNextPage,
    required this.measureUnit,
  });

  @override
  _MultiStepAlertDialogState createState() => _MultiStepAlertDialogState();
}

class _MultiStepAlertDialogState extends State<MultiStepAlertDialog> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  List<TextEditingController> _controllers = [];


  @override
  Widget build(BuildContext context) {
    BluetoothManager _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
    DrawerItemsState drawerItemsState = Provider.of<DrawerItemsState>(context);
    return
      GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child:
      AlertDialog(
      title: Text('Calibración'),
      content: Container(
        height: 250,
        width: double.maxFinite,
        child:
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            physics: NeverScrollableScrollPhysics(),
            children:[
              ...widget.commands.asMap().entries.expand((entry){
                int index = entry.key;
                String item = entry.value.hint;
                bool hasInput = entry.value.hasInput;
                String waitText = entry.value.waitText ?? "Sumerja el sensor dentro de la solución de ${_controllers[index].text} ${widget.measureUnit}, luego de que este estabilizado, presione siguiente.\n\nIMPORTANTE: Mantenga el sensor mientras presiona \"Siguiente\" ";
                return [
                  AlertPageCustom(hintText: item, extController: _controllers[index], enabledInput: hasInput,),
                  Column(
                    children: [
                      Text(
                        waitText,
                        //style: TextStyle(fontSize: 24),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 30),
                      Expanded(
                        child:
                        ReadBackground(
                          messageRecived: drawerItemsState.realTimeReading,
                          asyncTask: () {
                            _bluetoothManager.sendMessage("r", requiredEnd: true);
                          },
                        )
                      ),
                    ],
                  )
                ];
              }),
              Center(
                child: Text("Calibración completada"),
              )
            ],
        ),
      ),
      actions: <Widget>[
        if (_currentPage == 0)
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
        if (_currentPage > 0)
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              var navToPage = (_pageController.page! >= 2) ? _pageController.page!.toInt() - 2 : 0;
              _pageController.animateToPage(
                navToPage,
                duration: Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
            child: Text('Atrás'),
          ),
        if (_currentPage < widget.commands.length*2 )
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              if (_currentPage % 2 != 0) {
                var idxNum = _currentPage ~/ 2;
                widget.onNextPage(context,  widget.commands[idxNum].comand+_controllers[idxNum].text);
              }

              _pageController.nextPage(
                duration: Duration(milliseconds: 250),
                curve: Curves.ease,
              );
            },
            child: Text('Siguiente'),
          ),
        if (_currentPage == widget.commands.length*2)
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
            },
            child: Text('Aceptar'),
          ),
      ],
    ));
  }

  @override
  void initState() {
    super.initState();
    _controllers.addAll(widget.commands.map((item)=> TextEditingController()));
  }
}

class DialogHelper {
  static Future<void> baseDialog(BuildContext context, String titleText, List<Widget> body, VoidCallback onAccept) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titleText),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ...body,
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

  static void showMyDialog(BuildContext context, String titleText, String bodyText,VoidCallback onAccept){
    baseDialog(context, titleText, [
      Text(bodyText)
    ], onAccept);
  }
}

class BaseCard extends StatelessWidget {
  final String cardTitle;
  final IconData? cardIcon;
  final List<Widget> body;

  const BaseCard({
    required this.cardTitle,
    this.cardIcon,
    required this.body,
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
                  cardTitle,
                  style: TextStyle(
                    fontSize: 30,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                if(cardIcon != null) Icon(cardIcon, color: AppColors.primaryColor,),
              ],
            ),
            SizedBox(height: 15),
            ...body,
          ],
        ),
      ),
    );
  }
}

