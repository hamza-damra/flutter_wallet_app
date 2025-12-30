import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/user_model.dart';
import '../core/models/transaction_model.dart';
import '../core/models/category_model.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Operations
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  // Transaction Operations
  Future<void> addTransaction(TransactionModel transaction) async {
    await _firestore.collection('transactions').add(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _firestore.collection('transactions').doc(transactionId).delete();
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

  Stream<List<TransactionModel>> getFilteredTransactions(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    // To include the entire end day, we adjust it to the last millisecond
    final adjustedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    final adjustedStart = DateTime(
      start.year,
      start.month,
      start.day,
      0,
      0,
      0,
      0,
    );

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: adjustedStart)
        .where('createdAt', isLessThanOrEqualTo: adjustedEnd)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Category Operations
  Stream<List<CategoryModel>> getCategories(String userId) {
    return _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
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

  Future<void> seedDefaultCategories(String userId) async {
    final categoriesRef = _firestore.collection('categories');
    final snapshot = await categoriesRef
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    // Only seed if empty for this user
    if (snapshot.docs.isEmpty) {
      final defaults = [
        CategoryModel(
          id: '',
          userId: userId,
          name: 'cat_food',
          nameAr: 'طعام وشراب',
          icon: 'food',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          userId: userId,
          name: 'cat_shopping',
          nameAr: 'تسوق',
          icon: 'shopping',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          userId: userId,
          name: 'cat_transportation',
          nameAr: 'مواصلات',
          icon: 'transportation',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          userId: userId,
          name: 'cat_entertainment',
          nameAr: 'ترفيه',
          icon: 'entertainment',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          userId: userId,
          name: 'cat_bills',
          nameAr: 'فواتير',
          icon: 'bills',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          userId: userId,
          name: 'cat_income',
          nameAr: 'دخل إضافي',
          icon: 'income',
          type: 'income',
        ),
        CategoryModel(
          id: '',
          userId: userId,
          name: 'cat_salary',
          nameAr: 'راتب',
          icon: 'salary',
          type: 'income',
        ),
        CategoryModel(
          id: '',
          userId: userId,
          name: 'cat_other',
          nameAr: 'أخرى',
          icon: 'other',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          userId: userId,
          name: 'cat_haircut',
          nameAr: 'حلاقة',
          icon: 'hair cut',
          type: 'expense',
        ),
        CategoryModel(
          id: '',
          userId: userId,
          name: 'cat_home',
          nameAr: 'منزل',
          icon: 'home',
          type: 'expense',
        ),
      ];

      for (var cat in defaults) {
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
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getCategories(uid);
});

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).getUserStream(uid);
});
