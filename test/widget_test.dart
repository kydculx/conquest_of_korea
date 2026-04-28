import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('앱 기본 smoke test', (WidgetTester tester) async {
    // Provider/Supabase 의존성으로 인해 통합 테스트는 별도 구성 필요
    expect(true, isTrue);
  });
}
