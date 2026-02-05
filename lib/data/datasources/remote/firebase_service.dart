import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static GoogleSignIn? _googleSignIn;

  static FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception('FirebaseService not initialized. Call initialize() first.');
    }
    return _auth!;
  }

  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('FirebaseService not initialized. Call initialize() first.');
    }
    return _firestore!;
  }

  static Future<void> initialize({
    String? googleWebClientId,
  }) async {
    await Firebase.initializeApp();

    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;

    // Initialize Google Sign-In if web client ID is provided
    if (googleWebClientId != null && googleWebClientId.isNotEmpty) {
      _googleSignIn = GoogleSignIn(
        clientId: googleWebClientId,
      );
    }
  }

  /// Get current user
  static User? get currentUser => _auth?.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get user ID
  static String? get userId => currentUser?.uid;

  /// Sign in with Google
  static Future<UserCredential> signInWithGoogle() async {
    if (_googleSignIn == null) {
      throw Exception('Google Sign-In not initialized');
    }

    final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth!.signInWithCredential(credential);
  }

  /// Sign out
  static Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await _auth?.signOut();
  }

  /// Insert a document
  static Future<DocumentReference<Map<String, dynamic>>> insert(
    String collection,
    Map<String, dynamic> data,
  ) async {
    // Add userId and timestamps
    final docData = {
      ...data,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    return await firestore.collection(collection).add(docData);
  }

  /// Update a document
  static Future<void> update(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final docData = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await firestore.collection(collection).doc(documentId).update(docData);
  }

  /// Upsert a document (create or update)
  static Future<void> upsert(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final docData = {
      ...data,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await firestore.collection(collection).doc(documentId).set(docData, SetOptions(merge: true));
  }

  /// Delete a document
  static Future<void> delete(
    String collection,
    String documentId,
  ) async {
    await firestore.collection(collection).doc(documentId).delete();
  }

  /// Get documents with filters
  static Future<List<Map<String, dynamic>>> select(
    String collection, {
    Map<String, dynamic>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = firestore.collection(collection);

    // Add user filter
    query = query.where('userId', isEqualTo: userId);

    // Add filters
    if (filters != null) {
      filters.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });
    }

    // Add ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Add limit
    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get a single document
  static Future<Map<String, dynamic>?> selectSingle(
    String collection,
    String documentId,
  ) async {
    final doc = await firestore.collection(collection).doc(documentId).get();
    if (!doc.exists) return null;

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  /// Batch write operations
  static Future<void> batchWrite(List<WriteBatchOperation> operations) async {
    final batch = firestore.batch();

    for (final operation in operations) {
      final docRef = firestore.collection(operation.collection).doc(operation.documentId);

      switch (operation.type) {
        case WriteBatchType.set:
          batch.set(docRef, {
            ...operation.data,
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          break;
        case WriteBatchType.update:
          batch.update(docRef, {
            ...operation.data,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          break;
        case WriteBatchType.delete:
          batch.delete(docRef);
          break;
      }
    }

    await batch.commit();
  }
}

enum WriteBatchType { set, update, delete }

class WriteBatchOperation {
  final String collection;
  final String documentId;
  final WriteBatchType type;
  final Map<String, dynamic> data;

  WriteBatchOperation({
    required this.collection,
    required this.documentId,
    required this.type,
    required this.data,
  });
}