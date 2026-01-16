import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_page.dart'; 
import 'detail_page.dart';
import 'history_page.dart';
import 'profile_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _addToCart(Map<String, dynamic> product) async {
    if (user == null) {
      _showSnackBar("Silakan login terlebih dahulu!", Colors.red);
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(user!.uid)
          .collection('items')
          .doc(product['id'].toString());

      await cartRef.set({
        'id': product['id'],
        'name': product['name'],
        'price': product['price'],
        'image_url': product['image_url'],
        'quantity': FieldValue.increment(1), 
        'added_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSnackBar("${product['name']} berhasil ditambah!", Colors.green);
    } catch (e) {
      _showSnackBar("Gagal menambah keranjang", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "eTrade Market",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B4EAD),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage())),
          ),
          _buildCartBadge(), 
          IconButton(
            icon: const Icon(Icons.person_pin, color: Colors.white, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
          ),
          const SizedBox(width: 5), 
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 15, 20, 5),
            child: Text("Popular Products", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading data"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'].toString().toLowerCase();
                  return name.contains(searchQuery.toLowerCase());
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey),
                        Text("Produk tidak ditemukan", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final productData = {
                      ...data,
                      'id': doc.id, 
                    };

                    return _buildProductCard(productData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1B4EAD),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hello, Shopper!", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Cari barang impianmu...",
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Color(0xFF1B4EAD)),
                suffixIcon: searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => searchQuery = "");
                      },
                    )
                  : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCartBadge() {
    if (user == null) return IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () {});

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('carts')
          .doc(user!.uid)
          .collection('items')
          .snapshots(),
      builder: (context, snapshot) {
        int itemCount = 0;
        if (snapshot.hasData) {
          itemCount = snapshot.data!.docs.length;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
            ),
            if (itemCount > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text('$itemCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(product: data))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Hero(
                  tag: 'product-${data['name']}',
                  child: Image.network(
                    data['image_url'] ?? 'https://via.placeholder.com/150', 
                    fit: BoxFit.cover, 
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("Rp ${data['price']}", style: const TextStyle(color: Color(0xFF1B4EAD), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 35,
                    child: ElevatedButton(
                      onPressed: () => _addToCart(data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4EAD),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Add to Cart", style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}