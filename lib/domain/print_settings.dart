/// Represents the user-provided settings for generating an inventory PDF report.
class PrintSettings {
  final String academicYear;
  final String dateUpdated;
  final String taAssignedNames;
  final String shiftType;

  const PrintSettings({
    required this.academicYear,
    required this.dateUpdated,
    required this.taAssignedNames,
    required this.shiftType,
  });
}
