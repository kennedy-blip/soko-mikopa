import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage/ledger_store.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); await Hive.initFlutter(); await LedgerStore.instance.init(); runApp(const SokoMikopoApp()); }
class SokoMikopoApp extends StatefulWidget { const SokoMikopoApp({super.key}); @override State<SokoMikopoApp> createState()=>_AppState(); }
class _AppState extends State<SokoMikopoApp> { AppThemeMode mode=AppThemeMode.obsidian; @override Widget build(BuildContext context)=>MaterialApp(title:'SokoMikopo',debugShowCheckedModeBanner:false,theme:AppTheme.light(),darkTheme:AppTheme.dark(mode),themeMode:mode==AppThemeMode.daylight?ThemeMode.light:ThemeMode.dark,home:HomeScreen(mode:mode,onMode:(v)=>setState(()=>mode=v))); }
