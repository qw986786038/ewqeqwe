/// 联行号级联树节点。
class SrmCnapsTreeNode {
  String? value;
  String? label;
  bool leaf = false;
  String? bankCode;
}

/// 联行号搜索结果。
class SrmCnapsItem {
  String? id;
  String? name;
  String? bankCode;
  String? bankName;
  String? bankId;
  String? cityCode;
  String? cityName;
  String? provinceName;
  String? provinceCode;
}

/// 营业执照 OCR 识别结果。
class SrmBusinessLicenseOcrResult {
  String? title;
  String? creditCode;
  String? companyName;
  String? companyType;
  String? businessAddress;
  String? legalPerson;
  String? businessScope;
  String? registeredCapital;
  String? registrationDate;
  String? validPeriod;
  String? validFromDate;
  String? validToDate;
  String? companyForm;
  String? issueDate;
  String? message;
  /// 若服务端在 OCR 时落库并回传附件路径。
  String? licenseFile;

  static SrmBusinessLicenseOcrResult fromJson(Map<String, dynamic> json) {
    final byLower = <String, Object?>{
      for (final e in json.entries) e.key.toString().toLowerCase(): e.value,
    };
    String? textOf(Object? v) {
      if (v == null) return null;
      if (v is Map) {
        final inner = v['amount'] ?? v['value'] ?? v['text'] ?? v['name'];
        if (inner == null) return null;
        final t = inner.toString().trim();
        return t.isEmpty ? null : t;
      }
      final t = v.toString().trim();
      if (t.isEmpty || t == 'null') return null;
      return t;
    }

    String? s(String key, [List<String> alts = const []]) {
      for (final k in [key, ...alts]) {
        final direct = textOf(json[k]);
        if (direct != null) return direct;
        final folded = textOf(byLower[k.toLowerCase()]);
        if (folded != null) return folded;
      }
      return null;
    }

    return SrmBusinessLicenseOcrResult()
      ..title = s('title')
      ..creditCode = s('creditCode')
      ..companyName = s('companyName')
      ..companyType = s('companyType')
      ..businessAddress = s('businessAddress')
      ..legalPerson = s('legalPerson')
      ..businessScope = s('businessScope')
      ..registeredCapital = s('registeredCapital', const [
        'regCapital',
        'regCap',
        'registCapi',
        'registerCapital',
        'capital',
        'capitalAmount',
        'registered_capital',
        'reg_capital',
        '注册资本',
        '注册资金',
        '注册资本金',
      ])
      ..registrationDate = s('registrationDate', const [
        'RegistrationDate',
        'establishDate',
        'establishedDate',
        'foundDate',
        'esDate',
        'startDate',
        'setUpDate',
        'registerDate',
        'regDate',
        'registration_date',
        '成立日期',
        '注册日期',
        '成立时间',
      ])
      ..validPeriod = s('validPeriod')
      ..validFromDate = s('validFromDate')
      ..validToDate = s('validToDate')
      ..companyForm = s('companyForm')
      ..issueDate = s('issueDate', const ['issue_date'])
      ..message = s('message')
      ..licenseFile = s('licenseFile') ??
          s('fileName') ??
          s('filePath') ??
          s('url') ??
          s('path');
  }
}

/// 供应商 KPI 汇总（列表页顶部卡片）。
class SrmSupplierKpi {
  int total = 0;
  int propertyLeaseCount = 0;
  int mediaPurchaseCount = 0;
  int blacklistCount = 0;
}

/// 供应商银行账户子表。
class SrmSupplierBank {
  String? id;
  String? supplierId;
  String? bankName;
  String? bankAccount;
  String? invoiceInfo;
  int? sort;
  String? remark;
}

/// 供应商开票信息子表。
class SrmSupplierInvoice {
  String? id;
  String? supplierId;
  String? invoiceName;
  String? taxNo;
  String? registerAddress;
  String? registerPhone;
  String? bankName;
  String? bankAccount;
  String? invoiceType;
  String? taxRate;
  int? sort;
  String? remark;
}

/// 供应商联系人子表。
class SrmSupplierContact {
  String? id;
  String? supplierId;
  String? name;
  String? nameEn;
  String? gender;
  String? ageGroup;
  String? deptPost;
  String? dutyDesc;
  String? mobile;
  String? email;
  int? sort;
  String? remark;
}

/// 供应商我方对接人子表。
class SrmSupplierStaff {
  String? id;
  String? supplierId;
  String? userId;
  String? name;
  String? nameEn;
  String? gender;
  String? deptPost;
  int? sort;
  String? remark;
}

/// 供应商供应品类子表。
class SrmSupplierCategory {
  String? id;
  String? supplierId;
  String? supplyCategory;
  String? itemType;
  String? itemDesc;
  int? sort;
  String? remark;
}

/// 供应商列表行 / 详情（对接 SrmSupplierVo）。
class SrmSupplier {
  String? id;
  String? supplierCode;
  int? weight;
  String? shortName;
  String? fullName;
  String? supplierType;
  String? supplyCategoryText;
  String? enterpriseNature;
  int? teamSize;
  String? cooperationMode;
  String? settlementMethod;
  String? regionName;
  String? city;
  String? businessAddress;
  String? contactInfoText;
  String? staffInfoText;
  String? createTime;
  String? latestDynamic;
  String? logoFile;
  String? blacklistStatus;
  String? blacklistStatusText;
  String? status;
  String? statusText;

  // ── 详情扩展 ──────────────────────────────────────────────
  String? entityFile;
  String? province;
  String? district;
  String? website;
  String? creditCode;
  String? legalPerson;
  num? registeredCapital;
  String? establishDate;
  String? licenseValidStart;
  String? licenseValidEnd;
  String? registeredAddress;
  String? businessScope;
  int? paymentTermDays;
  String? paymentCondition;
  String? rebatePolicy;
  String? serviceArea;
  String? invoiceType;
  String? taxRate;
  String? deliveryCapacity;
  String? coreAdvantage;
  String? remark;
  String? categoryExportText;
  String? bankExportText;
  String? invoiceExportText;
  String? contactExportText;
  String? staffExportText;
  String? abnormalRecord;
  String? penaltyHistory;
  String? licenseFile;
  String? contractTemplate;
  String? invoiceTypeText;
  String? taxRateText;

  List<SrmSupplierBank> bankList = const [];
  List<SrmSupplierInvoice> invoiceList = const [];
  List<SrmSupplierContact> contactList = const [];
  List<SrmSupplierStaff> staffList = const [];
  List<SrmSupplierCategory> categoryList = const [];
}
