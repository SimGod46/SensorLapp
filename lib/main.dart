import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:sensor_lapp/BluetoothViewmodel.dart';
import 'package:sensor_lapp/CalibrationPage.dart';
import 'package:sensor_lapp/TerminalPage.dart';
import 'HomePage.dart';
import 'NotificationViewmodel.dart';
import 'Utils.dart';

final globalNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Datapp());
}

Future backgroundHandler(String msg) async {}

class Datapp extends StatefulWidget {
  const Datapp({Key? key}) : super(key: key);
  @override
  State<Datapp> createState() => _Datapp();
}

class _Datapp extends State<Datapp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
        navigatorKey: globalNavigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => HomePage(),
          '/calibration': (context) => CalibrationPage(),
          '/terminal': (context) => TerminalPage(),
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _executeOnClose();
    }
  }

  void _executeOnClose() {
    print('Executing function on app close or suspend');
    // Aquí puedes poner el código que deseas ejecutar al cerrar o suspender la aplicación.
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
        leading:
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: 12,
            height: 12,
            child: Image.asset('assets/logo_cmas.png'),
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.primaryColor),
      ),
      body:
    GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child:
        Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F5F7),
              ),
            ),
            body,  // Esto permite a cada pantalla especificar su propio contenido del body.
          ],
      )
    ),
    );
  }
}
