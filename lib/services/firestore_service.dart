import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/user_model.dart';
import '../core/models/transaction_model.dart';
import '../core/models/category_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Operations
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Transaction Operations
  Future<void> addTransaction(TransactionModel transaction) async {
    await _firestore.collection('transactions').add(transaction.toMap());
  }

  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Category Operations
  Stream<List<CategoryModel>> getCategories() {
    return _firestore
        .collection('categories')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addCategory(CategoryModel category) async {
    await _firestore.collection('categories').add(category.toMap());
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  // Seeding Logic

  Future<void> seedDefaultCategories() async {
    final categoriesRef = _firestore.collection('categories');
    final snapshot = await categoriesRef.limit(1).get();

    // Only seed if empty
    if (snapshot.docs.isEmpty) {
      final defaults = [
        CategoryModel(id: '', name: 'cat_food', icon: 'food', type: 'expense'),
        CategoryModel(
          id: '',
          name: 'cat_shopping',
          icon: 'shopping',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          name: 'cat_transportation',
          icon: 'transportation',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          name: 'cat_entertainment',
          icon: 'entertainment',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          name: 'cat_bills',
          icon: 'bills',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          name: 'cat_income',
          icon: 'income',
          type: 'income',
        ),
        CategoryModel(
          id: '',
          name: 'cat_other',
          icon: 'other',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          name: 'cat_haircut',
          icon: 'hair cut',
          type: 'expense',
        ),
        CategoryModel(id: '', name: 'cat_home', icon: 'home', type: 'expense'),
      ];

      for (var cat in defaults) {
        // We let Firestore generate the ID
        await categoriesRef.add(cat.toMap());
      }
    }
  }
}

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final transactionsProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, userId) {
      return ref.watch(firestoreServiceProvider).getTransactions(userId);
    });

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getCategories();
});
