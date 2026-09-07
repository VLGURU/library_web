class BookQuery {
  final String search;
  final int? genreId;
  final int? publisherId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const BookQuery({
    this.search = '',
    this.genreId,
    this.publisherId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  BookQuery copyWith({
    String? search,
    Object? genreId = _unset,
    Object? publisherId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BookQuery(
      search: search ?? this.search,
      genreId: genreId == _unset ? this.genreId : genreId as int?,
      publisherId: publisherId == _unset ? this.publisherId : publisherId as int?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1, // смена условий -> 1 страница
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory BookQuery.fromUri(Uri uri) {
    final q = uri.queryParameters;
    int? pInt(String key) => int.tryParse(q[key] ?? '');

    var sortField = 'title';
    var sortAscending = true;
    final sort = q['sort']; // year,desc
    if (sort != null && sort.trim().isNotEmpty) {
      final parts = sort.split(',');
      sortField = parts.first;
      if (parts.length >= 2) sortAscending = parts[1].toLowerCase() != 'desc';
    }

    final page = int.tryParse(q['page'] ?? '1') ?? 1;
    final size = int.tryParse(q['size'] ?? '10') ?? 10;

    return BookQuery(
      search: q['search'] ?? '',
      genreId: pInt('genreId'),
      publisherId: pInt('publisherId'),
      yearFrom: pInt('yearFrom'),
      yearTo: pInt('yearTo'),
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
    if (genreId != null) map['genreId'] = '$genreId';
    if (publisherId != null) map['publisherId'] = '$publisherId';
    if (yearFrom != null) map['yearFrom'] = '$yearFrom';
    if (yearTo != null) map['yearTo'] = '$yearTo';

    final dir = sortAscending ? 'asc' : 'desc';
    if (sortField != 'title' || dir != 'asc') map['sort'] = '$sortField,$dir';

    if (page != 1) map['page'] = '$page';
    if (size != 10) map['size'] = '$size';
    if (includeDeleted) map['includeDeleted'] = '1';

    return map;
  }

  @override
  bool operator ==(Object other) =>
      other is BookQuery &&
      search == other.search &&
      genreId == other.genreId &&
      publisherId == other.publisherId &&
      yearFrom == other.yearFrom &&
      yearTo == other.yearTo &&
      sortField == other.sortField &&
      sortAscending == other.sortAscending &&
      page == other.page &&
      size == other.size &&
      includeDeleted == other.includeDeleted;

  @override
  int get hashCode => Object.hash(
        search,
        genreId,
        publisherId,
        yearFrom,
        yearTo,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}