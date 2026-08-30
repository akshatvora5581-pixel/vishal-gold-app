import 'package:flutter/material.dart';
import '../../services/database_cleanup_service.dart';

class DatabaseCleanupScreen extends StatefulWidget {
  const DatabaseCleanupScreen({super.key});

  @override
  State<DatabaseCleanupScreen> createState() => _DatabaseCleanupScreenState();
}

class _DatabaseCleanupScreenState extends State<DatabaseCleanupScreen> {
  final DatabaseCleanupService _service = DatabaseCleanupService();
  final ScrollController _logScrollController = ScrollController();
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _service.progress.addListener(_onProgressUpdate);
    _addLog("Developer Cleanup Tool Initialized.");
    _addLog("WARNING: This operation is destructive.");
  }

  @override
  void dispose() {
    _service.progress.removeListener(_onProgressUpdate);
    _logScrollController.dispose();
    super.dispose();
  }

  void _onProgressUpdate() {
    if (!mounted) return;
    final progress = _service.progress.value;

    String message = "";
    switch (progress.stage) {
      case CleanupStage.fetching:
        message = "Fetching products: ${progress.totalFetched} found...";
        break;
      case CleanupStage.grouping:
        message = "Analyzing categories...";
        break;
      case CleanupStage.deleting:
        message = "Deleting products: ${progress.deletedCount} cumulative...";
        break;
      case CleanupStage.completed:
        message =
            "Successfully cleaned database! Total deleted: ${progress.deletedCount}";
        break;
      case CleanupStage.error:
        message = "CRITICAL ERROR: ${progress.error}";
        break;
      default:
        break;
    }

    if (message.isNotEmpty && (_logs.isEmpty || _logs.last != message)) {
      _addLog(message);
    }

    setState(() {}); // Refresh UI for progress bars
  }

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      _logs.add(
        "[${DateTime.now().toString().split(' ').last.substring(0, 8)}] $message",
      );
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _service.progress.value;
    final isRunning =
        progress.stage != CleanupStage.idle &&
        progress.stage != CleanupStage.completed &&
        progress.stage != CleanupStage.error;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Database Cleanup Utility',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityWarning(),
            const SizedBox(height: 24),
            _buildStatsSection(progress),
            const SizedBox(height: 24),
            const Text(
              "PROCESS LOG",
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            _buildLogTerminal(),
            const SizedBox(height: 24),
            _buildActionButtons(isRunning, progress.stage),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 8),
              const Text(
                "SECURITY PROTOCOL",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "1. Update Firestore Rules to 'allow delete: if true;' for /products collection.\n"
            "2. Run cleanup.\n"
            "3. REVERT Rules immediately after completion.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(CleanupProgress progress) {
    bool isDeleting = progress.stage == CleanupStage.deleting;
    bool isFetching = progress.stage == CleanupStage.fetching;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildStatRow("Total Fetched", "${progress.totalFetched}"),
          const Divider(color: Colors.white10, height: 24),
          _buildStatRow("Total Deleted", "${progress.deletedCount}"),
          const Divider(color: Colors.white10, height: 24),
          _buildStatRow("Progress", progress.stage.name.toUpperCase()),
          if (isDeleting || isFetching) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.white10,
                color: Colors.blueAccent,
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white60)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildLogTerminal() {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          controller: _logScrollController,
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                _logs[index],
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isRunning, CleanupStage stage) {
    if (stage == CleanupStage.completed) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
            foregroundColor: Colors.greenAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "CLOSE TOOL",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isRunning ? null : _service.runSubcategoryCleanup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isRunning && stage != CleanupStage.idle
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "CLEAN SUB-CATEGORIES",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isRunning ? null : _service.runCleanup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isRunning
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "NUKE PRODUCTS DATABASE",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
          ),
        ),
      ],
    );
  }
}
