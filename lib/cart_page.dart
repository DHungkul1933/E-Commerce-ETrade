import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _removeItem(String docId) async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('carts')
        .doc(user!.uid)
        .collection('items')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Silakan login untuk melihat keranjang")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Keranjang Saya", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B4EAD),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(user!.uid)
            .collection('items')
            .orderBy('added_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final cartDocs = snapshot.data!.docs;
          
          double totalPrice = 0;
          for (var doc in cartDocs) {
            var data = doc.data() as Map<String, dynamic>;
            var price = double.tryParse(data['price'].toString().replaceAll('.', '')) ?? 0;
            var qty = data['quantity'] ?? 1;
            totalPrice += (price * qty);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: cartDocs.length,
                  itemBuilder: (context, index) {
                    final item = cartDocs[index].data() as Map<String, dynamic>;
                    final docId = cartDocs[index].id;
                    return _buildCartItem(item, docId);
                  },
                ),
              ),
              _buildCheckoutSection(totalPrice, cartDocs),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Wah, keranjangmu kosong!", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          const Text("Yuk, cari barang impianmu sekarang.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4EAD), 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            child: const Text("Mulai Belanja"),
          )
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item['image_url'] ?? 'https://via.placeholder.com/80',
              width: 70, height: 70, fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? "Produk", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text("Rp ${item['price']}", 
                  style: const TextStyle(color: Color(0xFF1B4EAD), fontWeight: FontWeight.w600)),
                Text("Jumlah: ${item['quantity'] ?? 1}", 
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _removeItem(docId),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(double total, List<QueryDocumentSnapshot> docs) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Pembayaran", style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text(
                  "Rp ${total.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B4EAD)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  List<Map<String, dynamic>> items = docs.map((d) {
                    var data = d.data() as Map<String, dynamic>;
                    return {
                      ...data,
                      'cart_doc_id': d.id, 
                    };
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(
                        cartItems: items,
                        isFromCart: true,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4EAD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("CHECKOUT SEKARANG", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}