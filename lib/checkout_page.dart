import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  final int? quantity;
  final List<Map<String, dynamic>>? cartItems;
  final bool isFromCart;

  const CheckoutPage({
    super.key,
    this.product,
    this.quantity,
    this.cartItems,
    this.isFromCart = false,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedMethod = "Transfer Bank (VA)";
  bool _isLoading = false;
  final int _shippingFee = 5000;
  final int _serviceFee = 2500;

  double _calculateSubtotal() {
    if (widget.isFromCart) {
      double total = 0;
      for (var item in widget.cartItems!) {
        var price = double.tryParse(item['price'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        var qty = item['quantity'] ?? 1;
        total += (price * qty);
      }
      return total;
    } else {
      var price = double.tryParse(widget.product!['price'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return price * (widget.quantity ?? 1);
    }
  }

  Future<void> _processPayment() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "Anda harus login terlebih dahulu.";

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      double subtotal = _calculateSubtotal();
      int totalPayment = subtotal.toInt() + _shippingFee + _serviceFee;
      List<Map<String, dynamic>> orderItems = [];

      if (widget.isFromCart) {
        for (var item in widget.cartItems!) {
          String productId = item['id'].toString();
          int qty = item['quantity'] ?? 1;

          DocumentReference pRef = firestore.collection('products').doc(productId);
          DocumentSnapshot pSnap = await pRef.get();

          if (!pSnap.exists) throw "Produk ${item['name']} tidak ditemukan.";
          int currentStock = int.tryParse(pSnap.get('stock').toString()) ?? 0;
          if (currentStock < qty) throw "Stok ${item['name']} tidak mencukupi.";

          batch.update(pRef, {'stock': currentStock - qty});
          orderItems.add({
            'name': item['name'],
            'price': int.tryParse(item['price'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
            'qty': qty,
            'image_url': item['image_url'],
          });

          DocumentReference cartItemRef = firestore
              .collection('carts')
              .doc(user.uid)
              .collection('items')
              .doc(productId);
          batch.delete(cartItemRef);
        }
      } else {
        String productId = widget.product!['id'].toString();
        int qty = widget.quantity ?? 1;

        DocumentReference pRef = firestore.collection('products').doc(productId);
        DocumentSnapshot pSnap = await pRef.get();

        if (!pSnap.exists) throw "Produk tidak ditemukan.";
        int currentStock = int.tryParse(pSnap.get('stock').toString()) ?? 0;
        if (currentStock < qty) throw "Stok tidak mencukupi.";

        batch.update(pRef, {'stock': currentStock - qty});
        orderItems.add({
          'name': widget.product!['name'],
          'price': int.tryParse(widget.product!['price'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          'qty': qty,
          'image_url': widget.product!['image_url'],
        });
      }

      DocumentReference orderRef = firestore.collection('orders').doc();
      batch.set(orderRef, {
        'items': orderItems,
        'payment_method': _selectedMethod,
        'status': "success",
        'subtotal': subtotal,
        'total_payment': totalPayment,
        'user_id': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      if (mounted) _showSuccessDialog(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = _calculateSubtotal();
    double total = subtotal + _shippingFee + _serviceFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Konfirmasi Pesanan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4EAD))) 
        : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildSectionTitle("Daftar Produk"),
                      if (widget.isFromCart)
                        ...widget.cartItems!.map((item) => _buildModernItemTile(item, qyt: item['quantity'])).toList()
                      else
                        _buildModernItemTile(widget.product!, qyt: widget.quantity),
                      
                      const SizedBox(height: 25),
                      _buildSectionTitle("Metode Pembayaran"),
                      _buildPaymentCard(),
                      
                      const SizedBox(height: 25),
                      _buildSectionTitle("Ringkasan Biaya"),
                      _buildPriceSummary(subtotal, total),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(total),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
    );
  }

  Widget _buildModernItemTile(Map<String, dynamic> item, {int? qyt}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12), 
            child: Image.network(item['image_url'], width: 65, height: 65, fit: BoxFit.cover)
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("${qyt ?? 1} Barang", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Text("Rp ${item['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4EAD))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _customRadioTile("Transfer Bank (VA)", Icons.account_balance_rounded),
          const Divider(height: 1, indent: 50),
          _customRadioTile("E-Wallet (OVO/Dana)", Icons.account_balance_wallet_rounded),
        ],
      ),
    );
  }

  Widget _customRadioTile(String title, IconData icon) {
    bool isSelected = _selectedMethod == title;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = title),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF1B4EAD) : Colors.grey, size: 24),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.black : Colors.grey[700])),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF1B4EAD), size: 20)
            else Icon(Icons.circle_outlined, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(double subtotal, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _priceRow("Subtotal Produk", subtotal),
          _priceRow("Ongkos Kirim", _shippingFee.toDouble()),
          _priceRow("Biaya Layanan", _serviceFee.toDouble()),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text("Rp ${total.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B4EAD))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text("Rp ${amount.toInt()}", style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Total Tagihan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Rp ${total.toInt()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B4EAD))),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            width: 160,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4EAD),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Bayar Sekarang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text("Pembayaran Berhasil!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Pesanan Anda sedang diproses. Terima kasih telah berbelanja!", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4EAD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Kembali ke Beranda", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}