import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_employee.dart';
import '../../../../models/srm_supplier.dart';
import '../../../../services/srm_supplier_api.dart';
import '../../../../utils/china_regions.dart';
import '../../../customer_archive/dialogs/select_sales_person_dialog.dart';

class _DraftId {
  static var _n = 1;
  static int next() => _n++;
}

class BankDraft {
  BankDraft({this.serverId, String? bankName, String? bankAccount, String? invoiceInfo})
      : id = _DraftId.next(),
        bankName = bankName ?? '',
        bankAccount = bankAccount ?? '',
        invoiceInfo = invoiceInfo ?? '';

  final int id;
  final String? serverId;
  String bankName;
  String bankAccount;
  String invoiceInfo;
}

class InvoiceDraft {
  InvoiceDraft({
    this.serverId,
    String? invoiceName,
    String? taxNo,
    String? registerAddress,
    String? registerPhone,
    String? bankName,
    String? bankAccount,
  })  : id = _DraftId.next(),
        invoiceName = invoiceName ?? '',
        taxNo = taxNo ?? '',
        registerAddress = registerAddress ?? '',
        registerPhone = registerPhone ?? '',
        bankName = bankName ?? '',
        bankAccount = bankAccount ?? '';

  final int id;
  final String? serverId;
  String invoiceName;
  String taxNo;
  String registerAddress;
  String registerPhone;
  String bankName;
  String bankAccount;
}

class ContactDraft {
  ContactDraft({
    this.serverId,
    String? name,
    String? nameEn,
    String? gender,
    String? ageGroup,
    String? deptPost,
    String? dutyDesc,
    String? mobile,
    String? email,
  })  : id = _DraftId.next(),
        name = name ?? '',
        nameEn = nameEn ?? '',
        gender = gender,
        ageGroup = ageGroup,
        deptPost = deptPost ?? '',
        dutyDesc = dutyDesc ?? '',
        mobile = mobile ?? '',
        email = email ?? '';

  final int id;
  final String? serverId;
  String name;
  String nameEn;
  String? gender;
  String? ageGroup;
  String deptPost;
  String dutyDesc;
  String mobile;
  String email;
}

class StaffDraft {
  StaffDraft({
    this.serverId,
    this.userId,
    String? name,
    String? nameEn,
    String? gender,
    String? deptPost,
  })  : id = _DraftId.next(),
        name = name ?? '',
        nameEn = nameEn ?? '',
        gender = gender,
        deptPost = deptPost ?? '';

  final int id;
  final String? serverId;
  int? userId;
  String name;
  String nameEn;
  String? gender;
  String deptPost;
}

class CategoryDraft {
  CategoryDraft({
    this.serverId,
    String? supplyCategory,
    String? itemType,
    String? itemDesc,
  })  : id = _DraftId.next(),
        supplyCategory = supplyCategory ?? '',
        itemType = itemType ?? '',
        itemDesc = itemDesc ?? '';

  final int id;
  final String? serverId;
  String supplyCategory;
  String itemType;
  String itemDesc;
}

/// 新建 / 编辑供应商。
class SupplierEditController extends LxController {
  SupplierEditController({this.supplierId});

  final String? supplierId;
  final _api = SrmSupplierApi();
  final form = AppFormController();

  final bootLoading = true.obs;
  final saving = false.obs;
  final ocrLoading = false.obs;
  final errorMessage = Rxn<String>();
  /// 保存时校验子表必填并展示行内错误。
  final showChildErrors = false.obs;

  final regionOptions = <AppCascadeOption<String>>[].obs;
  final formEpoch = 0.obs;
  final initials = <String, Object?>{}.obs;

  final banks = <BankDraft>[].obs;
  final invoices = <InvoiceDraft>[].obs;
  final contacts = <ContactDraft>[].obs;
  final staffs = <StaffDraft>[].obs;
  final categories = <CategoryDraft>[].obs;

  final blacklist = false.obs;
  final logoPath = Rxn<String>();
  final logoLabel = Rxn<String>();
  final licensePath = Rxn<String>();
  final licenseLabel = Rxn<String>();
  final contractPaths = <String>[].obs;
  final contractLabels = <String>[].obs;

  bool get isEdit =>
      supplierId != null && supplierId!.trim().isNotEmpty;

  String? get editId => supplierId?.trim();

  static const supplierTypeOptions = [
    AppOption(value: '物业租赁', label: '物业租赁'),
    AppOption(value: '媒介采购', label: '媒介采购'),
    AppOption(value: '设备采购', label: '设备采购'),
  ];

  static const cooperationModeOptions = [
    AppOption(value: '框架协议', label: '框架协议'),
    AppOption(value: '单次采购', label: '单次采购'),
  ];

  static const settlementMethodOptions = [
    AppOption(value: '30天', label: '30天'),
    AppOption(value: '60天', label: '60天'),
    AppOption(value: '预付', label: '预付'),
  ];

  static const enterpriseNatureOptions = [
    AppOption(value: '有限责任公司', label: '有限责任公司'),
    AppOption(value: '股份有限公司', label: '股份有限公司'),
    AppOption(value: '个体工商户', label: '个体工商户'),
    AppOption(value: '合伙企业', label: '合伙企业'),
    AppOption(value: '其他', label: '其他'),
  ];

  static const invoiceTypeOptions = [
    AppOption(value: '增值税专用发票', label: '增值税专用发票'),
    AppOption(value: '增值税普通发票', label: '增值税普通发票'),
  ];

  static const taxRateOptions = [
    AppOption(value: '6%', label: '6%'),
    AppOption(value: '9%', label: '9%'),
    AppOption(value: '13%', label: '13%'),
    AppOption(value: '其他', label: '其他'),
  ];

  static const genderOptions = [
    AppOption(value: '1', label: '男'),
    AppOption(value: '2', label: '女'),
  ];

  static const ageGroupOptions = [
    AppOption(value: '20-29', label: '20-29'),
    AppOption(value: '30-39', label: '30-39'),
    AppOption(value: '40-49', label: '40-49'),
    AppOption(value: '50+', label: '50+'),
  ];

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onDispose() {
    form.dispose();
    super.onDispose();
  }

  Object? initialOf(String name) => initials[name];

  void putInitial(String name, Object? value) {
    if (value == null) return;
    if (value is String && value.trim().isEmpty) return;
    if (value is Iterable && value.isEmpty) return;
    initials[name] = value;
  }

  Future<void> _bootstrap() async {
    bootLoading.value = true;
    errorMessage.value = null;
    try {
      regionOptions
        ..clear()
        ..addAll(await ChinaRegions.load());
      final id = editId;
      if (id != null && id.isNotEmpty) {
        final detail = await _api.fetchDetail(id);
        _hydrate(detail);
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      bootLoading.value = false;
      formEpoch.value++;
    }
  }

  void _hydrate(SrmSupplier d) {
    initials.clear();
    putInitial('shortName', d.shortName);
    putInitial('fullName', d.fullName);
    final types = (d.supplierType ?? '')
        .split(RegExp(r'[,，、/|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    putInitial('supplierTypes', types);
    final regionPath = <String>[
      if ((d.province ?? '').trim().isNotEmpty) d.province!.trim(),
      if ((d.city ?? '').trim().isNotEmpty) d.city!.trim(),
      if ((d.district ?? '').trim().isNotEmpty) d.district!.trim(),
    ];
    putInitial('region', regionPath);
    putInitial('businessAddress', d.businessAddress);
    putInitial('website', d.website);
    putInitial('abnormalRecord', d.abnormalRecord);
    putInitial('penaltyHistory', d.penaltyHistory);
    putInitial('creditCode', d.creditCode);
    putInitial('legalPerson', d.legalPerson);
    putInitial('registeredCapital', d.registeredCapital?.round());
    putInitial('establishDate', _parseDate(d.establishDate));
    final start = _parseDate(d.licenseValidStart);
    final end = _parseDate(d.licenseValidEnd);
    if (start != null || end != null) {
      putInitial(
        'licenseValid',
        shad.DateTimeRange(start ?? end!, end ?? start!),
      );
    }
    putInitial('enterpriseNature', d.enterpriseNature);
    putInitial('registeredAddress', d.registeredAddress);
    putInitial('businessScope', d.businessScope);
    putInitial('cooperationMode', d.cooperationMode);
    putInitial('settlementMethod', d.settlementMethod);
    putInitial('paymentTermDays', d.paymentTermDays);
    putInitial('paymentCondition', d.paymentCondition);
    putInitial('rebatePolicy', d.rebatePolicy);
    final areas = (d.serviceArea ?? '')
        .split(RegExp(r'[,，、]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    putInitial('serviceArea', areas);
    putInitial('teamSize', d.teamSize);
    putInitial('invoiceType', d.invoiceType);
    putInitial('taxRate', d.taxRate);
    putInitial('deliveryCapacity', d.deliveryCapacity);
    putInitial('coreAdvantage', d.coreAdvantage);
    putInitial('remark', d.remark);

    blacklist.value = d.blacklistStatus == '1';
    logoPath.value = d.logoFile;
    logoLabel.value = _fileNameOf(d.logoFile);
    licensePath.value = d.licenseFile;
    licenseLabel.value = _fileNameOf(d.licenseFile);
    final contracts = (d.contractTemplate ?? '')
        .split(RegExp(r'[,;；]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    contractPaths
      ..clear()
      ..addAll(contracts);
    contractLabels
      ..clear()
      ..addAll(contracts.map(_fileNameOf).whereType<String>());

    banks
      ..clear()
      ..addAll([
        for (final b in d.bankList)
          BankDraft(
            serverId: b.id,
            bankName: b.bankName,
            bankAccount: b.bankAccount,
            invoiceInfo: b.invoiceInfo,
          ),
      ]);
    invoices
      ..clear()
      ..addAll([
        for (final i in d.invoiceList)
          InvoiceDraft(
            serverId: i.id,
            invoiceName: i.invoiceName,
            taxNo: i.taxNo,
            registerAddress: i.registerAddress,
            registerPhone: i.registerPhone,
            bankName: i.bankName,
            bankAccount: i.bankAccount,
          ),
      ]);
    contacts
      ..clear()
      ..addAll([
        for (final c in d.contactList)
          ContactDraft(
            serverId: c.id,
            name: c.name,
            nameEn: c.nameEn,
            gender: c.gender,
            ageGroup: c.ageGroup,
            deptPost: c.deptPost,
            dutyDesc: c.dutyDesc,
            mobile: c.mobile,
            email: c.email,
          ),
      ]);
    staffs
      ..clear()
      ..addAll([
        for (final s in d.staffList)
          StaffDraft(
            serverId: s.id,
            userId: int.tryParse(s.userId ?? ''),
            name: s.name,
            nameEn: s.nameEn,
            gender: s.gender,
            deptPost: s.deptPost,
          ),
      ]);
    categories
      ..clear()
      ..addAll([
        for (final c in d.categoryList)
          CategoryDraft(
            serverId: c.id,
            supplyCategory: c.supplyCategory,
            itemType: c.itemType,
            itemDesc: c.itemDesc,
          ),
      ]);
  }

  DateTime? _parseDate(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return null;
    final normalized = s.length >= 10 ? s.substring(0, 10) : s;
    return DateTime.tryParse(normalized);
  }

  String? _fileNameOf(String? path) {
    final p = path?.trim();
    if (p == null || p.isEmpty) return null;
    final parts = p.split(RegExp(r'[\\/]'));
    return parts.isEmpty ? p : parts.last;
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  void syncCategoriesFromTypes(List<String>? types) {
    final selected = types ?? const <String>[];
    final existing = {
      for (final c in categories)
        if (c.supplyCategory.trim().isNotEmpty) c.supplyCategory.trim(): c,
    };
    final next = <CategoryDraft>[];
    for (final t in selected) {
      next.add(
        existing[t] ??
            CategoryDraft(supplyCategory: t, itemType: t, itemDesc: ''),
      );
    }
    for (final c in categories) {
      final name = c.supplyCategory.trim();
      if (name.isEmpty || selected.contains(name)) continue;
      if (c.itemDesc.trim().isNotEmpty || c.itemType.trim().isNotEmpty) {
        next.add(c);
      }
    }
    categories
      ..clear()
      ..addAll(next);
  }

  Future<void> runOcr(BuildContext context) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
      windowsOptions: const WindowsOptions(lockParentWindow: true),
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      if (context.mounted) _toast(context, '无法读取图片内容', error: true);
      return;
    }
    ocrLoading.value = true;
    try {
      final result = await _api.ocrBusinessLicense(
        bytes: bytes,
        fileName: file.name,
      );
      _applyOcr(result);
      // OCR 接口本身已上传图片；若未回传路径则再走通用 OSS，便于提交 licenseFile。
      if ((result.licenseFile ?? '').trim().isEmpty) {
        try {
          final path = await _api.uploadOssFile(
            bytes: bytes,
            fileName: file.name,
          );
          licensePath.value = path;
          licenseLabel.value = file.name;
        } catch (_) {
          licenseLabel.value = file.name;
        }
      } else {
        licensePath.value = result.licenseFile;
        licenseLabel.value = file.name;
      }
      formEpoch.value++;
      if (context.mounted) {
        _toast(context, result.message?.trim().isNotEmpty == true
            ? result.message!
            : '识别成功');
      }
    } catch (e) {
      if (context.mounted) _toast(context, e.toString(), error: true);
    } finally {
      ocrLoading.value = false;
    }
  }

  void _applyOcr(SrmBusinessLicenseOcrResult r) {
    putInitial('fullName', r.companyName);
    putInitial('shortName', r.companyName);
    putInitial('creditCode', r.creditCode);
    putInitial('legalPerson', r.legalPerson);
    putInitial('registeredAddress', r.businessAddress);
    putInitial('businessAddress', r.businessAddress);
    putInitial('businessScope', r.businessScope);
    putInitial('enterpriseNature', r.companyType ?? r.companyForm);
    final capital = _parseCapitalWan(r.registeredCapital);
    if (capital != null) putInitial('registeredCapital', capital);
    final establish = _parseDate(r.registrationDate) ?? _parseDate(r.issueDate);
    if (establish != null) putInitial('establishDate', establish);
    final start = _parseDate(r.validFromDate);
    final end = _parseDate(r.validToDate);
    if (start != null || end != null) {
      putInitial(
        'licenseValid',
        shad.DateTimeRange(start ?? end!, end ?? start!),
      );
    }
    if ((r.licenseFile ?? '').trim().isNotEmpty) {
      licensePath.value = r.licenseFile;
    }
  }

  double? _parseCapitalWan(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return null;
    final m = RegExp(r'([\d.]+)').firstMatch(s);
    if (m == null) return null;
    var n = double.tryParse(m.group(1)!);
    if (n == null) return null;
    if (s.contains('亿')) n *= 10000;
    return n;
  }

  Future<void> pickLogo(BuildContext context) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      windowsOptions: const WindowsOptions(lockParentWindow: true),
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      if (context.mounted) _toast(context, '无法读取文件', error: true);
      return;
    }
    if (bytes.length > 2 * 1024 * 1024) {
      if (context.mounted) _toast(context, 'Logo 需 ≤2MB', error: true);
      return;
    }
    try {
      final path = await _api.uploadOssFile(bytes: bytes, fileName: file.name);
      logoPath.value = path;
      logoLabel.value = file.name;
    } catch (e) {
      if (context.mounted) _toast(context, e.toString(), error: true);
    }
  }

  Future<void> pickContract(BuildContext context) async {
    if (contractPaths.length >= 5) {
      _toast(context, '最多上传 5 个合同模板', error: true);
      return;
    }
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'png',
        'jpg',
        'jpeg',
        'webp',
        'pdf',
        'doc',
        'docx',
      ],
      windowsOptions: const WindowsOptions(lockParentWindow: true),
    );
    if (picked.isEmpty) return;
    for (final file in picked) {
      if (contractPaths.length >= 5) break;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      try {
        final path =
            await _api.uploadOssFile(bytes: bytes, fileName: file.name);
        contractPaths.add(path);
        contractLabels.add(file.name);
      } catch (e) {
        if (context.mounted) _toast(context, e.toString(), error: true);
        break;
      }
    }
  }

  void removeContractAt(int index) {
    if (index < 0 || index >= contractPaths.length) return;
    contractPaths.removeAt(index);
    if (index < contractLabels.length) contractLabels.removeAt(index);
  }

  void addBank() => banks.add(BankDraft());
  void removeBank(int id) => banks.removeWhere((e) => e.id == id);
  void duplicateBank(BankDraft src) {
    banks.add(
      BankDraft(
        bankName: src.bankName,
        bankAccount: src.bankAccount,
        invoiceInfo: src.invoiceInfo,
      ),
    );
  }

  void addInvoice() => invoices.add(InvoiceDraft());
  void removeInvoice(int id) => invoices.removeWhere((e) => e.id == id);
  void duplicateInvoice(InvoiceDraft src) {
    invoices.add(
      InvoiceDraft(
        invoiceName: src.invoiceName,
        taxNo: src.taxNo,
        registerAddress: src.registerAddress,
        registerPhone: src.registerPhone,
        bankName: src.bankName,
        bankAccount: src.bankAccount,
      ),
    );
  }

  void addContact() => contacts.add(ContactDraft());
  void removeContact(int id) => contacts.removeWhere((e) => e.id == id);

  void addStaffFromEmployees(List<HrmEmployee> list) {
    final exist = staffs.map((e) => e.userId).whereType<int>().toSet();
    for (final e in list) {
      final uid = e.userId;
      if (uid == null || exist.contains(uid)) continue;
      exist.add(uid);
      staffs.add(
        StaffDraft(
          userId: uid,
          name: e.name ?? e.aliasName ?? '',
          nameEn: e.englishName ?? '',
          gender: e.gender,
          deptPost: hrmEmployeeDeptPost(e),
        ),
      );
    }
  }

  void removeStaff(int id) => staffs.removeWhere((e) => e.id == id);

  String? _validateChildTables() {
    for (final b in banks) {
      if (b.bankName.trim().isEmpty || b.bankAccount.trim().isEmpty) {
        return '请完善银行账户信息（开户行、银行账号）';
      }
    }
    for (final i in invoices) {
      if (i.invoiceName.trim().isEmpty ||
          i.taxNo.trim().isEmpty ||
          i.bankName.trim().isEmpty ||
          i.bankAccount.trim().isEmpty) {
        return '请完善开票信息（名称、税号、开户行、开户银行账号）';
      }
    }
    for (final c in contacts) {
      if (c.name.trim().isEmpty ||
          c.mobile.trim().isEmpty ||
          c.email.trim().isEmpty) {
        return '请完善联系人信息（姓名、手机号、邮箱）';
      }
    }
    return null;
  }

  Future<bool> save({
    required BuildContext context,
    required bool continueAdd,
  }) async {
    try {
      saving.value = true;
      showChildErrors.value = true;
      final childErr = _validateChildTables();
      if (childErr != null) {
        if (context.mounted) _toast(context, childErr, error: true);
        return false;
      }
      final ok = await form.submit((values) async {
        final body = _buildBody(values);
        if (isEdit) {
          body['id'] = int.tryParse(editId!) ?? editId;
          await _api.updateSupplier(body);
        } else {
          await _api.createSupplier(body);
        }
      });
      if (!ok) return false;
      if (!context.mounted) return true;
      _toast(context, isEdit ? '更新成功' : '创建成功');
      if (continueAdd && !isEdit) {
        _resetForContinue();
        return true;
      }
      return true;
    } catch (e) {
      if (context.mounted) _toast(context, e.toString(), error: true);
      return false;
    } finally {
      saving.value = false;
    }
  }

  void _resetForContinue() {
    initials.clear();
    banks.clear();
    invoices.clear();
    contacts.clear();
    staffs.clear();
    categories.clear();
    blacklist.value = false;
    logoPath.value = null;
    logoLabel.value = null;
    licensePath.value = null;
    licenseLabel.value = null;
    contractPaths.clear();
    contractLabels.clear();
    form.reset();
    formEpoch.value++;
  }

  Map<String, dynamic> _buildBody(Map<String, Object?> values) {
    String? str(String key) {
      final v = values[key] ?? initials[key];
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    num? numOf(String key) {
      final v = values[key] ?? initials[key];
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    int? intOf(String key) {
      final n = numOf(key);
      return n?.round();
    }

    final types = <String>[];
    final rawTypes = values['supplierTypes'] ?? initials['supplierTypes'];
    if (rawTypes is List) {
      for (final e in rawTypes) {
        final s = e?.toString().trim();
        if (s != null && s.isNotEmpty) types.add(s);
      }
    }

    final region = <String>[];
    final rawRegion = values['region'] ?? initials['region'];
    if (rawRegion is List) {
      for (final e in rawRegion) {
        final s = e?.toString().trim();
        if (s != null && s.isNotEmpty) region.add(s);
      }
    }
    final province = region.isNotEmpty ? region[0] : null;
    final city = region.length > 1 ? region[1] : null;
    final district = region.length > 2 ? region[2] : null;
    final regionName = region.isEmpty ? null : region.join(' / ');

    final areas = <String>[];
    final rawAreas = values['serviceArea'] ?? initials['serviceArea'];
    if (rawAreas is List) {
      for (final e in rawAreas) {
        final s = e?.toString().trim();
        if (s != null && s.isNotEmpty) areas.add(s);
      }
    }

    DateTime? establish;
    final ed = values['establishDate'] ?? initials['establishDate'];
    if (ed is DateTime) establish = ed;

    DateTime? licenseStart;
    DateTime? licenseEnd;
    final lv = values['licenseValid'] ?? initials['licenseValid'];
    if (lv is shad.DateTimeRange) {
      licenseStart = lv.start;
      licenseEnd = lv.end;
    } else if (lv is DateTimeRange) {
      licenseStart = lv.start;
      licenseEnd = lv.end;
    }

    final shortName = str('shortName');
    final fullName = str('fullName');
    final cooperationMode = str('cooperationMode');
    final settlementMethod = str('settlementMethod');
    if (shortName == null ||
        fullName == null ||
        types.isEmpty ||
        cooperationMode == null ||
        settlementMethod == null) {
      throw SrmSupplierApiException(
        '请填写必填项：简称、全称、供应商类型、合作模式、结算方式',
      );
    }

    final body = <String, dynamic>{
      'shortName': shortName,
      'fullName': fullName,
      'supplierType': types.join(','),
      'cooperationMode': cooperationMode,
      'settlementMethod': settlementMethod,
      'blacklistStatus': blacklist.value ? '1' : '0',
      if (province != null) 'province': province,
      if (city != null) 'city': city,
      if (district != null) 'district': district,
      if (regionName != null) 'regionName': regionName,
      if (str('businessAddress') != null)
        'businessAddress': str('businessAddress'),
      if (logoPath.value != null) 'logoFile': logoPath.value,
      if (str('website') != null) 'website': str('website'),
      if (str('abnormalRecord') != null)
        'abnormalRecord': str('abnormalRecord'),
      if (str('penaltyHistory') != null)
        'penaltyHistory': str('penaltyHistory'),
      if (licensePath.value != null) 'licenseFile': licensePath.value,
      if (str('creditCode') != null) 'creditCode': str('creditCode'),
      if (str('legalPerson') != null) 'legalPerson': str('legalPerson'),
      if (numOf('registeredCapital') != null)
        'registeredCapital': numOf('registeredCapital'),
      if (establish != null) 'establishDate': _fmtDate(establish),
      if (licenseStart != null) 'licenseValidStart': _fmtDate(licenseStart),
      if (licenseEnd != null) 'licenseValidEnd': _fmtDate(licenseEnd),
      if (str('enterpriseNature') != null)
        'enterpriseNature': str('enterpriseNature'),
      if (str('registeredAddress') != null)
        'registeredAddress': str('registeredAddress'),
      if (str('businessScope') != null) 'businessScope': str('businessScope'),
      if (intOf('paymentTermDays') != null)
        'paymentTermDays': intOf('paymentTermDays'),
      if (str('paymentCondition') != null)
        'paymentCondition': str('paymentCondition'),
      if (str('rebatePolicy') != null) 'rebatePolicy': str('rebatePolicy'),
      if (contractPaths.isNotEmpty)
        'contractTemplate': contractPaths.join(','),
      if (areas.isNotEmpty) 'serviceArea': areas.join(','),
      if (intOf('teamSize') != null) 'teamSize': intOf('teamSize'),
      if (str('invoiceType') != null) 'invoiceType': str('invoiceType'),
      if (str('taxRate') != null) 'taxRate': str('taxRate'),
      if (str('deliveryCapacity') != null)
        'deliveryCapacity': str('deliveryCapacity'),
      if (str('coreAdvantage') != null) 'coreAdvantage': str('coreAdvantage'),
      if (str('remark') != null) 'remark': str('remark'),
      'bankList': [
        for (var i = 0; i < banks.length; i++)
          {
            if (banks[i].serverId != null)
              'id': int.tryParse(banks[i].serverId!) ?? banks[i].serverId,
            'bankName': banks[i].bankName.trim(),
            'bankAccount': banks[i].bankAccount.trim(),
            'invoiceInfo': banks[i].invoiceInfo.trim(),
            'sort': i + 1,
          },
      ],
      'invoiceList': [
        for (var i = 0; i < invoices.length; i++)
          {
            if (invoices[i].serverId != null)
              'id':
                  int.tryParse(invoices[i].serverId!) ?? invoices[i].serverId,
            'invoiceName': invoices[i].invoiceName.trim(),
            'taxNo': invoices[i].taxNo.trim(),
            'registerAddress': invoices[i].registerAddress.trim(),
            'registerPhone': invoices[i].registerPhone.trim(),
            'bankName': invoices[i].bankName.trim(),
            'bankAccount': invoices[i].bankAccount.trim(),
            'sort': i + 1,
          },
      ],
      'contactList': [
        for (var i = 0; i < contacts.length; i++)
          {
            if (contacts[i].serverId != null)
              'id':
                  int.tryParse(contacts[i].serverId!) ?? contacts[i].serverId,
            'name': contacts[i].name.trim(),
            'nameEn': contacts[i].nameEn.trim(),
            if (contacts[i].gender != null) 'gender': contacts[i].gender,
            if (contacts[i].ageGroup != null) 'ageGroup': contacts[i].ageGroup,
            'deptPost': contacts[i].deptPost.trim(),
            'dutyDesc': contacts[i].dutyDesc.trim(),
            'mobile': contacts[i].mobile.trim(),
            'email': contacts[i].email.trim(),
            'sort': i + 1,
          },
      ],
      'staffList': [
        for (var i = 0; i < staffs.length; i++)
          {
            if (staffs[i].serverId != null)
              'id': int.tryParse(staffs[i].serverId!) ?? staffs[i].serverId,
            if (staffs[i].userId != null) 'userId': staffs[i].userId,
            'name': staffs[i].name.trim(),
            'nameEn': staffs[i].nameEn.trim(),
            if (staffs[i].gender != null) 'gender': staffs[i].gender,
            'deptPost': staffs[i].deptPost.trim(),
            'sort': i + 1,
          },
      ],
      'categoryList': [
        for (var i = 0; i < categories.length; i++)
          {
            if (categories[i].serverId != null)
              'id': int.tryParse(categories[i].serverId!) ??
                  categories[i].serverId,
            'supplyCategory': categories[i].supplyCategory.trim(),
            'itemType': categories[i].itemType.trim(),
            'itemDesc': categories[i].itemDesc.trim(),
            'sort': i + 1,
          },
      ],
    };
    return body;
  }

  void _toast(BuildContext context, String title, {bool error = false}) {
    if (!context.mounted) return;
    AppToast.show(
      context: context,
      title: title,
      location:
          error ? AppToastLocation.topCenter : AppToastLocation.bottomRight,
    );
  }
}
