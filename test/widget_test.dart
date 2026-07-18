// Widget tests for the Offline Menu Translator.
//
// The root app (`MyApp` -> `TranslatorScreen`) kicks off a multi-gigabyte
// model download in `initState`, which is not suitable for a widget test.
// Instead we test `ChatMessageWidget`, the pure presentation widget that
// renders chat bubbles, which has no side effects.

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:offline_menu_translator/ui/translator_screen.dart';

void main() {
  testWidgets('ChatMessageWidget renders the message text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMessageWidget(
            message: Message(text: 'Grilled salmon', isUser: false),
          ),
        ),
      ),
    );

    expect(find.byType(ChatMessageWidget), findsOneWidget);
    expect(find.textContaining('Grilled salmon'), findsOneWidget);
  });

  testWidgets('User and AI bubbles both render their text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ChatMessageWidget(
                message: Message(text: 'Translate this menu', isUser: true),
              ),
              ChatMessageWidget(
                message: Message(text: 'Here is the translation', isUser: false),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(ChatMessageWidget), findsNWidgets(2));
    expect(find.textContaining('Translate this menu'), findsOneWidget);
    expect(find.textContaining('Here is the translation'), findsOneWidget);
  });
}
