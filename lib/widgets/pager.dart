import 'package:flutter/material.dart';

class Pager extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalItems;
  final int size;

  final ValueChanged<int> onPage;
  final ValueChanged<int> onSize;

  const Pager({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.size,
    required this.onPage,
    required this.onSize,
  });

  @override
  Widget build(BuildContext context) {
    final canPrev = page > 1;
    final canNext = page < totalPages;

    return Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Всего: $totalItems'),
        IconButton(onPressed: canPrev ? () => onPage(1) : null, icon: const Icon(Icons.first_page)),
        IconButton(onPressed: canPrev ? () => onPage(page - 1) : null, icon: const Icon(Icons.chevron_left)),
        Text('Стр. $page / $totalPages'),
        IconButton(onPressed: canNext ? () => onPage(page + 1) : null, icon: const Icon(Icons.chevron_right)),
        IconButton(onPressed: canNext ? () => onPage(totalPages) : null, icon: const Icon(Icons.last_page)),
        DropdownButton<int>(
          value: size,
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
          onChanged: (v) {
            if (v != null) onSize(v);
          },
        ),
        const Text('на странице'),
      ],
    );
  }
}