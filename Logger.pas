unit Logger;

interface

uses
  Forms,
  SysUtils,
  Windows;

type
  TLogTypes = (ltTrace, ltDebug, ltInfo, ltWarning, ltError, ltFatal);

  TLogger = class
    constructor Create(const AFileName: String = '');
    destructor Destroy; override;
    class function New(const AFilename: String = ''): TLogger;
    class function NewInstance: TObject; override;
  private
    FFileName   : string;
    FIsInit     : Boolean;
    FOutFile    : TextFile;
    FQuietMode  : Boolean;
    FQuietTypes : set of TLogTypes;

    procedure Initialize;
    procedure CreateFoldersIfNecessary;
    procedure Finalize;
    procedure Write(const Msg: string);
  public
    procedure Clear;

    procedure SetQuietMode;
    procedure SetNoisyMode;

    procedure DisableTraceLog;
    procedure DisableDebugLog;
    procedure DisableInfoLog;
    procedure DisableWarningLog;
    procedure DisableErrorLog;
    procedure DisableFatalLog;

    procedure EnableTraceLog;
    procedure EnableDebugLog;
    procedure EnableInfoLog;
    procedure EnableWarningLog;
    procedure EnableErrorLog;
    procedure EnableFatalLog;




    class procedure Trace  ( const Msg: string );
    class procedure Debug  ( const Msg: string );
    class procedure Info   ( const Msg: string );
    class procedure Warning( const Msg: string );
    class procedure Error  ( const Msg: string );
    class procedure Fatal  ( const Msg: string );
  end;

var
  FLogger: TLogger;
  LineNumber: Integer;

implementation

const
  FORMAT_LOG   = '%s %s';
  PREFIX_TRACE = 'TRACE';
  PREFIX_DEBUG = 'DEBUG';
  PREFIX_INFO  = 'INFO ';
  PREFIX_WARN  = 'WARN ';
  PREFIX_ERROR = 'ERROR';
  PREFIX_FATAL = 'FATAL';

{ TLogger }

constructor TLogger.Create(const AFileName: String = '');
begin
  if AFileName = '' then
    FFileName := ExtractFilePath( Application.ExeName ) + '\Diagnostic\' + FormatDateTime('yyyy-mm-dd', Now) + '.log'
  else
    FFileName := AFileName;

  FIsInit   := False;
  Self.SetNoisyMode;
  FQuietTypes := [];
end;

destructor TLogger.Destroy;
begin
  Self.Finalize;
  inherited;
end;

class function TLogger.New(const AFilename: String = ''): TLogger;
begin
  Result := TLogger.Create(AFilename);
end;

class function TLogger.NewInstance: TObject;
begin
  if not Assigned(FLogger) then
     FLogger := TLogger(inherited NewInstance);

  result := FLogger;
end;

procedure TLogger.Clear;
begin
  if not FileExists(FFileName) then
    Exit;

  if FIsInit then
    CloseFile(FOutFile);

  SysUtils.DeleteFile(FFileName);

  FIsInit := False;
end;

procedure TLogger.CreateFoldersIfNecessary;
var
  FilePath: string;
  FullApplicationPath: string;
begin
  FilePath := ExtractFilePath(FFileName);

  if Pos(':', FilePath) > 0 then
    ForceDirectories(FilePath)
  else
  begin
    FullApplicationPath := ExtractFilePath(Application.ExeName);
    ForceDirectories(IncludeTrailingPathDelimiter(FullApplicationPath) + FilePath);
  end;
end;

procedure TLogger.DisableDebugLog;
begin
  Include(FQuietTypes, ltDebug);
end;

procedure TLogger.DisableErrorLog;
begin
  Include(FQuietTypes, ltError);
end;

procedure TLogger.DisableFatalLog;
begin
  Include(FQuietTypes, ltFatal);
end;

procedure TLogger.DisableInfoLog;
begin
  Include(FQuietTypes, ltInfo);
end;

procedure TLogger.DisableTraceLog;
begin
  Include(FQuietTypes, ltTrace);
end;

procedure TLogger.DisableWarningLog;
begin
  Include(FQuietTypes, ltWarning);
end;

procedure TLogger.EnableDebugLog;
begin
  Exclude(FQuietTypes, ltDebug);
end;

procedure TLogger.EnableErrorLog;
begin
  Exclude(FQuietTypes, ltError);
end;

procedure TLogger.EnableFatalLog;
begin
  Exclude(FQuietTypes, ltFatal);
end;

procedure TLogger.EnableInfoLog;
begin
  Exclude(FQuietTypes, ltInfo);
end;

procedure TLogger.EnableTraceLog;
begin
  Exclude(FQuietTypes, ltTrace);
end;

procedure TLogger.EnableWarningLog;
begin
  Exclude(FQuietTypes, ltWarning);
end;

class procedure TLogger.Debug(const Msg: string);
begin
  if not Assigned(FLogger) then
    FLogger := TLogger.Create;

  {$WARN SYMBOL_PLATFORM OFF}
  if DebugHook = 0 then
    Exit;
  {$WARN SYMBOL_PLATFORM ON}

  with FLogger do
  begin
    if not (ltDebug in FQuietTypes) then
      Write(Format(FORMAT_LOG, [PREFIX_DEBUG, Msg]));
  end;
end;

class procedure TLogger.Error(const Msg: string);
begin
  if not Assigned(FLogger) then
    FLogger := TLogger.Create;

  with FLogger do
  begin
    if not (ltError in FQuietTypes) then
      Write( Format( FORMAT_LOG, [PREFIX_ERROR, Msg] ) );
  end;
end;

class procedure TLogger.Fatal(const Msg: string);
begin
  if not Assigned(FLogger) then
    FLogger := TLogger.Create;

  with FLogger do
  begin
    if not (ltFatal in FQuietTypes) then
      Write(Format(FORMAT_LOG, [PREFIX_FATAL, Msg]));
  end;
end;

procedure TLogger.Finalize;
begin
  if (FIsInit and (not FQuietMode)) then
    CloseFile(FOutFile);

  FIsInit := False;
end;

procedure TLogger.Initialize;
begin
  if FIsInit then
    CloseFile(FOutFile);

  if not FQuietMode then
  begin
    Self.CreateFoldersIfNecessary;

    AssignFile(FOutFile, FFileName);
    if not FileExists(FFileName) then
      Rewrite(FOutFile)
    else
      Append(FOutFile);
  end;

  FIsInit := True;
end;

class procedure TLogger.Info(const Msg: string);
begin
  if not Assigned(FLogger) then
    FLogger := TLogger.Create;

  with FLogger do
  begin
    if not (ltInfo in FQuietTypes) then
      Write(Format(FORMAT_LOG, [PREFIX_INFO, Msg]));
  end;
end;

procedure TLogger.SetNoisyMode;
begin
  FQuietMode := False;
end;

procedure TLogger.SetQuietMode;
begin
  FQuietMode := True;
end;

class procedure TLogger.Trace(const Msg: string);
begin
  if not Assigned(FLogger) then
    FLogger := TLogger.Create;

  with FLogger do
  begin
    if not (ltTrace in FQuietTypes) then
      Write(Format(FORMAT_LOG, [PREFIX_TRACE, Msg]));
  end;
end;

class procedure TLogger.Warning(const Msg: string);
begin
  if not Assigned(FLogger) then
    FLogger := TLogger.Create;

  with FLogger do
  begin
    if not (ltWarning in FQuietTypes) then
      Write(Format(FORMAT_LOG, [PREFIX_WARN, Msg]));
  end;
end;

procedure TLogger.Write(const Msg: string);
const
  FORMAT_DATETIME_DEFAULT = 'yyyy-mm-dd hh:nn:ss';
begin
  if FQuietMode then
    Exit;

  Self.Initialize;
  try
    if FIsInit then
      Writeln(FOutFile, Format('%s [%s]', [Msg, FormatDateTime(FORMAT_DATETIME_DEFAULT, Now)]));
  finally
    Self.Finalize;
  end;
end;

initialization
  FLogger := TLogger.Create;

finalization
  FLogger.Free;

end.
