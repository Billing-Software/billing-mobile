class Business {
  final int id;
  final int ownerId;
  final String legalName;
  final String? tradingName;
  final String? logoUrl;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? phone;
  final String? email;
  final String? website;
  final String? gstIn;
  final double defaultTaxRate;
  final bool pricesIncludeTax;

  Business({
    required this.id,
    required this.ownerId,
    required this.legalName,
    this.tradingName,
    this.logoUrl,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.phone,
    this.email,
    this.website,
    this.gstIn,
    required this.defaultTaxRate,
    required this.pricesIncludeTax,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] ?? 0,
      ownerId: json['ownerId'] ?? 0,
      legalName: json['legalName'] ?? '',
      tradingName: json['tradingName'],
      logoUrl: json['logoUrl'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      gstIn: json['gstIn'],
      defaultTaxRate: (json['defaultTaxRate'] as num?)?.toDouble() ?? 18.0,
      pricesIncludeTax: json['pricesIncludeTax'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'legalName': legalName,
      'tradingName': tradingName,
      'logoUrl': logoUrl,
      'address': address,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'phone': phone,
      'email': email,
      'website': website,
      'gstIn': gstIn,
      'defaultTaxRate': defaultTaxRate,
      'pricesIncludeTax': pricesIncludeTax,
    };
  }
}
