
class ConfigModel {

  final String id;
  final String transactionFeePercent;  // 0 at launch — update here to change globally
  final String autoReleaseHours;
  final String appealWindowHours;
  final double chatCloseHours;
  final double commissionPercent;
  final double fundingFees;
  final double bonusAirtime;
  final double bonusData;
  final double bonusCable;
  final double bonusElectric;

  ConfigModel(
    {
      required this.id,
      required this.transactionFeePercent,
      required this.autoReleaseHours,
      required this.appealWindowHours,
      required this.chatCloseHours,
      required this.commissionPercent,
      required this.fundingFees,
      required this.bonusAirtime,
      required this.bonusData,
      required this.bonusCable,
      required this.bonusElectric,
    }
  );

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
        id: json['id'],
        transactionFeePercent: json['transactionFeePercent'],
        autoReleaseHours: (json['autoReleaseHours'] ?? 0).toDouble(),
        appealWindowHours: (json['appealWindowHours'] ?? 0).toDouble(),
        chatCloseHours: (json['chatCloseHours'] ?? 0).toDouble(),
        commissionPercent: (json['commissionPercent'] ?? 0).toDouble(),
        fundingFees: (json['fundingFees'] ?? 0).toDouble(),
        bonusAirtime: (json['bonusAirtime'] ?? 0).toDouble(),
        bonusData: (json['bonusData'] ?? 0).toDouble(),
        bonusCable: (json['bonusCable'] ?? 0).toDouble(),
        bonusElectric: (json['bonusElectric'] ?? 0).toDouble()
    );
  }

  Map<String, dynamic> toJson() => {
    'transactionFeePercent': transactionFeePercent,
    'autoReleaseHours': autoReleaseHours,
    'appealWindowHours': appealWindowHours,
    'chatCloseHours': chatCloseHours,
    'commissionPercent': commissionPercent,
    'fundingFees': fundingFees,
    'bonusAirtime': bonusAirtime,
    'bonusData': bonusData,
    'bonusCable': bonusCable,
    'bonusElectric': bonusElectric,
  };


}