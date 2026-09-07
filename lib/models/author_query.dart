class AuthorQuery {
  final String search;
  final String? country;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const AuthorQuery({
    this.search = '',
    this.country,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  AuthorQuery copyWith({
    String? search,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AuthorQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory AuthorQuery.fromUri(Uri uri) {
    final q = uri.queryParameters;

    var sortField = 'lastName';
    var sortAscending = true;
    final sort = q['sort'];
    if (sort != null && sort.trim().isNotEmpty) {
      final parts = sort.split(',');
      sortField = parts.first;
      if (parts.length >= 2) sortAscending = parts[1].toLowerCase() != 'desc';
    }

    final page = int.tryParse(q['page'] ?? '1') ?? 1;
    final size = int.tryParse(q['size'] ?? '10') ?? 10;

    final country = (q['country'] ?? '').trim();
    return AuthorQuery(
      search: q['search'] ?? '',
      country: country.isEmpty ? null : country,
      sortField: sortField,
      sortAscending: sortAscending,
      page: page < 1 ? 1 : page,
      size: (size == 10 || size == 25 || size == 50) ? size : 10,
      includeDeleted: (q['includeDeleted'] ?? '') == '1',
    );
  }

  Map<String, String> toQueryParameters() {
    final map = <String, String>{};

    if (search.trim().isNotEmpty) map['search'] = search.trim();
    if (country != null && country!.trim().isNotEmpty) map['country'] = country!.trim();

    final dir = sortAscending ? 'asc' : 'desc';
    if (sortField != 'lastName' || dir != 'asc') map['sort'] = '$sortField,$dir';

    if (page != 1) map['page'] = '$page';
    if (size != 10) map['size'] = '$size';
    if (includeDeleted) map['includeDeleted'] = '1';

    return map;
  }

  @override
  bool operator ==(Object other) =>
      other is AuthorQuery &&
      search == other.search &&
      country == other.country &&
      sortField == other.sortField &&
      sortAscending == other.sortAscending &&
      page == other.page &&
      size == other.size &&
      includeDeleted == other.includeDeleted;

  @override
  int get hashCode => Object.hash(search, country, sortField, sortAscending, page, size, includeDeleted);
}