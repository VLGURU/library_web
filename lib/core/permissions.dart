import '../models/role.dart';

bool canViewCatalog(Role role) => role.level >= Role.reader.level;
bool canViewMyCards(Role role) => role == Role.reader;

bool canManageBooks(Role role) => role.level >= Role.librarian.level;
bool canManageDirectories(Role role) => role.level >= Role.librarian.level;
bool canManageReaders(Role role) => role.level >= Role.librarian.level;

bool canAdminUsers(Role role) => role.level >= Role.admin.level;
bool canHardDelete(Role role) => role.level >= Role.admin.level;