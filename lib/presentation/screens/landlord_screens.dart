import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/community_models.dart';
import '../../state/auth_providers.dart';
import 'splash_screen.dart';

class LandlordSetupScreen extends ConsumerStatefulWidget {
  const LandlordSetupScreen({super.key});

  @override
  ConsumerState<LandlordSetupScreen> createState() =>
      _LandlordSetupScreenState();
}

class _LandlordSetupScreenState extends ConsumerState<LandlordSetupScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apartment = await ref
          .read(communityServiceProvider)
          .createApartment(name: name);
      if (!mounted) return;
      Navigator.of(context).pop(apartment);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not create the apartment. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.apartment_rounded, color: primaryGreen, size: 58),
            const SizedBox(height: 22),
            const Text(
              'Set up your apartment',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a community space, then invite and manage verified buyers and sellers.',
              style: TextStyle(color: Color(0xFF5C635E), height: 1.5),
            ),
            const SizedBox(height: 28),
            const Text(
              'Apartment or property name',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('landlordApartmentName'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Sunrise Apartments',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                key: const Key('createApartmentButton'),
                onPressed: _loading ? null : _create,
                style: FilledButton.styleFrom(backgroundColor: primaryGreen),
                child: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Apartment',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandlordPortfolioScreen extends ConsumerStatefulWidget {
  const LandlordPortfolioScreen({super.key});

  @override
  ConsumerState<LandlordPortfolioScreen> createState() =>
      _LandlordPortfolioScreenState();
}

class _LandlordPortfolioScreenState
    extends ConsumerState<LandlordPortfolioScreen> {
  late Future<List<Apartment>> _properties;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _properties = ref.read(communityServiceProvider).loadManagedApartments();
  }

  Future<void> _addProperty() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LandlordSetupScreen()),
    );
    if (!mounted) return;
    setState(_reload);
  }

  Future<void> _remove(Apartment apartment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove property?'),
        content: Text(
          '${apartment.name} and its invitation code will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(communityServiceProvider)
        .removeManagedApartment(apartment.id);
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'My Properties',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addPropertyButton'),
        onPressed: _addProperty,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Property'),
      ),
      body: FutureBuilder<List<Apartment>>(
        future: _properties,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: () => setState(_reload),
                child: const Text('Try Again'),
              ),
            );
          }
          final properties = snapshot.data ?? const [];
          if (properties.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      size: 64,
                      color: primaryGreen,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Add your first property',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Each property gets its own invitation code and community members.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _addProperty,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Property'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: properties.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final property = properties[index];
              return Card(
                color: Colors.white,
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE6F3EB),
                    child: Icon(Icons.apartment_rounded, color: primaryGreen),
                  ),
                  title: Text(
                    property.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('Invite code: ${property.invitationCode}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'remove') _remove(property);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'remove', child: Text('Remove')),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LandlordDashboardScreen(
                        apartmentId: property.id,
                        apartmentName: property.name,
                        invitationCode: property.invitationCode,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LandlordDashboardScreen extends ConsumerWidget {
  const LandlordDashboardScreen({
    super.key,
    required this.apartmentId,
    required this.apartmentName,
    required this.invitationCode,
  });

  final String apartmentId;
  final String apartmentName;
  final String invitationCode;

  String get _inviteLink =>
      'https://doorstep-market-736d0.web.app/join?code=$invitationCode';

  String get _shareText =>
      'Join $apartmentName on Doorstep Market with code '
      '$invitationCode: $_inviteLink';

  void _soon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature will be available soon.')));
  }

  Future<void> _share({String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        text: _shareText,
        subject: subject,
        title: 'Doorstep Market invitation',
      ),
    );
  }

  Future<void> _copy(
    BuildContext context,
    String value,
    String confirmation,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(confirmation)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: const Text(
          'Property Manager',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apartmentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'INVITATION CODE',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invitationCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy code',
                      onPressed: () => _copy(
                        context,
                        invitationCode,
                        'Invitation code copied.',
                      ),
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ManagerAction(
                  icon: Icons.qr_code_rounded,
                  label: 'Generate QR',
                  onTap: () => _soon(context, 'QR invitations'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ManagerAction(
                  icon: Icons.person_add_alt_rounded,
                  label: 'Approvals',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Residents who use the invitation code join automatically.',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ManagerAction(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  onTap: _share,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ManagerAction(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  onTap: () => _share(subject: 'Invitation to $apartmentName'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ManagerAction(
                  icon: Icons.link_rounded,
                  label: 'Copy Link',
                  onTap: () =>
                      _copy(context, _inviteLink, 'Invitation link copied.'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          StreamBuilder<List<ApartmentMember>>(
            stream: ref
                .read(communityServiceProvider)
                .watchApartmentMembers(apartmentId),
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: primaryGreen),
                  ),
                );
              }
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Could not load property members.'),
                );
              }
              final members = snapshot.data ?? const [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Members (${members.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (members.isEmpty)
                    const Card(
                      color: Colors.white,
                      elevation: 0,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.group_outlined, color: primaryGreen),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No members have joined this property yet.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (final member in members)
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE6F3EB),
                            child: Icon(
                              Icons.person_rounded,
                              color: primaryGreen,
                            ),
                          ),
                          title: Text(
                            member.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            member.email.isEmpty
                                ? member.role
                                : '${member.role} • ${member.email}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove member',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remove member?'),
                                  content: Text(
                                    '${member.displayName} will lose access to this property.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await ref
                                    .read(communityServiceProvider)
                                    .removeApartmentMember(
                                      apartmentId: apartmentId,
                                      memberId: member.id,
                                    );
                              }
                            },
                            icon: const Icon(
                              Icons.person_remove_outlined,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
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

class _ManagerAction extends StatelessWidget {
  const _ManagerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Column(
            children: [
              Icon(icon, color: primaryGreen, size: 27),
              const SizedBox(height: 7),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
