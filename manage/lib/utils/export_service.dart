import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/models.dart';
import 'currency_utils.dart';
import 'file_saver.dart' as file_saver;
import 'web_download.dart' as web_download;

/// Service for exporting data in various formats (PDF, CSV, Excel, JSON)
class ExportService {
  final CurrencyFormatter currencyFormatter;
  final String farmName;

  ExportService({required this.currencyFormatter, required this.farmName});

  // ==================== ANIMAL INVENTORY REPORT ====================

  /// Generate inventory report as PDF
  Future<Uint8List> generateInventoryPdf(List<Animal> animals) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');
    final now = DateTime.now();

    // Group animals by species
    final Map<String, List<Animal>> bySpecies = {};
    for (final animal in animals) {
      bySpecies.putIfAbsent(animal.species.displayName, () => []).add(animal);
    }

    // Summary stats
    final totalAnimals = animals.length;
    final maleCount = animals.where((a) => a.gender == Gender.male).length;
    final femaleCount = animals.where((a) => a.gender == Gender.female).length;
    final healthyCount = animals
        .where((a) => a.status == AnimalStatus.healthy)
        .length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('Animal Inventory Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox('Total', totalAnimals.toString()),
                _buildStatBox('Male', maleCount.toString()),
                _buildStatBox('Female', femaleCount.toString()),
                _buildStatBox('Healthy', healthyCount.toString()),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // By Species Breakdown
          pw.Text(
            'Inventory by Species',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          ...bySpecies.entries.map((entry) {
            final speciesName = entry.key;
            final speciesAnimals = entry.value;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: PdfColors.grey200,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          speciesName,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('${speciesAnimals.length} animals'),
                      ],
                    ),
                  ),
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    cellHeight: 25,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.center,
                      2: pw.Alignment.center,
                      3: pw.Alignment.center,
                      4: pw.Alignment.centerRight,
                    },
                    headers: [
                      'Name',
                      'Gender',
                      'Status',
                      'Birth Date',
                      'Weight',
                    ],
                    data: speciesAnimals.map((a) {
                      return [
                        a.name,
                        a.gender.name.toUpperCase(),
                        a.status.name,
                        a.birthDate != null
                            ? dateFormat.format(a.birthDate!)
                            : 'N/A',
                        a.currentWeight != null
                            ? '${a.currentWeight!.toStringAsFixed(1)} kg'
                            : 'N/A',
                      ];
                    }).toList(),
                  ),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 20),
          pw.Text(
            'Report generated on ${dateFormat.format(now)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate inventory report as CSV
  String generateInventoryCsv(List<Animal> animals) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final headers = [
      'Tag ID',
      'Name',
      'Species',
      'Breed',
      'Gender',
      'Status',
      'Birth Date',
      'Age',
      'Current Weight (kg)',
      'Notes',
    ];

    final rows = animals.map((a) {
      return [
        a.tagId,
        a.name ?? '',
        a.species.displayName,
        a.breed ?? '',
        a.gender.name,
        a.status.name,
        a.birthDate != null ? dateFormat.format(a.birthDate!) : '',
        a.ageFormatted,
        a.currentWeight?.toStringAsFixed(1) ?? '',
        a.notes ?? '',
      ];
    }).toList();

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  // ==================== FINANCIAL REPORT ====================

  /// Generate financial report as PDF
  Future<Uint8List> generateFinancialPdf({
    required FinancialSummary summary,
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');

    // Group transactions by type
    final incomeTransactions = transactions.where((t) => t.isIncome).toList();
    final expenseTransactions = transactions.where((t) => t.isExpense).toList();

    // Group expenses by category
    final Map<String, double> expensesByCategory = {};
    for (final t in expenseTransactions) {
      expensesByCategory[t.category] =
          (expensesByCategory[t.category] ?? 0) + t.amount;
    }

    // Group income by category
    final Map<String, double> incomeByCategory = {};
    for (final t in incomeTransactions) {
      incomeByCategory[t.category] =
          (incomeByCategory[t.category] ?? 0) + t.amount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('Financial Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Period
          pw.Text(
            'Period: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),

          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBox(
                      'Total Income',
                      currencyFormatter.format(summary.totalIncome),
                    ),
                    _buildStatBox(
                      'Total Expenses',
                      currencyFormatter.format(summary.totalExpenses),
                    ),
                    _buildStatBox(
                      summary.netProfit >= 0 ? 'Net Profit' : 'Net Loss',
                      currencyFormatter.format(summary.netProfit.abs()),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Income by Category
          if (incomeByCategory.isNotEmpty) ...[
            pw.Text(
              'Income by Category',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.green100,
              ),
              cellHeight: 25,
              headers: ['Category', 'Amount'],
              data: incomeByCategory.entries.map((e) {
                return [
                  _formatCategory(e.key),
                  currencyFormatter.format(e.value),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Expenses by Category
          if (expensesByCategory.isNotEmpty) ...[
            pw.Text(
              'Expenses by Category',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.red100),
              cellHeight: 25,
              headers: ['Category', 'Amount'],
              data: expensesByCategory.entries.map((e) {
                return [
                  _formatCategory(e.key),
                  currencyFormatter.format(e.value),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Recent Transactions
          pw.Text(
            'Transaction Details',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            cellHeight: 22,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
            },
            headers: ['Date', 'Type', 'Description', 'Amount'],
            data: transactions.take(50).map((t) {
              return [
                dateFormat.format(t.date),
                t.isIncome ? 'Income' : 'Expense',
                t.description,
                '${t.isIncome ? '+' : '-'}${currencyFormatter.format(t.amount)}',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate financial report as CSV
  String generateFinancialCsv(List<Transaction> transactions) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final headers = [
      'Date',
      'Type',
      'Category',
      'Amount',
      'Description',
      'Animal ID',
      'Payment Method',
      'Reference Number',
      'Notes',
    ];

    final rows = transactions.map((t) {
      return [
        dateFormat.format(t.date),
        t.type.name,
        t.category,
        t.amount.toString(),
        t.description,
        t.animalId ?? '',
        t.paymentMethod?.name ?? '',
        t.referenceNumber ?? '',
        t.notes ?? '',
      ];
    }).toList();

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  Future<Uint8List> generateHealthPdf(List<HealthRecord> records) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');

    // Group by type
    final vaccinations = records
        .where((r) => r.type == HealthRecordType.vaccination)
        .toList();
    final treatments = records
        .where((r) => r.type == HealthRecordType.treatment)
        .toList();
    final checkups = records
        .where((r) => r.type == HealthRecordType.checkup)
        .toList();
    final medications = records
        .where((r) => r.type == HealthRecordType.medication)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('Health Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox('Total Records', records.length.toString()),
                _buildStatBox('Vaccinations', vaccinations.length.toString()),
                _buildStatBox('Treatments', treatments.length.toString()),
                _buildStatBox('Checkups', checkups.length.toString()),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Vaccinations
          if (vaccinations.isNotEmpty) ...[
            pw.Text(
              'Vaccinations',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.teal100,
              ),
              cellHeight: 25,
              headers: ['Date', 'Animal', 'Vaccine', 'Next Due'],
              data: vaccinations.map((r) {
                return [
                  dateFormat.format(r.date),
                  r.animalTagId ?? r.animalId,
                  r.vaccineName ?? r.title,
                  r.nextDueDate != null
                      ? dateFormat.format(r.nextDueDate!)
                      : '-',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Treatments
          if (treatments.isNotEmpty) ...[
            pw.Text(
              'Treatments',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.orange100,
              ),
              cellHeight: 25,
              headers: ['Date', 'Animal', 'Diagnosis', 'Treatment', 'Status'],
              data: treatments.map((r) {
                return [
                  dateFormat.format(r.date),
                  r.animalTagId ?? r.animalId,
                  r.diagnosis ?? '-',
                  r.treatment ?? r.title,
                  r.status.name,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Medications
          if (medications.isNotEmpty) ...[
            pw.Text(
              'Medications',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.purple100,
              ),
              cellHeight: 25,
              headers: ['Date', 'Animal', 'Medication', 'Dosage', 'Status'],
              data: medications.map((r) {
                return [
                  dateFormat.format(r.date),
                  r.animalTagId ?? r.animalId,
                  r.medicationName ?? r.title,
                  r.dosage ?? '-',
                  r.status.name,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Checkups
          if (checkups.isNotEmpty) ...[
            pw.Text(
              'Checkups',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue100,
              ),
              cellHeight: 25,
              headers: ['Date', 'Animal', 'Title', 'Notes', 'Status'],
              data: checkups.map((r) {
                return [
                  dateFormat.format(r.date),
                  r.animalTagId ?? r.animalId,
                  r.title,
                  r.description ?? '-',
                  r.status.name,
                ];
              }).toList(),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate health report as CSV
  String generateHealthCsv(List<HealthRecord> records) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final headers = [
      'Date',
      'Animal ID',
      'Animal Tag',
      'Type',
      'Title',
      'Description',
      'Diagnosis',
      'Treatment',
      'Medication',
      'Dosage',
      'Status',
      'Next Due Date',
      'Follow Up Date',
      'Cost',
    ];

    final rows = records.map((r) {
      return [
        dateFormat.format(r.date),
        r.animalId,
        r.animalTagId ?? '',
        r.type.name,
        r.title,
        r.description ?? '',
        r.diagnosis ?? '',
        r.treatment ?? '',
        r.medicationName ?? '',
        r.dosage ?? '',
        r.status.name,
        r.nextDueDate != null ? dateFormat.format(r.nextDueDate!) : '',
        r.followUpDate != null ? dateFormat.format(r.followUpDate!) : '',
        r.cost?.toString() ?? '',
      ];
    }).toList();

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  // ==================== BREEDING REPORT ====================

  /// Generate breeding report as PDF
  Future<Uint8List> generateBreedingPdf(List<BreedingRecord> records) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');

    // Stats based on actual BreedingStatus enum
    final inHeat = records
        .where((r) => r.status == BreedingStatus.inHeat)
        .length;
    final bred = records.where((r) => r.status == BreedingStatus.bred).length;
    final pregnant = records
        .where((r) => r.status == BreedingStatus.pregnant)
        .length;
    final delivered = records
        .where((r) => r.status == BreedingStatus.delivered)
        .length;
    final failed = records
        .where((r) => r.status == BreedingStatus.failed)
        .length;

    final completedRecords = records
        .where(
          (r) =>
              r.status == BreedingStatus.delivered ||
              r.status == BreedingStatus.failed,
        )
        .length;
    final successRate = completedRecords > 0
        ? (delivered / completedRecords * 100).toStringAsFixed(1)
        : 'N/A';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('Breeding Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.pink50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox('In Heat', inHeat.toString()),
                _buildStatBox('Bred', bred.toString()),
                _buildStatBox('Pregnant', pregnant.toString()),
                _buildStatBox('Delivered', delivered.toString()),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Success Rate: $successRate%',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.pink700,
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Text(
                  'Failed: $failed',
                  style: const pw.TextStyle(color: PdfColors.red700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Breeding Records Table
          pw.Text(
            'Breeding Records',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.pink100),
            cellHeight: 25,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
            },
            headers: [
              'Animal',
              'Heat Date',
              'Bred Date',
              'Status',
              'Expected',
              'Litter',
            ],
            data: records.map((r) {
              return [
                r.animalId,
                dateFormat.format(r.heatDate),
                r.breedingDate != null
                    ? dateFormat.format(r.breedingDate!)
                    : '-',
                r.status.name,
                r.expectedFarrowDate != null
                    ? dateFormat.format(r.expectedFarrowDate!)
                    : '-',
                r.litterSize?.toString() ?? '-',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate breeding report as CSV
  String generateBreedingCsv(List<BreedingRecord> records) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final headers = [
      'Animal ID',
      'Sire ID',
      'Heat Date',
      'Breeding Date',
      'Status',
      'Expected Farrow Date',
      'Actual Farrow Date',
      'Litter Size',
      'Notes',
    ];

    final rows = records.map((r) {
      return [
        r.animalId,
        r.sireId ?? '',
        dateFormat.format(r.heatDate),
        r.breedingDate != null ? dateFormat.format(r.breedingDate!) : '',
        r.status.name,
        r.expectedFarrowDate != null
            ? dateFormat.format(r.expectedFarrowDate!)
            : '',
        r.actualFarrowDate != null
            ? dateFormat.format(r.actualFarrowDate!)
            : '',
        r.litterSize?.toString() ?? '',
        r.notes ?? '',
      ];
    }).toList();

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  // ==================== WEIGHT/GROWTH REPORT ====================

  /// Generate growth report as PDF
  Future<Uint8List> generateGrowthPdf(
    List<Animal> animals,
    Map<String, List<WeightRecord>> weightsByAnimal,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('Growth Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          ...animals
              .where((a) => weightsByAnimal[a.id]?.isNotEmpty ?? false)
              .map((animal) {
                final weights = weightsByAnimal[animal.id]!;
                final latestWeight = weights.first.weight;
                final oldestWeight = weights.last.weight;
                final totalGain = latestWeight - oldestWeight;
                final daysBetween = weights.first.date
                    .difference(weights.last.date)
                    .inDays;
                final avgDailyGain = daysBetween > 0
                    ? totalGain / daysBetween
                    : 0.0;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        color: PdfColors.grey200,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${animal.name} - ${animal.breed}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'ADG: ${avgDailyGain.toStringAsFixed(2)} kg/day',
                              style: const pw.TextStyle(
                                color: PdfColors.green700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.TableHelper.fromTextArray(
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                        ),
                        cellHeight: 22,
                        headers: ['Date', 'Weight (kg)', 'Notes'],
                        data: weights.take(10).map((w) {
                          return [
                            dateFormat.format(w.date),
                            w.weight.toStringAsFixed(1),
                            w.notes ?? '-',
                          ];
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate growth report as CSV
  String generateGrowthCsv(
    List<Animal> animals,
    Map<String, List<WeightRecord>> weightsByAnimal,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final headers = [
      'Animal Name',
      'Animal Breed',
      'Date',
      'Weight (kg)',
      'Notes',
    ];

    final List<List<dynamic>> rows = [];

    for (final animal in animals) {
      final weights = weightsByAnimal[animal.id] ?? [];
      for (final w in weights) {
        rows.add([
          animal.name,
          animal.breed,
          dateFormat.format(w.date),
          w.weight.toStringAsFixed(1),
          w.notes ?? '',
        ]);
      }
    }

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  // ==================== HELPER METHODS ====================

  pw.Widget _buildPdfHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            farmName,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.Divider(color: PdfColors.grey300),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated: ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  String _formatCategory(String category) {
    // Convert camelCase or snake_case to Title Case
    return category
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  // ==================== EXCEL GENERATION ====================

  /// Generate inventory report as Excel
  Uint8List generateInventoryExcel(List<Animal> animals) {
    final excel = Excel.createExcel();
    final sheet = excel['Inventory'];
    excel.delete('Sheet1');

    // Headers
    final headers = [
      'Tag ID',
      'Breed',
      'Gender',
      'Status',
      'Birth Date',
      'Age',
      'Current Weight (kg)',
      'Notes',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(bold: true);
    }

    // Data rows
    final dateFormat = DateFormat('yyyy-MM-dd');
    for (var rowIdx = 0; rowIdx < animals.length; rowIdx++) {
      final a = animals[rowIdx];
      final row = [
        a.tagId,
        a.name ?? '',
        a.species.displayName,
        a.breed ?? '',
        a.gender.name,
        a.status.name,
        a.birthDate != null ? dateFormat.format(a.birthDate!) : '',
        a.ageFormatted,
        a.currentWeight?.toStringAsFixed(1) ?? '',
        a.notes ?? '',
      ];

      for (var colIdx = 0; colIdx < row.length; colIdx++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIdx,
                rowIndex: rowIdx + 1,
              ),
            )
            .value = TextCellValue(
          row[colIdx],
        );
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generate financial report as Excel
  Uint8List generateFinancialExcel(List<Transaction> transactions) {
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];
    excel.delete('Sheet1');

    // Headers
    final headers = [
      'Date',
      'Type',
      'Category',
      'Amount',
      'Description',
      'Animal ID',
      'Payment Method',
      'Reference Number',
      'Notes',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(bold: true);
    }

    // Data rows
    final dateFormat = DateFormat('yyyy-MM-dd');
    for (var rowIdx = 0; rowIdx < transactions.length; rowIdx++) {
      final t = transactions[rowIdx];
      final row = [
        dateFormat.format(t.date),
        t.type.name,
        t.category,
        t.amount.toString(),
        t.description,
        t.animalId ?? '',
        t.paymentMethod?.name ?? '',
        t.referenceNumber ?? '',
        t.notes ?? '',
      ];

      for (var colIdx = 0; colIdx < row.length; colIdx++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIdx,
                rowIndex: rowIdx + 1,
              ),
            )
            .value = TextCellValue(
          row[colIdx],
        );
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generate health report as Excel
  Uint8List generateHealthExcel(List<HealthRecord> records) {
    final excel = Excel.createExcel();
    final sheet = excel['Health Records'];
    excel.delete('Sheet1');

    // Headers
    final headers = [
      'Date',
      'Animal ID',
      'Animal Tag',
      'Type',
      'Title',
      'Description',
      'Diagnosis',
      'Treatment',
      'Medication',
      'Dosage',
      'Status',
      'Next Due Date',
      'Follow Up Date',
      'Cost',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(bold: true);
    }

    // Data rows
    final dateFormat = DateFormat('yyyy-MM-dd');
    for (var rowIdx = 0; rowIdx < records.length; rowIdx++) {
      final r = records[rowIdx];
      final row = [
        dateFormat.format(r.date),
        r.animalId,
        r.animalTagId ?? '',
        r.type.name,
        r.title,
        r.description ?? '',
        r.diagnosis ?? '',
        r.treatment ?? '',
        r.medicationName ?? '',
        r.dosage ?? '',
        r.status.name,
        r.nextDueDate != null ? dateFormat.format(r.nextDueDate!) : '',
        r.followUpDate != null ? dateFormat.format(r.followUpDate!) : '',
        r.cost?.toString() ?? '',
      ];

      for (var colIdx = 0; colIdx < row.length; colIdx++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIdx,
                rowIndex: rowIdx + 1,
              ),
            )
            .value = TextCellValue(
          row[colIdx],
        );
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generate breeding report as Excel
  Uint8List generateBreedingExcel(List<BreedingRecord> records) {
    final excel = Excel.createExcel();
    final sheet = excel['Breeding Records'];
    excel.delete('Sheet1');

    // Headers
    final headers = [
      'Animal ID',
      'Sire ID',
      'Heat Date',
      'Breeding Date',
      'Status',
      'Expected Farrow Date',
      'Actual Farrow Date',
      'Litter Size',
      'Notes',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(bold: true);
    }

    // Data rows
    final dateFormat = DateFormat('yyyy-MM-dd');
    for (var rowIdx = 0; rowIdx < records.length; rowIdx++) {
      final r = records[rowIdx];
      final row = [
        r.animalId,
        r.sireId ?? '',
        dateFormat.format(r.heatDate),
        r.breedingDate != null ? dateFormat.format(r.breedingDate!) : '',
        r.status.name,
        r.expectedFarrowDate != null
            ? dateFormat.format(r.expectedFarrowDate!)
            : '',
        r.actualFarrowDate != null
            ? dateFormat.format(r.actualFarrowDate!)
            : '',
        r.litterSize?.toString() ?? '',
        r.notes ?? '',
      ];

      for (var colIdx = 0; colIdx < row.length; colIdx++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIdx,
                rowIndex: rowIdx + 1,
              ),
            )
            .value = TextCellValue(
          row[colIdx],
        );
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generate growth report as Excel
  Uint8List generateGrowthExcel(
    List<Animal> animals,
    Map<String, List<WeightRecord>> weightsByAnimal,
  ) {
    final excel = Excel.createExcel();
    final sheet = excel['Weight Records'];
    excel.delete('Sheet1');

    // Headers
    final headers = [
      'Animal Tag ID',
      'Animal Breed',
      'Date',
      'Weight (kg)',
      'Notes',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(bold: true);
    }

    // Data rows
    final dateFormat = DateFormat('yyyy-MM-dd');
    var rowIdx = 1;

    for (final animal in animals) {
      final weights = weightsByAnimal[animal.id] ?? [];
      for (final w in weights) {
        final row = [
          animal.tagId,
          animal.species.displayName,
          animal.breed ?? '',
          dateFormat.format(w.date),
          w.weight.toStringAsFixed(1),
          w.notes ?? '',
        ];

        for (var colIdx = 0; colIdx < row.length; colIdx++) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIdx,
                  rowIndex: rowIdx,
                ),
              )
              .value = TextCellValue(
            row[colIdx],
          );
        }
        rowIdx++;
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  // ==================== JSON GENERATION ====================

  /// Generate inventory report as JSON
  String generateInventoryJson(List<Animal> animals) {
    final data = {
      'reportType': 'inventory',
      'farmName': farmName,
      'generatedAt': DateTime.now().toIso8601String(),
      'summary': {
        'totalAnimals': animals.length,
        'maleCount': animals.where((a) => a.gender == Gender.male).length,
        'femaleCount': animals.where((a) => a.gender == Gender.female).length,
        'healthyCount': animals
            .where((a) => a.status == AnimalStatus.healthy)
            .length,
      },
      'animals': animals.map((a) {
        return {
          'id': a.id,
          'tagId': a.tagId,
          'name': a.name,
          'species': a.species.name,
          'breed': a.breed,
          'gender': a.gender.name,
          'status': a.status.name,
          'birthDate': a.birthDate?.toIso8601String(),
          'ageInDays': a.ageInDays,
          'currentWeight': a.currentWeight,
          'notes': a.notes,
        };
      }).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Generate financial report as JSON
  String generateFinancialJson({
    required FinancialSummary summary,
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final data = {
      'reportType': 'financial',
      'farmName': farmName,
      'generatedAt': DateTime.now().toIso8601String(),
      'period': {
        'startDate': dateFormat.format(startDate),
        'endDate': dateFormat.format(endDate),
      },
      'summary': {
        'totalIncome': summary.totalIncome,
        'totalExpenses': summary.totalExpenses,
        'netProfit': summary.netProfit,
        'profitMargin': summary.profitMargin,
        'transactionCount': summary.transactionCount,
        'incomeByCategory': summary.incomeByCategory,
        'expensesByCategory': summary.expensesByCategory,
      },
      'transactions': transactions.map((t) {
        return {
          'id': t.id,
          'date': dateFormat.format(t.date),
          'type': t.type.name,
          'category': t.category,
          'amount': t.amount,
          'description': t.description,
          'animalId': t.animalId,
          'paymentMethod': t.paymentMethod?.name,
          'referenceNumber': t.referenceNumber,
          'notes': t.notes,
        };
      }).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Generate health report as JSON
  String generateHealthJson(List<HealthRecord> records) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final data = {
      'reportType': 'health',
      'farmName': farmName,
      'generatedAt': DateTime.now().toIso8601String(),
      'summary': {
        'totalRecords': records.length,
        'vaccinationCount': records
            .where((r) => r.type == HealthRecordType.vaccination)
            .length,
        'treatmentCount': records
            .where((r) => r.type == HealthRecordType.treatment)
            .length,
        'checkupCount': records
            .where((r) => r.type == HealthRecordType.checkup)
            .length,
        'medicationCount': records
            .where((r) => r.type == HealthRecordType.medication)
            .length,
      },
      'records': records.map((r) {
        return {
          'id': r.id,
          'animalId': r.animalId,
          'animalTagId': r.animalTagId,
          'type': r.type.name,
          'date': dateFormat.format(r.date),
          'title': r.title,
          'description': r.description,
          'diagnosis': r.diagnosis,
          'treatment': r.treatment,
          'medicationName': r.medicationName,
          'dosage': r.dosage,
          'status': r.status.name,
          'nextDueDate': r.nextDueDate != null
              ? dateFormat.format(r.nextDueDate!)
              : null,
          'followUpDate': r.followUpDate != null
              ? dateFormat.format(r.followUpDate!)
              : null,
          'cost': r.cost,
        };
      }).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Generate breeding report as JSON
  String generateBreedingJson(List<BreedingRecord> records) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final delivered = records
        .where((r) => r.status == BreedingStatus.delivered)
        .length;
    final failed = records
        .where((r) => r.status == BreedingStatus.failed)
        .length;
    final completedRecords = delivered + failed;
    final successRate = completedRecords > 0
        ? (delivered / completedRecords * 100)
        : null;

    final data = {
      'reportType': 'breeding',
      'farmName': farmName,
      'generatedAt': DateTime.now().toIso8601String(),
      'summary': {
        'totalRecords': records.length,
        'inHeatCount': records
            .where((r) => r.status == BreedingStatus.inHeat)
            .length,
        'bredCount': records
            .where((r) => r.status == BreedingStatus.bred)
            .length,
        'pregnantCount': records
            .where((r) => r.status == BreedingStatus.pregnant)
            .length,
        'deliveredCount': delivered,
        'failedCount': failed,
        'successRate': successRate,
      },
      'records': records.map((r) {
        return {
          'id': r.id,
          'animalId': r.animalId,
          'sireId': r.sireId,
          'heatDate': dateFormat.format(r.heatDate),
          'breedingDate': r.breedingDate != null
              ? dateFormat.format(r.breedingDate!)
              : null,
          'status': r.status.name,
          'expectedDeliveryDate': r.expectedDeliveryDate != null
              ? dateFormat.format(r.expectedDeliveryDate!)
              : null,
          'actualDeliveryDate': r.actualDeliveryDate != null
              ? dateFormat.format(r.actualDeliveryDate!)
              : null,
          'litterSize': r.litterSize,
          'notes': r.notes,
        };
      }).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Generate growth report as JSON
  String generateGrowthJson(
    List<Animal> animals,
    Map<String, List<WeightRecord>> weightsByAnimal,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final animalGrowthData = animals
        .where((a) => weightsByAnimal[a.id]?.isNotEmpty ?? false)
        .map((animal) {
          final weights = weightsByAnimal[animal.id]!;
          final latestWeight = weights.first.weight;
          final oldestWeight = weights.last.weight;
          final totalGain = latestWeight - oldestWeight;
          final daysBetween = weights.first.date
              .difference(weights.last.date)
              .inDays;
          final avgDailyGain = daysBetween > 0 ? totalGain / daysBetween : 0.0;

          return {
            'animalId': animal.id,
            'tagId': animal.tagId,
            'breed': animal.breed,
            'metrics': {
              'latestWeight': latestWeight,
              'oldestWeight': oldestWeight,
              'totalGain': totalGain,
              'daysBetween': daysBetween,
              'avgDailyGain': avgDailyGain,
            },
            'weightRecords': weights.map((w) {
              return {
                'id': w.id,
                'date': dateFormat.format(w.date),
                'weight': w.weight,
                'notes': w.notes,
              };
            }).toList(),
          };
        })
        .toList();

    final data = {
      'reportType': 'growth',
      'farmName': farmName,
      'generatedAt': DateTime.now().toIso8601String(),
      'summary': {
        'animalsWithRecords': animalGrowthData.length,
        'totalWeightRecords': weightsByAnimal.values.fold(
          0,
          (sum, list) => sum + list.length,
        ),
      },
      'animals': animalGrowthData,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // ==================== SHARE METHODS ====================

  /// Share CSV content as a file
  Future<void> shareCsv(String csvContent, String filename) async {
    try {
      if (kIsWeb) {
        web_download.downloadTextOnWeb(csvContent, filename, 'text/csv');
        return;
      }

      await file_saver.saveAndShareTextFile(csvContent, filename, 'text/csv');
    } catch (e) {
      rethrow;
    }
  }

  /// Share PDF content as a file
  Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    try {
      if (kIsWeb) {
        web_download.downloadOnWeb(pdfBytes, filename, 'application/pdf');
        return;
      }

      await file_saver.saveAndShareFile(pdfBytes, filename, 'application/pdf');
    } catch (e) {
      rethrow;
    }
  }

  /// Share Excel content as a file
  Future<void> shareExcel(Uint8List excelBytes, String filename) async {
    try {
      if (kIsWeb) {
        web_download.downloadOnWeb(
          excelBytes,
          filename,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        return;
      }

      await file_saver.saveAndShareFile(
        excelBytes,
        filename,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Share JSON content as a file
  Future<void> shareJson(String jsonContent, String filename) async {
    try {
      if (kIsWeb) {
        web_download.downloadTextOnWeb(
          jsonContent,
          filename,
          'application/json',
        );
        return;
      }

      await file_saver.saveAndShareTextFile(
        jsonContent,
        filename,
        'application/json',
      );
    } catch (e) {
      rethrow;
    }
  }
}
