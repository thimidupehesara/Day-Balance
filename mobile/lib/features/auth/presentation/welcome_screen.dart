import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../onboarding/presentation/setting_up_sky.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    backdrop: CustomPaint(
      painter: SettingUpSkyPainter(
        animation: const AlwaysStoppedAnimation(.12),
        horizon: 400,
        reduceMotion: false,
      ),
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewport.maxHeight - 64),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Day-Balance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      letterSpacing: 3,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 38),
                  Text(
                    'Make room\nfor your day.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.display.copyWith(
                      fontSize: 44,
                      height: 1.07,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Plan your hours. Do one thing at a time.\nLeave room for life.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body16,
                  ),
                  const SizedBox(height: 175),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: .35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A LITTLE BALANCE, EVERY DAY',
                          style: AppTextStyles.caption12.copyWith(
                            color: AppColors.setupAccent,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final item in [
                          ('Academic', '3 h', AppColors.academic),
                          ('Life/Family', '2 h', AppColors.lifeFamily),
                          ('Rest/Recovery', '1 h', AppColors.rest),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: item.$3,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.$1,
                                    style: AppTextStyles.caption12,
                                  ),
                                ),
                                Text(item.$2, style: AppTextStyles.caption12),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 32),
                  const Text(
                    'A little structure. A lot more breathing room.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption12,
                  ),
                  const SizedBox(height: 20),
                  AppPrimaryButton(
                    text: 'Get started',
                    onPressed: () => context.go('/register'),
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    text: 'Log in',
                    onPressed: () => context.go('/login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
