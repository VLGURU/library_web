enum Role {
  reader(1),
  librarian(2),
  admin(3);

  final int level;
  const Role(this.level);

  static Role fromJson(dynamic v) {
    final s = '$v'.toUpperCase().trim();
    return switch (s) {
      'ADMIN' => Role.admin,
      'LIBRARIAN' => Role.librarian,
      _ => Role.reader,
    };
  }

  String toJson() => switch (this) {
        Role.reader => 'READER',
        Role.librarian => 'LIBRARIAN',
        Role.admin => 'ADMIN',
      };
}