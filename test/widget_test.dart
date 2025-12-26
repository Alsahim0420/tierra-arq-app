// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:tierra_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Dashboard maqueta renderiza admin y maestro', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const TierraApp());

    expect(find.text('Control de obras'), findsOneWidget);
    expect(find.text('Proyectos activos'), findsOneWidget);
    expect(find.text('Tareas del proyecto'), findsOneWidget);

    await tester.tap(find.text('Maestro'));
    await tester.pumpAndSettle();

    expect(find.text('Registro de campo'), findsOneWidget);
    expect(find.text('Tareas asignadas'), findsOneWidget);
  });
}
