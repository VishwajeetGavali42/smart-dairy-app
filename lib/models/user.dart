class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone ?? '',
      'address': address ?? '',
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      address: map['address'],
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}
