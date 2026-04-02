#define MyAppName "SEMA Format"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "TREN Studio"
#define MyAppURL "https://trenstudio.com/sema"
#define MyAppExeName "sema-viewer.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\TREN Studio\SEMA
DefaultGroupName=TREN Studio\SEMA Format
AllowNoIcons=yes
; OutputDir=Output
OutputBaseFilename=SEMA-Setup-v1.0.0
SetupIconFile=sema_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
WizardImageFile=installer_banner.bmp
WizardSmallImageFile=installer_icon.bmp
UninstallDisplayIcon={app}\sema-viewer.exe
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "fileassoc"; Description: "Associate .sema files with SEMA Viewer"; GroupDescription: "File Associations:"; Flags: checkedonce

[Files]
Source: "files\sema-viewer.html"; DestDir: "{app}"; Flags: ignoreversion
Source: "files\sema_builder.py"; DestDir: "{app}"; Flags: ignoreversion
Source: "files\harira_recipe.sema"; DestDir: "{app}\examples"; Flags: ignoreversion
Source: "files\README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme
Source: "files\sema_launcher.exe"; DestDir: "{app}"; DestName: "sema-viewer.exe"; Flags: ignoreversion
Source: "files\sema_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
; File association for .sema
Root: HKCR; Subkey: ".sema"; ValueType: string; ValueName: ""; ValueData: "SEMAFile"; Flags: uninsdeletevalue; Tasks: fileassoc
Root: HKCR; Subkey: "SEMAFile"; ValueType: string; ValueName: ""; ValueData: "SEMA Semantic File"; Flags: uninsdeletekey; Tasks: fileassoc
Root: HKCR; Subkey: "SEMAFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\sema-viewer.exe,0"; Tasks: fileassoc
Root: HKCR; Subkey: "SEMAFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\sema-viewer.exe"" ""%1"""; Tasks: fileassoc

; Add MIME type
Root: HKLM; Subkey: "SOFTWARE\Classes\MIME\Database\Content Type\application/vnd.sema"; ValueType: string; ValueName: "Extension"; ValueData: ".sema"; Flags: uninsdeletekey

[Icons]
Name: "{group}\SEMA Viewer"; Filename: "{app}\sema-viewer.exe"
Name: "{group}\TREN Studio Website"; Filename: "{#MyAppURL}"
Name: "{commondesktop}\SEMA Viewer"; Filename: "{app}\sema-viewer.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\sema-viewer.exe"; Description: "{cm:LaunchProgram,SEMA Viewer}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
end;
