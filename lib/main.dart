import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notificaciones_service.dart';
 
// ── Paleta global BarterApp Verde ─────────────────────────────────────────
class AppColors {
  static const fondo        = Color(0xFF0D1F0F);
  static const superficie   = Color(0xFF152318);
  static const superficieAlt= Color(0xFF1A2E1C);
  static const borde        = Color(0xFF1E3A20);
  static const bordeAlt     = Color(0xFF2A4A2C);
  static const acento       = Color(0xFF5DC44C);
  static const acentoClaro  = Color(0xFF7EE86A);
  static const textoP       = Color(0xFFE8F5E9);
  static const textoS       = Color(0xFF8AB88C);
  static const textoH       = Color(0xFF5A7A5C);
  static const appBar       = Color(0xFF0F1F10);
}
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificacionesService().inicializar();
  runApp(const MyApp());
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
 
    return MaterialApp(
      title: 'BarterApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary:    AppColors.acento,
          secondary:  AppColors.acentoClaro,
          surface:    AppColors.superficie,
          onPrimary:  AppColors.fondo,
          onSurface:  AppColors.textoP,
        ),
        scaffoldBackgroundColor: AppColors.fondo,
        useMaterial3: true,
        fontFamily: 'Nunito',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _SmoothPageTransition(),
            TargetPlatform.iOS:     _SmoothPageTransition(),
          },
        ),
      ),
      routes: {
        '/login':    (context) => LoginScreen(authService: authService),
        '/registro': (context) => RegistroScreen(authService: authService),
      },
      home: const AppRoot(),
    );
  }
}
 
class _SmoothPageTransition extends PageTransitionsBuilder {
  const _SmoothPageTransition();
 
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeAnim  = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final slideAnim = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
 
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(position: slideAnim, child: child),
    );
  }
}
 
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}
 
class _AppRootState extends State<AppRoot> {
  bool _mostrarSplash = true;
  final authService = AuthService();
 
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _mostrarSplash = false);
    });
  }
 
  @override
  Widget build(BuildContext context) {
    if (_mostrarSplash) return const SplashScreen();
 
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.fondo,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.acento),
            ),
          );
        }
        if (snapshot.hasData) return const FeedScreen();
        return LoginScreen(authService: authService);
      },
    );
  }
}
