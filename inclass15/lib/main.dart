// Import Flutter and Firestore packages
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: InventoryHomePage(title: 'Inventory Home Page'),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class Item {
  final String? id;
  final String name;
  final int quantity;
  final double price;
  final String category;
  final DateTime createdAt;

  Item({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'category': category,
      'createdAt': createdAt,
    };
  }

  factory Item.fromMap(String id, Map<String, dynamic> map) {
    return Item(
      id: id,
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: map['price']?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class FirestoreService {
  final CollectionReference itemsCollection =
      FirebaseFirestore.instance.collection('items');

  Future<void> addItem(Item item) async {
    try {
      await itemsCollection.add(item.toMap());
    } catch (e) {
      print('Error adding item: $e');
    }
  }

  Future<void> updateItem(Item item) async {
    if (item.id == null) return;
    try {
      await itemsCollection.doc(item.id).update(item.toMap());
    } catch (e) {
      print('Error updating item: $e');
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await itemsCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting item: $e');
    }
  }

  Stream<List<Item>> getItems() {
    return itemsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Item.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  // TODO: 1. Initialize Firestore & Create a Stream for items
  // TODO: 2. Build a ListView using a StreamBuilder to display items
  // TODO: 3. Implement Navigation to an "Add Item" screen
  // TODO: 4. Implement one of the Delete methods (swipe or in-edit)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Inventory Management System'),
            // TODO: Replace this Text widget with your StreamBuilder & ListView
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to the Add/Edit Item Form
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}