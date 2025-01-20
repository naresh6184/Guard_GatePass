import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:guard_app/forgotpassword.dart';
import 'package:guard_app/home.dart';
import 'package:guard_app/signup.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Guard App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Set the initial route
      routes: {
        '/': (context) => const GuardLoginPage(),
        '/home': (context) => const HomePage(),
        '/signup':(context)=>const GuardSignupPage(),
        '/forgot':(context)=>const ForgotPasswordPage(),
      },
      navigatorObservers: [StackNavigatorObserver()], // Add observer
    );
  }
}

class StackNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];

  List<Route<dynamic>> get stack => List.unmodifiable(_stack);

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _stack.add(route);
    _logStack();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _stack.remove(route);
    _logStack();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) _stack.remove(oldRoute);
    if (newRoute != null) _stack.add(newRoute);
    _logStack();
  }

  void _logStack() {
    print('Current Stack:');
    for (var route in _stack) {
      print(' - ${route.settings.name ?? "Unnamed Route"}');
    }
  }
}
