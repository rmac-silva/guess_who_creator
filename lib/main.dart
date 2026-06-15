import 'package:flutter/material.dart';
import 'package:guess_who_creator/utils/theme.dart';
import 'package:guess_who_creator/views/game_view.dart';
import 'package:guess_who_creator/views/homepage.dart';
import 'package:guess_who_creator/views/new_game_page.dart';
import 'package:guess_who_creator/views/success_view.dart';
import 'package:routemaster/routemaster.dart';

final routes = RouteMap(
  routes: {
    '/': (_) => const Redirect("/home"),
    '/home': (_) => MaterialPage(child: GuessWhoHomepage()),
    '/new_game': (_) => MaterialPage(child: NewGamePage()),

    '/new_game/success': (routeData) => MaterialPage(
      child: SuccessView(
        title: routeData.queryParameters['title'] ?? 'Game Created!',
        message: routeData.queryParameters['message'] ?? 'Success',
        gameId: routeData.queryParameters['id'] ?? '',
      ),
    ),
    
    '/game/:id': (gameData) => MaterialPage(
        child: GameView(
          gameID: gameData.pathParameters['id'] ?? '',
        ),
      )
    
    //Todo - Game editing
  }
);

void main() {
  runApp(const MyAppRoot());
}

class MyAppRoot extends StatefulWidget {
  const MyAppRoot({super.key});

  @override
  State<MyAppRoot> createState() => _MyAppRootState();
}

class _MyAppRootState extends State<MyAppRoot> {
  bool isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HypothesizeTheIndividual',
      theme: isDarkMode ? darkTheme : lightTheme,
      debugShowCheckedModeBanner: false,
      routerDelegate: RoutemasterDelegate(
        routesBuilder: (context) => routes,
      ),
      routeInformationParser: const RoutemasterParser(),
      // We pass a way for child screens to change the theme
      builder: (context, child) {
        return ThemeProvider(
          isDarkMode: isDarkMode,
          onThemeChanged: (value) => setState(() => isDarkMode = value),
          child: child!,
        );
      },
    );
  }
}

//Useful to propagate information down the tree
//Can be accessed with ClassName.of(buildContext)
//Similar to react, when you envelop the components in your AuthManager or Router
class ThemeProvider extends InheritedWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const ThemeProvider({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required super.child,
  });

  static ThemeProvider of(context) => context.dependOnInheritedWidgetOfExactType<ThemeProvider>()!;

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) => isDarkMode != oldWidget.isDarkMode;
}