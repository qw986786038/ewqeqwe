import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:pinyin/pinyin.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_employee.dart';
import '../../../../models/srm_supplier.dart';
import '../../../../services/file_center_api.dart';
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
    String? remark,
  })  : id = _DraftId.next(),
        supplyCategory = supplyCategory ?? '',
        itemType = itemType ?? '',
        itemDesc = itemDesc ?? '',
        remark = remark ?? '';

  final int id;
  final String? serverId;
  String supplyCategory;
  String itemType;
  String itemDesc;
  String remark;
}

/// 详情页点哪张卡片，就只编辑哪一块。空表示新建或整单编辑。
enum SupplierEditSection {
  overview,
  basic,
  bank,
  invoice,
  contract,
  capability,
}

/// 新建 / 编辑供应商。
class SupplierEditController extends LxController {
  SupplierEditController({this.supplierId, this.section});

  final String? supplierId;
  final SupplierEditSection? section;

  String get dialogTitle {
    if (!isEdit) return '新建供应商';
    return switch (section) {
      SupplierEditSection.overview => '编辑供应商概览',
      SupplierEditSection.basic => '编辑基本信息',
      SupplierEditSection.bank => '编辑银行账户',
      SupplierEditSection.invoice => '编辑开票信息',
      SupplierEditSection.contract => '编辑合同与结算',
      SupplierEditSection.capability => '编辑能力与品类',
      null => '编辑供应商',
    };
  }

  bool shows(SupplierEditSection target) => section == null || section == target;
  final _api = SrmSupplierApi();
  final _fileCenterApi = FileCenterApi();
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
  /// 刚上传的本地预览；与 [logoPreviewUrl] 二选一展示。
  final logoBytes = Rxn<Uint8List>();
  final logoPreviewUrl = Rxn<String>();
  final licensePath = Rxn<String>();
  final licenseLabel = Rxn<String>();
  final contractPaths = <String>[].obs;
  final contractLabels = <String>[].obs;
  /// 与 [contractPaths] 对齐的本地缩略图（非图片则为 null）。
  final contractPreviewBytes = <Uint8List?>[].obs;
  final contractPreviewUrls = <String?>[].obs;

  bool get hasLogo =>
      (logoPath.value?.trim().isNotEmpty ?? false) ||
      (logoBytes.value?.isNotEmpty ?? false) ||
      (logoPreviewUrl.value?.trim().isNotEmpty ?? false);

  bool get isEdit =>
      supplierId != null && supplierId!.trim().isNotEmpty;

  String? get editId => supplierId?.trim();

  static const supplierTypeOptions = [
    AppOption(value: '设备采购', label: '设备采购'),
    AppOption(value: '媒介采购', label: '媒介采购'),
    AppOption(value: '物业租赁', label: '物业租赁'),
    AppOption(value: '维保运维', label: '维保运维'),
    AppOption(value: '灵活用工', label: '灵活用工'),
    AppOption(value: '技术服务', label: '技术服务'),
    AppOption(value: '物料制作', label: '物料制作'),
    AppOption(value: '工程施工', label: '工程施工'),
    AppOption(value: '其它', label: '其它'),
  ];

  static const cooperationModeOptions = [
    AppOption(value: '框架协议', label: '框架协议'),
    AppOption(value: '单次采购', label: '单次采购'),
  ];

  static const settlementMethodOptions = [
    AppOption(value: '30天', label: '30天'),
    AppOption(value: '60天', label: '60天'),
    AppOption(value: '90天', label: '90天'),
    AppOption(value: '按次结算', label: '按次结算'),
    AppOption(value: 'X天', label: 'X天'),
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

  /// 媒介采购 → 媒体类型（字典；可多选）。
  static const mediaTypeOptions = [
    AppOption(value: '户外LED屏', label: '户外LED屏'),
    AppOption(value: '户外大牌', label: '户外大牌'),
    AppOption(value: '灯光秀', label: '灯光秀'),
    AppOption(value: '公交车体', label: '公交车体'),
    AppOption(value: '公交候车亭', label: '公交候车亭'),
    AppOption(value: '地铁类', label: '地铁类'),
    AppOption(value: '高铁类', label: '高铁类'),
    AppOption(value: '机场类', label: '机场类'),
    AppOption(value: '影院灯箱', label: '影院灯箱'),
    AppOption(value: '电梯框架', label: '电梯框架'),
    AppOption(value: '电梯LCD屏', label: '电梯LCD屏'),
  ];

  /// 物业租赁 → 物业类型。
  static const propertyTypeOptions = [
    AppOption(value: '广告位租赁', label: '广告位租赁'),
    AppOption(value: '场地租赁', label: '场地租赁'),
    AppOption(value: '物业管理', label: '物业管理'),
  ];

  /// 设备采购 → 设备类型。
  static const equipmentTypeOptions = [
    AppOption(value: 'LCD屏', label: 'LCD屏'),
    AppOption(value: 'LED屏', label: 'LED屏'),
    AppOption(value: '广告灯箱', label: '广告灯箱'),
  ];

  static const genderOptions = [
    AppOption(value: '1', label: '男'),
    AppOption(value: '2', label: '女'),
    AppOption(value: '0', label: '未知'),
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
    final invoiceTypes = (d.invoiceType ?? '')
        .split(RegExp(r'[,，、]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    putInitial('invoiceType', invoiceTypes);
    final taxRate = (d.taxRate ?? '').trim();
    if (taxRate.isNotEmpty) {
      const presets = {'6%', '9%', '13%'};
      if (presets.contains(taxRate)) {
        putInitial('taxRate', taxRate);
      } else {
        putInitial('taxRate', '其他');
        if (taxRate != '其他') {
          putInitial(
            'taxRateCustom',
            taxRate.endsWith('%')
                ? taxRate.substring(0, taxRate.length - 1)
                : taxRate,
          );
        }
      }
    }
    putInitial('deliveryCapacity', d.deliveryCapacity);
    putInitial('coreAdvantage', d.coreAdvantage);
    putInitial('remark', d.remark);

    blacklist.value = d.blacklistStatus == '1';
    _hydrateLogo(d.logoFile);
    licensePath.value = d.licenseFile;
    licenseLabel.value = _fileNameOf(d.licenseFile);
    _hydrateContracts(d.contractTemplate);

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
            remark: c.remark,
          ),
      ]);
  }

  void removeCategory(int id) =>
      categories.removeWhere((e) => e.id == id);

  String _normalizeOcrDigits(String raw) {
    const wide = '０１２３４５６７８９';
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      final ch = String.fromCharCode(rune);
      final index = wide.indexOf(ch);
      if (index >= 0) {
        buffer.write(index);
      } else if (ch == '．') {
        buffer.write('.');
      } else if (ch == '，') {
        buffer.write(',');
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  DateTime? _parseDate(String? raw) {
    final source = raw?.trim();
    if (source == null || source.isEmpty) return null;
    final s = _normalizeOcrDigits(source);
    final head = s.length >= 10 ? s.substring(0, 10) : s;
    final direct = DateTime.tryParse(
      head.replaceAll('/', '-').replaceAll('.', '-'),
    );
    if (direct != null) return direct;
    final compact = RegExp(r'(\d{4})(\d{2})(\d{2})').firstMatch(s);
    if (compact != null) {
      final parsed = DateTime.tryParse(
        '${compact.group(1)}-${compact.group(2)}-${compact.group(3)}',
      );
      if (parsed != null) return parsed;
    }
    final text = RegExp(
      r'(\d{4})\s*[年./-]\s*(\d{1,2})\s*[月./-]\s*(\d{1,2})',
    ).firstMatch(s);
    if (text != null) {
      final month = text.group(2)!.padLeft(2, '0');
      final day = text.group(3)!.padLeft(2, '0');
      final parsed = DateTime.tryParse('${text.group(1)}-$month-$day');
      if (parsed != null) return parsed;
    }
    final yearMonth = RegExp(
      r'(\d{4})\s*[年./-]\s*(\d{1,2})',
    ).firstMatch(s);
    if (yearMonth == null) return null;
    final month = yearMonth.group(2)!.padLeft(2, '0');
    return DateTime.tryParse('${yearMonth.group(1)}-$month-01');
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
            CategoryDraft(supplyCategory: t, itemType: '', itemDesc: ''),
      );
    }
    for (final c in categories) {
      final name = c.supplyCategory.trim();
      if (name.isEmpty || selected.contains(name)) continue;
      if (c.itemDesc.trim().isNotEmpty ||
          c.itemType.trim().isNotEmpty ||
          c.remark.trim().isNotEmpty) {
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
      // Form 使用固定 GlobalKey，仅改 initialValue / formEpoch 不会刷新字段状态；
      // 先把当前表单值并入 initials，再叠 OCR，重建后 reset 才能回填。
      _snapshotFormToInitials();
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        form.reset();
      });
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

  void _snapshotFormToInitials() {
    for (final entry in form.values.entries) {
      putInitial(entry.key, entry.value);
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
    if (capital != null) putInitial('registeredCapital', capital.round());
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

  /// 营业执照注册资本统一成「万元」。`1000万元` 取 1000，`5000000元` 折成 500。
  double? _parseCapitalWan(String? raw) {
    final source = raw?.trim();
    if (source == null || source.isEmpty) return null;
    final cleaned = _normalizeOcrDigits(source).replaceAll(',', '');
    final m = RegExp(r'([\d.]+)').firstMatch(cleaned);
    if (m == null) return null;
    var n = double.tryParse(m.group(1)!);
    if (n == null) return null;
    final hasYi = cleaned.contains('亿');
    final hasWan = cleaned.contains('万');
    final hasYuan = cleaned.contains('元') || cleaned.contains('圆');
    if (hasYi) {
      n *= 10000;
    } else if (hasYuan && !hasWan) {
      n /= 10000;
    } else if (!hasWan && !hasYi && n >= 100000) {
      // 未标单位的大数按「元」折成万元。
      n /= 10000;
    }
    return n;
  }

  void _hydrateLogo(String? raw) {
    logoBytes.value = null;
    logoPreviewUrl.value = null;
    final v = raw?.trim();
    if (v == null || v.isEmpty) {
      logoPath.value = null;
      logoLabel.value = null;
      return;
    }
    logoPath.value = v;
    logoLabel.value = _fileNameOf(v) ?? 'logo';
    if (v.startsWith('http://') || v.startsWith('https://')) {
      logoPreviewUrl.value = v;
      return;
    }
    // fileId：异步拉展示地址，失败不影响编辑。
    if (RegExp(r'^\d+$').hasMatch(v)) {
      _fileCenterApi.fetchInfo(v).then((detail) {
        final url = detail.displayUrl?.trim().isNotEmpty == true
            ? detail.displayUrl
            : (detail.previewUrl?.trim().isNotEmpty == true
                ? detail.previewUrl
                : detail.objectUrl ?? detail.url);
        if ((url ?? '').trim().isEmpty) return;
        if (logoPath.value == v) {
          logoPreviewUrl.value = url!.trim();
          final name = detail.originalName ?? detail.fileName;
          if ((name ?? '').trim().isNotEmpty) {
            logoLabel.value = name!.trim();
          }
        }
      }).catchError((_) {});
    }
  }

  void clearLogo() {
    logoPath.value = null;
    logoLabel.value = null;
    logoBytes.value = null;
    logoPreviewUrl.value = null;
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
      // 业务字段存 fileId：presign → PUT → directComplete。
      final upload = await _fileCenterApi.uploadBytes(
        bytes: bytes,
        fileName: file.name,
        fetchDetail: false,
      );
      logoPath.value = upload.fileId;
      logoLabel.value = file.name;
      logoBytes.value = bytes;
      logoPreviewUrl.value = upload.displayUrl ?? upload.publicUrl;
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
        final upload = await _fileCenterApi.uploadBytes(
          bytes: bytes,
          fileName: file.name,
          fetchDetail: false,
        );
        final name = file.name;
        contractPaths.add(upload.fileId);
        contractLabels.add(name);
        contractPreviewBytes.add(_isImageFileName(name) ? bytes : null);
        contractPreviewUrls.add(
          _isImageFileName(name)
              ? (upload.displayUrl ?? upload.publicUrl)
              : null,
        );
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
    if (index < contractPreviewBytes.length) {
      contractPreviewBytes.removeAt(index);
    }
    if (index < contractPreviewUrls.length) {
      contractPreviewUrls.removeAt(index);
    }
  }

  void _hydrateContracts(String? raw) {
    final contracts = (raw ?? '')
        .split(RegExp(r'[,;；]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    contractPaths
      ..clear()
      ..addAll(contracts);
    contractLabels
      ..clear()
      ..addAll([
        for (final c in contracts) _fileNameOf(c) ?? c,
      ]);
    contractPreviewBytes
      ..clear()
      ..addAll(List<Uint8List?>.filled(contracts.length, null));
    contractPreviewUrls
      ..clear()
      ..addAll(List<String?>.filled(contracts.length, null));
    for (var i = 0; i < contracts.length; i++) {
      final v = contracts[i];
      if (v.startsWith('http://') || v.startsWith('https://')) {
        if (_isImageFileName(v)) contractPreviewUrls[i] = v;
        continue;
      }
      if (!RegExp(r'^\d+$').hasMatch(v)) continue;
      final index = i;
      final fileId = v;
      _fileCenterApi.fetchInfo(fileId).then((detail) {
        if (index >= contractPaths.length ||
            contractPaths[index] != fileId) {
          return;
        }
        final name = detail.originalName ?? detail.fileName;
        if ((name ?? '').trim().isNotEmpty) {
          contractLabels[index] = name!.trim();
        }
        final url = detail.displayUrl?.trim().isNotEmpty == true
            ? detail.displayUrl
            : (detail.previewUrl?.trim().isNotEmpty == true
                ? detail.previewUrl
                : detail.objectUrl ?? detail.url);
        final label = contractLabels[index];
        if ((url ?? '').trim().isNotEmpty && _isImageFileName(label)) {
          contractPreviewUrls[index] = url!.trim();
        }
      }).catchError((_) {});
    }
  }

  static bool _isImageFileName(String? name) {
    final n = name?.trim().toLowerCase() ?? '';
    return n.endsWith('.png') ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.webp') ||
        n.endsWith('.bmp') ||
        n.endsWith('.gif');
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

  void addStaff() => staffs.add(StaffDraft());

  /// 将通讯录员工写入某一行我方对接人；[userId] 已被其它行占用时返回 `false`。
  bool applyEmployeeToStaff(StaffDraft item, HrmEmployee e) {
    final uid = e.userId;
    if (uid != null) {
      for (final s in staffs) {
        if (s.id != item.id && s.userId == uid) return false;
      }
    }
    item.userId = uid;
    item.name = e.name ?? e.aliasName ?? '';
    final converted = _chineseToEnglishName(item.name);
    item.nameEn = converted.isNotEmpty
        ? converted
        : (e.englishName?.trim() ?? '');
    item.gender = _mapHrmGenderToSupplier(e.gender);
    item.deptPost = hrmEmployeeDeptPost(e);
    if (item.deptPost == '-') item.deptPost = '';
    staffs.refresh();
    return true;
  }

  /// 中文姓名转写入 Name 的英文拼写（姓、名首字母大写）。
  static String _chineseToEnglishName(String zh) {
    final raw = PinyinHelper.getPinyinE(
      zh.trim(),
      separator: ' ',
      format: PinyinFormat.WITHOUT_TONE,
    ).trim();
    if (raw.isEmpty) return '';
    return raw
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) {
          final lower = w.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  /// HRM 通讯录 `0/1`（男/女）→ 本表单 `1/2/0`（男/女/未知）。
  static String? _mapHrmGenderToSupplier(String? gender) {
    final g = gender?.trim() ?? '';
    return switch (g) {
      '0' || '男' => '1',
      '1' || '女' => '2',
      '2' => '2',
      '' => null,
      _ => g,
    };
  }

  void removeStaff(int id) => staffs.removeWhere((e) => e.id == id);

  static final _mobilePattern = RegExp(r'^\d{1,11}$');
  static final _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  /// 手机号：只能是数字，且不能超过 11 位。空值在必填时提示。
  static String? contactMobileError(
    String raw, {
    bool required = true,
    String label = '手机号',
  }) {
    final text = raw.trim();
    if (text.isEmpty) return required ? '请填写$label' : null;
    if (!_mobilePattern.hasMatch(text)) {
      return '$label只能输入数字，且不能超过11位';
    }
    return null;
  }

  /// 邮箱须符合邮箱格式。空值在必填时提示。
  static String? contactEmailError(String raw, {bool required = true}) {
    final text = raw.trim();
    if (text.isEmpty) return required ? '请填写邮箱' : null;
    if (!_emailPattern.hasMatch(text)) return '请输入正确的邮箱';
    return null;
  }

  String? _validateChildTables() {
    if (shows(SupplierEditSection.bank)) {
      for (final b in banks) {
        if (b.bankName.trim().isEmpty || b.bankAccount.trim().isEmpty) {
          return '请完善银行账户信息（开户行、银行账号）';
        }
      }
    }
    if (shows(SupplierEditSection.invoice)) {
      for (final i in invoices) {
        if (i.invoiceName.trim().isEmpty ||
            i.taxNo.trim().isEmpty ||
            i.bankName.trim().isEmpty ||
            i.bankAccount.trim().isEmpty) {
          return '请完善开票信息（名称、税号、开户行、开户银行账号）';
        }
        final phoneErr = contactMobileError(
          i.registerPhone,
          required: false,
          label: '注册电话',
        );
        if (phoneErr != null) return phoneErr;
      }
    }
    if (shows(SupplierEditSection.overview)) {
      for (final c in contacts) {
        if (c.name.trim().isEmpty) {
          return '请完善联系人信息（姓名、手机号、邮箱）';
        }
        final mobileErr = contactMobileError(c.mobile);
        if (mobileErr != null) return mobileErr;
        final emailErr = contactEmailError(c.email);
        if (emailErr != null) return emailErr;
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
    clearLogo();
    licensePath.value = null;
    licenseLabel.value = null;
    contractPaths.clear();
    contractLabels.clear();
    contractPreviewBytes.clear();
    contractPreviewUrls.clear();
    form.reset();
    formEpoch.value++;
  }

  /// 「其他」时用手填税率（补 %）；预设项原样提交。
  String? _resolveTaxRate(String? Function(String key) str) {
    final selected = str('taxRate');
    if (selected == null) return null;
    if (selected != '其他') return selected;
    final custom = str('taxRateCustom');
    if (custom == null) return '其他';
    final raw = custom.endsWith('%')
        ? custom.substring(0, custom.length - 1)
        : custom;
    final n = num.tryParse(raw);
    if (n == null || n < 0) {
      throw SrmSupplierApiException('请输入税率');
    }
    if (n > 100) return '100%';
    return '$raw%';
  }

  /// 「X天」保存为实际天数，如 `45天`；其它选项原样提交。
  String? _resolveSettlement(String? Function(String key) str) {
    final selected = str('settlementMethod');
    if (selected == null || selected != 'X天') return selected;
    final custom = str('settlementCustomDays');
    final n = int.tryParse(custom ?? '');
    if (custom == null || n == null || n < 0 || n > 3650) return null;
    return '$n天';
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

    final invoiceTypes = <String>[];
    final rawInvoiceTypes = values['invoiceType'] ?? initials['invoiceType'];
    if (rawInvoiceTypes is List) {
      for (final e in rawInvoiceTypes) {
        final s = e?.toString().trim();
        if (s != null && s.isNotEmpty) invoiceTypes.add(s);
      }
    } else {
      final one = rawInvoiceTypes?.toString().trim();
      if (one != null && one.isNotEmpty) invoiceTypes.add(one);
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
    final settlementMethod = _resolveSettlement(str);
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
      if (invoiceTypes.isNotEmpty) 'invoiceType': invoiceTypes.join(','),
      if (_resolveTaxRate(str) != null) 'taxRate': _resolveTaxRate(str),
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
            'remark': categories[i].remark.trim(),
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
