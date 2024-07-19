import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:sensor_lapp/BluetoothViewmodel.dart';
import 'HomePage.dart';
import 'NotificationViewmodel.dart';
import 'Utils.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BluetoothManager()),
        ChangeNotifierProvider(create: (context) => DrawerItemsState()),
      ],
      child: MaterialApp(
        title: 'Datapp',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF2C2C2C), // Cambia el color del texto del botón
            ),
          ),
          radioTheme: RadioThemeData(
            fillColor: WidgetStateColor.resolveWith((states) => Color(0xFF2C2C2C)), // Cambia el color del radio button
          ),
        ),
        home: HomePage(),
      ),
    );
  }

  @override
  void dispose() {
    print("Se cerró la app");
  }
}

class CustomScaffold extends StatelessWidget {
  final Widget body;

  CustomScaffold({required this.body,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: AppColors.primaryColor),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Image.asset('assets/logo_cmas.png'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F5F7),
            ),
          ),
          body,  // Esto permite a cada pantalla especificar su propio contenido del body.
        ],
      ),
    );
  }
}
