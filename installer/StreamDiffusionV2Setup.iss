; StreamDiffusionV2 Inno Setup Script
; Requires Inno Setup 6.x (https://jrsoftware.org/isinfo.php)

#define MyAppName "StreamDiffusionV2"
#define MyAppVersion "1.0"
#define MyAppPublisher "StreamDiffusionV2"
#define MyAppURL "https://github.com/your-org/StreamDiffusionV2"

[Setup]
AppId={{B8E3F2A1-5C7D-4E9F-A1B2-3C4D5E6F7A8B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppSupportURL={#MyAppURL}
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=output
OutputBaseFilename=StreamDiffusionV2Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=compiler:SetupClassicIcon.ico
DisableProgramGroupPage=yes
LicenseFile=..\LICENSE
InfoBeforeFile=info_before.txt

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Embedded Python 3.10
Source: "build\python\*"; DestDir: "{app}\python"; Flags: ignoreversion recursesubdirs createallsubdirs

; Application source code
Source: "..\causvid\*"; DestDir: "{app}\app\causvid"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\streamv2v\*"; DestDir: "{app}\app\streamv2v"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\demo\*"; DestDir: "{app}\app\demo"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "frontend\node_modules\*,frontend\.svelte-kit\*,frontend\src\*"
Source: "..\configs\*"; DestDir: "{app}\app\configs"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\examples\*"; DestDir: "{app}\app\examples"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\setup.py"; DestDir: "{app}\app"; Flags: ignoreversion
Source: "..\requirements.txt"; DestDir: "{app}\app"; Flags: ignoreversion

; Pre-built frontend (built by build_installer.bat)
Source: "build\frontend_public\*"; DestDir: "{app}\app\demo\frontend\public"; Flags: ignoreversion recursesubdirs createallsubdirs

; Scripts
Source: "scripts\*"; DestDir: "{app}\scripts"; Flags: ignoreversion recursesubdirs createallsubdirs

[Dirs]
Name: "{app}\app\wan_models"
Name: "{app}\app\ckpts"

[Icons]
Name: "{group}\Setup Environment"; Filename: "{app}\scripts\setup_environment.bat"; WorkingDir: "{app}"; IconFilename: "{sys}\cmd.exe"; Comment: "Install Python dependencies (run once after install)"
Name: "{group}\Download Models"; Filename: "{app}\scripts\download_models.bat"; WorkingDir: "{app}"; IconFilename: "{sys}\cmd.exe"; Comment: "Download AI models from HuggingFace"
Name: "{group}\Launch Web UI"; Filename: "{app}\scripts\launch_webui.bat"; WorkingDir: "{app}"; IconFilename: "{sys}\cmd.exe"; Comment: "Start the StreamDiffusionV2 Web UI"
Name: "{group}\Launch API"; Filename: "{app}\scripts\launch_api.bat"; WorkingDir: "{app}"; IconFilename: "{sys}\cmd.exe"; Comment: "Start the inference API"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{userdesktop}\{#MyAppName} Web UI"; Filename: "{app}\scripts\launch_webui.bat"; WorkingDir: "{app}"; IconFilename: "{sys}\cmd.exe"; Comment: "Start the StreamDiffusionV2 Web UI"

[Run]
Filename: "{app}\scripts\setup_environment.bat"; Description: "Run Setup Environment now (installs ~2.5 GB of Python packages - requires internet)"; Flags: nowait postinstall skipifsilent unchecked; WorkingDir: "{app}"

[UninstallRun]
Filename: "{app}\scripts\uninstall_cleanup.bat"; Flags: runhidden; WorkingDir: "{app}"; RunOnceId: "UninstallCleanup"

[Code]
function InitializeSetup(): Boolean;
var
  NvidiaSmiPath: String;
begin
  Result := True;
  // Find nvidia-smi in System32 (use {sysnative} to bypass WOW64 redirection)
  if IsWin64 then
    NvidiaSmiPath := ExpandConstant('{sysnative}\nvidia-smi.exe')
  else
    NvidiaSmiPath := ExpandConstant('{sys}\nvidia-smi.exe');
  if FileExists(NvidiaSmiPath) then
  begin
    // nvidia-smi exists, GPU drivers are installed — good to go
  end
  else
  begin
    if MsgBox('Warning: NVIDIA GPU drivers were not detected on this system.' + #13#10 +
              'StreamDiffusionV2 requires an NVIDIA GPU with CUDA support.' + #13#10#13#10 +
              'Do you want to continue the installation anyway?',
              mbConfirmation, MB_YESNO) = IDNO then
    begin
      Result := False;
    end;
  end;
end;
