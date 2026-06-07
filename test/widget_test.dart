import 'package:flutter_test/flutter_test.dart';

import 'package:jerseyapp/main.dart';
import 'package:jerseyapp/widgets/initials_avatar.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const JerseyDripApp());

    expect(find.text('Jersey Drip'), findsOneWidget);
  });

  test('initials are generated from profile names', () {
    expect(initialsFromName('Anik'), 'A');
    expect(initialsFromName('Anik Rahman'), 'AR');
    expect(initialsFromName('John Doe'), 'JD');
    expect(initialsFromName(null), 'U');
    expect(initialsFromName('   '), 'U');
  });
}
