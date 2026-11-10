import 'package:day_balance/core/theme/app_theme.dart';
import 'package:day_balance/features/auth/domain/user_model.dart';
import 'package:day_balance/features/auth/presentation/auth_controller.dart';
import 'package:day_balance/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SignedInAuth extends AuthController {
  @override
  AuthState build() => const AuthState(
    user: UserModel(
      id: 'profile-test',
      email: 'maya@example.com',
      displayName: 'Maya Chen',
      wakeTime: '22:00:00',
      bedtime: '06:00:00',
      routineMinutes: 90,
    ),
  );
}

void main() {
  testWidgets(
    'renders an overnight schedule and toggles alerts on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith(_SignedInAuth.new)],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const ProfileScreen(),
          ),
        ),
      );
      expect(find.text('Maya Chen'), findsOneWidget);
      expect(find.textContaining('8h awake'), findsOneWidget);
      final toggle = find.byType(SwitchListTile);
      await tester.scrollUntilVisible(toggle, 180);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      final control = find.byType(Switch);
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
