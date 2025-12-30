import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/category_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Operations
  Future<void> createUser(UserModel user) async {
    final data = user.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(user.uid).set(data);
  }

  Future<void> updateUser(UserModel user) async {
    final data = user.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(user.uid).update(data);
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
        .snapshots(includeMetadataChanges: true)
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  // Transaction Operations
  Future<String> addTransaction(TransactionModel transaction) async {
    final data = transaction.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    // If transaction.id is empty, Firestore will generate one.
    // If not, we might want to use it if we want to sync specific records.
    // However, usually we let Firestore generate it and then sync back to localId.
    final docRef = await _firestore.collection('transactions').add(data);
    return docRef.id;
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final data = transaction.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(data);
  }

  Future<void> deleteTransaction(String remoteId) async {
    await _firestore.collection('transactions').doc(remoteId).delete();
  }

  // Category Operations
  Future<String> addCategory(CategoryModel category) async {
    final data = category.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final docRef = await _firestore.collection('categories').add(data);
    return docRef.id;
  }

  Future<void> updateCategory(CategoryModel category) async {
    final data = category.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('categories').doc(category.id).update(data);
  }

  Future<void> deleteCategory(String remoteId) async {
    await _firestore.collection('categories').doc(remoteId).delete();
  }

  // Data fetching for sync (pull)
  Future<List<TransactionModel>> getRecentTransactions(
    String userId,
    DateTime since,
  ) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
        .where((t) => t.updatedAt.isAfter(since))
        .toList();
  }

  Future<List<CategoryModel>> getRecentCategories(
    String userId,
    DateTime since,
  ) async {
    final snapshot = await _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
        .where((c) => c.updatedAt.isAfter(since))
        .toList();
  }
}

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);
