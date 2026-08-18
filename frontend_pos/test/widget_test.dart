import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_pos/widgets/zenvi_logo_widgets.dart';

void main() {
  testWidgets('ZenviLogo renders correctly in solid and iconOnly variants', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ZenviLogo(size: 120, variant: ZenviLogoVariant.solid),
              ZenviLogo(size: 80, variant: ZenviLogoVariant.iconOnly),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(ZenviLogo), findsNWidgets(2));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('ZenviNotificationIcon displays badge count when count > 0', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ZenviNotificationIcon(notificationCount: 5),
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);
  });
}
