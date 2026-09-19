class LibraryCardItem {
  final int id;
  final String bookTitle;
  final String issuedAt;
  final String? returnedAt;

  const LibraryCardItem({
    required this.id,
    required this.bookTitle,
    required this.issuedAt,
    required this.returnedAt,
  });

  factory LibraryCardItem.fromJson(Map<String, dynamic> json) {
    final book = (json['book'] is Map) ? (json['book'] as Map).cast<String, dynamic>() : const <String, dynamic>{};
    return LibraryCardItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookTitle: book['title'] as String? ?? '',
      issuedAt: json['issuedAt'] as String? ?? '',
      returnedAt: json['returnedAt'] as String?,
    );
  }
}