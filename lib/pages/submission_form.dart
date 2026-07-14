import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SCHEMA NOTE — this screen now reads/writes a per-document `status` and
/// `rejection_reason` on `application_documents`, instead of relying only on
/// the old `is_verified` boolean. If your table doesn't have these columns
/// yet, add them (Supabase SQL editor):
///
///   ALTER TABLE application_documents
///     ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending'
///       CHECK (status IN ('pending', 'approved', 'rejected')),
///     ADD COLUMN IF NOT EXISTS rejection_reason text;
///
/// Reviewers (admin side) approve/reject a document by setting `status` to
/// 'approved' or 'rejected' (optionally with a `rejection_reason'). This
/// screen reacts to that automatically the next time the applicant opens it.
///
/// Backward compatibility: if `status` is missing/null on a row, it's
/// derived from `is_verified` (true -> approved, false -> pending) so
/// existing rows keep working without a migration.

/// Local, in-memory representation of one required document's server state.
class _DocState {
  final String status; // 'none' | 'pending' | 'approved' | 'rejected'
  final String? filePath;
  final String? fileName;
  final String? rejectionReason;
  // application_documents.id is a bigint in Supabase, not a uuid/string —
  // keep it as int here so we don't have to cast it awkwardly at every
  // call site (and so `type 'int' is not a subtype of 'String?'` can't happen).
  final int? documentId;

  const _DocState({
    this.status = 'none',
    this.filePath,
    this.fileName,
    this.rejectionReason,
    this.documentId,
  });

  // Approved or pending-review documents are locked — already submitted,
  // can't be touched again. Only 'none' (never uploaded) or 'rejected'
  // (needs a fix) can be tapped to upload/re-upload.
  bool get isLocked => status == 'pending' || status == 'approved';
  bool get canUpload => status == 'none' || status == 'rejected';
}

class SubmissionFormPage extends StatefulWidget {
  final bool isNewApplicant;

  const SubmissionFormPage({super.key, required this.isNewApplicant});

  @override
  State<SubmissionFormPage> createState() => _SubmissionFormPageState();
}

class _SubmissionFormPageState extends State<SubmissionFormPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _studentId;
  String? _applicationId;

  bool _loading = true;
  bool _isFinalizing = false;

  // documentType -> current server-backed state (persists across navigation
  // because it's re-fetched from Supabase every time this page opens).
  final Map<String, _DocState> _docStates = {};

  // documentType -> currently uploading (shows an inline spinner on that tile).
  final Set<String> _uploadingTypes = {};

  // Must match application_documents_document_type_check in Supabase
  // EXACTLY (case, spacing, punctuation) — the DB rejects anything else.
  List<String> get _requiredDocuments => widget.isNewApplicant
      ? const ["Certificate of Residency", "Certificate of Indigency", "Report Card / TOR", "School ID"]
      : const ["Report Card / TOR", "School ID"];

  // Unified accent — matches the Application Hub's red palette for both flows.
  Color get _accent => Colors.red.shade800;
  Color get _accentSoft => Colors.red.shade50;

  _DocState _stateOf(String documentType) => _docStates[documentType] ?? const _DocState();

  // Only pending/approved documents count as "done" — a rejected document
  // drops back out of this count automatically, which is what pulls the
  // progress bar down until it's fixed and re-uploaded.
  int get _completedCount =>
      _requiredDocuments.where((doc) => _stateOf(doc).isLocked).length;

  double get _progress =>
      _requiredDocuments.isEmpty ? 0 : _completedCount / _requiredDocuments.length;

  int get _rejectedCount =>
      _requiredDocuments.where((doc) => _stateOf(doc).status == 'rejected').length;

  bool get _hasOutstandingWork =>
      _requiredDocuments.any((doc) => _stateOf(doc).canUpload);

  @override
  void initState() {
    super.initState();
    for (final doc in _requiredDocuments) {
      _docStates[doc] = const _DocState();
    }
    _loadExistingState();
  }

  Future<void> _loadExistingState() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final studentId = await _resolveStudentId(firebaseUser.uid);
      if (studentId == null) return;
      _studentId = studentId;

      // Resume the most recent application of THIS flow's type for this
      // student, if any, so anything already uploaded (and its
      // approve/reject state) reloads exactly as it was left. Filtering by
      // application_type is what keeps New Application and Repeat Availer
      // from ever picking up each other's application/documents.
      final application = await _supabase
          .from('applications')
          .select('id')
          .eq('student_id', studentId)
          .eq('application_type', widget.isNewApplicant ? 'new' : 'returning')
          .order('applied_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (application == null) return;
      _applicationId = application['id'] as String;

      final docs = await _supabase
          .from('application_documents')
          .select('id, document_type, file_path, status, is_verified, rejection_reason')
          .eq('application_id', _applicationId as Object);

      for (final row in (docs as List)) {
        final type = row['document_type'] as String?;
        if (type == null || !_requiredDocuments.contains(type)) continue;

        final rawStatus = row['status'] as String?;
        final status = rawStatus ?? ((row['is_verified'] == true) ? 'approved' : 'pending');
        final path = row['file_path'] as String?;

        _docStates[type] = _DocState(
          status: status,
          filePath: path,
          fileName: path != null ? path.split('/').last : null,
          rejectionReason: row['rejection_reason'] as String?,
          documentId: row['id'] as int?,
        );
      }
    } catch (e) {
      debugPrint("Error loading existing documents: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _resolveStudentId(String firebaseUid) async {
    final profile = await _supabase
        .from('profiles')
        .select('id')
        .eq('firebase_uid', firebaseUid)
        .maybeSingle();
    return profile?['id'] as String?;
  }

  /// Returns a live, verified application id for THIS flow's type
  /// ('new' or 'returning').
  ///
  /// Pass [forceNew] to skip the cached `_applicationId` and always insert a
  /// fresh row — used when we've just found out the cached id no longer
  /// exists on the server (e.g. it was deleted while this page's State
  /// object stayed alive across a hot reload).
  Future<String> _getOrCreateApplicationId(String studentId, {bool forceNew = false}) async {
    if (_applicationId != null && !forceNew) return _applicationId!;

    final type = widget.isNewApplicant ? 'new' : 'returning';

    // Double-check there isn't already a live application of this type
    // before creating a new one (covers the case where _applicationId was
    // never loaded, e.g. _loadExistingState hadn't finished yet).
    if (!forceNew) {
      final existing = await _supabase
          .from('applications')
          .select('id')
          .eq('student_id', studentId)
          .eq('application_type', type)
          .order('applied_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (existing != null) {
        _applicationId = existing['id'] as String;
        return _applicationId!;
      }
    }

    // NOTE: 'status' is set explicitly here rather than relying on the
    // applications.status column default. The default happens to be
    // 'Pending' today, but pinning it in code means a future change to
    // the DB default can never silently put new applications into the
    // wrong state (e.g. showing as "Approved" before anything was
    // reviewed).
    final inserted = await _supabase
        .from('applications')
        .insert({
          'student_id': studentId,
          'application_type': type,
          'status': 'Pending',
        })
        .select('id')
        .single();
    _applicationId = inserted['id'] as String;
    return _applicationId!;
  }

  /// Uploads the file bytes/path to storage, then inserts or updates the
  /// matching `application_documents` row. Pulled out of `_pickAndUpload` so
  /// it can be retried with a freshly created `applicationId` if the first
  /// attempt fails because the cached id is stale (FK violation, code 23503).
  Future<void> _uploadDocumentRow({
    required String documentType,
    required PlatformFile file,
    required _DocState current,
    required String applicationId,
  }) async {
    final safeName = file.name.replaceAll(RegExp(r'\s+'), '_');
    final storagePath =
        '$_studentId/$applicationId/${documentType}_${DateTime.now().millisecondsSinceEpoch}_$safeName';

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

    final int? existingId = current.documentId;
    if (existingId != null) {
      // Re-uploading a previously rejected document — update the same
      // row in place and flip it back to pending review.
      await _supabase.from('application_documents').update({
        'application_id': applicationId,
        'file_path': storagePath,
        'status': 'pending',
        'is_verified': false,
        'rejection_reason': null,
      }).eq('id', existingId);

      setState(() {
        _docStates[documentType] = _DocState(
          status: 'pending',
          filePath: storagePath,
          fileName: file.name,
          documentId: existingId,
        );
      });
    } else {
      final inserted = await _supabase.from('application_documents').insert({
        'application_id': applicationId,
        'document_type': documentType,
        'file_path': storagePath,
        'status': 'pending',
        'is_verified': false,
      }).select('id').single();

      setState(() {
        _docStates[documentType] = _DocState(
          status: 'pending',
          filePath: storagePath,
          fileName: file.name,
          documentId: inserted['id'] as int?,
        );
      });
    }
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

  /// Picking a file immediately uploads it and writes/updates the
  /// application_documents row — this is what makes progress persist across
  /// navigation. Locked tiles (pending/approved) ignore taps entirely.
  Future<void> _pickAndUpload(String documentType) async {
    final current = _stateOf(documentType);
    if (!current.canUpload || _uploadingTypes.contains(documentType)) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _showSnack("You must be logged in to upload.", isError: true);
      return;
    }

    setState(() => _uploadingTypes.add(documentType));

    try {
      _studentId ??= await _resolveStudentId(firebaseUser.uid);
      if (_studentId == null) {
        _showSnack("No matching profile found for this account.", isError: true);
        return;
      }

      final applicationId = await _getOrCreateApplicationId(_studentId!);

      try {
        await _uploadDocumentRow(
          documentType: documentType,
          file: file,
          current: current,
          applicationId: applicationId,
        );
      } on PostgrestException catch (e) {
        if (e.code == '23503') {
          // Stale application_id — the cached row no longer exists on the
          // server (e.g. deleted during testing while this State object
          // survived a hot reload). Create a fresh application and retry once.
          final freshId = await _getOrCreateApplicationId(_studentId!, forceNew: true);
          await _uploadDocumentRow(
            documentType: documentType,
            file: file,
            current: current,
            applicationId: freshId,
          );
        } else {
          rethrow;
        }
      }

      _showSnack("$documentType uploaded — awaiting review.");
    } catch (e) {
      _showSnack("Upload failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _uploadingTypes.remove(documentType));
    }
  }

  /// Every document is already uploaded and stored the moment it's picked,
  /// so "finalizing" just confirms the application is ready for review once
  /// nothing is missing or still rejected.
  Future<void> _finalize() async {
    if (_hasOutstandingWork) {
      _showSnack("Please attach or re-upload all required documents first.", isError: true);
      return;
    }
    if (_applicationId == null) {
      _showSnack("Nothing to submit yet.", isError: true);
      return;
    }

    setState(() => _isFinalizing = true);
    try {
      await _supabase.from('applications').update({'status': 'Pending'}).eq('id', _applicationId as Object);
      _showSnack("Application submitted for review!");
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showSnack("Submission failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _accent))
          : SingleChildScrollView(
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
                  _buildSubmitButton(),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _statusFootnote(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _statusFootnote() {
    if (_rejectedCount > 0) {
      return "$_rejectedCount document${_rejectedCount == 1 ? '' : 's'} need${_rejectedCount == 1 ? 's' : ''} to be re-uploaded.";
    }
    if (_hasOutstandingWork) {
      final remaining = _requiredDocuments.length - _completedCount;
      return "$remaining document${remaining == 1 ? '' : 's'} still needed.";
    }
    return "All set — your documents are submitted for review.";
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
          if (_rejectedCount > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(BootstrapIcons.exclamation_triangle_fill, size: 13, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "$_rejectedCount rejected — re-upload to continue.",
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ],
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
    final state = _stateOf(documentType);
    final isUploading = _uploadingTypes.contains(documentType);

    late final Color bg;
    late final Color border;
    late final Color iconBg;
    late final Color iconColor;
    late final IconData icon;
    late final String title;

    switch (state.status) {
      case 'approved':
        bg = Colors.green.shade50.withOpacity(0.5);
        border = Colors.green.shade300;
        iconBg = Colors.green.shade100;
        iconColor = Colors.green.shade700;
        icon = BootstrapIcons.check_circle_fill;
        title = "Approved";
        break;
      case 'pending':
        bg = Colors.blue.shade50.withOpacity(0.5);
        border = Colors.blue.shade200;
        iconBg = Colors.blue.shade100;
        iconColor = Colors.blue.shade700;
        icon = BootstrapIcons.hourglass_split;
        title = "Submitted — awaiting review";
        break;
      case 'rejected':
        bg = Colors.red.shade50.withOpacity(0.6);
        border = Colors.red.shade200;
        iconBg = Colors.red.shade100;
        iconColor = Colors.red.shade700;
        icon = BootstrapIcons.x_circle_fill;
        title = "Rejected — tap to re-upload";
        break;
      default:
        bg = Colors.grey.shade50;
        border = Colors.grey.shade300;
        iconBg = _accentSoft;
        iconColor = _accent;
        icon = BootstrapIcons.upload;
        title = "Tap to attach PDF or image";
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: state.isLocked || state.status == 'rejected' ? 1.4 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: (state.canUpload && !isUploading) ? () => _pickAndUpload(documentType) : null,
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
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: isUploading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: iconColor),
                        )
                      : Icon(icon, size: 20, color: iconColor),
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
                      if (isUploading)
                        Text("Uploading…", style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                      else if (state.fileName != null)
                        Row(
                          children: [
                            Icon(_fileIcon(state.fileName!), size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                state.fileName!,
                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      if (state.status != 'none' && state.fileName != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                          ),
                        ),
                      ],
                      if (state.status == 'rejected' &&
                          state.rejectionReason != null &&
                          state.rejectionReason!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          "Reason: ${state.rejectionReason}",
                          style: TextStyle(fontSize: 11, color: Colors.red.shade700, height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (state.isLocked)
                  Icon(BootstrapIcons.lock_fill, size: 15, color: Colors.grey.shade400)
                else if (!isUploading)
                  Icon(BootstrapIcons.chevron_right, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final ready = !_hasOutstandingWork;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_isFinalizing || !ready) ? null : _finalize,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: _accent.withOpacity(0.5),
          elevation: ready ? 3 : 0,
          shadowColor: _accent.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isFinalizing
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