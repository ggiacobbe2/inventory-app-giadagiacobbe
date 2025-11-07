// Import Flutter and Firestore packages
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: InventoryHomePage(title: 'Inventory Management'),
    );
  }
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

  Future<void> addItem(Item item) async => await itemsCollection.add(item.toMap());

  Future<void> updateItem(Item item) async {
    if (item.id == null) return;
    await itemsCollection.doc(item.id).update(item.toMap());
  }

  Future<void> deleteItem(String id) async => await itemsCollection.doc(id).delete();

  Stream<List<Item>> getItems() {
    return itemsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Item.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}

class AddEditItemScreen extends StatefulWidget {
  final Item? item;
  const AddEditItemScreen({super.key, this.item});

  @override
  _AddEditItemScreenState createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _quantityController.text = widget.item!.quantity.toString();
      _priceController.text = widget.item!.price.toString();
      _categoryController.text = widget.item!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Item' : 'Add Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v!.isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Enter quantity' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Enter price' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) => v!.isEmpty ? 'Enter category' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: Text(isEditing ? 'Update Item' : 'Add Item'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final item = Item(
                      id: widget.item?.id,
                      name: _nameController.text,
                      quantity: int.parse(_quantityController.text),
                      price: double.parse(_priceController.text),
                      category: _categoryController.text,
                      createdAt: widget.item?.createdAt ?? DateTime.now(),
                    );
                    if (isEditing) {
                      await firestoreService.updateItem(item);
                    } else {
                      await firestoreService.addItem(item);
                    }
                    Navigator.pop(context);
                  }
                },
              ),
              if (isEditing)
                TextButton(
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    await firestoreService.deleteItem(widget.item!.id!);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  final String title;
  InventoryHomePage({super.key, required this.title});

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final FirestoreService firestoreService = FirestoreService();
  bool isSelecting = false;
  Set<String> selectedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (isSelecting)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                for (var id in selectedItems) {
                  await firestoreService.deleteItem(id);
                }
                setState(() {
                  isSelecting = false;
                  selectedItems.clear();
                });
              },
            ),
          IconButton(
            icon: Icon(isSelecting ? Icons.close : Icons.check_box),
            onPressed: () {
              setState(() {
                isSelecting = !isSelecting;
                if (!isSelecting) selectedItems.clear();
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Item>>(
        stream: firestoreService.getItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No items found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: isSelecting
                      ? Checkbox(
                          value: selectedItems.contains(item.id),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                selectedItems.add(item.id!);
                              } else {
                                selectedItems.remove(item.id);
                              }
                            });
                          },
                        )
                      : null,
                  title: Text(item.name),
                  subtitle: Text('Quantity: ${item.quantity}, Price: \$${item.price.toStringAsFixed(2)}'),
                  trailing: !isSelecting
                      ? IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => firestoreService.deleteItem(item.id!),
                        )
                      : null,
                  onTap: () {
                    if (isSelecting) {
                      setState(() {
                        if (isSelecting) {
                          selectedItems.remove(item.id!);
                        } else {
                          selectedItems.add(item.id!);
                        }
                      });
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditItemScreen(item: item),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditItemScreen()),
          );
        },
      ),
    );
  }
}