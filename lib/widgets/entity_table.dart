import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;

  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;

  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;

  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelect = onToggleSelect != null;
    final hasActions = actions != null;

    int? sortColumnIndex;
    if (sortField != null) {
      final i = columns.indexWhere((c) => c.sortField == sortField);
      if (i != -1) sortColumnIndex = i + (hasSelect ? 1 : 0);
    }

    final dataColumns = <DataColumn>[];

    if (hasSelect) {
      dataColumns.add(const DataColumn(label: SizedBox(width: 24)));
    }

    for (final c in columns) {
      dataColumns.add(
        DataColumn(
          label: Text(c.label),
          numeric: c.numeric,
          onSort: c.sortField == null || onSort == null
              ? null
              : (int columnIndex, bool ascending) => onSort!.call(c.sortField!),
        ),
      );
    }

    if (hasActions) {
      dataColumns.add(const DataColumn(label: Text('Действия')));
    }

    final rows = items.map((item) {
      final id = idOf(item);

      final cells = <DataCell>[];
      if (hasSelect) {
        cells.add(
          DataCell(
            Checkbox(
              value: selected.contains(id),
              onChanged: (_) => onToggleSelect!(id),
            ),
          ),
        );
      }

      for (final c in columns) {
        cells.add(DataCell(c.build(item)));
      }

      if (hasActions) {
        cells.add(
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!(item),
            ),
          ),
        );
      }

      return DataRow(cells: cells);
    }).toList();

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            columns: dataColumns,
            rows: rows,
          ),
        ),
      ),
    );
  }
}