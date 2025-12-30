import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../local/sqlite_database.dart';
import '../../core/models/category_model.dart';
import '../../services/auth_service.dart';
import 'transaction_repository.dart';

class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  Stream<List<CategoryModel>> watchCategories(String userId) {
    return (_db.select(_db.categories)
          ..where((c) => c.userId.equals(userId) | c.userId.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.name)]))
        .watch()
        .map((rows) => rows.map((row) => _mapRowToModel(row)).toList());
  }

  Future<void> addCategory(CategoryModel category) async {
    final id = category.id.isEmpty ? const Uuid().v4() : category.id;

    final companion = CategoriesCompanion.insert(
      id: id,
      userId: Value(category.userId),
      name: category.name,
      nameAr: Value(category.nameAr),
      icon: category.icon,
      type: category.type,
      updatedAt: category.updatedAt,
      syncStatus: const Value('pending'),
    );

    await _db.into(_db.categories).insert(companion);

    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: 'category',
            entityId: id,
            operation: 'insert',
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> updateCategory(CategoryModel category) async {
    await (_db.update(
      _db.categories,
    )..where((c) => c.id.equals(category.id))).write(
      CategoriesCompanion(
        name: Value(category.name),
        nameAr: Value(category.nameAr),
        icon: Value(category.icon),
        type: Value(category.type),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );

    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: 'category',
            entityId: category.id,
            operation: 'update',
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> deleteCategory(String id) async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      const CategoriesCompanion(syncStatus: Value('pending')),
    );

    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: 'category',
            entityId: id,
            operation: 'delete',
            createdAt: DateTime.now(),
          ),
        );
  }

  CategoryModel _mapRowToModel(Category row) {
    return CategoryModel(
      id: row.id,
      userId: row.userId,
      name: row.name,
      nameAr: row.nameAr,
      icon: row.icon,
      type: row.type,
      updatedAt: row.updatedAt,
    );
  }

  Future<void> seedDefaultCategories(String userId) async {
    final count = await (_db.select(_db.categories)..limit(1)).get();
    if (count.isNotEmpty) return;

    final defaults = [
      CategoryModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'cat_food',
        nameAr: 'طعام وشراب',
        icon: 'food',
        type: 'expense',
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'cat_shopping',
        nameAr: 'تسوق',
        icon: 'shopping',
        type: 'expense',
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'cat_transportation',
        nameAr: 'مواصلات',
        icon: 'transportation',
        type: 'expense',
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'cat_entertainment',
        nameAr: 'ترفيه',
        icon: 'entertainment',
        type: 'expense',
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'cat_bills',
        nameAr: 'فواتير',
        icon: 'bills',
        type: 'expense',
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'cat_income',
        nameAr: 'دخل إضافي',
        icon: 'income',
        type: 'income',
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'cat_salary',
        nameAr: 'راتب',
        icon: 'salary',
        type: 'income',
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'cat_other',
        nameAr: 'أخرى',
        icon: 'other',
        type: 'expense',
        updatedAt: DateTime.now(),
      ),
    ];

    for (var cat in defaults) {
      await addCategory(cat);
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepository(db);
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value([]);

  final repo = ref.watch(categoryRepositoryProvider);
  repo.seedDefaultCategories(uid);
  return repo.watchCategories(uid);
});
