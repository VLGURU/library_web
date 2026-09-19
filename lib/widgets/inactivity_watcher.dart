import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warnBefore;
  final Future<void> Function() onTimeout;
  final Widget child;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.warnBefore,
    required this.onTimeout,
    required this.child,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warnTimer;
  Timer? _timeoutTimer;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _restart() {
    _warnTimer?.cancel();
    _timeoutTimer?.cancel();

    final warnAt = widget.timeout - widget.warnBefore;
    if (warnAt.isNegative) {
      // если кто-то передал warnBefore больше timeout
      _timeoutTimer = Timer(widget.timeout, _doTimeout);
      return;
    }

    _warnTimer = Timer(warnAt, _showWarn);
    _timeoutTimer = Timer(widget.timeout, _doTimeout);
  }

  Future<void> _showWarn() async {
    if (!mounted || _dialogShown) return;
    _dialogShown = true;

    // Если пользователь ткнёт/нажмёт — таймер сбросится Listener’ом.
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Сессия скоро завершится'),
        content: Text('Если не будет действий, через ${widget.warnBefore.inSeconds} сек. произойдёт выход.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Остаться'),
          ),
        ],
      ),
    );

    _dialogShown = false;
    if (mounted) _restart();
  }

  Future<void> _doTimeout() async {
    if (!mounted) return;
    await widget.onTimeout();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _warnTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}