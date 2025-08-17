import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../analytics/analytics_service.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  List<Map<String, String>> familyMembers = [
    {'name': 'Mom', 'device_id': '123'},
    {'name': 'Dad', 'device_id': '456'},
  ];

  @override
  void initState() {
    super.initState();
    // Track family screen view
    AnalyticsService.logEvent('family_list_viewed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: familyMembers.isEmpty
          ? _buildEmptyState()
          : _buildFamilyList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInviteDialog,
        tooltip: 'Invite Family Member',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No family members yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to invite family members',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: familyMembers.length,
      itemBuilder: (context, index) {
        final member = familyMembers[index];
        return _buildFamilyMemberCard(member, index);
      },
    );
  }

  Widget _buildFamilyMemberCard(Map<String, String> member, int index) {
    final name = member['name'] ?? 'Unknown';
    final deviceId = member['device_id'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          radius: 24,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Device: ${deviceId.length > 8 ? '${deviceId.substring(0, 8)}...' : deviceId}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Member options',
          onSelected: (String value) => _handleMenuAction(value, member),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, size: 20),
                title: Text('Edit Name'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.delete, size: 20, color: Colors.red),
                title: Text('Remove', style: TextStyle(color: Colors.red)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Map<String, String> member) {
    switch (action) {
      case 'edit':
        _editMemberName(member);
        break;
      case 'remove':
        _showRemoveConfirmation(member);
        break;
    }
  }

  void _editMemberName(Map<String, String> member) {
    final TextEditingController controller = TextEditingController(
      text: member['name'],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Member Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter member name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != member['name']) {
                  setState(() {
                    member['name'] = newName;
                  });
                  AnalyticsService.logEvent('family_member_renamed', {
                    'new_name_length': newName.length,
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Name updated to $newName'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name cannot be empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveConfirmation(Map<String, String> member) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Family Member'),
          content: Text(
            'Are you sure you want to remove ${member['name']} from your family?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _removeMember(member);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _removeMember(Map<String, String> member) {
    setState(() {
      familyMembers.remove(member);
    });
    
    AnalyticsService.logFamilyMemberRemoved();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member['name']} has been removed'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              familyMembers.add(member);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${member['name']} has been restored'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invite Family Member'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose how you\'d like to invite a family member:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '• QR Code: Show a QR code to scan\n'
                '• Share Link: Send an invitation link\n'
                '• Both: Generate both options',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _generateQRCode();
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('QR Code'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _shareInviteLink();
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Link'),
            ),
          ],
        );
      },
    );
  }

  void _generateQRCode() {
    // TODO: Implement QR code generation
    AnalyticsService.logEvent('family_invite_created', {'method': 'qr_code'});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code generation coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareInviteLink() {
    // TODO: Implement link sharing
    AnalyticsService.logEvent('family_invite_created', {'method': 'link'});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link sharing coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}