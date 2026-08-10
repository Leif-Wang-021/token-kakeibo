; Token家计薄 安装脚本（Inno Setup 6）
#define MyAppName "Token家计薄"
#define MyAppNameEn "Token Kakeibo"
#define MyAppVersion "1.2.1"
#define MyAppPublisher "Token Kakeibo"
#define MyAppExeName "token_kakeibo.exe"

[Setup]
AppId={{B4A7C9E2-3D51-4F6A-9C0E-8D2F1A5B6C7D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\TokenKakeibo
UsePreviousAppDir=yes
DefaultGroupName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputDir=output
OutputBaseFilename=TokenKakeiboSetup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\windows\runner\resources\app_icon.ico
PrivilegesRequired=admin
DisableDirPage=no
DisableProgramGroupPage=no
CloseApplications=yes

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; appdata 是应用运行数据（账户、设置、日志），绝不打进安装包，
; 否则覆盖安装会用开发机数据冲掉用户配置。
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "token_kakeibo.exe.WebView2,appdata"

[Dirs]
; 应用数据（账户、日志、WebView2）v1.1.0 起迁移到 %LOCALAPPDATA%\token_kakeibo，
; 不再依赖安装目录。此目录仅保留给旧版本数据迁移（首次运行会自动搬走）。
; uninsneveruninstall：即使目录里还有残留文件，卸载也绝不删除。
Name: "{app}"; Permissions: users-modify
Name: "{app}\appdata"; Permissions: users-modify; Flags: uninsneveruninstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\卸载 {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// 安装完成后记录本次安装目录，供下次覆盖安装自动填入（UsePreviousAppDir）。
procedure CurStepChanged(CurStep: TSetupStep);
var
  Key: string;
begin
  if CurStep = ssPostInstall then
  begin
    Key := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{B4A7C9E2-3D51-4F6A-9C0E-8D2F1A5B6C7D}_is1';
    RegWriteStringValue(HKLM, Key, 'PreviousInstallLocation', ExpandConstant('{app}'));
  end;
end;
