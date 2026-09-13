class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Book copyWith({
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? this.authorIds,
      genreIds: genreIds ?? this.genreIds,
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable: copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isbn': isbn,
        'year': year,
        'pages': pages,
        'publisherId': publisherId,
        'authorIds': authorIds,
        'genreIds': genreIds,
        'copiesTotal': copiesTotal,
        'copiesAvailable': copiesAvailable,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Book.fromJson(Map<String, dynamic> json) {
    int readId(dynamic v) {
      if (v is num) return v.toInt();
      if (v is Map) return (v['id'] as num?)?.toInt() ?? 0;
      return 0;
    }

    List<int> readIdList(dynamic v) {
      if (v is List) {
        return v.map((e) => readId(e)).where((id) => id != 0).toList();
      }
      return const [];
    }

    final publisherId =
        (json['publisherId'] as num?)?.toInt() ?? readId(json['publisher']);

    final authorIds = (json['authorIds'] is List)
        ? (json['authorIds'] as List).map((e) => (e as num).toInt()).toList()
        : readIdList(json['authors']);

    final genreIds = (json['genreIds'] is List)
        ? (json['genreIds'] as List).map((e) => (e as num).toInt()).toList()
        : readIdList(json['genres']);

    return Book(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      isbn: json['isbn'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      pages: (json['pages'] as num?)?.toInt() ?? 0,
      publisherId: publisherId,
      authorIds: authorIds,
      genreIds: genreIds,
      copiesTotal: (json['copiesTotal'] as num?)?.toInt() ?? 0,
      copiesAvailable: (json['copiesAvailable'] as num?)?.toInt() ?? 0,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }
}