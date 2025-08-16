import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/family_provider.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  final TextEditingController _memberNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load family data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyProvider.notifier).loadFamily();
    });
  }

  @override
  void dispose() {
    _memberNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final familyState = ref.watch(familyProvider);
    final isInFamily = ref.watch(isInFamilyProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Sharing'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.family_restroom,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Family Sharing',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share PetitPal with family members to sync settings and provider access. Create an invite to get started.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (familyState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (familyState.error != null)
              _buildErrorCard(familyState.error!)
            else if (!isInFamily)
              _buildCreateFamilyCard()
            else
              _buildFamilyMembersCard(),
            
            const SizedBox(height: 24),
            
            // How it works
            _buildHowItWorksCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Error',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ref.read(familyProvider.notifier).clearError();
              ref.read(familyProvider.notifier).loadFamily();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateFamilyCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Family Group',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Start sharing PetitPal with your family members. Enter a name for the person you want to invite:',
              style: theme.textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _memberNameController,
              decoration: const InputDecoration(
                labelText: 'Family Member Name',
                hintText: 'e.g., Mom, Dad, Sarah',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _createInvite(),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _memberNameController.text.trim().isNotEmpty
                    ? _createInvite
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Create Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMembersCard() {
    final theme = Theme.of(context);
    final familyMembers = ref.watch(familyMembersProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Family Members',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: _showCreateInviteDialog,
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Invite Family Member',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (familyMembers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.family_restroom,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No family members yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...familyMembers.map((member) => _buildMemberTile(member)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(FamilyMember member) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary,
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(member.name),
      subtitle: Text('Joined ${_formatDate(member.joinedAt)}'),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(
            onPressed: () => _removeMember(member),
            child: const Row(
              children: [
                Icon(Icons.remove_circle_outline),
                SizedBox(width: 8),
                Text('Remove'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Family Sharing Works',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildHowItWorksStep(
              '1.',
              'Create an invite for a family member',
              Icons.person_add,
            ),
            
            _buildHowItWorksStep(
              '2.',
              'Share the QR code or link with them',
              Icons.qr_code,
            ),
            
            _buildHowItWorksStep(
              '3.',
              'They scan or tap to join automatically',
              Icons.smartphone,
            ),
            
            _buildHowItWorksStep(
              '4.',
              'Settings and access are shared securely',
              Icons.security,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksStep(String number, String description, IconData icon) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Icon(
            icon,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _createInvite() async {
    final memberName = _memberNameController.text.trim();
    if (memberName.isEmpty) return;
    
    final token = await ref.read(familyProvider.notifier).createInvite(memberName);
    
    if (token != null && mounted) {
      _memberNameController.clear();
      _showInviteCreatedDialog(token, memberName);
    }
  }

  void _showCreateInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Family Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _memberNameController,
              decoration: const InputDecoration(
                labelText: 'Family Member Name',
                hintText: 'e.g., Mom, Dad, Sarah',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createInvite();
            },
            child: const Text('Create Invite'),
          ),
        ],
      ),
    );
  }

  void _showInviteCreatedDialog(String token, String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Invite created for $memberName'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // QR Code placeholder
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: const Center(
                      child: Text(
                        'QR Code\n(Generated)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'petitpal://invite/$token',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement sharing
              Navigator.pop(context);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _removeMember(FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Family Member'),
        content: Text('Are you sure you want to remove ${member.name} from your family group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(familyProvider.notifier).removeMember(member.deviceId);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}