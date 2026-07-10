import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class StudentInfoPage extends StatefulWidget {
  const StudentInfoPage({super.key});

  @override
  State<StudentInfoPage> createState() => _StudentInfoPageState();
}

class _StudentInfoPageState extends State<StudentInfoPage> {
  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _mName = TextEditingController();
  final _age = TextEditingController();
  final _bday = TextEditingController();
  final _brgy = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _school = TextEditingController();
  final _year = TextEditingController();

  File? _selectedImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Looks up the profiles.id linked to this Firebase user, creating the
  // profiles row on the fly if it's somehow missing (e.g. registration
  // insert failed silently in the past).
  Future<String?> _resolveProfileId(fb_auth.User user) async {
    final existing = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('firebase_uid', user.uid)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final inserted = await Supabase.instance.client
        .from('profiles')
        .insert({
          'firebase_uid': user.uid,
          'first_name': '',
          'last_name': '',
          'role': 'student',
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      // We authenticate with FIREBASE, not Supabase Auth, so we must
      // read the current user from FirebaseAuth, not from Supabase.
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("DEBUG: No Firebase user session found.");
        return;
      }

      _profileId = await _resolveProfileId(user);

      final data = await Supabase.instance.client
          .from('student_details')
          .select()
          .eq('id', _profileId as Object)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _fName.text = data['first_name'] ?? '';
          _lName.text = data['last_name'] ?? '';
          _mName.text = data['middle_name'] ?? '';
          _age.text = (data['age']?.toString()) ?? '';
          _bday.text = data['birth_date'] ?? '';
          _brgy.text = data['barangay_id']?.toString() ?? '';
          _contact.text = data['contact_number'] ?? '';
          _email.text = data['email'] ?? '';
          _school.text = data['school_univ'] ?? '';
          _year.text = data['year_level'] ?? '';
          _profileImageUrl = data['image_url'];
        });
      } else {
        // No row yet — pre-fill email from Firebase so the field isn't empty.
        _email.text = user.email ?? '';
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not load profile: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error: User session not found. Please log in again."),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      // student_details.id is a FOREIGN KEY to profiles.id, so we must
      // resolve/create the matching profiles row first and reuse its id.
      _profileId ??= await _resolveProfileId(user);
      final profileId = _profileId!;

      String? imageUrl = _profileImageUrl;

      if (_selectedImage != null) {
        final fileName = 'profile_${user.uid}.jpg';
        final storage = Supabase.instance.client.storage.from('profile_images');
        await storage.upload(
          fileName,
          _selectedImage!,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
        // Bust cache so the new image shows immediately instead of a stale one.
        imageUrl = '${storage.getPublicUrl(fileName)}?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      // Upsert keyed on id (the primary key / FK to profiles.id).
      await Supabase.instance.client.from('student_details').upsert(
        {
          'id': profileId,
          'firebase_uid': user.uid,
          'first_name': _fName.text,
          'last_name': _lName.text,
          'middle_name': _mName.text,
          'age': int.tryParse(_age.text),
          'birth_date': _bday.text,
          'barangay_id': _brgy.text,
          'contact_number': _contact.text,
          'year_level': _year.text,
          'email': _email.text,
          'school_univ': _school.text,
          'image_url': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );

      setState(() {
        _profileImageUrl = imageUrl;
        _selectedImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Profile saved successfully!"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("Error saving: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Log Out?", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("You'll need to log in again to access your account."),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await fb_auth.FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Student Profile", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.red.shade800,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // fixes back arrow color
        actions: [
          IconButton(
            icon: const Icon(BootstrapIcons.box_arrow_right, color: Colors.white),
            tooltip: "Log Out",
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30, top: 10),
            decoration: BoxDecoration(color: Colors.red.shade800, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28))),
            child: Column(children: [
              Stack(children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?,
                  child: _selectedImage == null && _profileImageUrl == null ? Icon(BootstrapIcons.person_fill, size: 50, color: Colors.red.shade800) : null,
                ),
                Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _pickImage, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.red.shade800, width: 2)), child: Icon(BootstrapIcons.camera_fill, size: 16, color: Colors.red.shade800)))),
              ]),
              const SizedBox(height: 15),
              Text(
                _fName.text.isNotEmpty ? "${_fName.text} ${_lName.text}".trim() : "Your Profile",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text("Tap the camera icon to update your photo", style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(children: [
              _buildFormCard("Personal Information", [
                _buildTextField("First Name", _fName, BootstrapIcons.person),
                _buildTextField("Last Name", _lName, BootstrapIcons.person),
                _buildTextField("Middle Name", _mName, BootstrapIcons.person),
                Row(children: [
                  Expanded(child: _buildTextField("Age", _age, BootstrapIcons.calendar_event, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: InkWell(onTap: () => _selectDate(context), child: IgnorePointer(child: _buildTextField("Birthday", _bday, BootstrapIcons.cake)))),
                ]),
                _buildDropdown("Barangay", BootstrapIcons.geo_alt),
              ]),
              const SizedBox(height: 20),
              _buildFormCard("Academic Details", [
                _buildTextField("School/University", _school, BootstrapIcons.mortarboard),
                _buildTextField("Year Level", _year, BootstrapIcons.bar_chart),
                _buildTextField("Contact Number", _contact, BootstrapIcons.phone, isNumber: true),
                _buildTextField("Email Address", _email, BootstrapIcons.envelope),
              ]),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildFormCard(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 5, bottom: 10), child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade700, fontSize: 15))),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)), child: Column(children: children)),
    ]);
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18, color: Colors.red.shade800), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))));
  }

  final List<String> _barangays = ["Altura Bata", "Altura Matanda", "Altura South", "Ambulong", "Bagbag", "Bagumbayan", "Balele", "Bañadero", "Banjo East (Bungkalot)", "Banjo West (Banjo Laurel)", "Bilog-bilog", "Boot", "Cale", "Darasa", "Gonzales", "Hidalgo", "Janopol Oriental", "Janopol Occidental", "Laurel", "Luyos", "Mabini", "Malaking Pulo", "Maria Paz", "Montaña (Ik-ik)", "Maugat", "Natatas", "Pagaspas (Balokbalok)", "Pantay Bata", "Pantay Matanda", "Poblacion Barangay 1", "Poblacion Barangay 2", "Poblacion Barangay 3", "Poblacion Barangay 4", "Poblacion Barangay 5", "Poblacion Barangay 6", "Poblacion Barangay 7", "Sala", "Sambat", "San Jose", "Santol (Doña Jacoba Garcia)", "Santor", "Sulpoc", "Suplang", "Talaga", "Tinurik", "Trapiche", "Ulango", "Wawa"];

  Widget _buildDropdown(String label, IconData icon) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: DropdownButtonFormField<String>(value: _barangays.contains(_brgy.text) ? _brgy.text : null, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18, color: Colors.red.shade800), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), items: _barangays.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) => setState(() => _brgy.text = val!)));
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now(), builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: Colors.red.shade800)), child: child!));
    if (picked != null) setState(() => _bday.text = DateFormat('MMM dd, yyyy').format(picked));
  }
}