import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'BluetoothViewmodel.dart';
import 'Utils.dart';

class TerminalPage extends StatelessWidget {
  const TerminalPage({super.key});

  @override
  Widget build(BuildContext context) {
    BluetoothManager _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
    final _textinfield = TextEditingController();
    var newtext = "";
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal'),
      ),
        body:
        Center(
          child:
          Padding(
            padding: const EdgeInsets.all(32.0),
            child:
            Row(
              children: <Widget>[
              Expanded(
                child:
                TextField(
                  controller: _textinfield,
                  onChanged: (txt)=> newtext = txt,
                  decoration: InputDecoration(
                  hintText: 'Ingrese su mensaje...',
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
              ),],
            ),
          ),
        )
    );
  }
}

class TerminalCard extends StatelessWidget {
  const TerminalCard({super.key});

  @override
  Widget build(BuildContext context) {
    BluetoothManager _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
    final _textinfield = TextEditingController();
    var newtext = "";
    return
    Card(
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
                    "Terminal",
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
              Row(
                children: <Widget>[
                  Expanded(
                    child:
                    TextField(
                      controller: _textinfield,
                      onChanged: (txt)=> newtext = txt,
                      decoration: InputDecoration(
                        hintText: 'Ingrese su mensaje...',
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
                  ),],
              ),
            ]
        )
      ),
    );
  }
}