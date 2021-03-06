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
unit tswebcontestelements;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, htmlpages, tswebpagesbase, contests, webstrconsts,
  htmlpreprocess;

type

  { TContestParticipantNode }

  TContestParticipantNode = class(TTesterHtmlPageElement)
  private
    FIndex: integer;
    FSession: TContestParticipantSession;
    FUsername: string;
  protected
    procedure DoFillVariables; override;
    procedure DoGetSkeleton(Strings: TIndentTaggedStrings); override;
  public
    property Session: TContestParticipantSession read FSession;
    property Username: string read FUsername;
    property Index: integer read FIndex;
    constructor Create(AParent: THtmlPage; ASession: TContestParticipantSession;
      const AUsername: string; AIndex: integer);
  end;

  { TContestParticipantTable }

  TContestParticipantTable = class(TTesterHtmlListedPageElement)
  private
    FSession: TContestParticipantSession;
  protected
    procedure DoFillList;
    procedure DoFillVariables; override;
    procedure DoGetSkeleton(Strings: TIndentTaggedStrings); override;
  public
    property Session: TContestParticipantSession read FSession;
    constructor Create(AParent: THtmlPage; ASession: TContestParticipantSession);
  end;

  { TContestProblemListItem }

  TContestProblemListItem = class(TTesterHtmlPageElement)
  private
    FIndex: integer;
    FTransaction: TContestTransaction;
  protected
    procedure DoFillVariables; override;
    procedure DoGetSkeleton(Strings: TIndentTaggedStrings); override;
  public
    property Transaction: TContestTransaction read FTransaction;
    property Index: integer read FIndex;
    constructor Create(AParent: THtmlPage; ATransaction: TContestTransaction;
      AIndex: integer);
  end;

  { TContestProblemList }

  TContestProblemList = class(TTesterHtmlListedPageElement)
  private
    FTransaction: TContestTransaction;
  protected
    procedure DoFillList;
    procedure DoFillVariables; override;
    procedure DoGetSkeleton(Strings: TIndentTaggedStrings); override;
  public
    property Transaction: TContestTransaction read FTransaction;
    constructor Create(AParent: THtmlPage; ATransaction: TContestTransaction);
  end;

implementation

{ TContestProblemList }

procedure TContestProblemList.DoFillList;
var
  I: integer;
begin
  for I := 0 to Transaction.ProblemCount - 1 do
    List.Add(TContestProblemListItem.Create(Parent, Transaction, I));
end;

procedure TContestProblemList.DoFillVariables;
begin
  with Storage do
  begin
    ItemsAsText['contestProblemNumberHeader'] := SContestProblemNumberHeader;
    ItemsAsText['contestProblemNameHeader'] := SContestProblemNameHeader;
    ItemsAsText['contestProblemTitleHeader'] := SContestProblemTitleHeader;
    ItemsAsText['contestProblemActionsHeader'] := SContestProblemActionsHeader;
  end;
  AddListToVariable('contestProblemListInner');
end;

procedure TContestProblemList.DoGetSkeleton(Strings: TIndentTaggedStrings);
begin
  Strings.LoadFromFile(TemplateLocation('contest', 'contestProblemList'));
end;

constructor TContestProblemList.Create(AParent: THtmlPage;
  ATransaction: TContestTransaction);
begin
  inherited Create(AParent);
  FTransaction := ATransaction;
  DoFillList;
end;

{ TContestProblemListItem }

procedure TContestProblemListItem.DoFillVariables;

  procedure LoadAction(const VarName: string; Enabled: boolean);
  var
    FileName: string;
  begin
    if Enabled then
      FileName := 'contestActionBtnEnabled'
    else
      FileName := 'contestActionBtnDisabled';
    Storage.SetFromFile(VarName, TemplateLocation('contest', FileName));
  end;

begin
  with Storage do
  begin
    ItemsAsText['actionTarget'] := IntToStr(Index);
    ItemsAsText['contestProblemNumber'] := IntToStr(Index + 1);
    ItemsAsText['contestProblemName'] := Transaction.ProblemNames[Index];
    ItemsAsText['contestProblemTitle'] := Transaction.ProblemTitles[Index];
    ItemsAsText['actionUpCaption'] := SActionUpCaption;
    ItemsAsText['actionDownCaption'] := SActionDownCaption;
    ItemsAsText['actionDeleteCaption'] := SActionDeleteCaption;
  end;
  LoadAction('contestActionUp', Transaction.CanMoveProblemUp(Index));
  LoadAction('contestActionDown', Transaction.CanMoveProblemDown(Index));
  LoadAction('contestActionDelete', Transaction.CanDeleteProblem(Index));
end;

procedure TContestProblemListItem.DoGetSkeleton(Strings: TIndentTaggedStrings);
begin
  Strings.LoadFromFile(TemplateLocation('contest', 'contestProblemListItem'));
end;

constructor TContestProblemListItem.Create(AParent: THtmlPage;
  ATransaction: TContestTransaction; AIndex: integer);
begin
  inherited Create(AParent);
  FTransaction := ATransaction;
  FIndex := AIndex;
end;

{ TContestParticipantTable }

procedure TContestParticipantTable.DoFillList;
var
  StrList: TStringList;
  I: integer;
begin
  StrList := Session.ListParticipants;
  try
    for I := 0 to StrList.Count - 1 do
      List.Add(TContestParticipantNode.Create(Parent, Session, StrList[I], I));
  finally
    FreeAndNil(StrList);
  end;
end;

procedure TContestParticipantTable.DoFillVariables;
begin
  with Storage do
  begin
    ItemsAsText['participantIndexHeader'] := SParticipantIndexHeader;
    ItemsAsText['participantNameHeader'] := SParticipantNameHeader;
    ItemsAsText['participantDeleteHeader'] := SParticipantDeleteHeader;
  end;
  AddListToVariable('contestParticipantsTableInner');
end;

procedure TContestParticipantTable.DoGetSkeleton(Strings: TIndentTaggedStrings);
begin
  Strings.LoadFromFile(TemplateLocation('contest', 'contestParticipantsTable'));
end;

constructor TContestParticipantTable.Create(AParent: THtmlPage;
  ASession: TContestParticipantSession);
begin
  inherited Create(AParent);
  FSession := ASession;
  DoFillList;
end;

{ TContestParticipantNode }

procedure TContestParticipantNode.DoFillVariables;
var
  DeleteBtnLocation: string;
begin
  with Storage do
  begin
    ItemsAsText['participantIndex'] := IntToStr(Index + 1);
    ItemsAsText['participantName'] := Parent.GenerateUserLink(Username);
    ItemsAsText['deleteTargetType'] := 'user';
    ItemsAsText['deleteTarget'] := Username;
    ItemsAsText['deleteQuery'] := 'delete-user';
    if Session.CanDeleteParticipant then
      DeleteBtnLocation := 'editableDeleteEnabled'
    else
      DeleteBtnLocation := 'editableDeleteDisabled';
    SetFromFile('participantDelete', TemplateLocation('editable', DeleteBtnLocation));
  end;
end;

procedure TContestParticipantNode.DoGetSkeleton(Strings: TIndentTaggedStrings);
begin
  Strings.LoadFromFile(TemplateLocation('contest', 'contestParticipantsNode'));
end;

constructor TContestParticipantNode.Create(AParent: THtmlPage;
  ASession: TContestParticipantSession; const AUsername: string; AIndex: integer);
begin
  inherited Create(AParent);
  FSession := ASession;
  FUsername := AUsername;
  FIndex := AIndex;
end;

end.

