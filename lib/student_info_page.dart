import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadImagePath();
  }

  Future<void> _loadImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (path != null && File(path).existsSync()) {
      setState(() => _selectedImage = File(path));
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', pickedFile.path);
    }
  }

  void _saveProfile() {
    // 1. Validation
    if (_fName.text.isEmpty || _lName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in at least your First and Last name."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Logic for Saving (Supabase integration goes here later!)

    // 3. Success Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Profile saved successfully!"),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: Colors.red.shade900),
        ),
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
      appBar: AppBar(
        title: const Text("Student Profile", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.white)),
        backgroundColor: Colors.red.shade900,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                        child: _selectedImage == null 
                            ? Icon(BootstrapIcons.person_fill, size: 50, color: Colors.red.shade900) 
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red.shade900, width: 2),
                            ),
                            child: Icon(BootstrapIcons.camera_fill, size: 16, color: Colors.red.shade900),
                          ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("SAVE PROFILE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)),
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