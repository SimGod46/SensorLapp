import 'package:flutter/material.dart';

class TerminalPage extends StatelessWidget {
  const TerminalPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                print('Mensaje enviado!');
                },
              ),],
            ),
          ),
        )
    );
  }
}