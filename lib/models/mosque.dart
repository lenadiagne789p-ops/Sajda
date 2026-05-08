class Mosque {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  final String? website;
  final String gender; // 'mixed', 'men', 'women'
  double distance; // in km

  Mosque({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.website,
    this.gender = 'mixed',
    this.distance = 0,
  });

  factory Mosque.fromJson(Map<String, dynamic> json) {
    return Mosque(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Mosquée',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
      phone: json['phone'],
      website: json['website'],
      gender: json['gender'] ?? 'mixed',
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'phone': phone,
    'website': website,
    'gender': gender,
    'distance': distance,
  };
}
