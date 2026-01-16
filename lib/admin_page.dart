import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF1B4EAD);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: primaryColor,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Seller Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
            Text("Manage your business easily", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded, color: Colors.white)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: "Inventory"),
            Tab(text: "Orders"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          InventoryTab(),
          OrdersTab(),
        ],
      ),
    );
  }
}

class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  String _searchQuery = "";
  final _products = FirebaseFirestore.instance.collection('products');
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  void _showForm([DocumentSnapshot? doc]) {
    if (doc != null) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _priceController.text = (data['price'] ?? 0).toString();
      _imageController.text = data['image_url'] ?? '';
      _descController.text = data['description'] ?? '';
      _stockController.text = (data['stock'] ?? 0).toString();
    } else {
      _nameController.clear(); _priceController.clear(); _imageController.clear(); _descController.clear(); _stockController.clear();
    }

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          top: 25, left: 25, right: 25, 
          bottom: MediaQuery.of(context).viewInsets.bottom + 25
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(doc == null ? "Add New Product" : "Edit Product Information", 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B4EAD))),
              const SizedBox(height: 25),
              _buildTextField(_nameController, "Product Name", Icons.shopping_bag_outlined),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildTextField(_priceController, "Price (Rp)", Icons.payments_outlined, isNumber: true)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildTextField(_stockController, "Stock", Icons.inventory_2_outlined, isNumber: true)),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField(_imageController, "Image URL", Icons.image_outlined),
              const SizedBox(height: 15),
              _buildTextField(_descController, "Product Description", Icons.description_outlined, maxLines: 3),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4EAD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () async {
                    final data = {
                      "name": _nameController.text,
                      "price": int.tryParse(_priceController.text) ?? 0,
                      "stock": int.tryParse(_stockController.text) ?? 0,
                      "image_url": _imageController.text,
                      "description": _descController.text,
                    };
                    if (doc == null) { await _products.add(data); } 
                    else { await _products.doc(doc.id).update(data); }
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Save Product", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1B4EAD)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
    );
  }

  void _quickAddStock(DocumentSnapshot doc) {
    int currentStock = (doc.data() as Map<String, dynamic>)['stock'] ?? 0;
    doc.reference.update({'stock': currentStock + 1});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B4EAD),
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Product", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1B4EAD),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search inventory...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1B4EAD)),
                fillColor: Colors.white, filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _products.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs.where((doc) {
                  final name = (doc.data() as Map<String, dynamic>)['name']?.toString().toLowerCase() ?? '';
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (docs.isEmpty) return const Center(child: Text("No products found"));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) => ProductCard(
                    doc: docs[index],
                    onEdit: _showForm,
                    onDelete: (d) => _confirmDelete(context, d),
                    onQuickAdd: _quickAddStock,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product?"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () { doc.reference.delete(); Navigator.pop(context); }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }
}

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final order = doc.data() as Map<String, dynamic>;
            final String status = order['status'] ?? 'pending';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: ExpansionTile(
                title: Text("Order #${doc.id.substring(0,6).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Total: Rp ${order['total_payment'] ?? 0}"),
                trailing: _statusChip(status),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Divider(),
                        if (status != 'succes') Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.hourglass_bottom_rounded, size: 18), // SUDAH DIPERBAIKI (huruf kecil)
                                onPressed: () => doc.reference.update({'status': 'Diproses'}), 
                                label: const Text("Process"),
                              )
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                                onPressed: () => doc.reference.update({'status': 'succes'}), 
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green), 
                                label: const Text("Complete", style: TextStyle(color: Colors.white))
                              )
                            ),
                          ],
                        ) else const Text("✅ Transaction Completed", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusChip(String status) {
    Color color = status == 'succes' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class ProductCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Function(DocumentSnapshot) onEdit;
  final Function(DocumentSnapshot) onDelete;
  final Function(DocumentSnapshot) onQuickAdd;

  const ProductCard({super.key, required this.doc, required this.onEdit, required this.onDelete, required this.onQuickAdd});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; 
    int stock = data['stock'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailPage(data: data))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(data['image_url'] ?? '', width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey[100], child: const Icon(Icons.image_not_supported))),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Rp ${data['price'] ?? 0}", style: const TextStyle(color: Color(0xFF1B4EAD), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Stock: $stock", style: TextStyle(fontSize: 11, color: stock > 5 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => onQuickAdd(doc)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue), onPressed: () => onEdit(doc)),
                      IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), onPressed: () => onDelete(doc)),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const ProductDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    int stock = data['stock'] ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(data['name'] ?? "Detail")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(data['image_url'] ?? '', width: double.infinity, height: 300, fit: BoxFit.cover,
               errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 100)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? "", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Rp ${data['price']}", style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text("Stock: $stock"),
                  const Divider(),
                  const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(data['description'] ?? "-"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}