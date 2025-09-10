// lib/models/address.dart
class Address {
  final String street;
  final String city;
  final String state; // Or province
  final String postalCode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }

  @override
  String toString() {
    return '$street, $city, $state $postalCode, $country';
  }

  // Basic validation
  bool get isValid {
    return street.isNotEmpty && city.isNotEmpty && state.isNotEmpty && postalCode.isNotEmpty && country.isNotEmpty;
  }
}
