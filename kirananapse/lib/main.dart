import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/theme.dart';
import 'app/router.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/store_provider.dart';
import 'core/providers/recommendation_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for kirana owner usage
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KiranaNapseApp());
}

class KiranaNapseApp extends StatelessWidget {
  const KiranaNapseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, StoreProvider>(
          create: (_) => StoreProvider(),
          update: (_, auth, store) => store!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RecommendationProvider>(
          create: (_) => RecommendationProvider(),
          update: (_, auth, rec) => rec!..updateAuth(auth),
        ),
      ],
      child: MaterialApp.router(
        title: 'Kirana-Napse',
        debugShowCheckedModeBanner: false,
        theme: KiranaNapseTheme.lightTheme,
        darkTheme: KiranaNapseTheme.lightTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),

    );
  }
}
