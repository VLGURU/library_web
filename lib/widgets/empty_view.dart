import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  final String message;
  const EmptyView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message)));
  }
}