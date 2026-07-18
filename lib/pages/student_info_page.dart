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

class _StudentInfoPageState extends State<StudentInfoPage> with TickerProviderStateMixin {
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

  // One-shot controller that staggers the hero header and the two form
  // cards + save button into view once the profile finishes loading —
  // same cascading fade-in language used across the rest of the app.
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _fadeIn(Widget child, {required double start, required double end}) {
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 16),
            child: child,
          ),
        );
      },
    );
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
      if (mounted) {
        setState(() => _isLoading = false);
        _entranceController.forward(from: 0);
      }
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
          _fadeIn(
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.red.shade800, Color.lerp(Colors.red.shade800, Colors.black, 0.24)!],
                  ),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 30),
                      child: Column(children: [
                        Text(
                          "STUDENT PROFILE",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Watermark rings, now centered directly behind
                            // the profile picture instead of the corner.
                            IgnorePointer(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [_ring(170), _ring(130), _ring(90)],
                              ),
                            ),
                            Stack(children: [
                          Container(
                            width: 96,
                            height: 96,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.25)],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 45, // fills the 96px ring (minus 3px padding each side)
                              backgroundColor: Colors.white,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?,
                              child: _selectedImage == null && _profileImageUrl == null
                                  ? Icon(BootstrapIcons.person_fill, size: 46, color: Colors.red.shade800)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.red.shade800, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Icon(BootstrapIcons.camera_fill, size: 15, color: Colors.red.shade800),
                              ),
                            ),
                          ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _fName.text.isNotEmpty ? "${_fName.text} ${_lName.text}".trim() : "Your Profile",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Tap the camera icon to update your photo",
                          style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ]),
                    ),
                    ),
                  ],
                ),
              ),
            ),
            start: 0.0,
            end: 0.4,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(children: [
              _fadeIn(
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
                start: 0.18,
                end: 0.55,
              ),
              const SizedBox(height: 20),
              _fadeIn(
                _buildFormCard("Academic Details", [
                  _buildTextField("School/University", _school, BootstrapIcons.mortarboard),
                  _buildTextField("Year Level", _year, BootstrapIcons.bar_chart),
                  _buildTextField("Contact Number", _contact, BootstrapIcons.phone, isNumber: true),
                  _buildTextField("Email Address", _email, BootstrapIcons.envelope),
                ]),
                start: 0.34,
                end: 0.7,
              ),
              const SizedBox(height: 30),
              _fadeIn(
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
                start: 0.48,
                end: 0.85,
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // A single faint ring outline — used to build the concentric watermark
  // that now sits centered directly behind the profile picture.
  Widget _ring(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.2),
        ),
      );

  Widget _buildFormCard(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 5, bottom: 10), child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade700, fontSize: 15))),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)), child: Column(children: children)),
    ]);
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18, color: Colors.red.shade800), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))));
  }

  // Each entry has a friendly "display" label (with local nicknames, shown
  // to students in the dropdown) and a "value" that is what actually gets
  // stored in student_details.barangay_id — value must match barangays.name
  // in Supabase EXACTLY (case + spelling), or the claim-location stub lookup
  // silently fails to "Not yet assigned."
  final List<Map<String, String>> _barangays = [
    {"display": "Altura Bata", "value": "Altura Bata"},
    {"display": "Altura Matanda", "value": "Altura Matanda"},
    {"display": "Altura South", "value": "Altura South"},
    {"display": "Ambulong", "value": "Ambulong"},
    {"display": "Bagbag", "value": "Bagbag"},
    {"display": "Bagumbayan", "value": "Bagumbayan"},
    {"display": "Balele", "value": "Balele"},
    {"display": "Bañadero", "value": "Bañadero"},
    {"display": "Banjo East (Bungkalot)", "value": "Banjo East"},
    {"display": "Banjo West (Banjo Laurel)", "value": "Banjo West"},
    {"display": "Bilog-bilog", "value": "Bilog-bilog"},
    {"display": "Boot", "value": "Boot"},
    {"display": "Cale", "value": "Cale"},
    {"display": "Darasa", "value": "Darasa"},
    {"display": "Gonzales", "value": "Gonzales"},
    {"display": "Hidalgo", "value": "Hidalgo"},
    {"display": "Janopol Oriental", "value": "Janopol Oriental"},
    {"display": "Janopol Occidental", "value": "Janopol"},
    {"display": "Laurel", "value": "Laurel"},
    {"display": "Luyos", "value": "Luyos"},
    {"display": "Mabini", "value": "Mabini"},
    {"display": "Malaking Pulo", "value": "Malaking Pulo"},
    {"display": "Maria Paz", "value": "Maria Paz"},
    {"display": "Montaña (Ik-ik)", "value": "Montaña"},
    {"display": "Maugat", "value": "Maugat"},
    {"display": "Natatas", "value": "Natatas"},
    {"display": "Pagaspas (Balokbalok)", "value": "Pagaspas"},
    {"display": "Pantay Bata", "value": "Pantay Bata"},
    {"display": "Pantay Matanda", "value": "Pantay Matanda"},
    {"display": "Poblacion Barangay 1", "value": "Poblacion 1"},
    {"display": "Poblacion Barangay 2", "value": "Poblacion 2"},
    {"display": "Poblacion Barangay 3", "value": "Poblacion 3"},
    {"display": "Poblacion Barangay 4", "value": "Poblacion 4"},
    {"display": "Poblacion Barangay 5", "value": "Poblacion 5"},
    {"display": "Poblacion Barangay 6", "value": "Poblacion 6"},
    {"display": "Poblacion Barangay 7", "value": "Poblacion 7"},
    {"display": "Sala", "value": "Sala"},
    {"display": "Sambat", "value": "Sambat"},
    {"display": "San Jose", "value": "San Jose"},
    {"display": "Santol (Doña Jacoba Garcia)", "value": "Santol"},
    {"display": "Santor", "value": "Santor"},
    {"display": "Sulpoc", "value": "Sulpoc"},
    {"display": "Suplang", "value": "Suplang"},
    {"display": "Talaga", "value": "Talaga"},
    {"display": "Tinurik", "value": "Tinurik"},
    {"display": "Trapiche", "value": "Trapiche"},
    {"display": "Ulango", "value": "Ulango"},
    {"display": "Wawa", "value": "WaWa"},
  ];

  Widget _buildDropdown(String label, IconData icon) {
    // _brgy.text stores the DB value, not the display label — match against
    // the "value" field so an existing profile's saved barangay still shows
    // as selected in the dropdown.
    final matchingValue = _barangays.any((b) => b["value"] == _brgy.text) ? _brgy.text : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: matchingValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: Colors.red.shade800),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        items: _barangays
            .map((b) => DropdownMenuItem(value: b["value"], child: Text(b["display"]!)))
            .toList(),
        onChanged: (val) => setState(() => _brgy.text = val!),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now(), builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: Colors.red.shade800)), child: child!));
    if (picked != null) setState(() => _bday.text = DateFormat('MMM dd, yyyy').format(picked));
  }
}