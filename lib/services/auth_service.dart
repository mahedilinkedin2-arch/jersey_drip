import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(
    String name,
    String email,
    String password,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user != null) {
      await _saveUserProfile(user, name: name);
    }
    return userCredential;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign in cancelled',
      );
    }

    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null && googleAuth.accessToken == null) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Missing Google authentication tokens.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      await _saveUserProfile(user, name: user.displayName);
    }
    return userCredential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> _saveUserProfile(User user, {String? name}) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    final existingRole = (snapshot.data()?['role'] as String?) ?? 'user';

    await userRef.set({
      'uid': user.uid,
      'name': name ?? user.displayName ?? 'New User',
      'email': user.email ?? '',
      'role': existingRole,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
