import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  void _showEditProfileDialog(Map<String, dynamic>? userData) {
    final TextEditingController nameController = 
        TextEditingController(text: userData?['fullname'] ?? "");
    final TextEditingController phoneController = 
        TextEditingController(text: userData?['phone'] ?? "");
    final TextEditingController addressController = 
        TextEditingController(text: userData?['address'] ?? "");
    final TextEditingController photoController = 
        TextEditingController(text: userData?['photo_url'] ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nama Lengkap", prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Nomor Telepon", prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Alamat", prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: photoController,
                decoration: const InputDecoration(
                  labelText: "Link URL Foto Profil", 
                  prefixIcon: Icon(Icons.link),
                  hintText: "https://example.com/foto.jpg"
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                  'fullname': nameController.text,
                  'phone': phoneController.text,
                  'address': addressController.text,
                  'photo_url': photoController.text, 
                });
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profil berhasil diperbarui!")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Gagal update: $e"), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4EAD)),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Profil Saya", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B4EAD),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data tidak ditemukan"));
          }

          Map<String, dynamic>? userData = snapshot.data?.data() as Map<String, dynamic>?;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(userData),
                const SizedBox(height: 20),
                _buildMenuSection(context, userData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? userData) {
    String? photoUrl = userData?['photo_url'];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1B4EAD),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 52,
              backgroundColor: Colors.grey[200],
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
                  ? NetworkImage(photoUrl) 
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? const Icon(Icons.person, size: 60, color: Color(0xFF1B4EAD)) 
                  : null,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            userData?['fullname'] ?? "User eTrade",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(
            user?.email ?? "email@tidakditemukan.com",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, Map<String, dynamic>? userData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _profileMenuTile(Icons.person_outline, "Edit Profil", () => _showEditProfileDialog(userData)),
          _profileMenuTile(Icons.history, "Riwayat Pesanan", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage()));
          }),
          _profileMenuTile(Icons.help_outline, "Pusat Bantuan", () {
            showAboutDialog(
              context: context,
              applicationName: "eTrade App",
              applicationVersion: "1.0.0",
              children: [const Text("Hubungi admin untuk bantuan lebih lanjut.")],
            );
          }),
          const SizedBox(height: 20),
          _profileMenuTile(Icons.logout, "Keluar Aplikasi", () => _showLogoutConfirm(), color: Colors.red),
        ],
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _profileMenuTile(IconData icon, String title, VoidCallback onTap, {Color color = Colors.black87}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}