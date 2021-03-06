{
  This file is part of Tester Web

  Copyright (C) 2017 Alexander Kernozhitsky <sh200105@mail.ru>

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}
unit problems;

{$mode objfpc}{$H+}{$M+}

interface

uses
  Classes, SysUtils, editableobjects, datastorages, webstrconsts, TypInfo,
  tswebdirectories, filemanager, archivemanager, FileUtil, LazFileUtils,
  tswebconfig, users;

type
  TProblemStatementsType = (stNone, stHtml, stPdf, stDoc, stDocx);

const
  SFileTypesByExt: array [TProblemStatementsType] of string = (
    '',
    '.html',
    '.pdf',
    '.doc',
    '.docx'
    );

  SFileTypesByName: array [TProblemStatementsType] of string = (
    SNone,
    SProblemStatementsHtml,
    SProblemStatementsPdf,
    SProblemStatementsDoc,
    SProblemStatementsDocx
    );

  SFileTypesByMime: array [TProblemStatementsType] of string = (
    '',
    'text/html',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    );

  SArchiveMime = 'application/zip';
  SArchiveExt = '.zip';

type
  TProblem = class;

  { TProblemAccessSession }

  TProblemAccessSession = class(TEditableObjectAccessSession)
  protected
    {%H-}constructor Create(AManager: TEditableManager; AUser: TUser;
      AObject: TEditableObject);
  end;

  { TBaseProblemTransaction }

  TBaseProblemTransaction = class(TEditableTransaction)
  private
    FArchiveFileName: string;
    FMaxSrcLimit: integer;
    FPropsFileName: string;
    FPropsFullFileName: string;
    FStatementsFileName: string;
    FStatementsType: TProblemStatementsType;
    FUnpackedFileName: string;
    function GetProblem: TProblem;
  protected
    property ArchiveFileName: string read FArchiveFileName write FArchiveFileName;
    property UnpackedFileName: string read FUnpackedFileName;
    property PropsFullFileName: string read FPropsFullFileName;
    property PropsFileName: string read FPropsFileName write FPropsFileName;
    procedure DoCommit; override;
    procedure DoReload; override;
    procedure DoClone(ADest: TEditableTransaction); override;
    {%H-}constructor Create(AManager: TEditableManager; AUser: TUser;
      AObject: TEditableObject);
  public
    property Problem: TProblem read GetProblem;
    property StatementsType: TProblemStatementsType read FStatementsType write
      FStatementsType;
    property StatementsFileName: string read FStatementsFileName write
      FStatementsFileName;
    property MaxSrcLimit: integer read FMaxSrcLimit write FMaxSrcLimit;
    procedure Validate; override;
  end;

  { TProblemTransaction }

  TProblemTransaction = class(TBaseProblemTransaction)
  public
    property ArchiveFileName;
  end;

  { TProblemManagerSession }

  TProblemManagerSession = class(TEditableManagerSession)
  protected
    {%H-}constructor Create(AManager: TEditableManager; AUser: TUser);
  end;

  { TProblem }

  TProblem = class(TEditableObject)
  private
    function GetFileName(const Dir, Ext: string; MustExist, IsDir: boolean): string;
  protected
    {%H-}constructor Create(const AName: string; AManager: TEditableManager);
    function ArchiveFileName(MustExist: boolean): string;
    function UnpackedFileName(MustExist: boolean): string;
    function StatementsFileName(MustExist: boolean): string;
    function StatementsFileType: TProblemStatementsType;
    function PropsFullFileName: string;
    procedure HandleSelfDeletion; override;
  public
    function CreateAccessSession(AUser: TUser): TEditableObjectAccessSession; override;
    function CreateTransaction(AUser: TUser): TEditableTransaction; override;
  end;

  { TProblemManager }

  TProblemManager = class(TEditableManager)
  protected
    function ObjectTypeName: string; override;
    function CreateStorage: TAbstractDataStorage; override;
    function CreateObject(const AName: string): TEditableObject; override;
  public
    function CreateManagerSession(AUser: TUser): TEditableManagerSession; override;
  end;

function StatementsTypeToStr(AType: TProblemStatementsType): string;
function StrToStatementsType(const S: string): TProblemStatementsType;

implementation

function StatementsTypeToStr(AType: TProblemStatementsType): string;
begin
  Result := GetEnumName(TypeInfo(TProblemStatementsType), Ord(AType));
end;

function StrToStatementsType(const S: string): TProblemStatementsType;
var
  T: TProblemStatementsType;
begin
  for T in TProblemStatementsType do
    if StatementsTypeToStr(T) = S then
      Exit(T);
  raise EConvertError.Create(SNoSuchStatementsType);
end;

{ TProblemManager }

function TProblemManager.ObjectTypeName: string;
begin
  Result := SProblemTypeName;
end;

function TProblemManager.CreateStorage: TAbstractDataStorage;
begin
  Result := TXmlDataStorage.Create('problems');
end;

function TProblemManager.CreateObject(const AName: string): TEditableObject;
begin
  Result := TProblem.Create(AName, Self);
end;

function TProblemManager.CreateManagerSession(AUser: TUser): TEditableManagerSession;
begin
  Result := TProblemManagerSession.Create(Self, AUser);
end;

{ TProblem }

constructor TProblem.Create(const AName: string; AManager: TEditableManager);
begin
  inherited Create(AName, AManager);
end;

function TProblem.GetFileName(const Dir, Ext: string; MustExist, IsDir: boolean): string;
var
  Path: string;
  Exists: boolean;
begin
  Path := AppendPathDelim(ExpandInternalDirLocation(Dir));
  Result := Path + Format('problem%d%s', [ID, Ext]);
  if MustExist then
  begin
    if IsDir then
      Exists := DirectoryExistsUTF8(Result)
    else
      Exists := FileExistsUTF8(Result);
    if not Exists then
      Result := '';
  end;
end;

function TProblem.ArchiveFileName(MustExist: boolean): string;
begin
  Result := GetFileName('archives', SArchiveExt, MustExist, False);
end;

function TProblem.UnpackedFileName(MustExist: boolean): string;
begin
  Result := GetFileName('problems', '', MustExist, True);
end;

function TProblem.StatementsFileName(MustExist: boolean): string;
var
  FileType: TProblemStatementsType;
begin
  FileType := StatementsFileType;
  if FileType = stNone then
    Result := ''
  else
    Result := GetFileName('statements', SFileTypesByExt[FileType], MustExist, False);
end;

function TProblem.StatementsFileType: TProblemStatementsType;
var
  DefaultValue: string;
begin
  DefaultValue := StatementsTypeToStr(stNone);
  Result := StrToStatementsType(Storage.ReadString(FullKeyName('statementType'),
    DefaultValue));
end;

function TProblem.PropsFullFileName: string;
var
  PropsFile: string;
begin
  Result := UnpackedFileName(True);
  PropsFile := Storage.ReadString(FullKeyName('propsFile'), '');
  if (Result = '') or (PropsFile = '') then
    Exit('');
  Result := AppendPathDelim(Result) + PropsFile;
end;

procedure TProblem.HandleSelfDeletion;
var
  Success: boolean;
begin
  inherited HandleSelfDeletion;
  Success := True;
  Success := Success and TryDeleteFile(StatementsFileName(True));
  Success := Success and TryDeleteFile(ArchiveFileName(True));
  Success := Success and TryDeleteDir(UnpackedFileName(True));
  if not Success then
    raise EEditableAction.CreateFmt(SErrorsWhileDeletingProblem, [Name]);
end;

function TProblem.CreateAccessSession(AUser: TUser): TEditableObjectAccessSession;
begin
  Result := TProblemAccessSession.Create(Manager, AUser, Self);
end;

function TProblem.CreateTransaction(AUser: TUser): TEditableTransaction;
begin
  Result := TProblemTransaction.Create(Manager, AUser, Self);
end;

{ TProblemManagerSession }

constructor TProblemManagerSession.Create(AManager: TEditableManager;
  AUser: TUser);
begin
  inherited Create(AManager, AUser);
end;

{ TProblemAccessSession }

constructor TProblemAccessSession.Create(AManager: TEditableManager;
  AUser: TUser; AObject: TEditableObject);
begin
  inherited Create(AManager, AUser, AObject);
end;

{ TBaseProblemTransaction }

function TBaseProblemTransaction.GetProblem: TProblem;
begin
  Result := EditableObject as TProblem;
end;

procedure TBaseProblemTransaction.DoCommit;
begin
  inherited DoCommit;
  try
    // archive
    if FArchiveFileName <> Problem.ArchiveFileName(True) then
    begin
      TryDeleteFile(Problem.ArchiveFileName(True), True);
      Storage.WriteString(FullKeyName('propsFile'), FPropsFileName);
      UnpackArchive(FArchiveFileName, Problem.UnpackedFileName(False), True);
      CopyReplaceFile(FArchiveFileName, Problem.ArchiveFileName(False));
    end;
    // statements
    if FStatementsFileName <> Problem.StatementsFileName(True) then
    begin
      TryDeleteFile(Problem.StatementsFileName(True), True);
      Storage.WriteString(FullKeyName('statementType'), StatementsTypeToStr(FStatementsType));
      CopyReplaceFile(FStatementsFileName, Problem.StatementsFileName(False));
    end;
    // max submission limit
    Storage.WriteInteger(FullKeyName('maxSrc'), FMaxSrcLimit);
  except
    on E: EFileManager do
      raise EEditableAction.Create(E.Message)
    else
      raise;
  end;
end;

procedure TBaseProblemTransaction.DoReload;
begin
  inherited DoReload;
  FArchiveFileName := Problem.ArchiveFileName(True);
  FUnpackedFileName := Problem.UnpackedFileName(True);
  FStatementsFileName := Problem.StatementsFileName(True);
  FStatementsType := Problem.StatementsFileType;
  FMaxSrcLimit := Storage.ReadInteger(FullKeyName('maxSrc'), Config.Files_DefaultSrcSize);
  FPropsFileName := Storage.ReadString(FullKeyName('propsFile'), Config.Problem_DefaultPropsFile);
  FPropsFullFileName := Problem.PropsFullFileName;
end;

procedure TBaseProblemTransaction.DoClone(ADest: TEditableTransaction);
begin
  inherited DoClone(ADest);
  with ADest as TBaseProblemTransaction do
  begin
    ArchiveFileName := Self.ArchiveFileName;
    StatementsFileName := Self.StatementsFileName;
    StatementsType := Self.StatementsType;
    MaxSrcLimit := Self.MaxSrcLimit;
    PropsFileName := Self.PropsFileName;
  end;
end;

constructor TBaseProblemTransaction.Create(AManager: TEditableManager;
  AUser: TUser; AObject: TEditableObject);
begin
  inherited Create(AManager, AUser, AObject);
end;

procedure TBaseProblemTransaction.Validate;
begin
  inherited Validate;
  try
    // archive
    if FArchiveFileName <> Problem.ArchiveFileName(True) then
      ValidateArchive(FArchiveFileName, FPropsFileName);
    // statements file
    if FStatementsFileName <> Problem.StatementsFileName(True) then
      ValidateFileSize(FStatementsFileName, Config.Files_MaxStatementsSize,
        SStatementsTooBig);
    // max submisson limit
    if (FMaxSrcLimit < 1) or (FMaxSrcLimit > Config.Files_MaxSrcSize) then
      raise EEditableValidate.CreateFmt(SMaxSrcSize, [1, Config.Files_MaxSrcSize]);
  except
    on E: EFileManager do
      raise EEditableValidate.Create(E.Message)
    else
      raise;
  end;
end;

end.
