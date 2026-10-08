import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/owner_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders checks card and sitters when logged out',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OwnerHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.text('0 of 3 checks done'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('Michael Tau'), findsOneWidget);
    expect(find.text('Jessica Daniels'), findsOneWidget);

    await tester.tap(find.text('Complete your profile'));
    await tester.pumpAndSettle();
    expect(find.text('Incomplete'), findsNWidgets(3));

    await tester.tap(find.text('Home Address / Proof of Residence'));
    await tester.pumpAndSettle();
    expect(find.text('Home Address Verification'), findsOneWidget);

    await tester.tap(find.text('Save & Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Home Address Verification'), findsNothing);
    expect(find.text('Please log in to save your address.'), findsOneWidget);
  });
}
