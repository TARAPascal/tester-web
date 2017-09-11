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
unit tswebfeatures;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, htmlpages, htmlpreprocess, webstrconsts, tswebpagesbase,
  navbars;

// TODO : Add users and login panel!

type

  { TPageBaseFeature }

  TPageBaseFeature = class(THtmlPageFeature)
  public
    procedure Satisfy; override;
    procedure DependsOn({%H-}ADependencies: THtmlPageFeatureList); override;
  end;

  { TTesterPageFeature }

  TTesterPageFeature = class(THtmlPageFeature)
  protected
    procedure LoadPagePart(const VarName: string);
  public
    procedure DependsOn(ADependencies: THtmlPageFeatureList); override;
  end;

  { THeaderFeature }

  THeaderFeature = class(TTesterPageFeature)
  public
    procedure Satisfy; override;
  end;

  { TFooterFeature }

  TFooterFeature = class(TTesterPageFeature)
  public
    procedure Satisfy; override;
  end;

  { TContentFeature }

  TContentFeature = class(TTesterPageFeature)
  public
    procedure Satisfy; override;
  end;

  { TNavBarFeature }

  TNavBarFeature = class(TTesterPageFeature)
  public
    procedure Satisfy; override;
  end;

implementation

{ TNavBarFeature }

procedure TNavBarFeature.Satisfy;
var
  Strings: TIndentTaggedStrings;
  NavBarIntf: IPageNavBar;
begin
  NavBarIntf := Parent as IPageNavBar;
  Strings := TIndentTaggedStrings.Create;
  try
    NavBarIntf.NavBar.GetContents(Strings);
    Parent.PageParts.SetItemAsStrings('nav', Strings);
  finally
    FreeAndNil(Strings);
  end;
end;

{ TContentFeature }

procedure TContentFeature.Satisfy;
var
  Strings: TIndentTaggedStrings;
begin
  Strings := TIndentTaggedStrings.Create;
  try
    with (Parent as TTesterHtmlPage) do
    begin
      GetInnerContents(Strings);
      PageParts.SetItemAsStrings('content', Strings);
    end;
  finally
    FreeAndNil(Strings);
  end;
end;

{ TFooterFeature }

procedure TFooterFeature.Satisfy;
begin
  with Parent do
  begin
    Variables.ItemsAsText['copyright'] := SCopyright;
    Variables.ItemsAsText['license'] := SLicenseNotice;
    Variables.ItemsAsText['github'] := SSourcesNotice;
  end;
  LoadPagePart('footer');
end;

{ THeaderFeature }

procedure THeaderFeature.Satisfy;
begin
  LoadPagePart('header');
  // TODO : Add login panel here!
end;

{ TPageBaseFeature }

procedure TPageBaseFeature.Satisfy;
begin
  with Parent.Variables do
  begin
    ItemsAsText['documentRoot'] := DocumentRoot;
    ItemsAsText['dataRoot'] := DataRoot;
    if Parent is TTesterHtmlPage then
    begin
      ItemsAsText['pageHeader'] := (Parent as TTesterHtmlPage).Title;
      ItemsAsText['title'] := (Parent as TTesterHtmlPage).Title;
    end;
  end;
end;

procedure TPageBaseFeature.DependsOn(ADependencies: THtmlPageFeatureList);
begin
  // do nothing
end;

{ TTesterPageFeature }

procedure TTesterPageFeature.LoadPagePart(const VarName: string);
begin
  Parent.PageParts.SetFromFile(VarName, TemplateLocation(VarName));
end;

procedure TTesterPageFeature.DependsOn(ADependencies: THtmlPageFeatureList);
begin
  ADependencies.Add(TPageBaseFeature);
end;

end.
