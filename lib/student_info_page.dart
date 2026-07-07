import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('student_details')
          .select()
          .eq('id', user.id)
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
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    debugPrint("Save button pressed"); // Verification
    if (_fName.text.isEmpty || _lName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in First and Last name.")));
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not logged in.")));
      return;
    }

    try {
      await Supabase.instance.client.from('student_details').upsert({
        'id': user.id,
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Profile saved successfully!"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      debugPrint("Error saving: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  final List<String> _barangays = [
    "Altura Bata", "Altura Matanda", "Altura South", "Ambulong", "Bagbag", "Bagumbayan",
    "Balele", "Bañadero", "Banjo East (Bungkalot)", "Banjo West (Banjo Laurel)",
    "Bilog-bilog", "Boot", "Cale", "Darasa", "Gonzales", "Hidalgo", "Janopol Oriental",
    "Janopol Occidental", "Laurel", "Luyos", "Mabini", "Malaking Pulo", "Maria Paz",
    "Montaña (Ik-ik)", "Maugat", "Natatas", "Pagaspas (Balokbalok)", "Pantay Bata",
    "Pantay Matanda", "Poblacion Barangay 1", "Poblacion Barangay 2", "Poblacion Barangay 3",
    "Poblacion Barangay 4", "Poblacion Barangay 5", "Poblacion Barangay 6", "Poblacion Barangay 7",
    "Sala", "Sambat", "San Jose", "Santol (Doña Jacoba Garcia)", "Santor", "Sulpoc",
    "Suplang", "Talaga", "Tinurik", "Trapiche", "Ulango", "Wawa"
  ];

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: Colors.red.shade900)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _bday.text = DateFormat('MMM dd, yyyy').format(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text("Student Profile", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)), backgroundColor: Colors.red.shade900, centerTitle: true),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 30, top: 10),
                    decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30))),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white,
                              backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                              child: _selectedImage == null ? Icon(BootstrapIcons.person_fill, size: 50, color: Colors.red.shade900) : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.red.shade900, width: 2)), child: Icon(BootstrapIcons.camera_fill, size: 16, color: Colors.red.shade900)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text("EDIT PROFILE", style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2.0)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
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
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                            child: const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 5, bottom: 10), child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade700))),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: Colors.red.shade800),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: _barangays.contains(_brgy.text) ? _brgy.text : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: Colors.red.shade800),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        items: _barangays.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
        onChanged: (val) => setState(() => _brgy.text = val!),
      ),
    );
  }
}