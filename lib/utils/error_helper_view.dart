import 'package:flutter/material.dart';

class ErrorBanner {
  static OverlayEntry? _currentEntry;

  static void show(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    // If a banner is already showing, remove it immediately
    _currentEntry?.remove();

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10, // Just below status bar
        left: 20,
        right: 20,
        child: _ErrorBannerWidget(
          message: message,
          onDismissed: () {
            _currentEntry?.remove();
            _currentEntry = null;
          },
        ),
      ),
    );

    // Insert the banner into the overlay (top-most layer)
    Overlay.of(context).insert(_currentEntry!);

    Future.delayed(duration, () {
      if (_currentEntry != null) {
        _currentEntry?.remove();
        _currentEntry = null;
      }
    });
  }
}

class _ErrorBannerWidget extends StatelessWidget {
  final String message;
  final VoidCallback onDismissed;

  const _ErrorBannerWidget({required this.message, required this.onDismissed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade700,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: onDismissed,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            )
          ],
        ),
      ),
    );
  }
}