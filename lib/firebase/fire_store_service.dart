import 'package:cloud_firestore/cloud_firestore.dart';

class FireStoreService {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  Future<void> register(String email, String name) async {
    List<String> words = splitName(name);
    await _fireStore.collection('users').doc(email).set({
      'name': name,
      'dn': words[0],
      'email': email,
    });
  }

  // Get all documents from a collection
  Future<List<Map<String, dynamic>>> getDocuments(
      String col1, String email, String col2) async {
    final collectionRef =
        _fireStore.collection(col1).doc(email).collection(col2);
    final snapshot = await collectionRef.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocuments2(
      String col1, String email) {
    return _fireStore.collection(col1).doc(email).get();
  }

  Future<List<String>> getDocumentNames(
      String col1, String email, String col2) async {
    final collectionRef =
        _fireStore.collection(col1).doc(email).collection(col2);
    final snapshot = await collectionRef.get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> deleteCollection(String col1, String email, String col2) async {
    final collection =
        FirebaseFirestore.instance.collection(col1).doc(email).collection(col2);
    // Get all documents in the collection
    final snapshot = await collection.get();
    // Loop through and delete each document
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  //used for add places
  Future<void> addDocument(
      String col1, String doc1, String col2, Map<String, dynamic> data) async {
    final collectionRef =
        _fireStore.collection(col1).doc(doc1).collection(col2);
    await collectionRef.add(data);
  }

  List<String> splitName(String name) {
    List<String> words = name.split(" ");
    return words;
  }
}
