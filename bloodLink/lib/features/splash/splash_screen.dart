// lib/features/splash/splash_screen.dart
// Ecrã de apresentação (splash screen) da aplicação BloodLink.
// Exibe o logótipo, o nome da aplicação e um indicador de carregamento
// durante 3 segundos antes de redirecionar para o ecrã de login.
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../common/widgets/blood_drop.dart';

// Ecrã inicial da aplicação exibido no arranque.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Aguarda 4 segundos e redireciona para o ecrã de login
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutesUser.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logótipo da aplicação
            BloodDrop(size: 120),
            const SizedBox(height: 24),
            // Nome da aplicação
            const Text(
              'BloodLink',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            const SizedBox(height: 24),
            // Indicador de carregamento
            const CircularProgressIndicator(
              color: Color(0xFF5C1A1A),
            ),
          ],
        ),
      ),
    );
  }
}