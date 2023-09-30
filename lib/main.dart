import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportkit_statistik/Controller/buuttonStatus_provider.dart';
import 'package:sportkit_statistik/Controller/configuration_provider.dart';
import 'package:sportkit_statistik/Controller/token_provider.dart';
import 'package:sportkit_statistik/Models/data_inputConfiguration.dart';
import 'package:sportkit_statistik/Views/Screen/home.dart';
import 'package:sportkit_statistik/Views/Screen/kalkulator.dart';
import 'package:sportkit_statistik/Views/Screen/login.dart';
import 'package:sportkit_statistik/Views/Screen/subtitution.dart';

import 'Controller/matchData_provider.dart';
import 'Controller/subtitution_provider.dart';
import 'Controller/timer_provider.dart';
import 'Controller/user_provider.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserDataProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ConfigurationDataProvider(),
        ),
        ChangeNotifierProvider(
            create: (_) => ConfigurationModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => TokenProvider(),
        ),
        ChangeNotifierProvider(
            create: (context) => MatchDataProvider(),
        ),
        ChangeNotifierProvider(
            create: (context) => CountdownTimerProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => UserDataProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ButtonStatusModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => TerangGelapProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // return ChangeNotifierProvider(
    //   create: (context) => ButtonStatusModel(),
    //   child: MaterialApp(
    //     debugShowCheckedModeBanner: false,
    //     home: const MyHomePage(title: 'Flutter Demo Home Page'),
    //   ),
    // );
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
            child: Login(),
        ),
    );
  }
}
