import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm_cargo/main.dart';
import 'package:farm_cargo/order.dart';

void main() {
  for (final order in sampleOrders) {
    testWidgets('${order.category}: detail and acceptance return to lobby',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const FarmCargoApp());
      expect(find.text('추천 맞춤 오더'), findsOneWidget);
      await tester.ensureVisible(find.text(order.origin));
      await tester.tap(find.text(order.origin));
      await tester.pumpAndSettle();
      expect(find.text('오더 상세'), findsOneWidget);
      expect(find.text(order.destination), findsOneWidget);
      expect(find.textContaining('퇴비 이력이 기록됩니다.'),
          order.isCompost ? findsOneWidget : findsNothing);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text('추천 맞춤 오더'), findsOneWidget);
      expect(find.text('오더 상세'), findsNothing);
    });
  }

  testWidgets('detail back button returns to lobby', (tester) async {
    await tester.pumpWidget(const FarmCargoApp());
    await tester.tap(find.text(sampleOrders.first.origin));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('추천 맞춤 오더'), findsOneWidget);
    expect(find.text('오더 상세'), findsNothing);
  });
}
