class LibraryCard {
  final String number;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const LibraryCard({
    required this.number,
    required this.issuedAt,
    required this.expiresAt,
  });

  LibraryCard copyWith({
    String? number,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) {
    return LibraryCard(
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory LibraryCard.fromJson(Map<String, dynamic> json) => LibraryCard(
        number: json['number'] as String? ?? '',
        issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
            DateTime(2000, 1, 1),
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime(2099, 1, 1),
      );
}