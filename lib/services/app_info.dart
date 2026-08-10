/// 应用元信息：版本、GitHub 仓库与默认项目主页。
///
/// 与 pubspec.yaml、Inno Setup 脚本保持一致；发布新版本时统一修改。
library;

const String kAppVersion = '1.2.0';
const String kGitHubRepo = 'Leif-Wang-021/token-kakeibo';
const String kProjectHomeUrl = 'https://github.com/$kGitHubRepo';
const String kReleasesApi =
    'https://api.github.com/repos/$kGitHubRepo/releases/latest';
