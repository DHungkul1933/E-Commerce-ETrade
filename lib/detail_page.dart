import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_page.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const DetailPage({super.key, required this.product});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _quantity = 1;

  int get _availableStock => widget.product['stock'] ?? 0;

  void _incrementQty() {
    if (_quantity < _availableStock) {
      setState(() => _quantity++);
    } else {
      _showSnackBar("Stok tidak mencukupi!");
    }
  }

  void _decrementQty() {
    if (_quantity > 1) setState(() => _quantity--);
  }
  Future<void> _addToFirestoreCart() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar("Silakan login terlebih dahulu!");
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(widget.product['id'].toString());

      await cartRef.set({
        'id': widget.product['id'],
        'name': widget.product['name'],
        'price': widget.product['price'],
        'image_url': widget.product['image_url'],
        'quantity': FieldValue.increment(_quantity), 
        'added_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSnackBar("Berhasil masuk keranjang!");
    } catch (e) {
      _showSnackBar("Gagal menambah keranjang: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1B4EAD),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.3),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFF8FAFF),
                child: Hero(
                  tag: 'product-${widget.product['name']}',
                  child: Image.network(
                    widget.product['image_url'] ?? 'https://via.placeholder.com/400',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product['name'] ?? "Premium Product",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _availableStock > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Stok: $_availableStock",
                          style: TextStyle(
                            color: _availableStock > 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Rp ${widget.product['price']}",
                    style: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFF1B4EAD),
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 25),
                  const Text("Pilih Jumlah",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 130,
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _qtyButton(Icons.remove, _decrementQty),
                            Text("$_quantity",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            _qtyButton(Icons.add, _incrementQty),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      if (_availableStock <= 5 && _availableStock > 0)
                        Text(
                          "Sisa sedikit!",
                          style: TextStyle(color: Colors.orange[800], fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  const Divider(height: 50),
                  const Text("Deskripsi",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    widget.product['description'] ?? "No description available.",
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey[600], height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildBottomAction() {
    final bool isOutOfStock = _availableStock <= 0;

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isOutOfStock ? Colors.grey[200] : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              icon: Icon(Icons.add_shopping_cart, 
                color: isOutOfStock ? Colors.grey : Colors.orange, 
                size: 28),
              onPressed: isOutOfStock ? null : _addToFirestoreCart, 
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: isOutOfStock ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(
                        product: widget.product, 
                        quantity: _quantity,
                        isFromCart: false,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock ? Colors.grey : const Color(0xFF1B4EAD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: Text(isOutOfStock ? "STOK HABIS" : "BELI SEKARANG",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3)],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1B4EAD)),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1B4EAD),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}