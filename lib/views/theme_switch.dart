import 'package:flutter/material.dart';

class ThemeSwitch extends StatefulWidget {

  final bool value;
  final ValueChanged<bool> onChanged;

  const ThemeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<StatefulWidget> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<ThemeSwitch> {
  

  static const WidgetStateProperty<Icon> thumbIcon =
      WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
        WidgetState.selected: Icon(Icons.nightlight_sharp),
        WidgetState.any: Icon(Icons.sunny),
      });
    
  final WidgetStateProperty<Color?> trackColor =
        WidgetStateProperty<Color?>.fromMap(<WidgetStatesConstraint, Color>{
          WidgetState.selected: Colors.deepPurple.shade300,
          WidgetState.any: Colors.blue.shade50
        });
  
    

  @override
  Widget build(BuildContext context) {
    return Switch(
      thumbIcon: thumbIcon,
      trackColor: trackColor,
      value: widget.value,
      onChanged: widget.onChanged
    );
  }
}
