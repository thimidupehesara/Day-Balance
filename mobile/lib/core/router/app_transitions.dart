import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';

/// Smooth, non-abrupt page transitions for Day-Balance.
///
/// Forward navigation: gentle horizontal shared-axis (slide + fade), ~300ms ease-out.
/// Back navigation: reverse of horizontal shared-axis.
/// Auth <-> Onboarding / Home boundaries: gentle fade-through.
class AppTransitions {
  AppTransitions._();

  static const Duration duration = Duration(milliseconds: 300);

  /// Horizontal shared-axis transition page for hierarchical navigation within a flow.
  static CustomTransitionPage<T> sharedAxis<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final curvedSecondary = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SharedAxisTransition(
          animation: curvedAnimation,
          secondaryAnimation: curvedSecondary,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    );
  }

  /// Fade-through transition page for major mode changes (e.g. Auth to Onboarding or Home).
  static CustomTransitionPage<T> fadeThrough<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
    );
  }

  /// Modal slide-up transition page for modals and edit sheets.
  static CustomTransitionPage<T> modal<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }
}

