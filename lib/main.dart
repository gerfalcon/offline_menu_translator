import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:offline_menu_translator/ui/translator_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register inference engines. flutter_gemma 1.x registers NO engine by
  // default, so this must run before any model is created. The LiteRT-LM
  // engine is required to run the Gemma 4 `.litertlm` model.
  await FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Menu Translator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const TranslatorScreen(),
    );
  }
}
