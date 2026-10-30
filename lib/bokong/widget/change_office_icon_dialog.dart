import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/utils/pinyin_initial.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/change_sidebar_icon_dialog.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/office_card_icon.dart';
import 'package:yidivination/bokong/widget/sidebar_avatar_icon.dart';

final _kBackgroundPalette = [for (final p in kOfficeIconPalette) p.tile];

const _kIconColor = Color(0xFF1F2937);

const _kGlyphModeOptions = [
  AppOption(value: 0, label: '中文首汉字'),
  AppOption(value: 1, label: '英文首字母'),
];

/// 楼栋（写字楼）侧栏「更换图标」；接口同 [showChangeSidebarIconDialog]（type=2）。图标样式待定，暂同设备弹窗。
Future<ChangeSidebarIconResult?> showChangeOfficeIconDialog(
  BuildContext context, {
  required int officeId,
  required String title,
  String? currentAvatarIcon,
  int deviceCount = 0,
}) {
  return showAppWindowDialog<ChangeSidebarIconResult>(
    context: context,
    barrierDismissible: false,
    initialSize: const Size(440, 820),
    builder: (_) => _ChangeOfficeIconDialog(
      officeId: officeId,
      title: title,
      currentAvatarIcon: currentAvatarIcon,
      deviceCount: deviceCount,
    ),
  ).future;
}

class _ChangeOfficeIconDialog extends StatefulWidget {
  const _ChangeOfficeIconDialog({
    required this.officeId,
    required this.title,
    this.currentAvatarIcon,
    this.deviceCount = 0,
  });

  final int officeId;
  final String title;
  final String? currentAvatarIcon;
  final int deviceCount;

  @override
  State<_ChangeOfficeIconDialog> createState() =>
      _ChangeOfficeIconDialogState();
}

class _ChangeOfficeIconDialogState extends State<_ChangeOfficeIconDialog> {
  final _templates = sidebarAvatarTemplatesForType(
    SidebarAvatarIconType.office,
  );
  late final _titleController = TextEditingController(
    text: widget.title == '-' ? '' : widget.title,
  );
  late Color _background;
  late Color _iconColor;
  late String _templateName;
  var _tab = 0;
  var _glyphMode = 0;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String get _glyph {
    final title = _titleController.text.trim();
    if (_glyphMode == 0) {
      return RegExp(r'[\u4e00-\u9fa5]').firstMatch(title)?.group(0) ?? '';
    }
    final initial = pinyinInitialOf(title);
    return RegExp(r'^[A-Z]$').hasMatch(initial) ? initial : '';
  }

  @override
  void initState() {
    super.initState();
    final parsed = SidebarAvatarIconValue.tryParse(widget.currentAvatarIcon);
    final known = parsed?.isText == true || _templates.any((t) => t.name == parsed?.name);
    _templateName = _templates.any((t) => t.name == parsed?.name) ? parsed!.name! : kOfficeDefaultTemplate;
    if (parsed?.isText == true) {
      _tab = 1;
      _glyphMode = RegExp(r'^[A-Za-z]$').hasMatch(parsed!.text!) ? 1 : 0;
    }
    _background = known && parsed!.bg != null
        ? parsed.bg!
        : _kBackgroundPalette[2];
    _iconColor = known && parsed!.color != null ? parsed.color! : _kIconColor;
  }

  String _encodeAvatar() {
    final glyph = _glyph;
    return (_tab == 1 && glyph.isNotEmpty
            ? SidebarAvatarIconValue.text(text: glyph, color: _iconColor, bg: _background)
            : SidebarAvatarIconValue.template(name: _templateName, color: _iconColor, bg: _background))
        .encode();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showWarn('请输入标题名称');
      return;
    }
    if (_tab == 1 && _glyph.isEmpty) {
      showWarn(_glyphMode == 0 ? '标题中没有汉字' : '标题中没有可用的首字母');
      return;
    }
    final avatarIcon = _encodeAvatar();
    final resp = await LcdApi.updateFileIcon(
      type: SidebarAvatarIconType.office,
      updateId: widget.officeId,
      avatarIcon: avatarIcon,
      title: title,
    );
    if (!resp.isSuccess()) {
      showError(resp.info());
      return;
    }
    showComplete(resp.info());
    if (!mounted) return;
    AppOverlay.close<ChangeSidebarIconResult>(
      context,
      ChangeSidebarIconResult(avatarIcon: avatarIcon, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final dialogRadius = AppTheme.maybeOf(context)?.dialogRadius;
    const labelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
    final panel = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.border),
    );
    return AppCard(
      shadow: false,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      borderRadius: dialogRadius == null
          ? null
          : BorderRadius.circular(dialogRadius),
      padding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const Text('标题名称', style: labelStyle),
          // 待上游：AppTextFormField 支持 fillColor 后改为字段参数。
          shad.Theme(
            data: ShadcnTheme.of(context).copyWith(
              colorScheme: () => ShadcnTheme.of(context).colorScheme.copyWith(muted: () => Colors.white),
            ),
            child: shad.ComponentTheme(
              data: const shad.TextFieldTheme(filled: true),
              child: AppTextFormField(
                controller: _titleController,
                hintText: '请输入标题名称',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('新图标效果', style: labelStyle),
              const SizedBox(width: 12),
              Container(
                width: 78,
                height: 78,
                alignment: Alignment.center,
                decoration: panel,
                child: OfficeCardIcon(avatarIcon: _encodeAvatar(), count: widget.deviceCount),
              ),
              const Spacer(),
              const Text('原图标效果', style: labelStyle),
              const SizedBox(width: 12),
              Container(
                width: 78,
                height: 78,
                alignment: Alignment.center,
                decoration: panel,
                child: OfficeCardIcon(avatarIcon: widget.currentAvatarIcon, count: widget.deviceCount),
              ),
            ],
          ),
          const Text('模版组件库', style: labelStyle),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: panel,
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (final color in _kBackgroundPalette)
                  AppInkWell(
                    onPressed: () => setState(() => _background = color),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color == _background
                            ? const Color(0xFFE0F2FE)
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: color == _background
                            ? Border.all(color: colors.primary)
                            : null,
                      ),
                      child: OfficeCardIcon.swatch(color, count: widget.deviceCount),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AppTabs(
              index: _tab,
              selectedColor: Colors.white,
              selectedTextColor: _kIconColor,
              unselectedColor: const Color(0xFFE5E7EB),
              unselectedForegroundColor: _kIconColor,
              onChanged: (index) => setState(() => _tab = index),
              children: const [
                AppTabItem(child: Text('图标')),
                AppTabItem(child: Text('字体')),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: panel,
                    child: GridView.count(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        for (final item in _templates)
                          AppInkWell(
                            onPressed: () =>
                                setState(() => _templateName = item.name),
                            hoverOpacity: 0,
                            pressedOpacity: 0,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: item.name == _templateName
                                    ? const Color(0xFFE0F2FE)
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                border: item.name == _templateName
                                    ? Border.all(color: colors.primary)
                                    : null,
                              ),
                              child: sidebarAvatarSvg(
                                asset: item.asset,
                                size: 24,
                                color: _kIconColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Align(
                    alignment: Alignment.topLeft,
                    child: AppRadioGroup<int>(
                      options: _kGlyphModeOptions,
                      value: _glyphMode,
                      onChanged: (value) => setState(() => _glyphMode = value),
                    ),
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 12,
            children: [
              AppButton.secondary(
                onPressed: () => AppOverlay.close(context),
                child: const Text('取消'),
              ),
              AppButton.primary(onPressed: _save, child: const Text('保存')),
            ],
          ),
        ],
      ),
    );
  }
}
