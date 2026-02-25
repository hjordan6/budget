import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Singleton service handling Firebase Auth operations and username mappings.
///
/// Firestore layout:
///   usernames/{username}  -> { uid, email }
///   user_accounts/{uid}   -> { username, email, linkedAt }
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Sign in with an email address OR a username + password.
  Future<UserCredential> signIn(String usernameOrEmail, String password) async {
    String email = usernameOrEmail.trim();
    if (!email.contains('@')) {
      final doc = await _firestore.collection('usernames').doc(email).get();
      if (!doc.exists) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account found with that username.',
        );
      }
      final resolved = doc.data()?['email'] as String?;
      if (resolved == null || resolved.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Username is not linked to an email address.',
        );
      }
      email = resolved;
    }
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  /// Create a new Firebase Auth account with email + password.
  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Return the Firestore username linked to the current Firebase Auth user.
  Future<String?> getLinkedUsername() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc =
        await _firestore.collection('user_accounts').doc(user.uid).get();
    return doc.data()?['username'] as String?;
  }

  /// Link the authenticated Firebase user to a Firestore username.
  /// Works for migrating existing username-only accounts OR creating new ones.
  Future<void> linkToUsername(String username) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated.');

    final trimmed = username.trim();
    if (trimmed.isEmpty) throw Exception('Username cannot be empty.');

    // Prevent claiming a username owned by a different UID
    final usernameDoc =
        await _firestore.collection('usernames').doc(trimmed).get();
    if (usernameDoc.exists) {
      final existingUid = usernameDoc.data()?['uid'] as String?;
      if (existingUid != null && existingUid != user.uid) {
        throw Exception('That username is already linked to another account.');
      }
    }

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('user_accounts').doc(user.uid),
      {
        'username': trimmed,
        'email': user.email,
        'linkedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      _firestore.collection('usernames').doc(trimmed),
      {'uid': user.uid, 'email': user.email},
    );
    await batch.commit();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
