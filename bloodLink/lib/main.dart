// lib/main.dart
//
// Ponto de entrada da aplicação BloodLink.
// Inicializa o Firebase, as variáveis de ambiente e as localizações pt_PT.
// Define o router com todas as rotas da aplicação (utilizador e centro).

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/features/aptidao/aptidao_screen.dart';
import 'package:flutter_application_1/features/chat_user/chat_lista_user_screen.dart';
import 'package:flutter_application_1/features/notificacoes/notificacoes_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/app_routes.dart';
import 'constants/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/schedule/questionario_screen.dart';
import 'features/schedule/centros_screen.dart';
import 'features/schedule/agenda_screen.dart';
import 'features/schedule/confirmar_screen.dart';
import 'features/esclarecer/esclarecer_screen.dart';
import 'features/painel/painel_screen.dart';
import 'features/perfil/perfil_screen.dart';
import 'features/centro/centro_home_screen.dart';
import 'features/centro/centro_perfil_screen.dart';
import 'features/centro/gerir_vagas_screen.dart';
import 'features/centro/pedidos_screen.dart';
import 'features/historico/historico_doacoes_screen.dart';

/// Ponto de entrada da aplicação.
/// Inicializa todos os serviços externos antes de arrancar a UI.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega variáveis de ambiente (chaves de API, configuração Firebase)
  await dotenv.load(fileName: '.env');

  // Inicializa o Firebase com a configuração do ficheiro .env
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

  // Inicializa dados de formatação de datas em português de Portugal
  await initializeDateFormatting('pt_PT', null);

  runApp(const BloodLinkApp());
}

/// Widget raiz da aplicação BloodLink.
///
/// Configura o tema, localização pt_PT e todas as rotas nomeadas.
class BloodLinkApp extends StatelessWidget {
  const BloodLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloodLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,

      // Localização em português de Portugal
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'PT'),
        Locale('en', 'US'),
      ],
      locale: const Locale('pt', 'PT'),

      // Rota inicial — ecrã de login
      initialRoute: AppRoutesUser.login,

      routes: {
        // ── Sessão do utilizador doador ──────────────────────────────────────
        AppRoutesUser.login:        (_) => const LoginScreen(),
        AppRoutesUser.register:     (_) => const RegisterScreen(),
        AppRoutesUser.home:         (_) => const HomeScreen(),
        AppRoutesUser.aptidao:      (_) => const AptidaoScreen(),
        AppRoutesUser.questionario: (_) => const QuestionarioScreen(),
        AppRoutesUser.centros:      (_) => const CentrosScreen(),
        AppRoutesUser.agenda:       (_) => const AgendaScreen(),
        AppRoutesUser.confirmar:    (_) => const ConfirmarScreen(),
        AppRoutesUser.esclarecer:   (_) => const EsclarecerScreen(),
        AppRoutesUser.painel:       (_) => const PainelScreen(),
        AppRoutesUser.perfil:       (_) => const PerfilScreen(),
        AppRoutesUser.chats:        (_) => const ChatListaUserScreen(),
        AppRoutesUser.notificacoes: (_) => const NotificacoesScreen(),
        AppRoutesUser.historico:    (_) => const HistoricoDoacoesScreen(),

        // ── Sessão do centro de saúde ────────────────────────────────────────
        AppRoutesCentro.home:       (_) => const CentroHomeScreen(),
        AppRoutesCentro.perfil:     (_) => const CentroPerfilScreen(),
        AppRoutesCentro.gerirVagas: (_) => const GerirVagasScreen(),
        AppRoutesCentro.pedidos:    (_) => const PedidosScreen(),
      },
    );
  }
}
