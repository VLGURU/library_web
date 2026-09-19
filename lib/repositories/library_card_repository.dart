import '../models/library_card_item.dart';

abstract interface class LibraryCardRepository {
  Future<List<LibraryCardItem>> mine();
}