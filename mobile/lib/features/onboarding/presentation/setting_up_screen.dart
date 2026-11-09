import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import 'onboarding_controller.dart';
import 'setting_up_constants.dart';
import 'setting_up_sky.dart';

/// The approved sunrise-to-moonset introduction, concurrent with the real save.
class SettingUpScreen extends ConsumerStatefulWidget {
  const SettingUpScreen({super.key});

  @override
  ConsumerState<SettingUpScreen> createState() => _SettingUpScreenState();
}

class _SettingUpScreenState extends ConsumerState<SettingUpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sequence;
  bool _saved = false;
  bool _reduceMotion = false;
  String? _error;
  int _attempt = 0;
  int _phase = 0;

  bool get _ready => _saved && (_reduceMotion || _sequence.isCompleted);

  @override
  void initState() {
    super.initState();
    _sequence = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startFlow();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wasReduced = _reduceMotion;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) _sequence.stop();
    if (wasReduced &&
        !_reduceMotion &&
        _attempt > 0 &&
        !_sequence.isCompleted &&
        _error == null) {
      _sequence.forward();
    }
  }

  void _onTick() {
    final phase = math.min(3, (_sequence.value * 4).floor());
    if (phase != _phase || _sequence.isCompleted) {
      setState(() => _phase = phase);
    }
  }

  Future<void> _startFlow() async {
    final attempt = ++_attempt;
    setState(() {
      _saved = false;
      _error = null;
      _phase = 0;
    });
    _sequence.reset();
    if (!_reduceMotion) _sequence.forward();
    final ok = await ref
        .read(onboardingControllerProvider.notifier)
        .completeFullOnboarding();
    if (!mounted || attempt != _attempt) return;
    setState(() {
      _saved = ok;
      if (!ok) {
        _error =
            ref.read(onboardingControllerProvider).errorMessage ??
            SettingUpTexts.errorMessage;
        _sequence.stop();
      }
    });
  }

  @override
  void dispose() {
    _sequence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _error != null) context.go('/onboarding/categories');
        },
        child: Scaffold(
          backgroundColor: AppColors.setupBackground,
          body: LayoutBuilder(
            builder: (context, viewport) {
              final top = MediaQuery.paddingOf(context).top;
              final skyHeight = (viewport.maxHeight * .50).clamp(280.0, 405.0);
              return Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: SettingUpSkyPainter(
                          animation: _sequence,
                          horizon: skyHeight,
                          reduceMotion: _reduceMotion,
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
                            child: Column(
                              children: [
                                Text(
                                  'DAY—BALANCE',
                                  style: AppTextStyles.body14.copyWith(
                                    color: AppColors.setupForeground,
                                    letterSpacing: 4,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'A LITTLE SPACE FOR YOU',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption12.copyWith(
                                    color: AppColors.setupAccent,
                                    letterSpacing: 2,
                                  ),
                                ),
                                SizedBox(
                                  height: math.max(110, skyHeight - top - 100),
                                ),
                                if (_error != null)
                                  _errorView()
                                else
                                  _content(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content() {
    final phase = SettingUpTexts.chapters[_phase];
    final status = _ready
        ? 'Your Day-Balance is ready'
        : _sequence.isCompleted
        ? 'Saving your preferences…'
        : phase.status;
    return Semantics(
      label: _ready
          ? 'Your Day-Balance is ready.'
          : 'Setting up your day. Please wait.',
      container: true,
      child: Column(
        children: [
          // Normal flow, never positioned: large text can grow without overlap.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 208),
            child: AnimatedBuilder(
              animation: _sequence,
              builder: (context, child) {
                final local = _sequence.value == 1
                    ? 1.0
                    : (_sequence.value * 4) % 1;
                final fadeIn = _phase == 0
                    ? 1.0
                    : (local / .12).clamp(0.0, 1.0);
                final fadeOut = _phase == 3
                    ? 1.0
                    : ((1 - local) / .12).clamp(0.0, 1.0);
                final opacity = _reduceMotion
                    ? 1.0
                    : Curves.easeInOut.transform(math.min(fadeIn, fadeOut));
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, (1 - opacity) * 6),
                    child: child,
                  ),
                );
              },
              child: Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    Text(
                      phase.eyebrow,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption12.copyWith(
                        color: AppColors.setupAccent,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      phase.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.setupHeading,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      phase.body,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body14.copyWith(
                        color: AppColors.setupSecondary,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(
                _ready ? Icons.check_circle_outline : Icons.timelapse_rounded,
                size: 16,
                color: AppColors.setupAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status,
                  style: AppTextStyles.caption12.copyWith(
                    color: AppColors.setupSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '0${_phase + 1} / 04',
                style: AppTextStyles.caption12.copyWith(
                  color: AppColors.setupMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          AnimatedBuilder(
            animation: _sequence,
            builder: (context, _) => LinearProgressIndicator(
              // The introductory sequence is not a measurement of network work.
              semanticsLabel: _ready ? 'Setup complete' : 'Preparing your day',
              value: _ready
                  ? 1
                  : _reduceMotion
                  ? 0
                  : _sequence.value * .95,
              minHeight: 3,
              borderRadius: BorderRadius.circular(5),
              color: AppColors.setupAccent,
              backgroundColor: AppColors.setupForeground.withValues(alpha: .10),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A little structure. A lot more breathing room.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption12.copyWith(
              color: AppColors.setupMuted,
            ),
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: _ready ? 'Step into my day' : 'Your day is taking shape…',
            onPressed: _ready ? () => context.go('/home') : null,
            backgroundColor: AppColors.setupButton,
            foregroundColor: AppColors.setupButtonText,
            disabledBackgroundColor: AppColors.setupForeground.withValues(
              alpha: .05,
            ),
            disabledForegroundColor: AppColors.setupMuted,
          ),
        ],
      ),
    );
  }

  Widget _errorView() => Semantics(
    liveRegion: true,
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: AppColors.setupAccent,
          size: 36,
        ),
        const SizedBox(height: 20),
        Text(
          SettingUpTexts.errorTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.setupHeading,
        ),
        const SizedBox(height: 16),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: AppTextStyles.body14.copyWith(color: AppColors.setupSecondary),
        ),
        const SizedBox(height: 12),
        Text(
          'Your chosen schedule and categories are safe.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body14.copyWith(color: AppColors.setupSecondary),
        ),
        const SizedBox(height: 32),
        AppPrimaryButton(
          label: SettingUpTexts.tryAgainButton,
          onPressed: _startFlow,
          backgroundColor: AppColors.setupButton,
          foregroundColor: AppColors.setupButtonText,
        ),
        const SizedBox(height: 12),
        AppSecondaryButton(
          label: SettingUpTexts.backButton,
          foregroundColor: AppColors.setupForeground,
          onPressed: () => context.go('/onboarding/categories'),
        ),
      ],
    ),
  );
}
