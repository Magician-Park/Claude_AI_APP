import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm_cargo/cargo_catalog.dart';
import 'package:farm_cargo/transport_request_screen.dart';

void main() {
  final catalog = CargoCatalog.fromJson(
      jsonDecode(File('assets/cargo_catalog.json').readAsStringSync()));

  test(
      'food suppliers, feed ingredients, milling byproducts and tobacco stay distinct',
      () {
    final feed =
        catalog.categories.firstWhere((item) => item.id == 'compound-feed');
    expect(feed.suppliers.map((item) => item.id),
        containsAll(['farmsco', 'sunjin-gunsan']));
    expect(
        feed.suppliers.any((item) =>
            ['spc', 'daesang-gunsan', 'samyang-asan'].contains(item.id)),
        isFalse);
    final ingredients =
        catalog.categories.firstWhere((item) => item.id == 'feed-ingredients');
    expect(ingredients.suppliers.single.id, 'daesang-gunsan');
    final milling =
        catalog.categories.firstWhere((item) => item.id == 'food-milling');
    final samyang =
        milling.suppliers.firstWhere((item) => item.id == 'samyang-asan');
    final spc = milling.suppliers.firstWhere((item) => item.id == 'spc');
    expect(spc.isRecipient, isTrue);
    expect(spc.groups.single.products.first.name, '밀가루');
    expect(samyang.name, '삼양사 아산공장');
    expect(
        samyang.groups
            .firstWhere((item) => item.id == 'wheat-bran')
            .products
            .single
            .name,
        contains('소맥피'));
    final raw =
        catalog.categories.firstWhere((item) => item.id == 'agricultural-raw');
    expect(raw.suppliers.single.groups.single.products.single.name, '국산 담뱃잎');
  });

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> choose<T>(WidgetTester tester, String text) async {
    final field = find.byType(DropdownButtonFormField<T>);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tapText(tester, text);
  }

  Future<void> fill(WidgetTester tester, String label, String text) async {
    final field = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == label);
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  Future<void> open(
      WidgetTester tester, ValueChanged<TransportRequest?> received) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        received(await Navigator.push<TransportRequest>(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    TransportRequestScreen(catalog: catalog))));
                      },
                      child: const Text('운송 요청 열기')),
                ))));
    await tapText(tester, '운송 요청 열기');
  }

  bool enabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '선택한 화물 확인'))
          .onPressed !=
      null;

  testWidgets('feed request retains selected factory, product and destination',
      (tester) async {
    TransportRequest? result;
    await open(tester, (value) => result = value);
    await tapText(tester, '배합사료');
    await tapText(tester, '팜스코');
    await choose<String>(tester, '정읍');
    await choose<CargoGroup>(tester, '양돈 사료');
    await choose<CargoProduct>(tester, '모돈용 배합사료');
    await fill(tester, '하차지', '전북 김제시 농장');
    await tapText(tester, '선택한 화물 확인');
    expect(
        find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining('팜스코 · 정읍')),
        findsOneWidget);
    await tapText(tester, '요청 내용 저장');
    expect(result?.category, '배합사료');
    expect(result?.product, '모돈용 배합사료');
    expect(result?.origin, '팜스코 · 정읍');
    expect(result?.destination, '전북 김제시 농장');
  });

  testWidgets('changing category clears a previous supplier and product',
      (tester) async {
    await open(tester, (_) {});
    await tapText(tester, '배합사료');
    await tapText(tester, '팜스코');
    await choose<String>(tester, '안성');
    await choose<CargoGroup>(tester, '양돈 사료');
    await choose<CargoProduct>(tester, '자돈용 배합사료');
    await fill(tester, '하차지', '도착 농장');
    expect(enabled(tester), isTrue);
    await tapText(tester, '원료·첨가제');
    expect(find.text('팜스코'), findsNothing);
    expect(enabled(tester), isFalse);
    await tapText(tester, '대상 군산공장');
    await choose<CargoGroup>(tester, '사료용 아미노산');
    await choose<CargoProduct>(tester, 'L-라이신 · 액상');
    expect(find.textContaining('액상 원료:'), findsOneWidget);
    expect(enabled(tester), isFalse);
    await fill(tester, '하차지', '원료 도착 공장');
    expect(enabled(tester), isTrue);
  });

  testWidgets(
      'domestic tobacco requires its own origin and remains agricultural cargo',
      (tester) async {
    TransportRequest? result;
    await open(tester, (value) => result = value);
    await tapText(tester, '농산 원물');
    await tapText(tester, '국산 담뱃잎');
    await fill(tester, '하차지', '담뱃잎 집하장');
    expect(enabled(tester), isFalse);
    await fill(tester, '출하자·상차지', '홍천 재배농가');
    await tapText(tester, '선택한 화물 확인');
    await tapText(tester, '요청 내용 저장');
    expect(result?.category, '농산 원물');
    expect(result?.product, '국산 담뱃잎');
    expect(result?.origin, contains('홍천 재배농가'));
  });

  testWidgets(
      'SPC ingredient deliveries retain true origin and require a custom ingredient name',
      (tester) async {
    TransportRequest? result;
    await open(tester, (value) => result = value);
    await tapText(tester, '식품 원료·제분 부산물');
    await tapText(tester, 'SPC');
    await choose<CargoProduct>(tester, '기타 제빵 원료 · 직접 입력');
    await fill(tester, '출하자·상차지', '제분공장 상차장');
    await fill(tester, '하차지', '원료 입고장');
    expect(enabled(tester), isFalse);
    await fill(tester, '실제 원료 품목', '제빵용 기타 원료');
    await tapText(tester, '선택한 화물 확인');
    await tapText(tester, '요청 내용 저장');
    expect(result?.product, '제빵용 기타 원료');
    expect(result?.supplier, 'SPC');
    expect(result?.origin, '제분공장 상차장');
    expect(result?.destination, 'SPC · 원료 입고장');
  });
}
