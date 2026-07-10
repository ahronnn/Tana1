import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmissionFormPage extends StatefulWidget {
  final bool isNewApplicant;

  const SubmissionFormPage({super.key, required this.isNewApplicant});

  @override
  State<SubmissionFormPage> createState() => _SubmissionFormPageState();
}

class _SubmissionFormPageState extends State<SubmissionFormPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // documentType -> picked file
  final Map<String, PlatformFile> _pickedFiles = {};
  bool _isSubmitting = false;

  List<String> get _requiredDocuments => widget.isNewApplicant
      ? const ["Application Letter", "Birth Certificate", "Proof of Enrollment"]
      : const ["Report Card / Transcript", "Updated Proof of Enrollment"];

  // Unified accent — matches the Application Hub's red palette for both flows.
  Color get _accent => Colors.red.shade800;
  Color get _accentSoft => Colors.red.shade50;

  int get _completedCount =>
      _requiredDocuments.where((doc) => _pickedFiles.containsKey(doc)).length;

  double get _progress =>
      _requiredDocuments.isEmpty ? 0 : _completedCount / _requiredDocuments.length;

  Future<void> _pickFile(String documentType) async {
    // file_picker 11.x uses static methods (FilePicker.pickFiles),
    // not the older instance-based FilePicker.platform.pickFiles.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true, // required explicitly in 11.x — no longer defaults to true
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFiles[documentType] = result.files.first;
      });
    }
  }

  void _removeFile(String documentType) {
    setState(() => _pickedFiles.remove(documentType));
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return BootstrapIcons.file_earmark_pdf_fill;
    if (['png', 'jpg', 'jpeg'].contains(ext)) return BootstrapIcons.file_earmark_image_fill;
    return BootstrapIcons.file_earmark_fill;
  }

  Future<void> _submit() async {
    // 1. Validate every required document has a file attached
    final missing = _requiredDocuments.where((doc) => !_pickedFiles.containsKey(doc)).toList();
    if (missing.isNotEmpty) {
      _showSnack("Please attach: ${missing.join(', ')}", isError: true);
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _showSnack("You must be logged in to submit.", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 2. Resolve the Supabase profile row linked to this Firebase user
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('firebase_uid', firebaseUser.uid)
          .maybeSingle();

      if (profile == null) {
        _showSnack("No matching profile found for this account.", isError: true);
        setState(() => _isSubmitting = false);
        return;
      }
      final String studentId = profile['id'] as String;

      // 3. Create the application row
      final insertedApplication = await _supabase
          .from('applications')
          .insert({'student_id': studentId})
          .select('id')
          .single();

      final String applicationId = insertedApplication['id'] as String;

      // 4. Upload each file to Storage, then log it in application_documents
      for (final entry in _pickedFiles.entries) {
        final documentType = entry.key;
        final file = entry.value;

        final safeName = file.name.replaceAll(RegExp(r'\s+'), '_');
        final storagePath = '$studentId/$applicationId/${documentType}_$safeName';

        if (file.bytes != null) {
          await _supabase.storage.from('application_documents').uploadBinary(
                storagePath,
                file.bytes!,
                fileOptions: const FileOptions(upsert: false),
              );
        } else if (file.path != null) {
          await _supabase.storage.from('application_documents').upload(
                storagePath,
                File(file.path!),
                fileOptions: const FileOptions(upsert: false),
              );
        } else {
          throw Exception('Could not read file: ${file.name}');
        }

        await _supabase.from('application_documents').insert({
          'application_id': applicationId,
          'document_type': documentType,
          'file_path': storagePath,
          'is_verified': false,
        });
      }

      _showSnack("Application submitted successfully!");
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showSnack("Submission failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _completedCount == _requiredDocuments.length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.isNewApplicant ? "New Application" : "Requirement Submission",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _accent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildProgressCard(),
            const SizedBox(height: 20),
            _buildUploadSection(),
            const SizedBox(height: 28),
            _buildSubmitButton(allDone),
            const SizedBox(height: 12),
            Center(
              child: Text(
                allDone
                    ? "All set — review your files, then submit."
                    : "${_requiredDocuments.length - _completedCount} document${_requiredDocuments.length - _completedCount == 1 ? '' : 's'} still needed.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_accent, Color.lerp(_accent, Colors.black, 0.15)!],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              widget.isNewApplicant
                  ? BootstrapIcons.person_plus_fill
                  : BootstrapIcons.file_earmark_arrow_up_fill,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isNewApplicant ? "New Applicant Requirements" : "Returning Availer Update",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isNewApplicant
                ? "Please attach the required documents for your initial application."
                : "Please upload your latest documents to renew your status.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Upload Progress",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$_completedCount / ${_requiredDocuments.length}",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(BootstrapIcons.file_earmark_text_fill, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              const Text(
                "Required Documents",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final documentType in _requiredDocuments) ...[
            _buildUploadTile(documentType),
            if (documentType != _requiredDocuments.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadTile(String documentType) {
    final pickedFile = _pickedFiles[documentType];
    final isDone = pickedFile != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50.withOpacity(0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? Colors.green.shade300 : Colors.grey.shade300,
          width: isDone ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _isSubmitting ? null : () => _pickFile(documentType),
          borderRadius: BorderRadius.circular(14),
          splashColor: _accent.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green.shade100 : _accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDone ? BootstrapIcons.check_circle_fill : _fileIconPlaceholder(),
                    size: 20,
                    color: isDone ? Colors.green.shade700 : _accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documentType,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      if (isDone)
                        Row(
                          children: [
                            Icon(_fileIcon(pickedFile.name), size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pickedFile.name,
                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (pickedFile.size > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                "· ${_formatBytes(pickedFile.size)}",
                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                              ),
                            ],
                          ],
                        )
                      else
                        Text(
                          "Tap to attach PDF or image",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isDone)
                  InkWell(
                    onTap: _isSubmitting ? null : () => _removeFile(documentType),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(BootstrapIcons.trash3, size: 16, color: Colors.red.shade400),
                    ),
                  )
                else
                  Icon(BootstrapIcons.chevron_right, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _fileIconPlaceholder() => BootstrapIcons.upload;

  Widget _buildSubmitButton(bool allDone) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: _accent.withOpacity(0.5),
          elevation: allDone ? 3 : 0,
          shadowColor: _accent.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "SUBMIT DOCUMENTS",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                  ),
                  const SizedBox(width: 8),
                  const Icon(BootstrapIcons.arrow_right_circle_fill, color: Colors.white, size: 18),
                ],
              ),
      ),
    );
  }
}