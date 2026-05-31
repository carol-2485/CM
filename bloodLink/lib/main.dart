// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/screens/centro/centro_home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/app_routes.dart';
import 'constants/app_theme.dart';
import 'screens/user/login_screen.dart';
import 'screens/user/register_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/user/aptidao_screen.dart';
import 'screens/user/questionario_screen.dart';
import 'screens/user/centros_screen.dart';
import 'screens/user/esclarecer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID']!,
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
      initialRoute: AppRoutesUser.login,
      routes: {
        AppRoutesUser.login: (_) => const LoginScreen(),
        AppRoutesUser.register: (_) => const RegisterScreen(),
        AppRoutesUser.home: (_) => const HomeScreen(),
        AppRoutesUser.aptidao: (_) => const AptidaoScreen(),
        AppRoutesUser.questionario: (_) => const QuestionarioScreen(),
        AppRoutesUser.centros: (_) => const CentrosScreen(),
        AppRoutesUser.esclarecer: (_) => const EsclarecerScreen(),
        AppRoutesCentro.home: (context) => const CentroHomeScreen(),
      },
    );
  }
}
