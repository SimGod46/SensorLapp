import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensor_lapp/HomePage.dart';
import 'package:sensor_lapp/TerminalPage.dart';
import 'package:sensor_lapp/Utils.dart';
import 'package:sensor_lapp/main.dart';
import 'dart:async';

import 'BluetoothViewmodel.dart';
import 'SensorsViewmodel.dart';

class CalibrationPage extends StatefulWidget {
  final String sensorType;

  const CalibrationPage({
    required this.sensorType,
  });
  @override
  _CalibrationPage createState() => _CalibrationPage();
}

class _CalibrationPage extends State<CalibrationPage> {
  void _SendCalibration(BuildContext context, String sensorMessage){
    BluetoothManager _bluetoothManager = Provider.of<BluetoothManager>(context, listen: false);
    _bluetoothManager.sendMessage(sensorMessage, requiredEnd: true);
  }

  @override
  Widget build(BuildContext context) {
    BluetoothManager _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
    DrawerItemsState drawerItemsState = Provider.of<DrawerItemsState>(context);
    final _textinfield = TextEditingController();
    var newtext = "";
    //drawerItemsState.setCurrentPage("CalibrationPage");

    return CustomScaffold(
        body: SingleChildScrollView(
          child: Center(
            child:
            PopScope(
                canPop: true,
                onPopInvoked: (bool didPop) async{
                  _bluetoothManager.sendMessage("0");
                },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  BaseCard(cardTitle: widget.sensorType, body: [
                    if (widget.sensorType == "PH") ...[
                      ButtonCustom(
                        onPressed: () {_bluetoothManager.sendMessage("Cal,clear", requiredEnd: true);},
                        color: AppColors.secondaryColor,
                        text: "Limpiar calibración",
                        fillWidth: true,
                        textColor: AppColors.primaryColor,
                      ),
                      SizedBox(height: 20),
                      ButtonCustom(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => MultiStepAlertDialog(
                                measureUnit: "pH",
                                commands: [
                                  SensorCommand(comand: "Cal,mid,", hint: "Punto medio pH")],
                                onNextPage: _SendCalibration),
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
                            barrierDismissible: false,
                            builder: (context) => MultiStepAlertDialog(
                              measureUnit: "pH",
                              commands: [
                                SensorCommand(comand: "Cal,mid,", hint: "Punto medio pH"),
                                SensorCommand(comand: "Cal,low,", hint: "Punto inferior pH"),
                                SensorCommand(comand: "Cal,high,", hint: "Punto superior pH")],
                              onNextPage: _SendCalibration,),
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
                          drawerItemsState.clearTerminal();
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => TerminalPage()));
                          },
                        color: AppColors.secondaryColor,
                        text: "Terminal",
                        fillWidth: true,
                        textColor: AppColors.primaryColor,
                      ),
                      SizedBox(height: 20,),
                      ButtonCustom(
                        onPressed: () {
                          _bluetoothManager.sendMessage("0", requiredEnd: true);
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
                    if (widget.sensorType == "EC") ...[
                      ButtonCustom(
                        onPressed: () {_bluetoothManager.sendMessage("Cal,clear", requiredEnd: true);},
                        color: AppColors.secondaryColor,
                        text: "Limpiar calibración",
                        fillWidth: true,
                        textColor: AppColors.primaryColor,
                      ),
                      SizedBox(height: 20),
                      ButtonCustom(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => MultiStepAlertDialog(
                                measureUnit: "μS/cm",
                                commands: [
                                  SensorCommand(comand: "Cal,dry", hint: "Punto seco EC", hasInput: false, waitText: "Con el sensor seco, espere 10 segundos y luego presione siguiente."),
                                  SensorCommand(comand: "Cal,", hint: "Punto n EC")],
                                onNextPage: _SendCalibration),
                          );
                        },
                        color: AppColors.secondaryColor,
                        text: "Dos puntos",
                        fillWidth: true,
                        textColor: AppColors.primaryColor,
                      ),
                      SizedBox(height: 20),
                      ButtonCustom(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => MultiStepAlertDialog(
                                measureUnit: "μS/cm",
                                commands: [
                                  SensorCommand(comand: "Cal,dry", hint: "Punto seco EC", hasInput: false),
                                  SensorCommand(comand: "Cal,low,", hint: "Punto inferior EC"),
                                  SensorCommand(comand: "Cal,high,", hint: "Punto superior EC")],
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
                          drawerItemsState.clearTerminal();
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => TerminalPage()));
                        },
                        color: AppColors.secondaryColor,
                        text: "Terminal",
                        fillWidth: true,
                        textColor: AppColors.primaryColor,
                      ),
                      SizedBox(height: 20),
                      ButtonCustom(
                        onPressed: () {
                          _bluetoothManager.sendMessage("0", requiredEnd: true);
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
                  BaseCard(cardTitle: "Lectura",
                      body:
                      [
                        SizedBox(height: 15),
                        ReadBackground(
                          messageRecived: drawerItemsState.realTimeReading,
                          asyncTask: () {
                            _bluetoothManager.sendMessage("r", requiredEnd: true);
                          },
                        ),
                        SizedBox(height: 15),
                      ]
                  )
                ])
            ),
          ),
        ));
  }
}

class ReadBackground extends StatefulWidget {
  final String messageRecived;
  final VoidCallback asyncTask;

  const ReadBackground({
    Key? key,
    required this.messageRecived,
    required this.asyncTask,
  }): super(key: key);

  @override
  _ReadBackground createState() => _ReadBackground();
}

class _ReadBackground extends State<ReadBackground> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else if (state == AppLifecycleState.paused) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      widget.asyncTask();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return
      Center(child:
        Text(widget.messageRecived,
          style: TextStyle(
            fontSize: 25,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.normal,),
        ),
      );
  }
}