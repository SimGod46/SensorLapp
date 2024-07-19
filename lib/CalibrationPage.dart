import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensor_lapp/HomePage.dart';
import 'package:sensor_lapp/Utils.dart';
import 'package:sensor_lapp/main.dart';

import 'BluetoothViewmodel.dart';

class CalibrationPage extends StatefulWidget {
  final String sensorType;

  const CalibrationPage({
    required this.sensorType,
  });
  @override
  _CalibrationPage createState() => _CalibrationPage();
}

class _CalibrationPage extends State<CalibrationPage> {
  @override
  Widget build(BuildContext context) {
    var drawerItemsState = Provider.of<DrawerItemsState>(context);
    BluetoothManager _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
    String? initMenuCode = drawerItemsState.itemsAdress[widget.sensorType];
    if (initMenuCode!= null) _bluetoothManager.sendMessage(initMenuCode);
    return CustomScaffold(
        body: Center(
      child: SensorCalibrationCard(sensorSelected: widget.sensorType),
    ));
  }
}

class SensorCalibrationCard extends StatelessWidget {
  final String sensorSelected;

  const SensorCalibrationCard({
    required this.sensorSelected,
  });

  void _SendCalibration(BuildContext context, String sensorMessage){
    BluetoothManager _bluetoothManager = Provider.of<BluetoothManager>(context, listen: false);
    _bluetoothManager.sendMessage(sensorMessage);
  }

  @override
  Widget build(BuildContext context) {
    BluetoothManager _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
    final _textinfield = TextEditingController();
    var newtext = "";

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      BaseCard(cardTitle: sensorSelected, body: [
        if (sensorSelected == "PH") ...[
          ButtonCustom(
            onPressed: () {_bluetoothManager.sendMessage("Cal,clear");},
            color: AppColors.secondaryColor,
            text: "Limpiar calibración",
            fillWidth: true,
            textColor: AppColors.primaryColor,
          ),
          SizedBox(height: 20),
          ButtonCustom(
            onPressed: () {
              DialogHelper.showMyInputDialog(
                context,
                "Ingrese valor",
                "Valor del punto medio para pH",
                () {},
              );
            },
            color: AppColors.secondaryColor,
            text: "Único punto",
            fillWidth: true,
            textColor: AppColors.primaryColor,
          ),
          SizedBox(height: 20),
          ButtonCustom(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => MultiStepAlertDialog(
                    hintTexts: ["Punto medio pH","Punto inferior pH", "Punto superior pH"],
                    onNextPage: _SendCalibration),
              );
            },
            color: AppColors.secondaryColor,
            text: "Tres puntos",
            fillWidth: true,
            textColor: AppColors.primaryColor,
          ),
          SizedBox(height: 20),
          ButtonCustom(
            onPressed: () {
              _bluetoothManager.sendMessage("9");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
            color: AppColors.primaryColor,
            text: "Atrás",
            fillWidth: true,
            textColor: AppColors.secondaryColor,
          )
        ],
        if (sensorSelected == "EC") ...[
          ButtonCustom(
            onPressed: () {_bluetoothManager.sendMessage("Cal,clear");},
            color: AppColors.secondaryColor,
            text: "Limpiar calibración",
            fillWidth: true,
            textColor: AppColors.primaryColor,
          ),
          SizedBox(height: 20),
          ButtonCustom(
            onPressed: () {
              DialogHelper.showMyInputDialog(
                context,
                "Ingrese valor",
                "Valor del punto seco para EC",
                () {},
              );
            },
            color: AppColors.secondaryColor,
            text: "Punto seco",
            fillWidth: true,
            textColor: AppColors.primaryColor,
          ),
          SizedBox(height: 20),
          ButtonCustom(
            onPressed: () {
              DialogHelper.showMyInputDialog(
                context,
                "Ingrese valor",
                "Valor de punto único para EC",
                () {},
              );
            },
            color: AppColors.secondaryColor,
            text: "Punto único",
            fillWidth: true,
            textColor: AppColors.primaryColor,
          ),
          SizedBox(height: 20),
          ButtonCustom(
            onPressed: () {
              DialogHelper.showMyInputDialog(
                context,
                "Ingrese valor",
                "Valor del punto superior para EC",
                () {},
              );
            },
            color: AppColors.secondaryColor,
            text: "Punto superior",
            fillWidth: true,
            textColor: AppColors.primaryColor,
          ),
          SizedBox(height: 20),
          ButtonCustom(
            onPressed: () {
              DialogHelper.showMyInputDialog(
                context,
                "Ingrese valor",
                "Valor del punto inferior para EC",
                () {},
              );
            },
            color: AppColors.secondaryColor,
            text: "Punto inferior",
            fillWidth: true,
            textColor: AppColors.primaryColor,
          ),
          SizedBox(height: 20),
          ButtonCustom(
            onPressed: () {
              _bluetoothManager.sendMessage("9");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
            color: AppColors.primaryColor,
            text: "Atrás",
            fillWidth: true,
            textColor: AppColors.secondaryColor,
          )
        ],
      ]),
      SizedBox(height: 30),
      BaseCard(
        cardTitle: "Terminal",
        body: [
          Row(children: <Widget>[
            Expanded(
              child: TextField(
                controller: _textinfield,
                onChanged: (txt) => newtext = txt,
                decoration: InputDecoration(
                  hintText: 'Ingrese comando...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 8.0), // Espacio entre el TextField y el IconButton
            IconButton(
              icon: Icon(Icons.send), // Icono de avión de papel
              onPressed: () {
                // Acción al presionar el botón (enviar mensaje, por ejemplo)
                _textinfield.clear();
                _bluetoothManager.sendMessage(newtext);
              },
            ),
          ]),
          SizedBox(height: 20),
          /*
          ButtonCustom(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
            color: AppColors.primaryColor,
            text: "Atrás",
            fillWidth: true,
            textColor: AppColors.secondaryColor,
          )
           */
        ],
      )
    ]);
  }
}
