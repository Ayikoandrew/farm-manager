import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../providers/auth_providers.dart';

/// A GenUI component for creating invite codes via the AI assistant
class GenUiInviteCodeForm extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialData;

  const GenUiInviteCodeForm({super.key, required this.initialData});

  @override
  ConsumerState<GenUiInviteCodeForm> createState() =>
      _GenUiInviteCodeFormState();
}

class _GenUiInviteCodeFormState extends ConsumerState<GenUiInviteCodeForm> {
  late UserRole _selectedRole;
  late int _maxUses;
  late int _validityDays;
  final _emailController = TextEditingController();
  bool _isCreating = false;
  bool _isCreated = false;
  String? _generatedCode;
  String? _errorText;
  String? _inviteeEmail;

  @override
  void initState() {
    super.initState();

    // Parse role from initial data
    final roleStr = widget.initialData['role'] as String?;
    _selectedRole = _parseRole(roleStr);

    // Parse max uses (default: 1)
    _maxUses = widget.initialData['maxUses'] as int? ?? 1;

    // Parse validity days (default: 7)
    _validityDays = widget.initialData['validityDays'] as int? ?? 7;

    // Parse email if provided
    final email = widget.initialData['email'] as String?;
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  UserRole _parseRole(String? roleStr) {
    if (roleStr == null) return UserRole.worker;
    switch (roleStr.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      case 'vet':
      case 'veterinarian':
        return UserRole.vet;
      case 'worker':
      default:
        return UserRole.worker;
    }
  }

  Future<void> _createInviteCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorText =
            'Please enter the email address of the person you want to invite';
      });
      return;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorText = 'Please enter a valid email address';
      });
      return;
    }

    final farmId = ref.read(activeFarmIdProvider);
    if (farmId == null) {
      setState(() {
        _errorText = 'No farm selected';
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _errorText = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final code = await authNotifier.generateInviteCode(
        farmId,
        _selectedRole,
        email: email,
        maxUses: _maxUses,
        validity: Duration(days: _validityDays),
      );

      if (code != null) {
        if (mounted) {
          setState(() {
            _generatedCode = code;
            _inviteeEmail = email;
            _isCreated = true;
            _isCreating = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorText =
                'Failed to create invite code. Make sure you have permission.';
            _isCreating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Error: $e';
          _isCreating = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    if (_generatedCode != null) {
      Clipboard.setData(ClipboardData(text: _generatedCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite code copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isCreated && _generatedCode != null) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 40),
              const SizedBox(height: 8),
              Text(
                'Invite Code Created!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _generatedCode!,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyToClipboard,
                      tooltip: 'Copy to clipboard',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'For: ${_inviteeEmail ?? "Unknown"}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Role: ${InviteCode.getRoleDisplayName(_selectedRole)}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'Valid for $_validityDays days • ${_maxUses == 1 ? "Single use" : "$_maxUses uses"}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share this code with the person you want to invite.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 450),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_add,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create Invite Code',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    hintText: 'person@example.com',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                // Role selection
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [Text(InviteCode.getRoleDisplayName(role))],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Role description
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    InviteCode.getRoleDescription(_selectedRole),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 12),

                // Max uses and validity in a row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _maxUses,
                        decoration: const InputDecoration(
                          labelText: 'Max Uses',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [1, 5, 10, 25, 50].map((uses) {
                          return DropdownMenuItem(
                            value: uses,
                            child: Text(uses == 1 ? '1 use' : '$uses uses'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _maxUses = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _validityDays,
                        decoration: const InputDecoration(
                          labelText: 'Valid For',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [1, 3, 7, 14, 30].map((days) {
                          return DropdownMenuItem(
                            value: days,
                            child: Text(days == 1 ? '1 day' : '$days days'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _validityDays = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Create button
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createInviteCode,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.vpn_key, size: 18),
                  label: Text(
                    _isCreating ? 'Creating...' : 'Generate Invite Code',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
