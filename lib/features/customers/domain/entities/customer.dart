/// Business entity representing a customer.
class Customer {
  final int? customerId;
  final String fullName;
  final String mobileNumber;
  final String? alternateNumber;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    this.customerId,
    required this.fullName,
    required this.mobileNumber,
    this.alternateNumber,
    this.address,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of the customer with updated fields.
  Customer copyWith({
    int? customerId,
    String? fullName,
    String? mobileNumber,
    String? alternateNumber,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      customerId: customerId ?? this.customerId,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      alternateNumber: alternateNumber ?? this.alternateNumber,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer &&
          runtimeType == other.runtimeType &&
          customerId == other.customerId &&
          fullName == other.fullName &&
          mobileNumber == other.mobileNumber &&
          alternateNumber == other.alternateNumber &&
          address == other.address &&
          notes == other.notes &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      customerId.hashCode ^
      fullName.hashCode ^
      mobileNumber.hashCode ^
      alternateNumber.hashCode ^
      address.hashCode ^
      notes.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}
