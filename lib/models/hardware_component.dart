class HardwareComponent {
  String dntsSerial = '';
  String mfgSerial = '';
  String category = '';
  String status = '';
  String brand = '';
  String? dateAcquired;

  HardwareComponent({
    this.dntsSerial = '',
    this.mfgSerial = '',
    this.category = '',
    this.status = '',
    this.brand = '',
    this.dateAcquired,
  });

  factory HardwareComponent.fromJson(Map<String, dynamic> json) {
    return HardwareComponent(
      dntsSerial: json['dnts_serial'] as String? ?? '',
      mfgSerial: json['mfg_serial'] as String? ?? '',
      category: json['category'] as String? ?? '',
      status: json['status'] as String? ?? '',
      brand: json['notes'] as String? ?? '',
      dateAcquired: json['date_acquired'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dnts_serial': dntsSerial,
      'mfg_serial': mfgSerial,
      'category': category,
      'status': status,
      'notes': brand,
      if (dateAcquired != null) 'date_acquired': dateAcquired,
    };
  }

  HardwareComponent copyWith({
    String? dntsSerial,
    String? mfgSerial,
    String? category,
    String? status,
    String? brand,
    String? dateAcquired,
  }) {
    return HardwareComponent(
      dntsSerial: dntsSerial ?? this.dntsSerial,
      mfgSerial: mfgSerial ?? this.mfgSerial,
      category: category ?? this.category,
      status: status ?? this.status,
      brand: brand ?? this.brand,
      dateAcquired: dateAcquired ?? this.dateAcquired,
    );
  }
}
