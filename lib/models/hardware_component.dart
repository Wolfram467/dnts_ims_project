class HardwareComponent {
  final String dntsSerial;
  final String mfgSerial;
  final String category;
  final String status;

  const HardwareComponent({
    required this.dntsSerial,
    required this.mfgSerial,
    required this.category,
    required this.status,
  });

  factory HardwareComponent.fromJson(Map<String, dynamic> json) {
    return HardwareComponent(
      dntsSerial: json['dnts_serial'] as String? ?? '',
      mfgSerial: json['mfg_serial'] as String? ?? '',
      category: json['category'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dnts_serial': dntsSerial,
      'mfg_serial': mfgSerial,
      'category': category,
      'status': status,
    };
  }

  HardwareComponent copyWith({
    String? dntsSerial,
    String? mfgSerial,
    String? category,
    String? status,
  }) {
    return HardwareComponent(
      dntsSerial: dntsSerial ?? this.dntsSerial,
      mfgSerial: mfgSerial ?? this.mfgSerial,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }
}
