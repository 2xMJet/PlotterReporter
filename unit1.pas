unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, Windows, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, Menus, Grids, Regexpr, Fileutil, TASources, TAGraph,
  TASeries, lrPDFExport, LR_DSet, LR_View, LR_Class,
  lrAddFunctionLibrary, LR_e_img, LR_e_htmldiv, lr_e_fclpdf, Types;

type

  { TForm1 }

  TForm1 = class(TForm)
    AddGraphButton: TButton;
    AddNote: TLabel;
    AddNoteButton: TButton;
    ClearReport: TButton;
    CompileButton: TButton;
    Edit1: TEdit;
    frHtmlDivExport1: TfrHtmlDivExport;
    frImageExport1: TfrImageExport;
    Image1: TImage;
    Image2: TImage;
    Label1: TLabel;
    Label3: TLabel;
    lrAddFunctionLibrary1: TlrAddFunctionLibrary;
    PDFReportButton: TButton;
    HTMLReportButton: TButton;
    Chart1: TChart;
    Chart1LineSeries1: TLineSeries;
    ClrGrid: TButton;
    DataBankPath: TLabeledEdit;
    frPreview1: TfrPreview;
    frReport1: TfrReport;
    frUserDataset1: TfrUserDataset;
    AddGraph: TLabeledEdit;
    ListChartSource1: TListChartSource;
    Note: TMemo;
    FilesGrid: TStringGrid;
    Workfolder: TLabeledEdit;
    lrPDFExport1: TlrPDFExport;
    RefreshData: TButton;
    DatabankTree: TTreeView;
    UnsetDataBank: TButton;
    SetDataBank: TButton;
    IView: TfrView;
    procedure AddGraphButtonClick(Sender: TObject);
    procedure AddGraphChange(Sender: TObject);
    procedure AddNoteButtonClick(Sender: TObject);
    procedure ClearReportClick(Sender: TObject);
    procedure ClrGridClick(Sender: TObject);
    procedure DatabankTreeMouseLeave(Sender: TObject);
    procedure DatabankTreeMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure FilesGridClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure frUserDataset1CheckEOF(Sender: TObject; var Eof: Boolean);
    procedure frUserDataset1First(Sender: TObject);
    procedure frUserDataset1Next(Sender: TObject);
    procedure HTMLReportButtonClick(Sender: TObject);
    procedure PDFReportButtonClick(Sender: TObject);
    procedure RefreshDataClick(Sender: TObject);
    procedure UnsetDataBankClick(Sender: TObject);
    procedure SetDataBankClick(Sender: TObject);
    procedure GetDirectories(Tree: TTreeView; Directory: string; Item: TTreeNode; IncludeFiles: Boolean);
    procedure DatabankTreeClick(Sender: TObject);
    procedure CompileButtonClick(Sender: TObject);
  private
  public

  end;

var
  Form1: TForm1;
  Refreshed:Boolean;
  Databank,WorkFolderWay:string;
  DirsAround,FilesInWorkFolder,NoteText: TStrings;
  numrec,ImageCount,NoteCount,ContentCount:Byte;
  IsImage,IsNote:Array[0..255] of Integer;
  TargetTime,TargetU:Textfile;
implementation
{$R *.lfm}
function GetEventMousePos: TPoint;
var
  MousePos: DWORD;
begin
  MousePos := GetMessagePos;
  Result.X := TSmallPoint(MousePos).x;
  Result.Y := TSmallPoint(MousePos).y;
end;
procedure ChartSourceGetData(CS1:TListChartSource;UFile,WFF:String;Sender: TObject);
var
  I:Integer;
  Temp:String;
  XList,YList:Array [0..2499] of Double;
begin
  Try
   DefaultFormatSettings.DecimalSeparator:='.' ;
   CS1.Clear;
   CS1.BeginUpdate;
   I:=0;
   AssignFile(TargetTime,WFF+'\time.dat');
   Reset(TargetTime);
    while not EOF(TargetTime) do begin
     Readln(TargetTime,Temp);
     XList[I]:=StrToFloat(Temp);//Showmessage(FloatToStr(XList[I])+' is '+IntToStr(I));
     I:=I+1;
    end;
   Close(TargetTime);//Showmessage('XList set');
   Temp:='';I:=0; //Showmessage('zeroed Temp and I');
   AssignFile(TargetU,UFile);//Showmessage('Assigned File at:'+UFile);
   Reset(TargetU); //Showmessage('Ready to read');
    while not EOF(TargetU) do begin
     Readln(TargetU,Temp);
     YList[I]:=StrToFloat(Temp);
     I:=I+1;
    end;
   Close(TargetU);//Showmessage('YList set');
   Temp:='';I:=0;
    Repeat
     CS1.Add(XList[I],YList[I]);
     I:=I+1;
    Until I=2499;
   I:=0;
   CS1.EndUpdate;
   DefaultFormatSettings.DecimalSeparator:=',';
   except
    Showmessage('EmptyField or wrong *.dat File. Try Again');
     if DefaultFormatSettings.DecimalSeparator='.'  then DefaultFormatSettings.DecimalSeparator:=',';
     CS1.Clear;
     CS1.EndUpdate;
  end;
end;

function DirectoryIsEmpty(Directory: string): Boolean;
var
  SR: TSearchRec;
  i: Integer;
begin
  Result := False;
  FindFirst(IncludeTrailingPathDelimiter(Directory) + '*', faAnyFile, SR);
  for i := 1 to 2 do
    if (SR.Name = '.') or (SR.Name = '..') then
      Result := FindNext(SR) <> 0;
  FindClose(SR);
end;
function GetTreePath(Item:TTreeNode): string;
var
  Node: TTreeNode;
begin
  Result := '';
  Node := Item;
  while Assigned(Node) do
  begin
    if Result <> '' then
      Result := '\' + Result;
    Result := Node.Text + Result;
    Node := Node.Parent;
  end;
end;
function GrabFilesFrom(Dir,Mask:String):TStrings;
begin
  Result:=nil;
 Result:=FindAllFiles(Dir,Mask,False,71);
end;
procedure TForm1.GetDirectories(Tree: TTreeView; Directory: string; Item: TTreeNode; IncludeFiles: Boolean);
var
  SearchRec: TSearchRec;
  ItemTemp: TTreeNode;
begin
  Tree.Items.BeginUpdate;
  Try
  if Directory[Length(Directory)] <> '\' then Directory := Directory + '\';
  if FindFirst(Directory + '*.*', faDirectory, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Attr and faDirectory = faDirectory) and (SearchRec.Name[1] <> '.') and (DirectoryIsEmpty(Directory)=false) then
      begin
        if (SearchRec.Attr and faDirectory > 0) then begin
          Item := Tree.Items.AddChild(Item, SearchRec.Name);
        end;
        ItemTemp := Item.Parent;
        GetDirectories(Tree, Directory + SearchRec.Name, Item, IncludeFiles);
        Item := ItemTemp;
      end
      else if IncludeFiles then
        if SearchRec.Name[1] <> '.' then
          Tree.Items.AddChild(Item, SearchRec.Name);
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
   except
  Showmessage('Wrong dataBank path. Try again with correct one.');
  Tree.Items.EndUpdate;
 end;
 Tree.Items.EndUpdate;
end;

procedure TForm1.RefreshDataClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := Databank;
  Screen.Cursor := crHourGlass;
  DatabankTree.Items.BeginUpdate;
  try
    DatabankTree.Items.Clear;
    GetDirectories(DatabankTree, Dir, nil, False);
    Refreshed:=True;
  finally
    Screen.Cursor := crDefault;
    DatabankTree.Items.EndUpdate;
    Refreshed:=True;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
Counter:Integer;
begin
 Screen.Cursor := crHourGlass;
 DirsAround:=FindAllDirectories(ProgramDirectory,False);
 CreateDir('TempDataStorage');
 ImageCount:=0;
 NoteCount:=0;
 ContentCount:=0;
 FilesGrid.Cells[0,0]:='№';
 FilesGrid.Cells[2,0]:='Full Path';
 FilesGrid.Cells[1,0]:='File';
 for Counter:= 0 to 255 do begin
 IsImage[Counter]:=0;
 IsNote[Counter]:=0;
 end;
  if (DirsAround<>nil) and (DirsAround.IndexOf(ProgramDirectory+'dataBank')<>-1) then begin
   Showmessage('Found dataBank in Execution Directory');
   Databank:=DirsAround.Strings[DirsAround.IndexOf(ProgramDirectory+'dataBank')];
   DataBankPath.Text:=DirsAround.Strings[DirsAround.IndexOf(ProgramDirectory+'dataBank')];
   DataBankPath.ReadOnly:=True;
   DataBankPath.Font.Color:=clWindowFrame;
  end
  else
  Showmessage('Found no dataBank in directory:'+ProgramDirectory+' type the way in Databank Path Field');
  Screen.Cursor := crDefault;
end;
procedure TForm1.frUserDataset1CheckEOF(Sender: TObject; var Eof: Boolean);
begin
  if numrec =512 then
  EOF:=True
  else
    EOF:=False;
end;

procedure TForm1.frUserDataset1First(Sender: TObject);
begin
  numrec:=0;
end;

procedure TForm1.frUserDataset1Next(Sender: TObject);
begin
  numrec:=numrec+1;
end;

procedure TForm1.HTMLReportButtonClick(Sender: TObject);
var
 CD,CT,Way:String;
begin
    if frReport1.PrepareReport then begin
  DateTimeToString(CD,'dd-mm-yyyy',Date);
  LongTimeFormat := 'hh.mm.ss';
  DateTimeToString(CT,'tt',Time);
  Way:=ProgramDirectory+'HTML-Report from '+CD+'--'+CT+'.html';
  Try
  frReport1.ExportTo(TfrHtmlDivExportFilter,Way);
  Showmessage('HTML-Report saved: '+Way);
  except
    Showmessage('Unable to create file. Unknown Error');
    LongTimeFormat:=DefaultFormatSettings.LongTimeFormat;
  end;
  LongTimeFormat:=DefaultFormatSettings.LongTimeFormat;
  end;
end;

procedure TForm1.PDFReportButtonClick(Sender: TObject);
var
CD,CT,Way:String;
begin
 Screen.Cursor := crHourGlass;
    if frReport1.PrepareReport then begin
  DateTimeToString(CD,'dd-mm-yyyy',Date);
  LongTimeFormat := 'hh.mm.ss';
  DateTimeToString(CT,'tt',Time);
  Way:=ProgramDirectory+'PDF-Report from '+CD+'--'+CT+'.pdf';
  Try
  frReport1.ExportTo(TlrPdfExportFilter,Way);
  Showmessage('PDF-Report saved: '+Way);
  except
    Showmessage('Unable to create file. Unknown Error');
    LongTimeFormat:=DefaultFormatSettings.LongTimeFormat;
    Screen.Cursor:=crDefault;
  end;
  LongTimeFormat:=DefaultFormatSettings.LongTimeFormat;
  Screen.Cursor:=crDefault;
  end;
end;

procedure TForm1.ClrGridClick(Sender: TObject);
begin
 if FilesGrid<>nil then FilesGrid.Clean;
 if FilesInWorkFolder<>nil then FilesInWorkFolder.Clear;
 Workfolderway:='';
end;

procedure TForm1.DatabankTreeMouseLeave(Sender: TObject);
begin
  DatabankTree.ShowHint:=False;
end;

procedure TForm1.DatabankTreeMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  DatabankTree.ShowHint:=true;
end;

procedure TForm1.FilesGridClick(Sender: TObject);
begin
 Try
 If FilesGrid.Col=2 then
  AddGraph.Text:=FilesGrid.Cells[FilesGrid.Col,FilesGrid.Row]
  else If FilesGrid.Col=1 then
  AddGraph.Text:=FilesGrid.Cells[FilesGrid.Col+1,FilesGrid.Row];
 except
   ShowMessage('Nothing to Plot');
 end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
Check:Boolean;
begin
 Check:=DeleteDirectory(ProgramDirectory+'TempDataStorage',True);
 If Check then
  RemoveDir(ProgramDirectory+'TempDataStorage');
  frReport1.Preview.Hide;
  frReport1.CleanupInstance;
  frReport1.Pages.CleanupInstance;
  CloseAction:=caFree;
end;

procedure TForm1.AddGraphButtonClick(Sender: TObject);
begin
 Inc(ImageCount);Inc(ContentCount);
 IsImage[ContentCount]:=2;
 Chart1.SaveToBitmapFile(ProgramDirectory+'TempDataStorage\Image'+IntToStr(ImageCount)+'.bmp');
 //IView.Assign(ProgramDirectory+'TempDataStorage\Image'+IntToStr(ImageCount)+'.bmp');
 //IView.Tag:='PICTURE';
end;

procedure TForm1.AddGraphChange(Sender: TObject);
begin
 Screen.Cursor := crHourGlass;
 ChartSourceGetData(ListChartSource1,AddGraph.Text,WorkFolderWay,Sender);
 Chart1.Update;
 Screen.Cursor := crDefault;
end;

procedure TForm1.AddNoteButtonClick(Sender: TObject);
begin
 IsNote[ContentCount]:=1;
 Inc(NoteCount);Inc(ContentCount);
 Note.Lines.SaveToFile('TempDataStorage\Note'+IntToStr(NoteCount)+'.txt',TEncoding.GetEncoding(CP_UTF8));
 Note.Text:='';
end;

procedure TForm1.ClearReportClick(Sender: TObject);
var
pnt:integer;
begin
 Try
 frReport1.Preview.Hide;
 frReport1.Preview.FreeInstance;
 frReport1.CleanupInstance;
 //frReport1.Pages.CleanupInstance;
 Showmessage(IntToStr(frReport1.Pages.Count)+' pages left');
 //for pnt:=0 to 255 do begin
 DeleteDirectory(ProgramDirectory+'TempDataStorage',True);
 if directoryexists(ProgramDirectory+'TempDataStorage')=False then
 CreateDir('TempDataStorage');
 finally
 frReport1.Preview.Assign(frReport1);
 frReport1.Preview.Show;
 end;
end;

procedure GetFolderFromTree(Tree: TTreeView);
var
  TempItem: TTreeNode;
  Str:string;
begin
 Workfolderway:='';
 TempItem:=Tree.Selected;
 if TempItem<>nil then Str:=Databank+'\'+GetTreePath(TempItem)
 else Str:='???';
  if Str.IsEmpty=False then begin
   Workfolderway:=Str;
   FilesInWorkFolder:=GrabFilesFrom(Workfolderway,'CH?_U?.dat;CH?_U??.dat;U??.dat;U???.dat;U????.dat');
  end;
end;

procedure TForm1.DatabankTreeClick(Sender: TObject);
var
  I:integer;
begin
 GetFolderFromTree(DatabankTree{,Dir,Eventhappened});
 //Showmessage('Workfolder is:'+Workfolderway);
 Workfolder.Text:=Workfolderway;
 FilesGrid.RowCount := FilesInWorkFolder.Count + 1;
 for I := 0 to FilesInWorkFolder.Count - 1 do begin
  FilesGrid.Cells[1,I+1]:= StringReplace(FilesInWorkFolder.Strings[I], WorkFolderway+'\','',[rfReplaceAll, rfIgnoreCase]);
  FilesGrid.Cells[2,I+1] := FilesInWorkFolder.Strings[I];
  FilesGrid.Cells[0,I+1]:=IntToStr(I+1);

 end;
end;

procedure TForm1.UnsetDataBankClick(Sender: TObject);
begin
   DataBankPath.ReadOnly:=False;
   DataBankPath.Font.Color:=clDefault;
end;

procedure TForm1.SetDataBankClick(Sender: TObject);
begin
  Databank:=DataBankPath.Text;
  DataBankPath.ReadOnly:=True;
  DataBankPath.Font.Color:=clWindowFrame;
end;
procedure ReportCompilePage(Im1,Im2:TfrPictureView;Nt1,Nt2:TfrView;PageNumber:Integer;Report:TfrReport);
begin
  {Image1 SetOn Page}
  Im1 := TfrPictureView.Create(Report.Pages[PageNumber]);
  Im1.width  := 760; Im1.Height := 400;
  Im1.Left   := 0;   Im1.Top    := 40;
  Im1.Stretched:=true;
  Im1.Picture.LoadFromFile(ProgramDirectory+'TempDataStorage\Image'+IntToStr(2*Pagenumber+1)+'.bmp');
  Report.Pages[PageNumber].Objects.Add(Im1);
  try
  Nt1:= frCreateObject(gtMemo,'Memo', Report.Pages[PageNumber]);
    Nt1.SetBounds(10,440,760,100);
    Nt1.Memo.LoadFromFile(ProgramDirectory+'TempDataStorage\Note'+IntToStr(2*Pagenumber+1)+'.txt',TEncoding.GetEncoding(CP_UTF8));
  //Nt1.LoadFromFile(ProgramDirectory+'TempDataStorage\Note'+IntToStr(2*Pagenumber+1)+'.txt');
  if Nt1 <> nil then
  Report.Pages[PageNumber].Objects.Add(Nt1);
  //Report.Pages[PageNumber].FindObject(Nt1).Width:= 760;
  //Report.Pages[PageNumber].FindObject(Nt1).Height:= 100;
  //Report.Pages[PageNumber].FindObject(Nt1).Left:= 0;
  //Report.Pages[PageNumber].FindObject(Nt1).Top:= 440;
  except
  ShowMessage('No Note for 1st on page Graph '+IntToStr(2*Pagenumber+1));
  end;
  {Image2 SetOn Page}
  Try
  Im2 := TfrPictureView.Create(Report.Pages[PageNumber]);
  Im2.width  := 760; Im2.Height := 400;
  Im2.Left   := 0;   Im2.Top    := 540;
  Im2.Stretched:=true;
  Im2.Picture.LoadFromFile(ProgramDirectory+'TempDataStorage\Image'+IntToStr(2*Pagenumber+2)+'.bmp');
  Report.Pages[PageNumber].Objects.Add(Im2);
  try
    Nt2:= frCreateObject(gtMemo,'Memo', Report.Pages[PageNumber]);
      Nt2.SetBounds(10,940,760,100);
      Nt2.Memo.LoadFromFile(ProgramDirectory+'TempDataStorage\Note'+IntToStr(2*Pagenumber+2)+'.txt',TEncoding.GetEncoding(CP_UTF8));
    //Nt1.LoadFromFile(ProgramDirectory+'TempDataStorage\Note'+IntToStr(2*Pagenumber+1)+'.txt');
    if Nt2 <> nil then
    Report.Pages[PageNumber].Objects.Add(Nt1);
    //Report.Pages[PageNumber].FindObject(Nt1).Width:= 760;
    //Report.Pages[PageNumber].FindObject(Nt1).Height:= 100;
    //Report.Pages[PageNumber].FindObject(Nt1).Left:= 0;
    //Report.Pages[PageNumber].FindObject(Nt1).Top:= 440;
    except
    ShowMessage('No Note for 2nd on page Graph'+IntToStr(2*Pagenumber+2));
    end;
  except
    Showmessage('there is only one image on the last Report-page');
  end;
end;
procedure TForm1.CompileButtonClick(Sender: TObject);
  var
    i,Clrptr:Integer;
  Images : array [0..255] of TfrPictureView;
  Notes: array [0..255] of TfrView;
begin
  frReport1.Preview.Hide;
  frReport1.CleanupInstance;
 frReport1.Pages.CleanupInstance;
  i:=0;
  for ClrPtr:= 0 to 255 do begin
   Images[ClrPtr]:=nil;
   Notes[ClrPtr]:=nil;
  end;
  while FileExists('TempDataStorage\Image'+IntToStr(2*i+1)+'.bmp') do begin
  frReport1.Pages.Add();
  ReportCompilePage(Images[0+2*i],Images[1+2*i],Notes[0+2*i],Notes[1+2*i],i,frReport1);
  Inc(i);
  end;
  frReport1.Preview.Show;
  frReport1.ShowReport;
  Label1.Caption:=('Report Preview');
end;
end.

