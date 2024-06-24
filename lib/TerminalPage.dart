import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'BluetoothViewmodel.dart';

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