import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_entity.dart';
import 'package:yidivination/bokong/pages/common/left_list_page.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_add_dialog.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_controller.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_utils.dart';
import 'package:yidivination/bokong/router/route_transitions.dart';
import 'package:yidivination/bokong/utils/ext.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart' hide AppText;
import 'package:yidivination/bokong/widget/app_layout.dart';
import 'package:yidivination/bokong/widget/app_text.dart';
import 'package:yidivination/bokong/widget/filter_icon_button.dart';
import 'package:yidivination/bokong/widget/glass_list_item.dart';
import 'package:yidivination/bokong/widget/info/info_item_column.dart';
import 'package:yidivination/bokong/widget/info/info_item_widget.dart';
import 'package:yidivination/bokong/widget/search_icon_button.dart';

class LcdCustomerManagerPage extends StatefulWidget {
  const LcdCustomerManagerPage({super.key});

  @override
  State<LcdCustomerManagerPage> createState() => _LcdCustomerManagerPageState();
}

class _LcdCustomerManagerPageState extends State<LcdCustomerManagerPage> {
  final LcdCustomerController _controller = Lemon.put(
    LcdCustomerController.new,
  );
  final TextEditingController _searchController = TextEditingController();
  int _listRefreshKey = 0;

  Map<String, dynamic> get _customerListQueryParam {
    final Map<String, dynamic> params = <String, dynamic>{'is_delete': 0};
    final String keyword = _searchController.text.trim();
    if (keyword.isNotEmpty) params['customer_name'] = keyword;
    return params;
  }

  void _applySearch() => setState(() => _listRefreshKey++);

  Future<void> _showAddCustomerDialog() async {
    final bool added = await showLcdCustomerAddDialog(
      context: context,
      onSubmit: (param) async {
        final resp = await LcdApi.adCustomerCreate(param: param);
        if (!resp.isSuccess()) throw resp;
      },
    );
    if (!mounted || !added) return;
    setState(() => _listRefreshKey++);
  }

  @override
  void dispose() {
    _searchController.dispose();
    Lemon.remove<LcdCustomerController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppLayout(
          maxContentWidth: 20000,
          startWidth: 400,
          widePadding: const EdgeInsets.only(left: 0, right: 0),
          start: LeftListPage(
            refresh: _listRefreshKey,
            queryParam: _customerListQueryParam,
            loadDelay: contentLoadShortDelay,
            topViewBuilder: (context, obj) {
              return Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppCard(
                            padding: const EdgeInsets.only(left: 12),
                            child: TextField(
                              controller: _searchController,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: '搜索客户名称',
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context).hintColor,
                                    ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10.5,
                                ),
                                suffixIcon: SearchIconButton(
                                  onPressed: _applySearch,
                                  unifyTrailingInset: false,
                                ),
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 35,
                                  minHeight: 35,
                                ),
                              ),
                              onSubmitted: (_) => _applySearch(),
                            ),
                          ),
                        ),
                        const Gap(8),
                        FilterIconButton(count: 0, onPressed: () {}),
                        const Gap(8),
                        AppIconButton(
                          icon: const Icon(Icons.add),
                          tooltip: '添加',
                          variant: AppButtonVariant.primary,
                          color: ShadcnTheme.of(
                            context,
                          ).colorScheme.primaryForeground,
                          onPressed: _showAddCustomerDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            api: ({int? page, int? size, Map<String, dynamic>? param}) {
              return LcdApi.adCustomerList(
                page: page,
                size: size,
                param: param,
              );
            },
            onDatasChanged: (datas) {
              _controller.customers.replaceAll(
                datas.whereType<AdCustomerEntity>(),
              );
            },
            itemBuilder: (BuildContext context, int index, value) {
              return _CustomerListTile(
                key: ValueKey((value as AdCustomerEntity).id),
                item: value,
                controller: _controller,
              );
            },
          ),
          main: Obx(() {
            final AdCustomerEntity? customer = _controller.current.value;
            if (customer == null) {
              return Center(
                child: Text(
                  '请选择左侧客户',
                  style: context.theme.textTheme.titleMedium,
                ),
              );
            }
            return _CustomerDetailPanel(customer: customer);
          }),
        ),
    );
  }
}

class _CustomerListTile extends StatelessWidget {
  const _CustomerListTile({
    super.key,
    required this.item,
    required this.controller,
  });

  final AdCustomerEntity item;
  final LcdCustomerController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;

    return Obx(() {
      final bool isSelected = controller.current.value?.id == item.id;
      return GlassListItem(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        selected: isSelected,
        onTap: () => controller.selectCustomer(item),
        child: Builder(
          builder: (context) {
            final ThemeData itemTheme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.customer_name ?? '-',
                                style: itemTheme.listTileTheme.titleTextStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Gap(6),
                            AppBadge.info(
                              appearance: AppBadgeStyle.outline,
                              shape: AppBadgeShape.square,
                              child: Text(item.industry ?? '-'),
                            ),
                          ],
                        ),
                        const Gap(4),
                        Text(
                          item.customer_no ?? '-',
                          style: theme.listTileTheme.subtitleTextStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  customerStatusBadge(item.status),
                  const Gap(8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: theme.hintColor,
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

class _CustomerDetailPanel extends StatelessWidget {
  const _CustomerDetailPanel({required this.customer});

  final AdCustomerEntity customer;

  static String _text(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '-';
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: AppText.largeTitle(customer.customer_name ?? '-')),
            const Gap(8),
            customerStatusBadge(customer.status),
            const Gap(8),
            AppBadge.info(
              appearance: AppBadgeStyle.outline,
              shape: AppBadgeShape.square,
              child: Text(customer.industry ?? '-'),
            ),
          ],
        ),
        const Gap(16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _infoSection(
                  context,
                  title: '基本信息',
                  children: [
                    InfoItemInlineWidget(
                      title: '客户编号',
                      info: _text(customer.customer_no),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '客户名称',
                      info: _text(customer.customer_name),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '客户类型',
                      info: customerTypeLabel(customer.type),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '所属行业',
                      info: _text(customer.industry),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '行业 ID',
                      info: customer.industry_id?.toString(),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '播放设置',
                      info: customer.play_setting?.toString(),
                    ),
                  ],
                ),
                const Gap(12),
                _infoSection(
                  context,
                  title: '合同信息',
                  children: [
                    InfoItemInlineWidget(
                      title: '采购时间',
                      info: _text(customer.purchase_time),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '生效时间',
                      info: _text(customer.effective_time),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '到期时间',
                      info: _text(customer.expire_time),
                    ),
                  ],
                ),
                const Gap(12),
                _infoSection(
                  context,
                  title: '联系信息',
                  children: [
                    InfoItemInlineWidget(
                      title: '联系人',
                      info: _text(customer.contact_person),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '联系电话',
                      info: _text(customer.contact_phone),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '邮箱',
                      info: _text(customer.email),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '地址',
                      info: _text(customer.address),
                      titleWidth: 80,
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '备注',
                      info: _text(customer.remark),
                      titleWidth: 80,
                    ),
                  ],
                ),
                const Gap(12),
                _infoSection(
                  context,
                  title: '系统信息',
                  children: [
                    InfoItemInlineWidget(
                      title: '创建时间',
                      info: _text(customer.create_time),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '更新时间',
                      info: _text(customer.update_time),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '创建人',
                      info: _text(customer.create_by),
                    ),
                    const Gap(12),
                    InfoItemInlineWidget(
                      title: '更新人',
                      info: _text(customer.update_by),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title(title),
          const Gap(16),
          InfoItemColumn(children: children),
        ],
      ),
    );
  }
}
