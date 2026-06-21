import 'package:flutter_test/flutter_test.dart';
import 'package:officeflow/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const OfficeFlowApp());
    expect(find.byType(OfficeFlowApp), findsOneWidget);
  });
}
