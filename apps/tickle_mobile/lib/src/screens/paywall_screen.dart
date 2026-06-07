import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/premium_cubit.dart';
import '../utils/haptic_feedback.dart';

/// Full-screen Tickle Pro paywall. Tickle Pro is a one-time lifetime unlock.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const _gradient = LinearGradient(
    colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PaywallScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<PremiumCubit, PremiumState>(
      listenWhen: (prev, curr) =>
          prev.isPro != curr.isPro || prev.error != curr.error,
      listener: (context, state) {
        if (state.isPro) {
          HapticsHelper.trigger('heavy');
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome to Tickle Pro! 🎉')),
          );
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
          context.read<PremiumCubit>().clearError();
        }
      },
      builder: (context, state) {
        final isLoading = state.isLoading;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      _buildHeader(theme),
                      const SizedBox(height: 32),
                      _buildFeatures(theme),
                      const SizedBox(height: 28),
                      _buildPriceCard(theme, state.priceString),
                      const SizedBox(height: 24),
                      _buildCta(context, isLoading, state.priceString),
                      const SizedBox(height: 12),
                      _buildRestore(context, isLoading),
                      const SizedBox(height: 16),
                      _buildFinePrint(theme),
                    ],
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: MediaQuery.of(context).padding.top + 4,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE94057).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.star_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 20),
        Text(
          'Tickle Pro',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unlock everything, forever.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(ThemeData theme) {
    const features = [
      (
        Icons.cloud_done_rounded,
        'Cloud Sync',
        'Back up and sync your counters across devices.',
      ),
      (
        Icons.widgets_rounded,
        'Home Screen Widgets',
        'Track and tap your top counters without opening the app.',
      ),
      (
        Icons.notifications_active_rounded,
        'Reminders',
        'Get nudged so you never miss a count.',
      ),
    ];

    return Column(
      children: [
        for (final (icon, title, subtitle) in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _FeatureRow(icon: icon, title: title, subtitle: subtitle),
          ),
      ],
    );
  }

  Widget _buildPriceCard(ThemeData theme, String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE94057), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lifetime Access',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'One-time payment · no subscription',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              foreground: Paint()
                ..shader = _gradient.createShader(
                  const Rect.fromLTWH(0, 0, 120, 40),
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context, bool isLoading, String price) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE94057).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                HapticsHelper.selectionClick('medium');
                context.read<PremiumCubit>().purchasePro();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                'Unlock Tickle Pro — $price',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildRestore(BuildContext context, bool isLoading) {
    return TextButton(
      onPressed: isLoading
          ? null
          : () {
              HapticsHelper.selectionClick('light');
              context.read<PremiumCubit>().restorePurchases();
            },
      child: const Text('Restore Purchases'),
    );
  }

  Widget _buildFinePrint(ThemeData theme) {
    return Text(
      'A one-time payment unlocks Tickle Pro forever on this account. '
      'Payment is charged to your App Store / Google Play account.',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 11,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE94057).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFE94057), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
