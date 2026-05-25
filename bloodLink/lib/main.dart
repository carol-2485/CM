// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/app_routes.dart';
import 'constants/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/aptidao_screen.dart';
import 'screens/questionario_screen.dart';
import 'screens/centros_screen.dart';
import 'screens/esclarecer_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDG-TzIHsqqFn0YgzdLKK3Y5y6luKLTJtM",
      authDomain: "bloodlink-v2-6b758.firebaseapp.com",
      projectId: "bloodlink-v2-6b758",
      storageBucket: "bloodlink-v2-6b758.firebasestorage.app",
      messagingSenderId: "81135854685",
      appId: "1:81135854685:web:3a353aa9b6a627ae0619b4",
      measurementId: "G-X5MSRRD6ZS",
    ),
  );

  await initializeDateFormatting('pt_PT', null);
  runApp(const BloodLinkApp());
}

class BloodLinkApp extends StatelessWidget {
  const BloodLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloodLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'PT'), Locale('en', 'US')],
      locale: const Locale('pt', 'PT'),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login:        (_) => const LoginScreen(),
        AppRoutes.register:     (_) => const RegisterScreen(),
        AppRoutes.home:         (_) => const HomeScreen(),
        AppRoutes.aptidao:      (_) => const AptidaoScreen(),
        AppRoutes.questionario: (_) => const QuestionarioScreen(),
        AppRoutes.centros:      (_) => const CentrosScreen(),
        AppRoutes.esclarecer:   (_) => const EsclarecerScreen(),
      },
    );
  }
}
