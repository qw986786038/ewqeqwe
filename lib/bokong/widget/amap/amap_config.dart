/// 高德开放平台：https://console.amap.com/
///
/// 1. 创建「Key」并选择服务平台为 **Web端(JS API)**。
/// 2. 将 Key 填到 [webJsApiKey]；若控制台启用了「安全密钥」，把密钥填到 [securityJsCode]。
/// 3. 在 Key 的「域名白名单」中按需配置（本地 WebView 可用测试域名或按文档填写）。
const String webJsApiKey = '31e08a69bdbad9674869e74851dac2bf';

/// 未启用安全密钥时保持为空字符串。
const String securityJsCode = '5a4de33427a208e6f19a58c1ba66ba07';
