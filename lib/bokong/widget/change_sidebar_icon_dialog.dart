import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/pages/media/ad_media_picked_file.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/sidebar_avatar_icon.dart';

/// 侧边栏「更换图标」保存结果（[avatarIcon] 已写入接口）。
class ChangeSidebarIconResult {
  const ChangeSidebarIconResult({required this.avatarIcon, this.title});

  /// 上传图为 URL；模版为 JSON `name/color/bg`。
  final String avatarIcon;

  /// 同时修改的标题（未修改为 null）。
  final String? title;
}

const _kImageExtensions = <String>['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];

/// 打开更换图标弹窗；保存成功返回结果，取消返回 `null`。
///
/// [iconType] / [updateId] 对应 ShowDoc 1514：1 客户 / 2 写字楼 / 3 设备 / 4 主订单。
Future<ChangeSidebarIconResult?> showChangeSidebarIconDialog(
  BuildContext context, {
  required int iconType,
  required int updateId,
  String? currentAvatarIcon,
  Color initialIconColor = const Color(0xFF111827),
  Color initialBackgroundColor = const Color(0xFFFFFFFF),
}) {
  return showAppWindowDialog<ChangeSidebarIconResult>(
    context: context,
    barrierDismissible: false,
    resizable: true,
    initialSize: const Size(440, 620),
    builder: (dialogContext) => _ChangeSidebarIconDialog(
      iconType: iconType,
      updateId: updateId,
      currentAvatarIcon: currentAvatarIcon,
      initialIconColor: initialIconColor,
      initialBackgroundColor: initialBackgroundColor,
    ),
  ).future;
}

class _ChangeSidebarIconDialog extends StatefulWidget {
  const _ChangeSidebarIconDialog({
    required this.iconType,
    required this.updateId,
    this.currentAvatarIcon,
    required this.initialIconColor,
    required this.initialBackgroundColor,
  });

  final int iconType;
  final int updateId;
  final String? currentAvatarIcon;
  final Color initialIconColor;
  final Color initialBackgroundColor;

  @override
  State<_ChangeSidebarIconDialog> createState() =>
      _ChangeSidebarIconDialogState();
}

class _ChangeSidebarIconDialogState extends State<_ChangeSidebarIconDialog> {
  final _form = AppFormController();
  late AppColorDerivative _iconColor;
  late AppColorDerivative _backgroundColor;
  late String _selectedTemplateName;
  String? _uploadedUrl;
  var _uploading = false;
  var _saving = false;

  List<SidebarAvatarTemplate> get _templates =>
      sidebarAvatarTemplatesForType(widget.iconType);

  String get _defaultTemplateName =>
      _templates.isNotEmpty ? _templates.first.name : 'folder';

  @override
  void initState() {
    super.initState();
    final parsed = SidebarAvatarIconValue.tryParse(widget.currentAvatarIcon);
    final known = sidebarAvatarTemplateByName(parsed?.name);
    if (parsed?.isNetwork == true) {
      _uploadedUrl = parsed!.url;
      _iconColor = AppColorDerivative.fromColor(widget.initialIconColor);
      _backgroundColor = AppColorDerivative.fromColor(
        widget.initialBackgroundColor,
      );
      _selectedTemplateName = _defaultTemplateName;
    } else if (known != null && _templates.any((t) => t.name == known.name)) {
      _uploadedUrl = null;
      _selectedTemplateName = known.name;
      _iconColor = AppColorDerivative.fromColor(
        parsed?.color ?? widget.initialIconColor,
      );
      _backgroundColor = AppColorDerivative.fromColor(
        parsed?.bg ?? widget.initialBackgroundColor,
      );
    } else {
      _iconColor = AppColorDerivative.fromColor(widget.initialIconColor);
      _backgroundColor = AppColorDerivative.fromColor(
        widget.initialBackgroundColor,
      );
      _selectedTemplateName = _defaultTemplateName;
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _uploadIcon() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _kImageExtensions,
      );
      final path = file?.path;
      if (path == null || path.isEmpty) return;
      final uploaded = await AdMediaPickedFile.loadUploadAndParse(path);
      if (!uploaded.isImage) {
        throw StateError('请上传图片文件');
      }
      final url = uploaded.publicUrl?.trim();
      if (url == null || url.isEmpty) {
        throw StateError('上传后图片地址为空');
      }
      setState(() => _uploadedUrl = url);
    } catch (e) {
      showError('$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _buildAvatarIcon() {
    final url = _uploadedUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return SidebarAvatarIconValue.url(url).encode();
    }
    return SidebarAvatarIconValue.template(
      name: _selectedTemplateName,
      color: _iconColor.toColor(),
      bg: _backgroundColor.toColor(),
    ).encode();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final avatarIcon = _buildAvatarIcon();
      final resp = await LcdApi.updateFileIcon(
        type: widget.iconType,
        updateId: widget.updateId,
        avatarIcon: avatarIcon,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      showComplete(resp.info());
      if (!mounted) return;
      AppOverlay.close<ChangeSidebarIconResult>(
        context,
        ChangeSidebarIconResult(avatarIcon: avatarIcon),
      );
    } catch (e) {
      showError('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _currentPreview() {
    return SidebarAvatarIcon(
      avatarIcon: widget.currentAvatarIcon,
      size: 48,
      iconSize: 28,
      borderRadius: 16,
    );
  }

  Widget _replacePreview() {
    final url = _uploadedUrl;
    if (url != null && url.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: ExtendedImage.network(
          url,
          fit: BoxFit.cover,
          width: 48,
          height: 48,
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _backgroundColor.toColor(),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      alignment: Alignment.center,
      child: sidebarAvatarSvg(
        asset:
            sidebarAvatarTemplateAsset(_selectedTemplateName) ??
            _templates.first.asset,
        size: 28,
        color: _iconColor.toColor(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final dialogRadius = AppTheme.maybeOf(context)?.dialogRadius;
    return AppCard(
      shadow: false,
      filled: true,
      fillColor: colors.card,
      borderRadius: dialogRadius == null ? null : BorderRadius.circular(dialogRadius),
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                const Expanded(child: AppText.h2('更换图标')),
                const AppDialogCloseButton(),
              ],
            ),
          ),
          const AppDivider.horizontal(),
          Expanded(
            child: AppForm(
              controller: _form,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 12,
                      children: [
                        SizedBox(
                          width: 72,
                          child: AppText.label(
                            '文件图标',
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                        ),
                        _currentPreview(),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 12,
                      children: [
                        SizedBox(
                          width: 72,
                          child: AppText.label(
                            '替换图标',
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                        ),
                        _replacePreview(),
                        AppButton.outline(
                          loading: _uploading,
                          leading: const Icon(AppLucideIcons.upload, size: 14),
                          onPressed: _uploading ? null : _uploadIcon,
                          child: const Text('上传图标'),
                        ),
                      ],
                    ),
                    AppFieldScope.horizontal(
                      labelWidth: 64,
                      child: Row(
                        spacing: 12,
                        children: [
                          Expanded(
                            child: AppColorInputFormField(
                              name: 'icon_color',
                              label: '图标颜色',
                              initialValue: _iconColor,
                              showAlpha: false,
                              onChanged: (value) {
                                setState(() => _iconColor = value);
                              },
                            ),
                          ),
                          Expanded(
                            child: AppColorInputFormField(
                              name: 'bg_color',
                              label: '背景颜色',
                              initialValue: _backgroundColor,
                              showAlpha: false,
                              onChanged: (value) {
                                setState(() => _backgroundColor = value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 8,
                        children: [
                          AppText.label(
                            '模版组件库',
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final item in _templates)
                                      AppInkWell(
                                        onPressed: () => setState(() {
                                          _selectedTemplateName = item.name;
                                          _uploadedUrl = null;
                                        }),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color:
                                                  _selectedTemplateName ==
                                                          item.name &&
                                                      _uploadedUrl == null
                                                  ? colors.primary
                                                  : const Color(0xFFE5E7EB),
                                              width:
                                                  _selectedTemplateName ==
                                                          item.name &&
                                                      _uploadedUrl == null
                                                  ? 1.5
                                                  : 1,
                                            ),
                                          ),
                                          child: sidebarAvatarSvg(
                                            asset: item.asset,
                                            size: 24,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const AppDivider.horizontal(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                AppButton.outline(
                  onPressed: _saving ? null : () => AppOverlay.close(context),
                  child: const Text('取消'),
                ),
                AppButton.primary(
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                  child: const Text('保存'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
