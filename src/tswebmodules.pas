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
unit tswebmodules;

{$mode objfpc}{$H+}{$B-}

interface

uses
  SysUtils, webmodules, tswebnavbars, navbars, htmlpreprocess, fphttp,
  htmlpages, tswebpages, HTTPDefs, users, webstrconsts, authwebmodules,
  tswebprofilefeatures, tswebpagesbase;

type

  { TDefaultNavBar }

  TDefaultNavBar = class(TTesterNavBar)
  protected
    procedure DoCreateElements; override;
  end;

  { TSimpleHtmlPage }

  TSimpleHtmlPage = class(TDefaultHtmlPage)
  private
    FTextContent: string;
  protected
    function CreateNavBar: TNavBar; override;
    procedure DoGetInnerContents(Strings: TIndentTaggedStrings); override;
  public
    property TextContent: string read FTextContent write FTextContent;
  end;

  { TProfileHtmlPage }

  TProfileHtmlPage = class(TDefaultHtmlPage, IUserInfo)
  private
    FUsername: string;
  protected
    function CreateNavBar: TNavBar; override;
    procedure DoGetInnerContents(Strings: TIndentTaggedStrings); override;
    procedure AddFeatures; override;
    function GetInfo: TUserInfo;
  public
    constructor Create; override;
    constructor Create(const AUsername: string);
  end;

  { TNavLoginPage }

  TNavLoginPage = class(TLoginHtmlPage)
  protected
    function CreateNavBar: TNavBar; override;
  end;

  { TNavRegisterPage }

  TNavRegisterPage = class(TRegisterHtmlPage)
  protected
    function CreateNavBar: TNavBar; override;
  end;

  { TNavConfirmPasswordPage }

  TNavConfirmPasswordPage = class(TConfirmPasswordHtmlPage)
  protected
    function CreateNavBar: TNavBar; override;
  end;

  { TIndexWebModule }

  TIndexWebModule = class(THtmlPageWebModule)
  protected
    function DoCreatePage: THtmlPage; override;
  end;

  { TPage1WebModule }

  TPage1WebModule = class(THtmlPageWebModule)
  protected
    function DoCreatePage: THtmlPage; override;
  end;

  { TPage2WebModule }

  TPage2WebModule = class(THtmlPageWebModule)
  protected
    function DoCreatePage: THtmlPage; override;
  end;

  { TLoginWebModule }

  TLoginWebModule = class(TAuthCreateUserWebModule)
  protected
    function DoCreatePage: THtmlPage; override;
    procedure DoHandleAuth(ARequest: TRequest); override;
  end;

  { TRegisterWebModule }

  TRegisterWebModule = class(TAuthCreateUserWebModule)
  protected
    function DoCreatePage: THtmlPage; override;
    procedure DoHandleAuth(ARequest: TRequest); override;
  end;

  { TChangeUserRoleWebModule }

  TChangeUserRoleWebModule = class(TConfirmPasswordWebModule)
  protected
    procedure ConfirmationSuccess(var ACanRedirect: boolean;
      var ARedirect: string); override;
    function DoCreatePage: THtmlPage; override;
  public
    procedure AfterConstruction; override;
  end;

  { TProfileWebModule }

  TProfileWebModule = class(THtmlPageWebModule)
  protected
    function DoCreatePage: THtmlPage; override;
  end;

  { TKillServerWebModule }

  TKillServerWebModule = class(TTesterWebModule)
  protected
    procedure DoInsideRequest; override;
  end;

implementation

{ TChangeUserRoleWebModule }

procedure TChangeUserRoleWebModule.ConfirmationSuccess(var ACanRedirect: boolean;
  var ARedirect: string);
var
  AdminUser: TAdminUser;
  Username: string;
  Info: TUserInfo;
  Role: TUserRole;
begin
  // load admin, info & role
  AdminUser := User as TAdminUser;
  Username := Request.QueryFields.Values['user'];
  Info := UserManager.GetUserInfo(Username);
  try
    Role := StrToUserRole(Request.QueryFields.Values['newrole']);
    // try to perform the action
    AdminUser.GrantRole(Info, Role);
    // if success, redirect back to users
    ACanRedirect := True;
    ARedirect := DocumentRoot + '/profile?user=' + Username;
  finally
    FreeAndNil(Info);
  end;
end;

function TChangeUserRoleWebModule.DoCreatePage: THtmlPage;
begin
  Result := TNavConfirmPasswordPage.Create;
end;

procedure TChangeUserRoleWebModule.AfterConstruction;
begin
  inherited AfterConstruction;
  Handlers.Insert(0, TDeclineNotLoggedWebModuleHandler.Create([urAdmin, urOwner]));
end;

{ TNavConfirmPasswordPage }

function TNavConfirmPasswordPage.CreateNavBar: TNavBar;
begin
  Result := TDefaultNavBar.Create(Self);
end;

{ TProfileWebModule }

function TProfileWebModule.DoCreatePage: THtmlPage;
begin
  Result := TProfileHtmlPage.Create(Request.QueryFields.Values['user']);
end;

{ TProfileHtmlPage }

function TProfileHtmlPage.CreateNavBar: TNavBar;
begin
  Result := TDefaultNavBar.Create(Self);
end;

procedure TProfileHtmlPage.DoGetInnerContents(Strings: TIndentTaggedStrings);
begin
  Strings.Text := '~#+profile;';
end;

procedure TProfileHtmlPage.AddFeatures;
begin
  inherited AddFeatures;
  AddFeature(TProfileTitlePageFeature);
  AddFeature(TProfilePageFeature);
  AddFeature(TProfileChangeRoleFeature);
end;

function TProfileHtmlPage.GetInfo: TUserInfo;
begin
  if FUsername = '' then
  begin
    if User = nil then
      raise EUserAccessDenied.Create(SAccessDenied)
    else
      Result := UserManager.GetUserInfo(User.Username);
  end
  else
    Result := UserManager.GetUserInfo(FUsername);
end;

constructor TProfileHtmlPage.Create;
begin
  inherited Create;
  FUsername := '';
end;

constructor TProfileHtmlPage.Create(const AUsername: string);
begin
  inherited Create;
  FUsername := AUsername;
end;

{ TNavRegisterPage }

function TNavRegisterPage.CreateNavBar: TNavBar;
begin
  Result := TDefaultNavBar.Create(Self);
end;

{ TNavLoginPage }

function TNavLoginPage.CreateNavBar: TNavBar;
begin
  Result := TDefaultNavBar.Create(Self);
end;

{ TKillServerWebModule }

procedure TKillServerWebModule.DoInsideRequest;
var
  User: TUser;
begin
  User := UserManager.LoadUserFromSession(Session);
  try
    if (User = nil) or not (User is TOwnerUser) then
      raise EUserAccessDenied.Create(SAccessDenied);
    (User as TOwnerUser).TerminateServer;
  finally
    FreeAndNil(User);
  end;
end;

{ TRegisterWebModule }

function TRegisterWebModule.DoCreatePage: THtmlPage;
begin
  Result := TNavRegisterPage.Create;
end;

procedure TRegisterWebModule.DoHandleAuth(ARequest: TRequest);
var
  Username, Password, Password2, FirstName, LastName: string;
begin
  Username := ARequest.ContentFields.Values['username'];
  Password := ARequest.ContentFields.Values['password'];
  Password2 := ARequest.ContentFields.Values['password2'];
  FirstName := ARequest.ContentFields.Values['first-name'];
  LastName := ARequest.ContentFields.Values['last-name'];
  UserManager.AddNewUser(Username, Password, Password2, FirstName, LastName);
  UserManager.AuthentificateSession(Session, Username, Password);
end;

{ TLoginWebModule }

function TLoginWebModule.DoCreatePage: THtmlPage;
begin
  Result := TNavLoginPage.Create;
end;

procedure TLoginWebModule.DoHandleAuth(ARequest: TRequest);
var
  Username, Password: string;
begin
  Username := ARequest.ContentFields.Values['username'];
  Password := ARequest.ContentFields.Values['password'];
  UserManager.AuthentificateSession(Session, Username, Password);
end;

{ TPage2WebModule }

function TPage2WebModule.DoCreatePage: THtmlPage;
begin
  Result := TSimpleHtmlPage.Create;
  try
    with Result as TSimpleHtmlPage do
    begin
      Title := 'Page 2';
      TextContent := 'This is page 2.';
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

{ TPage1WebModule }

function TPage1WebModule.DoCreatePage: THtmlPage;
begin
  Result := TSimpleHtmlPage.Create;
  try
    with Result as TSimpleHtmlPage do
    begin
      Title := 'Page 1';
      TextContent := 'This is page 1.';
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

{ TIndexWebModule }

function TIndexWebModule.DoCreatePage: THtmlPage;
begin
  Result := TSimpleHtmlPage.Create;
  try
    with Result as TSimpleHtmlPage do
    begin
      Title := 'Main Page';
      TextContent := 'Hello World!';
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

{ TDefaultNavBar }

procedure TDefaultNavBar.DoCreateElements;
begin
  AddElement('Main Page', '~documentRoot;/index');
  AddElement('Page 1', '~documentRoot;/page1');
  AddElement('Page 2', '~documentRoot;/page2');
end;

{ TSimpleHtmlPage }

function TSimpleHtmlPage.CreateNavBar: TNavBar;
begin
  Result := TDefaultNavBar.Create(Self);
end;

procedure TSimpleHtmlPage.DoGetInnerContents(Strings: TIndentTaggedStrings);
begin
  Strings.Text := FTextContent;
end;

initialization
  RegisterHTTPModule('index', TIndexWebModule, True);
  RegisterHTTPModule('page1', TPage1WebModule, True);
  RegisterHTTPModule('page2', TPage2WebModule, True);
  RegisterHTTPModule('login', TLoginWebModule, True);
  RegisterHTTPModule('logout', TLogoutWebModule, True);
  RegisterHTTPModule('register', TRegisterWebModule, True);
  RegisterHTTPModule('kill', TKillServerWebModule, True);
  RegisterHTTPModule('profile', TProfileWebModule, True);
  RegisterHTTPModule('change-role', TChangeUserRoleWebModule, True);

end.
