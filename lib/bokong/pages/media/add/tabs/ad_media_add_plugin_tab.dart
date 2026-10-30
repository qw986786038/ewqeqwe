import 'package:extended_image/extended_image.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/api/ad_plugin_api.dart';
import 'package:yidivination/bokong/entity/order/ad_plugin_entity.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 添加素材 ·「插件」Tab。
class AdMediaAddPluginTab extends StatelessWidget {
  const AdMediaAddPluginTab({
    required this.reloadListenable,
    required this.onPluginSelected,
    required this.onAddPlugin,
    super.key,
  });

  final Listenable reloadListenable;
  final ValueChanged<AdPluginEntity> onPluginSelected;
  final VoidCallback onAddPlugin;

  @override
  Widget build(BuildContext context) {
    return _PluginPickerField(
      reloadListenable: reloadListenable,
      onPluginSelected: onPluginSelected,
      onAddPlugin: onAddPlugin,
      validator: (value) => value == null ? '请选择插件' : null,
    );
  }
}

class _PluginPickerField extends FormField<AdPluginEntity> {
  _PluginPickerField({
    this.onPluginSelected,
    this.onAddPlugin,
    this.reloadListenable,
    super.validator,
  }) : super(builder: _buildField);

  final ValueChanged<AdPluginEntity>? onPluginSelected;
  final VoidCallback? onAddPlugin;
  final Listenable? reloadListenable;

  static Widget _buildField(FormFieldState<AdPluginEntity> field) {
    final state = field as _PluginPickerFieldState;
    final picker = state.widget;
    final selected = field.value;

    return AppFormFieldBinding<AdPluginEntity>(
      name: 'plugin',
      value: field.value,
      builder: (context, asyncError) => AppField(
        label: '选择插件',
        required: true,
        errorText: field.errorText ?? asyncError,
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 12,
              children: [
                AppText.muted('请从下方列表中选择一个插件（必须）').expanded(),
                AppButton.primary(
                  size: AppButtonSize.small,
                  onPressed: picker.onAddPlugin,
                  child: const Text('新建'),
                ),
              ],
            ),
            if (state._loading && state._items.isEmpty)
              const SizedBox(
                height: 120,
                child: Center(child: AppCircularProgressIndicator()),
              )
            else if (state._items.isEmpty)
              const SizedBox(height: 120, child: Center(child: AppEmptyState()))
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final plugin in state._items)
                    _PluginCard(
                      plugin: plugin,
                      selected: selected?.id == plugin.id,
                      onTap: field.widget.enabled
                          ? () {
                              field.didChange(plugin);
                              picker.onPluginSelected?.call(plugin);
                            }
                          : null,
                    ),
                ],
              ),
            if (state._totalPages > 1)
              AppPagination(
                page: state._page,
                totalPages: state._totalPages,
                maxPages: 5,
                onPageChanged: state._loadPage,
              ).center(),
          ],
        ),
      ),
    );
  }

  @override
  FormFieldState<AdPluginEntity> createState() => _PluginPickerFieldState();
}

class _PluginPickerFieldState extends FormFieldState<AdPluginEntity> {
  static const int _pageSize = 6;

  final List<AdPluginEntity> _items = <AdPluginEntity>[];
  bool _loading = false;
  int _page = 1;
  int _totalPages = 1;

  @override
  _PluginPickerField get widget => super.widget as _PluginPickerField;

  @override
  void initState() {
    super.initState();
    widget.reloadListenable?.addListener(_onReloadRequested);
    _loadPage(1);
  }

  @override
  void didUpdateWidget(covariant _PluginPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadListenable != widget.reloadListenable) {
      oldWidget.reloadListenable?.removeListener(_onReloadRequested);
      widget.reloadListenable?.addListener(_onReloadRequested);
    }
  }

  @override
  void dispose() {
    widget.reloadListenable?.removeListener(_onReloadRequested);
    super.dispose();
  }

  void _onReloadRequested() => _loadPage(1);

  Future<void> _loadPage(int pageNo) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final resp = await AdPluginApi.list(page: pageNo, size: _pageSize);
      _items
        ..clear()
        ..addAll(resp.data ?? <AdPluginEntity>[]);
      _page = resp.page?.page ?? pageNo;
      final int totalPages = resp.page?.totalPages ?? 0;
      _totalPages = totalPages > 0 ? totalPages : 1;
    } catch (e) {
      showError('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _PluginCard extends StatelessWidget {
  const _PluginCard({required this.plugin, required this.selected, this.onTap});

  final AdPluginEntity plugin;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final String name = plugin.name?.trim().isNotEmpty == true
        ? plugin.name!.trim()
        : '未命名插件';
    final String? preview = plugin.prview_url?.trim();

    return SizedBox(
      width: 168,
      child: AppInkWell(
        onPressed: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AppCard(
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          borderColor: selected ? colors.primary : null,
          borderWidth: selected ? 2 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (preview == null || preview.isEmpty)
                Container(
                  height: 96,
                  color: colors.muted,
                  alignment: Alignment.center,
                  child: Icon(
                    AppLucideIcons.puzzle,
                    size: 28,
                    color: colors.mutedForeground,
                  ),
                )
              else
                ExtendedImage.network(
                  preview,
                  height: 96,
                  width: 168,
                  fit: BoxFit.cover,
                  loadStateChanged: (state) {
                    if (state.extendedImageLoadState == LoadState.failed) {
                      return Container(
                        height: 96,
                        color: colors.muted,
                        alignment: Alignment.center,
                        child: Icon(
                          AppLucideIcons.imageOff,
                          size: 24,
                          color: colors.mutedForeground,
                        ),
                      );
                    }
                    return null;
                  },
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: AppText.body(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
