import 'package:flutter/material.dart';
enum AppThemeMode { obsidian, daylight, field }
class AppTheme {
 static const mint=Color(0xFF29D6A0);
 static ThemeData dark(AppThemeMode mode){final accent=mode==AppThemeMode.field?const Color(0xFFFFD34E):mint;return ThemeData(useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:mode==AppThemeMode.field?const Color(0xFF050505):const Color(0xFF101820),colorScheme:ColorScheme.fromSeed(seedColor:accent,brightness:Brightness.dark),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white.withValues(alpha:.06),border:OutlineInputBorder(borderRadius:BorderRadius.circular(13))));}
 static ThemeData light()=>ThemeData(useMaterial3:true,brightness:Brightness.light,scaffoldBackgroundColor:const Color(0xFFF1F5F2),colorScheme:ColorScheme.fromSeed(seedColor:mint),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(13))));
}
