class ApplicationData {
  String? applicationNo;
  String? applicantName;
  String? sex;
  String? nationality;
  String? passportNo;
  String? passportExpiryDate;
  String? currentResidentCountry;
  String? status;
  String? photoPath;
  String? invitationOwnerName;
  String? idCard;
  String? jobTitle;
  String? address;
  String? receiptNumber;
  String? transactionId;
  String? paymentDate;
  String? paymentMethod;
  String? paidAmount;
  String? applicationDate;
  String? applicationStatus;

  ApplicationData({
    this.applicationNo,
    this.applicantName,
    this.sex,
    this.nationality,
    this.passportNo,
    this.passportExpiryDate,
    this.currentResidentCountry,
    this.status,
    this.photoPath,
    this.invitationOwnerName,
    this.idCard,
    this.jobTitle,
    this.address,
    this.receiptNumber,
    this.transactionId,
    this.paymentDate,
    this.paymentMethod,
    this.paidAmount,
    this.applicationDate,
    this.applicationStatus,
  });

  // Validate if applicant information is complete
  bool isApplicantInfoComplete() {
    return applicantName != null && 
           applicantName!.isNotEmpty &&
           sex != null &&
           sex!.isNotEmpty &&
           nationality != null &&
           nationality!.isNotEmpty &&
           passportNo != null &&
           passportNo!.isNotEmpty &&
           passportExpiryDate != null &&
           passportExpiryDate!.isNotEmpty &&
           currentResidentCountry != null &&
           currentResidentCountry!.isNotEmpty &&
           photoPath != null &&
           photoPath!.isNotEmpty;
  }
  
  // Validate if invitation information is complete
  bool isInvitationInfoComplete() {
    return invitationOwnerName != null &&
           invitationOwnerName!.isNotEmpty &&
           idCard != null &&
           idCard!.isNotEmpty &&
           jobTitle != null &&
           jobTitle!.isNotEmpty &&
           address != null &&
           address!.isNotEmpty;
  }
  
  // Validate if payment information is complete
  bool isPaymentInfoComplete() {
    return receiptNumber != null &&
           receiptNumber!.isNotEmpty &&
           transactionId != null &&
           transactionId!.isNotEmpty &&
           paymentDate != null &&
           paymentDate!.isNotEmpty &&
           paymentMethod != null &&
           paymentMethod!.isNotEmpty &&
           paidAmount != null &&
           paidAmount!.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'applicationNo': applicationNo ?? '',
      'applicantName': applicantName ?? '',
      'sex': sex ?? '',
      'nationality': nationality ?? '',
      'passportNo': passportNo ?? '',
      'passportExpiryDate': passportExpiryDate ?? '',
      'currentResidentCountry': currentResidentCountry ?? '',
      'status': status ?? '',
      'photoPath': photoPath ?? '',
      'invitationOwnerName': invitationOwnerName ?? '',
      'idCard': idCard ?? '',
      'jobTitle': jobTitle ?? '',
      'address': address ?? '',
      'receiptNumber': receiptNumber ?? '',
      'transactionId': transactionId ?? '',
      'paymentDate': paymentDate ?? '',
      'paymentMethod': paymentMethod ?? '',
      'paidAmount': paidAmount ?? '',
      'applicationDate': applicationDate ?? '',
      'applicationStatus': applicationStatus ?? 'IN PROGRESS',
    };
  }

  factory ApplicationData.fromJson(Map<String, dynamic> json) {
    return ApplicationData(
      applicationNo: json['applicationNo'] ?? '',
      applicantName: json['applicantName'] ?? '',
      sex: json['sex'] ?? '',
      nationality: json['nationality'] ?? '',
      passportNo: json['passportNo'] ?? '',
      passportExpiryDate: json['passportExpiryDate'] ?? '',
      currentResidentCountry: json['currentResidentCountry'] ?? '',
      status: json['status'] ?? '',
      photoPath: json['photoPath'] ?? '',
      invitationOwnerName: json['invitationOwnerName'] ?? '',
      idCard: json['idCard'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      address: json['address'] ?? '',
      receiptNumber: json['receiptNumber'] ?? '',
      transactionId: json['transactionId'] ?? '',
      paymentDate: json['paymentDate'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      paidAmount: json['paidAmount'] ?? '',
      applicationDate: json['applicationDate'] ?? '',
      applicationStatus: json['applicationStatus'] ?? 'IN PROGRESS',
    );
  }
}
