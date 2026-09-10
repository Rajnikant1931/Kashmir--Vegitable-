import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const KashmirVegitableApp());
}

class KashmirVegitableApp extends StatelessWidget {
  const KashmirVegitableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kashmir Vegitable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _admin(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kashmir Vegitable'),
        actions: [
          IconButton(
            tooltip: 'Admin',
            onPressed: () => _admin(context),
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').where('stock', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Products load error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No vegetables available yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              return Card(
                child: ListTile(
                  title: Text('${d['name'] ?? 'Vegetable'}'),
                  subtitle: Text('₹${d['price'] ?? 0} / ${d['unit'] ?? 'kg'}'),
                  trailing: const Icon(Icons.add_shopping_cart),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() { loading = true; error = null; });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      final uid = cred.user!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        await FirebaseAuth.instance.signOut();
        throw Exception('This account is not an admin.');
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPanelPage()));
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Login')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Admin Email')),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 16),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: loading ? null : login,
            child: loading ? const CircularProgressIndicator() : const Text('Login'),
          ),
        ],
      ),
    ),
  );
}

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  Future<void> addProduct(BuildContext context) async {
    final name = TextEditingController();
    final price = TextEditingController();
    final unit = TextEditingController(text: 'kg');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Add Vegetable'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
        TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
      ],
    ));
    if (ok == true && name.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('products').add({
        'name': name.text.trim(),
        'price': double.tryParse(price.text.trim()) ?? 0,
        'unit': unit.text.trim().isEmpty ? 'kg' : unit.text.trim(),
        'stock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateOrderStatus(DocumentSnapshot<Map<String, dynamic>> doc, String status) =>
      doc.reference.update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin Panel'),
      actions: [
        IconButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => addProduct(context),
      icon: const Icon(Icons.add),
      label: const Text('Vegetable'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Products', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('products').orderBy('name').snapshots(),
          builder: (_, s) {
            if (!s.hasData) return const CircularProgressIndicator();
            return Column(children: s.data!.docs.map((d) {
              final x = d.data();
              final stock = x['stock'] == true;
              return Card(child: ListTile(
                title: Text('${x['name'] ?? ''}'),
                subtitle: Text('₹${x['price'] ?? 0} / ${x['unit'] ?? 'kg'}'),
                trailing: Switch(value: stock, onChanged: (v) => d.reference.update({'stock': v})),
              ));
            }).toList());
          },
        ),
        const SizedBox(height: 20),
        const Text('Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
          builder: (_, s) {
            if (!s.hasData) return const CircularProgressIndicator();
            return Column(children: s.data!.docs.map((d) {
              final x = d.data();
              final status = (x['status'] ?? 'Pending').toString();
              return Card(child: ListTile(
                title: Text('Order ${d.id.substring(0, 6)} • ₹${x['total'] ?? 0}'),
                subtitle: Text('${x['paymentMethod'] ?? 'COD'} • ${x['address'] ?? ''}'),
                trailing: DropdownButton<String>(
                  value: ['Pending','Packed','Out for Delivery','Delivered'].contains(status) ? status : 'Pending',
                  items: ['Pending','Packed','Out for Delivery','Delivered'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) { if (v != null) updateOrderStatus(d, v); },
                ),
              ));
            }).toList());
          },
        ),
      ],
    ),
  );
}
