part of 'wallet_mode_screen.dart';

class _WalletTopBar extends StatelessWidget {
  const _WalletTopBar({
    required this.isMajor,
    required this.onLivenessTap,
    required this.onTransactionTap,
  });

  final bool isMajor;
  final VoidCallback onLivenessTap;
  final VoidCallback onTransactionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMajor ? 'Guardian Wallet' : 'Protected Wallet',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isMajor
                    ? 'Major mode with full access to payments, IDs, and cards.'
                    : 'Minor mode with supervised access and active limits.',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onLivenessTap,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.face_retouching_natural),
          label: const Text('Liveness'),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onTransactionTap,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
          ),
          icon: Icon(isMajor ? Icons.verified_user_rounded : Icons.payments_outlined),
          label: Text(isMajor ? 'Approvals' : 'Pay'),
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final WalletMode mode;
  final ValueChanged<WalletMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: 'Major',
              selected: mode == WalletMode.major,
              onTap: () => onChanged(WalletMode.major),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ToggleChip(
              label: 'Minor',
              selected: mode == WalletMode.minor,
              onTap: () => onChanged(WalletMode.minor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF365DF0) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class MajorWalletView extends StatelessWidget {
  const MajorWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('major-wallet'),
      children: const [
        _WalletHeroCard(
          title: 'Full Wallet Access',
          subtitle: 'Payments, identity, travel, and complete wallet controls.',
          accent: Color(0xFF365DF0),
          amount: 'Rs. 24,500',
          chipLabel: 'MAJOR',
        ),
        SizedBox(height: 16),
        _StatsStrip(
          items: [
            _StatData('Cards', '04'),
            _StatData('IDs', '05'),
            _StatData('Rewards', '2.3k'),
          ],
        ),
        SizedBox(height: 16),
        _QuickActionGrid(
          title: 'Quick actions',
          actions: [
            _QuickActionData('Pay', Icons.payments_outlined),
            _QuickActionData('Scan', Icons.qr_code_scanner_rounded),
            _QuickActionData('Cards', Icons.credit_card_rounded),
            _QuickActionData('Travel', Icons.train_outlined),
          ],
        ),
        SizedBox(height: 16),
        _InfoBanner(
          title: 'Guardian sync active',
          subtitle: 'Identity vault and spending controls were synced 2 minutes ago.',
          icon: Icons.sync_rounded,
        ),
        SizedBox(height: 16),
        _SectionCard(
          title: 'Government IDs',
          subtitle:
              'Aadhaar, Student ID, Health card, and Driving license ready to view',
          icon: Icons.badge_outlined,
        ),
        SizedBox(height: 12),
        _SectionCard(
          title: 'Wallet cards',
          subtitle:
              'Debit card, campus card, metro pass, and emergency contact card',
          icon: Icons.wallet_outlined,
        ),
        SizedBox(height: 12),
        _SectionCard(
          title: 'Recent activity',
          subtitle: '3 payments cleared and 1 identity check completed today',
          icon: Icons.insights_outlined,
        ),
      ],
    );
  }
}

class MinorWalletView extends StatelessWidget {
  const MinorWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('minor-wallet'),
      children: const [
        _WalletHeroCard(
          title: 'Restricted Wallet',
          subtitle:
              'Safe spending mode with guardian approval and category limits.',
          accent: Color(0xFF7D5CFF),
          amount: 'Rs. 1,200',
          chipLabel: 'MINOR',
        ),
        SizedBox(height: 16),
        _RestrictionPanel(),
        SizedBox(height: 16),
        _QuickActionGrid(
          title: 'Allowed actions',
          actions: [
            _QuickActionData('School', Icons.school_outlined),
            _QuickActionData('Bus Pass', Icons.directions_bus_outlined),
            _QuickActionData('Allowance', Icons.savings_outlined),
            _QuickActionData('Help', Icons.support_agent_rounded),
          ],
        ),
        SizedBox(height: 16),
        _SectionCard(
          title: 'Restrictions active',
          subtitle:
              'Online purchases blocked, ATM cash blocked, guardian alerts always on',
          icon: Icons.lock_outline_rounded,
        ),
        SizedBox(height: 12),
        _SectionCard(
          title: 'Allowed categories',
          subtitle:
              'Food, transport, books, school supplies, and approved subscriptions',
          icon: Icons.verified_user_outlined,
        ),
        SizedBox(height: 12),
        _SectionCard(
          title: 'Guardian notice',
          subtitle: 'Every purchase above Rs. 500 needs approval before payment',
          icon: Icons.notifications_active_outlined,
        ),
      ],
    );
  }
}

class _WalletHeroCard extends StatelessWidget {
  const _WalletHeroCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.amount,
    required this.chipLabel,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final String amount;
  final String chipLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chipLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available balance',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.nfc_rounded, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.items});

  final List<_StatData> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: item == items.last ? 0 : 12),
                child: _GlassSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RestrictionPanel extends StatelessWidget {
  const _RestrictionPanel();

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.gpp_good_outlined, color: Color(0xFFB8A8FF)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Protected rules are active',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _RestrictionItem(
            label: 'Daily spend limit',
            value: 'Rs. 1,500',
          ),
          SizedBox(height: 10),
          _RestrictionItem(
            label: 'Location check',
            value: 'School and home zones allowed',
          ),
          SizedBox(height: 10),
          _RestrictionItem(
            label: 'Approval rule',
            value: 'Guardian approval above Rs. 500',
          ),
        ],
      ),
    );
  }
}

class _RestrictionItem extends StatelessWidget {
  const _RestrictionItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF10233F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.title, required this.actions});

  final String title;
  final List<_QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return Column(
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(action.icon),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.label,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  const _GlassSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value);

  final String label;
  final String value;
}

class _QuickActionData {
  const _QuickActionData(this.label, this.icon);

  final String label;
  final IconData icon;
}
