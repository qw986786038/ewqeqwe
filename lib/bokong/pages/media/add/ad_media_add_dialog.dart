import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_plugin_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_controller.dart';
import 'package:yidivination/bokong/pages/media/ad_media_picked_file.dart';
import 'package:yidivination/bokong/pages/media/ad_media_utils.dart';
import 'package:yidivination/bokong/pages/media/add/ad_plugin_add_dialog.dart';
import 'package:yidivination/bokong/pages/media/add/tabs/ad_media_add_live_tab.dart';
import 'package:yidivination/bokong/pages/media/add/tabs/ad_media_add_plugin_tab.dart';
import 'package:yidivination/bokong/pages/media/add/tabs/ad_media_add_upload_tab.dart';
import 'package:yidivination/bokong/pages/media/add/tabs/ad_media_add_web_tab.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/message.dart';

enum AdMediaAddTab { upload, web, live, plugin }

/// 打开「添加片源」弹窗；提交成功返回 `true`。
Future<bool> showAdMediaAddDialog({
  required BuildContext context,
  required AdMediaController controller,
  required AdMediaLibraryScope scope,
}) async {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  final bool? submitted = await showAppWindowDialog<bool>(
    context: context,
    barrierDismissible: false,
    resizable: true,
    initialSize: Size(640, initialHeight),
    builder: (dialogContext) =>
        _AdMediaAddDialog(controller: controller, scope: scope),
  ).future;
  return submitted == true;
}

/// 添加素材弹窗壳：Tab 栏 + 公共字段 + 切换各 Tab。
class _AdMediaAddDialog extends StatefulWidget {
  const _AdMediaAddDialog({required this.controller, required this.scope});

  final AdMediaController controller;
  final AdMediaLibraryScope scope;

  @override
  State<_AdMediaAddDialog> createState() => _AdMediaAddDialogState();
}

class _AdMediaAddDialogState extends State<_AdMediaAddDialog> {
  final AppFormController _form = AppFormController();
  final TextEditingController _titleController = TextEditingController();
  final ValueNotifier<int> _pluginReload = ValueNotifier<int>(0);

  AdMediaAddTab _tab = AdMediaAddTab.upload;
  final int _duration = 15;
  List<AppOption<int>> _customerOptions = const [];
  final Map<int, int> _industryByCustomerId = <int, int>{};

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _form.dispose();
    _titleController.dispose();
    _pluginReload.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final resp = await LcdApi.adCustomerList(page: 1, size: 500);
    final options = <AppOption<int>>[];
    _industryByCustomerId.clear();
    for (final AdCustomerEntity customer in resp.data ?? <AdCustomerEntity>[]) {
      final int? id = customer.id;
      if (id == null) continue;
      final int? industryId = customer.industry_id;
      if (industryId != null) _industryByCustomerId[id] = industryId;
      options.add(
        AppOption<int>(
          value: id,
          label: customer.customer_name?.trim().isNotEmpty == true
              ? customer.customer_name!.trim()
              : '-',
        ),
      );
    }
    if (!mounted) return;
    setState(() => _customerOptions = options);
  }

  void _onFilePicked(AdMediaPickedFile file) {
    if (_titleController.text.trim().isEmpty) {
      _titleController.text = AdMediaPickedFile.titleSuggestionFromPath(
        file.localPath,
      );
    }
  }

  void _onPluginSelected(AdPluginEntity plugin) {
    final String name = plugin.name?.trim() ?? '';
    if (name.isNotEmpty) _titleController.text = name;
  }

  Future<void> _addPlugin() async {
    final bool created = await showAdPluginAddDialog(context: context);
    if (created) _pluginReload.value++;
  }

  /// 校验并创建；成功返回 `true`（由确认按钮关窗）。
  Future<bool> _submit(Map<String, Object?> values) async {
    final int? customerId = values['customerId'] as int?;
    if (customerId == null) {
      showWarn('请选择所属客户');
      return false;
    }
    final int? categoryId = _industryByCustomerId[customerId];
    if (categoryId == null) {
      showWarn('所选客户未配置行业');
      return false;
    }
    final String title =
        (values['title'] as String?)?.trim() ?? _titleController.text.trim();
    if (title.isEmpty) {
      showWarn('请输入内容标题');
      return false;
    }
    final String? description = (values['description'] as String?)?.trim();

    final String message;
    switch (_tab) {
      case AdMediaAddTab.plugin:
        final AdPluginEntity? plugin = values['plugin'] as AdPluginEntity?;
        final String contentUrl = plugin?.content?.trim() ?? '';
        if (plugin == null || contentUrl.isEmpty) {
          showWarn('请选择插件');
          return false;
        }
        message = await widget.controller.createPluginMedia(
          title: title,
          customerId: customerId,
          categoryId: categoryId,
          contentUrl: contentUrl,
          previewUrl: plugin.prview_url,
          description: description,
          scope: widget.scope,
        );
      case AdMediaAddTab.web:
        final String url = (values['url'] as String?)?.trim() ?? '';
        final String? urlError = validateAdMediaUrl(url);
        if (urlError != null) {
          showWarn(urlError);
          return false;
        }
        message = await widget.controller.createWebMedia(
          title: title,
          customerId: customerId,
          categoryId: categoryId,
          url: url,
          description: description,
          scope: widget.scope,
        );
      case AdMediaAddTab.live:
        final String url = (values['url'] as String?)?.trim() ?? '';
        final String? urlError = validateAdMediaUrl(url);
        if (urlError != null) {
          showWarn(urlError);
          return false;
        }
        message = await widget.controller.createLiveMedia(
          title: title,
          customerId: customerId,
          categoryId: categoryId,
          url: url,
          description: description,
          scope: widget.scope,
        );
      case AdMediaAddTab.upload:
        final AdMediaPickedFile? file = values['file'] as AdMediaPickedFile?;
        if (file == null) {
          showWarn('请上传片源');
          return false;
        }
        message = await widget.controller.createMedia(
          file: file,
          title: title,
          customerId: customerId,
          categoryId: categoryId,
          duration: _duration,
          pushToCloud: values['pushCloud'] as bool? ?? false,
          description: description,
          scope: widget.scope,
        );
    }

    showComplete(message.isNotEmpty ? message : '添加成功');
    return true;
  }

  Future<void> _onConfirm() async {
    try {
      var submitted = false;
      await _form.submit((values) async {
        submitted = await _submit(values);
      });
      if (submitted && mounted) {
        await AppOverlay.close<bool>(context, true);
      }
    } catch (e) {
      if (e is AppRespEntity) {
        showError(e.msg);
      } else {
        showError('$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPluginTab = _tab == AdMediaAddTab.plugin;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AppFormDialog(
      title: Align(
        alignment: Alignment.centerLeft,
        child: AppTabs(
          index: _tab.index,
          onChanged: (index) =>
              setState(() => _tab = AdMediaAddTab.values[index]),
          selectedColor: Colors.white,
          children: const [
            AppTabItem(child: Text('上传')),
            AppTabItem(child: Text('网页')),
            AppTabItem(child: Text('直播')),
            AppTabItem(child: Text('插件')),
          ],
        ),
      ),
      constraints: const BoxConstraints(minWidth: 620, maxWidth: 640),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: AppForm(
          controller: _form,
          child: AppCard(
            borderWidth: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextFormField(
                  name: 'title',
                  label: '内容标题',
                  required: true,
                  controller: _titleController,
                  hintText: isPluginTab ? '选择插件后自动填入插件名称，可修改' : '请输入内容标题',
                  validator: AppValidators.required(message: '请输入内容标题'),
                ),
                AppComboboxFormField<int>(
                  name: 'customerId',
                  label: '所属客户',
                  required: true,
                  hintText: '搜索客户',
                  initialValue: widget.controller.customerId.value,
                  options: _customerOptions,
                  validator: (value) => value == null ? '请选择所属客户' : null,
                ),
                if (_tab == AdMediaAddTab.web || _tab == AdMediaAddTab.live)
                  AppTextFormField(
                    name: 'url',
                    label: 'URL',
                    required: true,
                    hintText: _tab == AdMediaAddTab.live
                        ? '例(https://www.palsmon.com/live.m3u8)'
                        : '例(https://www.palsmon.com/)',
                    keyboardType: TextInputType.url,
                    validator: validateAdMediaUrl,
                  ),
                switch (_tab) {
                  AdMediaAddTab.upload => AdMediaAddUploadTab(
                    durationSeconds: _duration,
                    onFilePicked: _onFilePicked,
                  ),
                  AdMediaAddTab.web => const AdMediaAddWebTab(),
                  AdMediaAddTab.live => const AdMediaAddLiveTab(),
                  AdMediaAddTab.plugin => AdMediaAddPluginTab(
                    reloadListenable: _pluginReload,
                    onPluginSelected: _onPluginSelected,
                    onAddPlugin: _addPlugin,
                  ),
                },
                // 备注放公共区末尾：各 Tab 切换时旧字段 dispose 滞后，同名会重复注册。
                AppTextAreaFormField(
                  name: 'description',
                  label: '备注',
                  hintText: '备注',
                  minHeight: 72,
                ),
              ],
            ).scroll(),
          ),
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close<bool>(context, false),
          child: const Text('关闭'),
        ),
        AppButton.primary(onPressed: _onConfirm, child: const Text('确认')),
      ],
    );
  }
}
