class PredictionRequest {
  final int age;
  final double income;
  final double landSize;
  final int isRural;
  final int houseType;
  final int isTaxpayer;
  final int isGovtEmp;
  final String? language;

  PredictionRequest({
    required this.age,
    required this.income,
    required this.landSize,
    required this.isRural,
    required this.houseType,
    required this.isTaxpayer,
    required this.isGovtEmp,
    this.language,
  });

  Map<String, dynamic> toJson() => {
        'age': age,
        'income': income,
        'land_size': landSize,
        'is_rural': isRural,
        'house_type': houseType,
        'is_taxpayer': isTaxpayer,
        'is_govt_emp': isGovtEmp,
        if (language != null) 'language': language,
      };
}
