class BusinessProfile {
  final String legalName;
  final String tradingName;
  final String address;
  final String city;
  final String postalCode;
  final String gstIn;
  final String defaultTaxRate;
  final bool pricesIncludeTax;

  BusinessProfile({
    required this.legalName,
    required this.tradingName,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.gstIn,
    required this.defaultTaxRate,
    required this.pricesIncludeTax,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      legalName: json['legalName'] ?? '',
      tradingName: json['tradingName'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      postalCode: json['postalCode'] ?? '',
      gstIn: json['gstIn'] ?? '',
      defaultTaxRate: json['defaultTaxRate'] ?? '',
      pricesIncludeTax: json['pricesIncludeTax'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'legalName': legalName,
      'tradingName': tradingName,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'gstIn': gstIn,
      'defaultTaxRate': defaultTaxRate,
      'pricesIncludeTax': pricesIncludeTax,
    };
  }
}

class WhatsAppSettings {
  final String apiKey;
  final bool isConnected;
  final List<String> templates;

  WhatsAppSettings({
    required this.apiKey,
    required this.isConnected,
    required this.templates,
  });

  factory WhatsAppSettings.fromJson(Map<String, dynamic> json) {
    var rawTemplates = json['templates'] as List?;
    List<String> list = rawTemplates != null
        ? rawTemplates.map((t) => t.toString()).toList()
        : [];
    return WhatsAppSettings(
      apiKey: json['apiKey'] ?? '',
      isConnected: json['isConnected'] ?? false,
      templates: list,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'isConnected': isConnected,
      'templates': templates,
    };
  }
}
