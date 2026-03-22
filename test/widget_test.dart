import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigs_mobile/main.dart';

void main() {
  testWidgets('App starts and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SigsApp()));
    expect(find.text('SIGS'), findsOneWidget);
  });
}
