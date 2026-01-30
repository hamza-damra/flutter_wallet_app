import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/category_model.dart';
import '../../features/debts/models/friend_model.dart';
import '../../features/debts/models/debt_transaction_model.dart';

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
    debugPrint('🔥 FIRESTORE: addTransaction called');
    debugPrint('🔥 FIRESTORE: userId=${transaction.userId}, title=${transaction.title}, amount=${transaction.amount}');
    final data = transaction.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    debugPrint('🔥 FIRESTORE: Data to write: $data');
    try {
      final docRef = await _firestore.collection('transactions').add(data);
      debugPrint('🔥 FIRESTORE: ✅ Transaction written with id=${docRef.id}');
      return docRef.id;
    } catch (e, stack) {
      debugPrint('🔥 FIRESTORE: ❌ Failed to write transaction: $e');
      debugPrint('🔥 FIRESTORE: Stack: $stack');
      rethrow;
    }
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
    debugPrint('🔥 FIRESTORE: addCategory called - ${category.name} with id=${category.id}');
    final data = category.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    try {
      // Use .set() with the category's existing ID to maintain consistency
      // between local and remote IDs
      await _firestore.collection('categories').doc(category.id).set(data);
      debugPrint('🔥 FIRESTORE: ✅ Category written with id=${category.id}');
      return category.id;
    } catch (e, stack) {
      debugPrint('🔥 FIRESTORE: ❌ Failed to write category: $e');
      debugPrint('🔥 FIRESTORE: Stack: $stack');
      rethrow;
    }
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
    debugPrint('🔥 FIRESTORE: getRecentTransactions for userId=$userId');
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('🔥 FIRESTORE: Found ${snapshot.docs.length} transaction docs in Firestore');
      for (final doc in snapshot.docs) {
        debugPrint('🔥 FIRESTORE: Doc ${doc.id}: ${doc.data()}');
      }

      final result = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .where((t) => t.updatedAt.isAfter(since))
          .toList();
      debugPrint('🔥 FIRESTORE: Returning ${result.length} transactions after filtering');
      return result;
    } catch (e, stack) {
      debugPrint('🔥 FIRESTORE: ❌ Error fetching transactions: $e');
      debugPrint('🔥 FIRESTORE: Stack: $stack');
      rethrow;
    }
  }

  Future<List<CategoryModel>> getRecentCategories(
    String userId,
    DateTime since,
  ) async {
    debugPrint('🔥 FIRESTORE: getRecentCategories for userId=$userId');
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('🔥 FIRESTORE: Found ${snapshot.docs.length} category docs in Firestore');
      
      final result = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
          .where((c) => c.updatedAt.isAfter(since))
          .toList();
      debugPrint('🔥 FIRESTORE: Returning ${result.length} categories after filtering');
      return result;
    } catch (e, stack) {
      debugPrint('🔥 FIRESTORE: ❌ Error fetching categories: $e');
      debugPrint('🔥 FIRESTORE: Stack: $stack');
      rethrow;
    }
  }

  // Friend Operations
  Future<String> addFriend(FriendModel friend) async {
    debugPrint('🔥 FIRESTORE: addFriend called - ${friend.name}');
    final data = friend.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    try {
      final docRef = await _firestore.collection('friends').add(data);
      debugPrint('🔥 FIRESTORE: ✅ Friend written with id=${docRef.id}');
      return docRef.id;
    } catch (e, stack) {
      debugPrint('🔥 FIRESTORE: ❌ Failed to write friend: $e');
      debugPrint('🔥 FIRESTORE: Stack: $stack');
      rethrow;
    }
  }

  Future<void> updateFriend(FriendModel friend) async {
    final data = friend.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('friends').doc(friend.id).update(data);
  }

  Future<void> deleteFriend(String remoteId) async {
    await _firestore.collection('friends').doc(remoteId).delete();
  }

  Future<List<FriendModel>> getRecentFriends(String userId, DateTime since) async {
    debugPrint('🔥 FIRESTORE: getRecentFriends for userId=$userId');
    try {
      final snapshot = await _firestore
          .collection('friends')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('🔥 FIRESTORE: Found ${snapshot.docs.length} friend docs in Firestore');

      final result = snapshot.docs
          .map((doc) => FriendModel.fromMap(doc.id, doc.data()))
          .where((f) => f.updatedAt.isAfter(since))
          .toList();
      debugPrint('🔥 FIRESTORE: Returning ${result.length} friends after filtering');
      return result;
    } catch (e, stack) {
      debugPrint('🔥 FIRESTORE: ❌ Error fetching friends: $e');
      debugPrint('🔥 FIRESTORE: Stack: $stack');
      rethrow;
    }
  }

  // DebtTransaction Operations
  Future<String> addDebtTransaction(DebtTransactionModel debt) async {
    debugPrint('🔥 FIRESTORE: addDebtTransaction called - amount=${debt.amount}');
    final data = debt.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    try {
      final docRef = await _firestore.collection('debtTransactions').add(data);
      debugPrint('🔥 FIRESTORE: ✅ DebtTransaction written with id=${docRef.id}');
      return docRef.id;
    } catch (e, stack) {
      debugPrint('🔥 FIRESTORE: ❌ Failed to write debtTransaction: $e');
      debugPrint('🔥 FIRESTORE: Stack: $stack');
      rethrow;
    }
  }

  Future<void> updateDebtTransaction(DebtTransactionModel debt) async {
    final data = debt.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('debtTransactions').doc(debt.id).update(data);
  }

  Future<void> deleteDebtTransaction(String remoteId) async {
    await _firestore.collection('debtTransactions').doc(remoteId).delete();
  }

  Future<List<DebtTransactionModel>> getRecentDebtTransactions(String userId, DateTime since) async {
    debugPrint('🔥 FIRESTORE: getRecentDebtTransactions for userId=$userId');
    try {
      final snapshot = await _firestore
          .collection('debtTransactions')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('🔥 FIRESTORE: Found ${snapshot.docs.length} debtTransaction docs in Firestore');

      final result = snapshot.docs
          .map((doc) => DebtTransactionModel.fromMap(doc.id, doc.data()))
          .where((d) => d.updatedAt.isAfter(since))
          .toList();
      debugPrint('🔥 FIRESTORE: Returning ${result.length} debtTransactions after filtering');
      return result;
    } catch (e, stack) {
      debugPrint('🔥 FIRESTORE: ❌ Error fetching debtTransactions: $e');
      debugPrint('🔥 FIRESTORE: Stack: $stack');
      rethrow;
    }
  }
}

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);
