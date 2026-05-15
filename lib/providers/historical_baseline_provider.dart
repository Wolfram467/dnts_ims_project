class HistoricalRecord {
  final String deskId;
  final String category;
  final String dntsSerial;
  final String mfgSerial;
  final String brand;
  final String notes;
  final String? dateAcquired;

  const HistoricalRecord({
    required this.deskId,
    required this.category,
    required this.dntsSerial,
    required this.mfgSerial,
    required this.brand,
    required this.notes,
    this.dateAcquired,
  });
}
