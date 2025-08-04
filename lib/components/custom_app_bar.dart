import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? style;
  final double elevation;

  CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.style,
    this.elevation = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: _setTextStyle(style),textAlign: TextAlign.left,),
      actions: actions,
      leading: leading,
      foregroundColor: _setForegroundColor(foregroundColor),
      backgroundColor: _setBackgroundColor(backgroundColor),
      elevation: elevation,
      automaticallyImplyLeading: false,
    );
  }

  Color _setBackgroundColor(Color? color) {
    if (color != null) {
      return color;
    } else {
      return const Color.fromARGB(255, 250, 121, 0);
    }
  }

  Color _setForegroundColor(Color? color) {
    if (color != null) {
      return color;
    } else {
      return const Color.fromARGB(255, 252, 252, 252);
    }
  }
   
  TextStyle _setTextStyle(TextStyle? style) {
    if (style != null) {
      return style;
    } else {
      return TextStyle(
        color: Color.fromARGB(255, 252, 252, 252),
        fontWeight: FontWeight.bold,
      );
    }
  } 

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}