import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/permissions.dart';
import 'package:library_web/models/role.dart';

void main() {
  test('permissions by role', () {
    expect(canViewCatalog(Role.reader), true);
    expect(canViewMyCards(Role.reader), true);
    expect(canManageBooks(Role.reader), false);
    expect(canManageDirectories(Role.reader), false);
    expect(canAdminUsers(Role.reader), false);

    expect(canManageBooks(Role.librarian), true);
    expect(canManageReaders(Role.librarian), true);
    expect(canAdminUsers(Role.librarian), false);

    expect(canAdminUsers(Role.admin), true);
    expect(canHardDelete(Role.admin), true);
  });
}