import 'package:flutter/material.dart';
import 'package:guess_who_creator/main.dart';
import 'package:guess_who_creator/utils/theme.dart';
import 'package:routemaster/routemaster.dart';

class NotFoundPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    return Scaffold(
      
      body: Container(
        color: themeProvider.isDarkMode
              ? darkTheme.primaryColor
              : lightTheme.primaryColor,
        child: Center(
          
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '404 - Page Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Routemaster.of(context).push('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
