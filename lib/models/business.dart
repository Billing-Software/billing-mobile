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
  final String? receiptHeader;
  final String? receiptFooter;
  final bool showLogoOnReceipt;
  final String receiptTemplateType;

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
    this.receiptHeader,
    this.receiptFooter,
    this.showLogoOnReceipt = true,
    this.receiptTemplateType = 'Thermal80mm',
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] ?? json['Id'] ?? 0,
      ownerId: json['ownerId'] ?? json['OwnerId'] ?? 0,
      legalName: json['legalName'] ?? json['LegalName'] ?? '',
      tradingName: json['tradingName'] ?? json['TradingName'],
      logoUrl: json['logoUrl'] ?? json['LogoUrl'],
      address: json['address'] ?? json['Address'],
      city: json['city'] ?? json['City'],
      state: json['state'] ?? json['State'],
      postalCode: json['postalCode'] ?? json['PostalCode'],
      country: json['country'] ?? json['Country'],
      phone: json['phone'] ?? json['Phone'],
      email: json['email'] ?? json['Email'],
      website: json['website'] ?? json['Website'],
      gstIn: json['gstIn'] ?? json['GstIn'],
      defaultTaxRate: ((json['defaultTaxRate'] ?? json['DefaultTaxRate']) as num?)?.toDouble() ?? 18.0,
      pricesIncludeTax: json['pricesIncludeTax'] ?? json['PricesIncludeTax'] ?? true,
      receiptHeader: json['receiptHeader'] ?? json['ReceiptHeader'],
      receiptFooter: json['receiptFooter'] ?? json['ReceiptFooter'],
      showLogoOnReceipt: json['showLogoOnReceipt'] ?? json['ShowLogoOnReceipt'] ?? true,
      receiptTemplateType: json['receiptTemplateType'] ?? json['ReceiptTemplateType'] ?? 'Thermal80mm',
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
      'receiptHeader': receiptHeader,
      'receiptFooter': receiptFooter,
      'showLogoOnReceipt': showLogoOnReceipt,
      'receiptTemplateType': receiptTemplateType,
    };
  }
}
