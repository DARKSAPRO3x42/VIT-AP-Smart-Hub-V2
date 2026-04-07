import 'package:flutter/material.dart';

class UpdateDialog extends StatelessWidget {
  final bool isForceUpdate;
  final String? version;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const UpdateDialog({
    super.key,
    required this.isForceUpdate,
    this.version,
    required this.onUpdate,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isForceUpdate,
      child: AlertDialog(
        title: Text(isForceUpdate ? 'Update Required' : 'Update Available'),
        content: Text(
          isForceUpdate
              ? 'A new required version of the app${version != null ? ' ($version)' : ''} is available. Please update to continue using the app.'
              : 'A new version of the app${version != null ? ' ($version)' : ''} is available. Would you like to update now?',
        ),
        actions: [
          if (!isForceUpdate)
            TextButton(
              onPressed: onLater ?? () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          ElevatedButton(onPressed: onUpdate, child: const Text('Update')),
        ],
      ),
    );
  }
}
