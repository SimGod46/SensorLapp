import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'BluetoothViewmodel.dart';
import 'HomePage.dart';
import 'SensorsViewmodel.dart';
import 'Utils.dart';

class TerminalPage extends StatelessWidget {
  const TerminalPage({super.key});

  @override
  Widget build(BuildContext context) {
    print(ModalRoute.of(context)!.settings.name);
    DrawerItemsState drawerItemsState = Provider.of<DrawerItemsState>(context);
    BluetoothManager _bluetoothManager = Provider.of<BluetoothManager>(context, listen: true);
    final _textinfield = TextEditingController();
    var newtext = "";
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal'),
      ),
        body:
        GestureDetector(
        onTap: () {
        FocusScope.of(context).unfocus();
        },
        child:
        PopScope(
            canPop: true,
            onPopInvoked: (bool didPop) async{
              drawerItemsState.isOnTerminal = false;
              _bluetoothManager.sendMessage("0");
            },
            child:
            Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: drawerItemsState.terminalMessages.length,
                itemBuilder: (context, index) {
                  final textColor = drawerItemsState.terminalMessages[index].fromName == "Remote" ? Colors.black : Colors.grey;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Row(
                      children: [
                        Text(
                          drawerItemsState.terminalMessages[index].timeStamp,
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child:
                          Text(drawerItemsState.terminalMessages[index].message,
                              style: TextStyle(color: textColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
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
                      _bluetoothManager.sendMessage(newtext, requiredEnd: true);
                    },
                  ),],
              ),
            ),
          ],
        ))
      )
    );
  }
}