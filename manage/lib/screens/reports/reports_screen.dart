import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../models/models.dart';
import '../../providers/auth_providers.dart';
import '../../providers/providers.dart';
import '../../utils/export_service.dart';
import '../../utils/responsive_layout.dart';

/// Report type enum
enum ReportType { inventory, financial, health, breeding, growth }

/// Export format enum
enum ExportFormat { pdf, csv, excel, json }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportType _selectedReport = ReportType.inventory;
  ExportFormat _selectedFormat = ExportFormat.pdf;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Export')),
      body: ResponsiveBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Type Selection
              const Text(
                'Select Report Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildReportTypeGrid(),
              const SizedBox(height: 24),

              // Date Range Selection (for applicable reports)
              if (_selectedReport != ReportType.inventory) ...[
                const Text(
                  'Date Range',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildDateRangeSelector(),
                const SizedBox(height: 24),
              ],

              // Export Format Selection
              const Text(
                'Export Format',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildFormatSelector(),
              const SizedBox(height: 24),

              // Report Preview / Description
              _buildReportDescription(),
              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isGenerating ? null : _generateReport,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.file_download),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate Report',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTypeGrid() {
    final reports = [
      _ReportOption(
        type: ReportType.inventory,
        icon: Icons.inventory_2,
        label: 'Inventory',
        description: 'Current animal stock',
        color: Colors.blue,
      ),
      _ReportOption(
        type: ReportType.financial,
        icon: Icons.attach_money,
        label: 'Financial',
        description: 'Income & expenses',
        color: Colors.green,
      ),
      _ReportOption(
        type: ReportType.health,
        icon: Icons.medical_services,
        label: 'Health',
        description: 'Vaccinations & treatments',
        color: Colors.red,
      ),
      _ReportOption(
        type: ReportType.breeding,
        icon: Icons.favorite,
        label: 'Breeding',
        description: 'Breeding records',
        color: Colors.pink,
      ),
      _ReportOption(
        type: ReportType.growth,
        icon: Icons.trending_up,
        label: 'Growth',
        description: 'Weight progression',
        color: Colors.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adaptive columns: 2 on mobile, 3 on tablet, 5 on desktop (all in one row)
        int columns;
        double aspectRatio;
        if (constraints.maxWidth > Breakpoints.desktop) {
          columns = 5;
          aspectRatio = 1.2;
        } else if (constraints.maxWidth > Breakpoints.tablet) {
          columns = 5;
          aspectRatio = 1.0;
        } else if (constraints.maxWidth > Breakpoints.mobile) {
          columns = 3;
          aspectRatio = 1.3;
        } else {
          columns = 2;
          aspectRatio = 1.5;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            final isSelected = _selectedReport == report.type;

            return InkWell(
              onTap: () => setState(() => _selectedReport = report.type),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? report.color.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? report.color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      report.icon,
                      size: 28,
                      color: isSelected ? report.color : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? report.color : Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      report.description,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.blue),
        title: Text(
          '${dateFormat.format(_dateRange.start)} - ${dateFormat.format(_dateRange.end)}',
        ),
        subtitle: Text(
          '${_dateRange.duration.inDays + 1} days',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.edit),
        onTap: _selectDateRange,
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildFormatOption(
            format: ExportFormat.pdf,
            icon: Icons.picture_as_pdf,
            label: 'PDF',
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFormatOption(
            format: ExportFormat.csv,
            icon: Icons.table_chart,
            label: 'CSV',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFormatOption(
            format: ExportFormat.excel,
            icon: Icons.grid_on,
            label: 'Excel',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFormatOption(
            format: ExportFormat.json,
            icon: Icons.data_object,
            label: 'JSON',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildFormatOption({
    required ExportFormat format,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedFormat == format;

    return InkWell(
      onTap: () => setState(() => _selectedFormat = format),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportDescription() {
    String title;
    String description;
    List<String> includes;

    switch (_selectedReport) {
      case ReportType.inventory:
        title = 'Animal Inventory Report';
        description = 'A complete list of all animals in your farm.';
        includes = [
          'Summary by breed and gender',
          'Animal details (tag, status, weight)',
          'Birth dates and sources',
        ];
        break;
      case ReportType.financial:
        title = 'Financial Report';
        description = 'Income and expense analysis for the selected period.';
        includes = [
          'Total income and expenses',
          'Category breakdown',
          'Net profit/loss calculation',
          'Transaction list',
        ];
        break;
      case ReportType.health:
        title = 'Health Report';
        description = 'Vaccination and treatment records.';
        includes = [
          'Vaccination history',
          'Treatment records',
          'Health checkups',
          'Upcoming due dates',
        ];
        break;
      case ReportType.breeding:
        title = 'Breeding Report';
        description = 'Breeding records and success rates.';
        includes = [
          'Breeding statistics',
          'Success rate analysis',
          'Expected farrow dates',
          'Litter information',
        ];
        break;
      case ReportType.growth:
        title = 'Growth Report';
        description = 'Weight progression and growth analysis.';
        includes = [
          'Weight records by animal',
          'Average daily gain',
          'Growth trends',
        ];
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getReportIcon(_selectedReport),
                  color: _getReportColor(_selectedReport),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            const Text(
              'Includes:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ...includes.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Text(item),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.inventory:
        return Icons.inventory_2;
      case ReportType.financial:
        return Icons.attach_money;
      case ReportType.health:
        return Icons.medical_services;
      case ReportType.breeding:
        return Icons.favorite;
      case ReportType.growth:
        return Icons.trending_up;
    }
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.inventory:
        return Colors.blue;
      case ReportType.financial:
        return Colors.green;
      case ReportType.health:
        return Colors.red;
      case ReportType.breeding:
        return Colors.pink;
      case ReportType.growth:
        return Colors.orange;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final currencyFormatter = ref.read(currencyFormatterProvider);
      final userAsync = ref.read(currentUserProvider);
      // Use activeFarm getter to get the correct active farm name
      final farmName = userAsync.value?.activeFarm?.farmName ?? 'Farm';

      debugPrint(
        'Generating ${_selectedReport.name} report in ${_selectedFormat.name} format',
      );

      final exportService = ExportService(
        currencyFormatter: currencyFormatter,
        farmName: farmName,
      );

      switch (_selectedReport) {
        case ReportType.inventory:
          await _generateInventoryReport(exportService);
          break;
        case ReportType.financial:
          await _generateFinancialReport(exportService);
          break;
        case ReportType.health:
          await _generateHealthReport(exportService);
          break;
        case ReportType.breeding:
          await _generateBreedingReport(exportService);
          break;
        case ReportType.growth:
          await _generateGrowthReport(exportService);
          break;
      }
    } catch (e, stackTrace) {
      debugPrint('Error generating report: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.red.shade100, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Error generating report: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateInventoryReport(ExportService exportService) async {
    final animalsAsync = ref.read(animalsProvider);
    final animals = animalsAsync.value ?? [];

    if (animals.isEmpty) {
      _showEmptyDataMessage('No animals found');
      return;
    }

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());

    switch (_selectedFormat) {
      case ExportFormat.pdf:
        final pdfBytes = await exportService.generateInventoryPdf(animals);
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'inventory_report_$dateStr.pdf',
        );
        break;
      case ExportFormat.csv:
        final csv = exportService.generateInventoryCsv(animals);
        await exportService.shareCsv(csv, 'inventory_report_$dateStr.csv');
        break;
      case ExportFormat.excel:
        final excelBytes = exportService.generateInventoryExcel(animals);
        await exportService.shareExcel(
          excelBytes,
          'inventory_report_$dateStr.xlsx',
        );
        break;
      case ExportFormat.json:
        final json = exportService.generateInventoryJson(animals);
        await exportService.shareJson(json, 'inventory_report_$dateStr.json');
        break;
    }

    _showSuccessMessage();
  }

  Future<void> _generateFinancialReport(ExportService exportService) async {
    final farmId = ref.read(activeFarmIdProvider);
    if (farmId == null) {
      _showEmptyDataMessage('No farm selected');
      return;
    }

    final repository = ref.read(financialRepositoryProvider);

    final summary = await repository.getFinancialSummary(
      farmId,
      startDate: _dateRange.start,
      endDate: _dateRange.end,
    );

    final transactions = await repository.getTransactions(farmId);
    final filteredTransactions = transactions.where((t) {
      return t.date.isAfter(
            _dateRange.start.subtract(const Duration(days: 1)),
          ) &&
          t.date.isBefore(_dateRange.end.add(const Duration(days: 1)));
    }).toList();

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());

    switch (_selectedFormat) {
      case ExportFormat.pdf:
        final pdfBytes = await exportService.generateFinancialPdf(
          summary: summary,
          transactions: filteredTransactions,
          startDate: _dateRange.start,
          endDate: _dateRange.end,
        );
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'financial_report_$dateStr.pdf',
        );
        break;
      case ExportFormat.csv:
        final csv = exportService.generateFinancialCsv(filteredTransactions);
        await exportService.shareCsv(csv, 'financial_report_$dateStr.csv');
        break;
      case ExportFormat.excel:
        final excelBytes = exportService.generateFinancialExcel(
          filteredTransactions,
        );
        await exportService.shareExcel(
          excelBytes,
          'financial_report_$dateStr.xlsx',
        );
        break;
      case ExportFormat.json:
        final json = exportService.generateFinancialJson(
          summary: summary,
          transactions: filteredTransactions,
          startDate: _dateRange.start,
          endDate: _dateRange.end,
        );
        await exportService.shareJson(json, 'financial_report_$dateStr.json');
        break;
    }

    _showSuccessMessage();
  }

  Future<void> _generateHealthReport(ExportService exportService) async {
    final healthAsync = ref.read(healthRecordsProvider);
    final records = healthAsync.value ?? [];

    final filteredRecords = records.where((r) {
      return r.date.isAfter(
            _dateRange.start.subtract(const Duration(days: 1)),
          ) &&
          r.date.isBefore(_dateRange.end.add(const Duration(days: 1)));
    }).toList();

    if (filteredRecords.isEmpty) {
      _showEmptyDataMessage('No health records in selected period');
      return;
    }

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());

    switch (_selectedFormat) {
      case ExportFormat.pdf:
        final pdfBytes = await exportService.generateHealthPdf(filteredRecords);
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'health_report_$dateStr.pdf',
        );
        break;
      case ExportFormat.csv:
        final csv = exportService.generateHealthCsv(filteredRecords);
        await exportService.shareCsv(csv, 'health_report_$dateStr.csv');
        break;
      case ExportFormat.excel:
        final excelBytes = exportService.generateHealthExcel(filteredRecords);
        await exportService.shareExcel(
          excelBytes,
          'health_report_$dateStr.xlsx',
        );
        break;
      case ExportFormat.json:
        final json = exportService.generateHealthJson(filteredRecords);
        await exportService.shareJson(json, 'health_report_$dateStr.json');
        break;
    }

    _showSuccessMessage();
  }

  Future<void> _generateBreedingReport(ExportService exportService) async {
    final breedingAsync = ref.read(breedingRecordsProvider);
    final records = breedingAsync.value ?? [];

    final filteredRecords = records.where((r) {
      return r.heatDate.isAfter(
            _dateRange.start.subtract(const Duration(days: 1)),
          ) &&
          r.heatDate.isBefore(_dateRange.end.add(const Duration(days: 1)));
    }).toList();

    if (filteredRecords.isEmpty) {
      _showEmptyDataMessage('No breeding records in selected period');
      return;
    }

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());

    switch (_selectedFormat) {
      case ExportFormat.pdf:
        final pdfBytes = await exportService.generateBreedingPdf(
          filteredRecords,
        );
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'breeding_report_$dateStr.pdf',
        );
        break;
      case ExportFormat.csv:
        final csv = exportService.generateBreedingCsv(filteredRecords);
        await exportService.shareCsv(csv, 'breeding_report_$dateStr.csv');
        break;
      case ExportFormat.excel:
        final excelBytes = exportService.generateBreedingExcel(filteredRecords);
        await exportService.shareExcel(
          excelBytes,
          'breeding_report_$dateStr.xlsx',
        );
        break;
      case ExportFormat.json:
        final json = exportService.generateBreedingJson(filteredRecords);
        await exportService.shareJson(json, 'breeding_report_$dateStr.json');
        break;
    }

    _showSuccessMessage();
  }

  Future<void> _generateGrowthReport(ExportService exportService) async {
    final animalsAsync = ref.read(animalsProvider);
    final animals = animalsAsync.value ?? [];

    if (animals.isEmpty) {
      _showEmptyDataMessage('No animals found');
      return;
    }

    final weightRepository = ref.read(weightRepositoryProvider);
    final Map<String, List<WeightRecord>> weightsByAnimal = {};

    for (final animal in animals) {
      final weights = await weightRepository.getWeightHistoryForAnimal(
        animal.id,
      );
      final filteredWeights = weights.where((w) {
        return w.date.isAfter(
              _dateRange.start.subtract(const Duration(days: 1)),
            ) &&
            w.date.isBefore(_dateRange.end.add(const Duration(days: 1)));
      }).toList();

      if (filteredWeights.isNotEmpty) {
        weightsByAnimal[animal.id] = filteredWeights;
      }
    }

    if (weightsByAnimal.isEmpty) {
      _showEmptyDataMessage('No weight records in selected period');
      return;
    }

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());

    switch (_selectedFormat) {
      case ExportFormat.pdf:
        final pdfBytes = await exportService.generateGrowthPdf(
          animals,
          weightsByAnimal,
        );
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'growth_report_$dateStr.pdf',
        );
        break;
      case ExportFormat.csv:
        final csv = exportService.generateGrowthCsv(animals, weightsByAnimal);
        await exportService.shareCsv(csv, 'growth_report_$dateStr.csv');
        break;
      case ExportFormat.excel:
        final excelBytes = exportService.generateGrowthExcel(
          animals,
          weightsByAnimal,
        );
        await exportService.shareExcel(
          excelBytes,
          'growth_report_$dateStr.xlsx',
        );
        break;
      case ExportFormat.json:
        final json = exportService.generateGrowthJson(animals, weightsByAnimal);
        await exportService.shareJson(json, 'growth_report_$dateStr.json');
        break;
    }

    _showSuccessMessage();
  }

  void _showEmptyDataMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade100,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade100,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text('Report generated successfully!'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ReportOption {
  final ReportType type;
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  _ReportOption({
    required this.type,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}
