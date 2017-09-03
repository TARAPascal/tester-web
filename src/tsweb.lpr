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
program tsweb;

{$mode objfpc}{$H+}

uses
  heaptrc,
  fphttpapp,
  index,
  htmlpreprocess,
  escaping,
  webstrconsts,
  SysUtils,
  datastorages;

function DoGetApplicationName: string;
begin
  Result := 'tsweb';
end;

var
  AStorage: TAbstractDataStorage;
begin
  OnGetApplicationName := @DoGetApplicationName;

  AStorage := TXmlDataStorage.Create('demo');
  try
    AStorage.WriteInteger('app.ints.answer', 42);
    AStorage.WriteBool('app.bools.isTrue', True);
    AStorage.WriteFloat('temperature', 36.6152845245);
    AStorage.WriteInt64('app.ints.int64', 42862469295);
    AStorage.WriteString('strconts.hello', 'Привет');
    WriteLn('Here!!!');
    AStorage.Reload;
    WriteLn(AStorage.ReadInteger('app.ints.answer', -1));
  finally
    FreeAndNil(AStorage);
  end;

  Application.Title := 'Tester Web';
  {Application.Port := 8080;
  Application.Initialize;
  Application.Run;}
end.
