class ApiConfig {
  /// 正式环境
  static const String baseUrl =
      'https://saas.palsmon.com/prod-api/media-market-service';
  /// 本地测试环境
  // static const String baseUrl =
  //     'http://192.168.5.77:8089/media-market-service';
  // static const String baseUrl =
  //     'http://192.168.5.37:8089/media-market-service';
  /// 内网测试环境
  // static const String baseUrl =
  //     'http://192.168.5.45:8089/media-market-service';
  static const String clientId = '099f6954410409ca0b9cc736d9ba1020';

  /// 桌面端固定租户编号（登录 Body 必传）。
  /// 正式环境
  static const String tenantId = '922729';
  /// 本地测试环境
  // static const String tenantId = '469579';

  static const String passwordLogin = '/desktop/passwordLogin';
  /// 按用户名查租户列表（登录前）：`GET /desktop/tenant/listByUsername?username=`。
  static const String tenantListByUsername = '/desktop/tenant/listByUsername';
  static const String captchaCode = '/desktop/code';
  static const String brandOverview = '/desktop/oac/brand/overview';
  static const String brandList = '/desktop/oac/brand/list';
  /// 品牌视角导出 Excel：`POST /desktop/oac/brand/export`。
  static const String brandExport = '/desktop/oac/brand/export';
  /// 企业视角 KPI：`GET /desktop/oac/enterprise/overview`。
  static const String enterpriseOverview = '/desktop/oac/enterprise/overview';
  /// 企业视角列表：`GET /desktop/oac/enterprise/list`。
  static const String enterpriseList = '/desktop/oac/enterprise/list';
  /// 4A 公司视角 KPI：`GET /desktop/oac/agency/overview`。
  static const String agencyOverview = '/desktop/oac/agency/overview';
  /// 4A 公司视角列表：`GET /desktop/oac/agency/list`。
  static const String agencyList = '/desktop/oac/agency/list';
  /// 人视角 KPI：`GET /desktop/oac/person/overview`。
  static const String personOverview = '/desktop/oac/person/overview';
  /// 人视角列表：`GET /desktop/oac/person/list`。
  static const String personList = '/desktop/oac/person/list';
  static const String createOrder = '/admin/oac/order';
  /// 更新订单：`PUT /desktop/oac/order`。
  static const String updateOrder = '/desktop/oac/order';
  /// 更新订单关联 4A：`PUT /desktop/oac/order/agency`（body: id + agencyCustomerId，空则清空）。
  static const String updateOrderAgency = '/desktop/oac/order/agency';
  static const String customerList = '/desktop/oac/customer/list';
  static const String customerOverview = '/desktop/oac/customer/overview';
  static const String customerCreate = '/desktop/oac/customer';
  /// 客户档案导出（按可见列；序号固定）：`POST /desktop/oac/customer/export`。
  static const String customerExport = '/desktop/oac/customer/export';
  /// 下载「导入联系人」模板：`POST /desktop/oac/customer/importContactTemplate`。
  static const String customerImportContactTemplate =
      '/desktop/oac/customer/importContactTemplate';
  /// 解析联系人导入文件预览：`POST /desktop/oac/customer/importContact/preview`。
  static const String customerImportContactPreview =
      '/desktop/oac/customer/importContact/preview';
  /// 确认导入联系人：`POST /desktop/oac/customer/importContact/confirm`。
  static const String customerImportContactConfirm =
      '/desktop/oac/customer/importContact/confirm';
  /// 下载「导入经营主体」模板：`POST /desktop/oac/customer/importEnterpriseTemplate`。
  static const String customerImportEnterpriseTemplate =
      '/desktop/oac/customer/importEnterpriseTemplate';
  /// 解析经营主体导入文件预览：`POST /desktop/oac/customer/importEnterprise/preview`。
  static const String customerImportEnterprisePreview =
      '/desktop/oac/customer/importEnterprise/preview';
  /// 确认导入经营主体：`POST /desktop/oac/customer/importEnterprise/confirm`。
  static const String customerImportEnterpriseConfirm =
      '/desktop/oac/customer/importEnterprise/confirm';
  static const String adCodeList = '/desktop/common/ad-code';
  static const String hrmDept = '/desktop/hrm/dept';
  /// 公司整体配置：`GET /desktop/hrm/dept/summary`。
  static const String hrmDeptSummary = '/desktop/hrm/dept/summary';
  static const String hrmEmployeeDirectory = '/desktop/hrm/employee-directory';
  static const String hrmPost = '/desktop/hrm/post';
  /// 职务序列列表：`GET /desktop/hrm/post-seq`。
  static const String hrmPostSeq = '/desktop/hrm/post-seq';
  /// 职务序列职级列表：`GET /desktop/hrm/post-seq-level`。
  static const String hrmPostSeqLevel = '/desktop/hrm/post-seq-level';
  /// 编制分页 / 增删改：`GET|POST /desktop/hrm/position`，`PUT|DELETE …/{id}`。
  static const String hrmPosition = '/desktop/hrm/position';
  /// 编制全量列表（组织架构等）：`GET /desktop/hrm/position/list`。
  static const String hrmPositionList = '/desktop/hrm/position/list';
  static const String hrmEmployeeAssignOnDuty =
      '/desktop/hrm/employee-assign/on-duty';
  /// 任职：`POST /desktop/hrm/employee-assign/appoint`。
  static const String hrmEmployeeAssignAppoint =
      '/desktop/hrm/employee-assign/appoint';
  /// 卸任：`POST /desktop/hrm/employee-assign/relieve`。
  static const String hrmEmployeeAssignRelieve =
      '/desktop/hrm/employee-assign/relieve';
  /// 修改职级：`POST /desktop/hrm/employee-assign/level`。
  static const String hrmEmployeeAssignLevel =
      '/desktop/hrm/employee-assign/level';
  /// 调岗：`POST /desktop/hrm/employee-assign/transfer`。
  static const String hrmEmployeeAssignTransfer =
      '/desktop/hrm/employee-assign/transfer';
  /// 员工分页：`GET /desktop/hrm/employee`。
  static const String hrmEmployeeList = '/desktop/hrm/employee';
  /// 添加待入职：`POST /desktop/hrm/employee/pending-active`。
  static const String hrmEmployeePendingActive =
      '/desktop/hrm/employee/pending-active';
  /// 员工统计：`GET /desktop/hrm/employee/stats`。
  static const String hrmEmployeeStats = '/desktop/hrm/employee/stats';

  /// 待入职统计：`GET /desktop/hrm/employee/stats/pending-active`。
  static const String hrmEmployeePendingActiveStats =
      '/desktop/hrm/employee/stats/pending-active';

  /// 待转正统计：`GET /desktop/hrm/employee/stats/pending-regularization`。
  static const String hrmEmployeePendingRegularizationStats =
      '/desktop/hrm/employee/stats/pending-regularization';
  static const String hrmNation = '/desktop/hrm/nation';
  static const String hrmOfficeLocation = '/desktop/hrm/office-location';
  /// 修改 / 删除办公地：`PUT|DELETE /desktop/hrm/office-location/{id}`。
  static String hrmOfficeLocationById(String id) =>
      '/desktop/hrm/office-location/$id';
  static const String hrmSkillGroup = '/desktop/hrm/skill-group';

  /// 供应商 KPI：`GET /desktop/srm/supplier/stats`。
  static const String srmSupplierStats = '/desktop/srm/supplier/stats';
  /// 供应商分页列表：`GET /desktop/srm/supplier/list`。
  static const String srmSupplierList = '/desktop/srm/supplier/list';
  /// 供应商详情（主表 + 子表）：`GET /desktop/srm/supplier/{id}`。
  static String srmSupplierDetail(String id) => '/desktop/srm/supplier/$id';
  /// 供应商导出（须勾选 ids）：`POST /desktop/srm/supplier/export`。
  static const String srmSupplierExport = '/desktop/srm/supplier/export';
  /// 供应商批量导入：`POST /desktop/srm/supplier/import`（multipart file）。
  static const String srmSupplierImport = '/desktop/srm/supplier/import';
  /// 供应商导入模板：`POST /desktop/srm/supplier/importTemplate`。
  static const String srmSupplierImportTemplate =
      '/desktop/srm/supplier/importTemplate';
  /// 新建 / 更新供应商（主表 + 子表）：`POST|PUT /desktop/srm/supplier`。
  static const String srmSupplier = '/desktop/srm/supplier';
  /// 营业执照 OCR：`POST /desktop/srm/supplier/ocr/businessLicense/upload`。
  static const String srmSupplierOcrBusinessLicense =
      '/desktop/srm/supplier/ocr/businessLicense/upload';
  /// 开户许可证 / 基本存款账户 OCR：`POST /desktop/oac/ocr/bankAccountLicense/upload`。
  static const String oacOcrBankAccountLicense =
      '/desktop/oac/ocr/bankAccountLicense/upload';
  /// 营业执照 OCR（按图片公网 URL）：`GET /desktop/oac/ocr/businessLicense?url=`。
  static const String oacOcrBusinessLicense =
      '/desktop/oac/ocr/businessLicense';
  /// 经营异常 / 企业风险查询：`GET /desktop/oac/ocr/entRiskQuery?creditCode=`。
  static const String oacOcrEntRiskQuery = '/desktop/oac/ocr/entRiskQuery';
  /// 阿里云统一识别 RecognizeAllText：`POST /desktop/oac/ocr/allText/upload?type=`。
  static const String oacOcrAllTextUpload = '/desktop/oac/ocr/allText/upload';
  /// 通用 OSS 上传（logo / 合同等）：`POST /desktop/resource/oss/upload`。
  static const String resourceOssUpload = '/desktop/resource/oss/upload';
  /// 文件中心 · 预签名上传：`POST /filecenter/presign`。
  static const String fileCenterPresign = '/filecenter/presign';
  /// 文件中心 · 直传登记：`POST /filecenter/directComplete`。
  static const String fileCenterDirectComplete = '/filecenter/directComplete';
  /// 文件中心 · 文件详情：`GET /filecenter/info/{fileId}`。
  static String fileCenterInfo(String fileId) => '/filecenter/info/$fileId';
  /// 文件中心默认业务模块字典键值。
  static const String fileCenterModuleCode = 'mediaMarketService';
  /// 联行号级联 · 省：`GET /desktop/srm/cnaps/provinces`。
  static const String srmCnapsProvinces = '/desktop/srm/cnaps/provinces';
  /// 联行号级联 · 市：`GET /desktop/srm/cnaps/cities?provinceName=`。
  static const String srmCnapsCities = '/desktop/srm/cnaps/cities';
  /// 联行号级联 · 支行：`GET /desktop/srm/cnaps/branches`。
  static const String srmCnapsBranches = '/desktop/srm/cnaps/branches';
  /// 联行号搜索：`GET /desktop/srm/cnaps/search`。
  static const String srmCnapsSearch = '/desktop/srm/cnaps/search';

  /// 采购订单 KPI：`GET /desktop/srm/purchaseOrder/kpi`。
  static const String srmPurchaseOrderKpi = '/desktop/srm/purchaseOrder/kpi';
  /// 采购订单分页列表：`GET /desktop/srm/purchaseOrder/list`。
  static const String srmPurchaseOrderList = '/desktop/srm/purchaseOrder/list';
  /// 采购订单导出（须勾选 ids）：`POST /desktop/srm/purchaseOrder/export`。
  static const String srmPurchaseOrderExport =
      '/desktop/srm/purchaseOrder/export';
  /// 采购订单批量导入：`POST /desktop/srm/purchaseOrder/import`（multipart file）。
  static const String srmPurchaseOrderImport =
      '/desktop/srm/purchaseOrder/import';
  /// 采购订单导入模板：`POST /desktop/srm/purchaseOrder/importTemplate`。
  static const String srmPurchaseOrderImportTemplate =
      '/desktop/srm/purchaseOrder/importTemplate';
  /// 采购订单新建 / 更新：`POST|PUT /desktop/srm/purchaseOrder`。
  static const String srmPurchaseOrder = '/desktop/srm/purchaseOrder';
  /// 采购订单详情：`GET /desktop/srm/purchaseOrder/{id}`。
  static String srmPurchaseOrderDetail(String id) =>
      '/desktop/srm/purchaseOrder/$id';
  /// 采购订单删除：`DELETE /desktop/srm/purchaseOrder/{ids}`。
  static String srmPurchaseOrderDelete(String ids) =>
      '/desktop/srm/purchaseOrder/$ids';
  /// 关联供应商：`PUT /desktop/srm/purchaseOrder/bindSupplier`。
  static const String srmPurchaseOrderBindSupplier =
      '/desktop/srm/purchaseOrder/bindSupplier';
  /// 解除供应商关联：`PUT /desktop/srm/purchaseOrder/unbindSupplier`。
  static const String srmPurchaseOrderUnbindSupplier =
      '/desktop/srm/purchaseOrder/unbindSupplier';

  static String brandDetail(String id) => '/desktop/oac/brand/$id/detail';

  /// 品牌库名称联想：`GET /desktop/oac/brandLibrary/nameOptions?brandName=`。
  static const String brandLibraryNameOptions =
      '/desktop/oac/brandLibrary/nameOptions';

  /// 品牌库详情（选中后回填）：`GET /desktop/oac/brandLibrary/nameOptions/{id}`。
  static String brandLibraryNameOptionDetail(String id) =>
      '/desktop/oac/brandLibrary/nameOptions/$id';

  /// 客户档案详情 / 按 id 定位。
  static String customerDetail(String id) => '/desktop/oac/customer/$id';

  /// 联系人详情（含职业履历）：`GET /desktop/oac/contact/{id}`。
  static String contactDetail(String id) => '/desktop/oac/contact/$id';

  /// 部门详情：`GET /desktop/hrm/dept/{deptId}`。
  static String hrmDeptDetail(String deptId) => '/desktop/hrm/dept/$deptId';

  /// 按职务序列查职级：`GET /desktop/hrm/post-seq-level/post-seq/{postSeqId}`。
  static String hrmPostSeqLevelsBySeq(String postSeqId) =>
      '/desktop/hrm/post-seq-level/post-seq/$postSeqId';

  /// 字典数据：Path `dictType`，如 `mm_crm_customer_type`、`mm_industry`。
  static String dictDataByType(String dictType) =>
      '/desktop/oac/dict/data/type/$dictType';

  /// 按员工 ID 查详情：`GET /desktop/hrm/employee/{id}`。
  static String hrmEmployeeDetail(String id) => '/desktop/hrm/employee/$id';

  /// 按 userId 查员工详情：`GET /desktop/hrm/employee/user/{userId}`。
  static String hrmEmployeeByUser(int userId) =>
      '/desktop/hrm/employee/user/$userId';

  /// 修改员工：`PUT /desktop/hrm/employee/{id}`。
  static String hrmEmployeeUpdate(String id) => '/desktop/hrm/employee/$id';

  /// 确认入职：`POST /desktop/hrm/employee/{id}/hire`。
  static String hrmEmployeeHire(String id) => '/desktop/hrm/employee/$id/hire';

  /// 取消入职：`POST /desktop/hrm/employee/{id}/hire-revoke`。
  static String hrmEmployeeHireRevoke(String id) =>
      '/desktop/hrm/employee/$id/hire-revoke';

  /// 恢复为待入职：`POST /desktop/hrm/employee/{id}/hire-restore`。
  static String hrmEmployeeHireRestore(String id) =>
      '/desktop/hrm/employee/$id/hire-restore';

  /// 确认转正：`POST /desktop/hrm/employee/{id}/regularize`。
  static String hrmEmployeeRegularize(String id) =>
      '/desktop/hrm/employee/$id/regularize';

  /// 离职申请：`POST /desktop/hrm/employee/{id}/leave-apply`。
  static String hrmEmployeeLeaveApply(String id) =>
      '/desktop/hrm/employee/$id/leave-apply';

  /// 确认离职：`POST /desktop/hrm/employee/{id}/leave-confirm`。
  static String hrmEmployeeLeaveConfirm(String id) =>
      '/desktop/hrm/employee/$id/leave-confirm';

  /// 撤销离职申请：`POST /desktop/hrm/employee/{id}/leave-revoke`。
  static String hrmEmployeeLeaveRevoke(String id) =>
      '/desktop/hrm/employee/$id/leave-revoke';

  /// 紧急联系人：`GET /desktop/hrm/employees/{id}/contacts`。
  static String hrmEmployeeContacts(String id) =>
      '/desktop/hrm/employees/$id/contacts';

  /// 教育背景：`GET /desktop/hrm/employees/{id}/educations`。
  static String hrmEmployeeEducations(String id) =>
      '/desktop/hrm/employees/$id/educations';

  /// 工作经历：`GET /desktop/hrm/employees/{id}/work-experiences`。
  static String hrmEmployeeWorkExperiences(String id) =>
      '/desktop/hrm/employees/$id/work-experiences';

  /// 合同与协议：`GET /desktop/hrm/employees/{id}/contracts`。
  static String hrmEmployeeContracts(String id) =>
      '/desktop/hrm/employees/$id/contracts';

  /// 能力标签：`GET|PUT /desktop/hrm/employees/{id}/skills`（PUT 全量覆盖）。
  static String hrmEmployeeSkills(String id) =>
      '/desktop/hrm/employees/$id/skills';

  /// 附件列表：`GET /desktop/hrm/employees/{employeeId}/files`。
  static String hrmEmployeeFiles(String id) =>
      '/desktop/hrm/employees/$id/files';
}
