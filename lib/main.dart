import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notificaciones_service.dart';
import '../main.dart';
 
// ── Paleta global BarterApp Verde Claro ───────────────────────────────────
class AppColors {
  static const fondo        = Color(0xFFEBE6D6);
  static const superficie   = Color(0xFFEBE6D6);
  static const superficieAlt= Color(0xFFEBE6D6);
  static const borde        = Color(0xFF2D5A27);
  static const bordeAlt     = Color(0xFF2D5A27);
  static const acento       = Color(0xFF2D5A27);
  static const acentoClaro  = Color(0xFF2D5A27);
  static const textoP       = Color(0xFF2D5A27);
  static const textoS       = Color(0xFF2D5A27);
  static const textoH       = Color(0xFF2D5A27);
  static const appBar       = Color(0xFFEBE6D6);
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
        colorScheme: ColorScheme.light(
          primary:    const Color(0xFF2D5A27),
          secondary:  const Color(0xFF2D5A27),
          surface:    const Color(0xFFEBE6D6),
          onPrimary:  const Color(0xFFEBE6D6),
          onSurface:  const Color(0xFF2D5A27),
        ),
        scaffoldBackgroundColor: const Color(0xFFEBE6D6),
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
            backgroundColor: Color(0xFFEBE6D6),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2D5A27)),
            ),
          );
        }
        if (snapshot.hasData) return const FeedScreen();
        return LoginScreen(authService: authService);
      },
    );
  }
}
