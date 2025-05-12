unit uFileSortMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons, Vcl.ExtDlgs, System.ImageList, Vcl.ImgList,
  System.Actions, Vcl.ActnList, Math;

type

  TfmFileSortMain = class(TForm)
    edtFileNameIn: TEdit;
    SpeedButton1: TSpeedButton;
    Panel1: TPanel;
    btnCancel: TButton;
    StatusBar: TStatusBar;
    ActionList1: TActionList;
    actSort: TAction;
    ActCancel: TAction;
    ActSetFilePathIn: TAction;
    ImageList: TImageList;
    stfDialog: TSaveTextFileDialog;
    SpeedButton2: TSpeedButton;
    edtFileNameOut: TEdit;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    ActSetFilePathOut: TAction;
    Button2: TButton;
    pnlSort: TPanel;
    lbGen: TLinkLabel;
    ProgressBar: TProgressBar;
    procedure ActSetFilePathInExecute(Sender: TObject);
    procedure ActSetFilePathOutExecute(Sender: TObject);
    procedure actSortExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ActCancelExecute(Sender: TObject);
    function makeChunk:boolean;
    function mergeChunks(c1,c2:String):boolean;
    function getChunkName:String;
  private
    { Private declarations }
    bstop:boolean;
    minStr:String;
    fIn:TextFile;
    fOut:TextFile;
    chunksList:TStringList;
    inProgress:boolean;
    chunkTotalSize:Int64;
  public
    { Public declarations }
  end;

var
  chunkCount:integer;
  fmFileSortMain: TfmFileSortMain;
  function GetFileSize(FileName: string): Int64;
  function minString(s1,s2:String):String;
  function maxString(s1,s2:String):String;

implementation

{$R *.dfm}

procedure TfmFileSortMain.ActCancelExecute(Sender: TObject);
begin
  if bstop then exit;
  bstop := true;
  pnlSort.Visible := false;
  actSort.Enabled := true;
  ActCancel.Enabled := false;

end;


procedure TfmFileSortMain.actSortExecute(Sender: TObject);
var
  i:integer;
  errMessages:String;
  fSize:Int64;
begin
    //Проверка ввода
   errMessages:= '';
   if trim(edtFileNameIn.Text)='' then errMessages := 'Не введено имя исходного файла'+#13 else
     if not(fileExists(edtFileNameIn.Text)) then errMessages := errMessages + ' '+edtFileNameIn.Text+' - файл не найден'+#13 ;
   if trim(edtFileNameOut.Text)='' then errMessages := errMessages + 'Не введено имя выходного файла'+#13 ;


  if not(errMessages='') then
    Application.MessageBox(PChar(errMessages),'Сообщение', mb_IconError)
  else
  begin
    bstop := false;
    fSize := GetFileSize(edtFileNameIn.Text);
    chunkTotalSize :=0;
    actCancel.Enabled := true;
    actSort.Enabled := false;
    pnlSort.Visible := true;
    ProgressBar.Max := fSize;
    chunkCount := 0;
    AssignFile(fIn, edtFileNameIn.Text);
    try
    Reset(fIn);
    while makeChunk and not bstop do
    begin
      ProgressBar.Position := trunc(chunkTotalSize/2);
    end;
    finally
      closeFile(fIn);
    end;
    ProgressBar.Max := chunksList.Count*2;
    while (chunksList.Count > 1) and not bstop do
    begin
      mergeChunks(chunksList[0],chunksList[1]);
      for I := 0 to 1 do chunksList.Delete(0);
      ProgressBar.Position := ProgressBar.Max - chunksList.Count;
    end;
    if not(bstop) then
      showmessage('Готово');
    bstop := true;
    pnlSort.Visible := false;
    actSort.Enabled := true;
    ActCancel.Enabled := false;
  end;
end;

procedure TfmFileSortMain.ActSetFilePathInExecute(Sender: TObject);
begin
  if stfDialog.Execute then
    edtFileNameIn.Text := stfDialog.Files[0];
end;

procedure TfmFileSortMain.ActSetFilePathOutExecute(Sender: TObject);
begin
  if stfDialog.Execute then
    edtFileNameOut.Text := stfDialog.Files[0];
end;

function smReadln(sm:TStringStream; var starts:Int64):String;
var
  simb:String;
  eof:boolean;
begin
  eof := false;
  result := '';
  while((simb<>#13) and not eof) do begin
    sm.Position := starts;
    simb := '';
    try
      simb := sm.ReadString(1);
    except
      eof := true;
    end;
    if (simb<>#13) then
      result := result + simb;
    inc(starts);
  end;
  inc(starts);
end;

function SortCompare(AList: TStringList; Index1, Index2: integer): integer;
begin
  if AList[Index1] = AList[Index2] then
  begin
    result := 0;
  end
  else
  begin
    if minString(AList[Index1],AList[Index2]) = AList[Index1] then
      result := -1
    else
      result := 1;
  end;
end;

function TfmFileSortMain.mergeChunks(c1,c2:String):boolean;
var
  ch1,ch2:TextFile;
  resfileName:String;
  resfile:TextFile;
  str1,str2:String;
  i:integer;

  str1writed,str2writed:boolean;
begin
  if chunksList.Count>2 then
    resfileName := GetChunkName
  else
    resfileName := edtFileNameOut.Text;

  AssIgnFile(resfile,resfileName);
  chunksList.Add(resfileName);
  AssignFile(ch1, c1);
  AssignFile(ch2, c2);
  rewrite(resfile);
  reset(ch1);
  reset(ch2);

  str1writed := true;
  str2writed := true;
  while not(EOF(ch1) and EOF(ch2)) do
  begin
    if str1writed and not EOF(ch1) then
    begin
      ReadLn(ch1,str1);
      str1writed := false;
    end;
    if str2writed and not EOF(ch2) then
    begin
      ReadLn(ch2,str2);
      str2writed := false;
    end;
    if (str1=str2) then
    begin
      for i:=0 to 1 do WriteLN(resFile,str1);
      str1writed := true;
      str2writed := true;
    end
    else if (MinString(str1,str2) = str1) then
    begin
      WriteLN(resFile,str1);
      str1 := '';
      str1writed := true;
    end
    else if (MinString(str1,str2) = str2) then
    begin
      WriteLN(resFile,str2);
      str2 := '';
      str2writed := true;
    end;
  end;
  if not(str1writed) then
    WriteLN(resFile,str1);
  if not(str2writed) then
    WriteLN(resFile,str2);

  inc(chunkCount);
  closeFile(ch1);
  closeFile(ch2);
  closeFile(resFile);
  deleteFile(c1);
  deleteFile(c2);
  result := true;
end;

function TfmFileSortMain.GetChunkName:String;
var
  s:string;
begin
  s := GetEnvironmentVariable('temp');
  result := s + extractFileName(edtFileNameIn.Text)+IntToStr(chunkCount)+'.txt';
  //result := 'D:\chunks\'+extractFileName(edtFileNameIn.Text)+IntToStr(chunkCount)+'.txt';
  inc(chunkCount);
end;

function TfmFileSortMain.makeChunk:boolean;
var
  sl:TStringList;
  i:Integer;
  curStr:String;
  chunkName:String;
begin
  result := true;
  sl := TSTringList.Create;
  try
  for i := 0 to 200000 do
  begin
    ReadLn(fIn,curStr);
    sl.Add(curStr);
    if EOF(fIn) or bstop then
    begin
      result := false;
      break;
    end;
    Application.ProcessMessages;
  end;
  sl.CustomSort(SortCompare);
  chunkName := getChunkName;
  sl.SaveToFile(chunkName);
  chunksList.Add(chunkName);

  chunkTotalSize := chunkTotalSize + GetFileSize(chunkName);

  application.ProcessMessages;
  finally
    sl.Free;
  end;
end;

function minString(s1,s2:String):String;
var
  list: TStringList; //Так как я не знаю способ сортировки строк, использую стандартный
  stS1,stS2:String; //Строчные части
  n1,n2:Int64;      //Номерные части
  sn1,sn2:String;
  dotpos1:integer;
  dotpos2:integer;
begin
    if s1='' then
    begin
      result := s2;
      exit;
    end;
    if s2='' then
    begin
      result := s1;
      exit;
    end;
    dotpos1 := pos('.', s1);
    stS1 := copy(s1, dotpos1+1);
    dotpos2 := pos('.', s2);
    stS2 := copy(s2, dotpos2+1);
    if (stS1 = stS2) then
    begin
      sn1 := copy(s1,1, dotpos1-1);
      sn2 := copy(s2,1, dotpos2-1);
      n1 := StrToInt(sn1);
      n2 := StrToInt(sn2);

      if n1<n2 then
        result := s1
      else
        result := s2;
    end
    else
    begin
      list :=TstringList.Create;
      list.Add(stS1);
      list.Add(stS2);
      list.Sort;
      if list[0]=stS1 then
        result := s1
      else
        result := s2;
      list.Free;
    end;
end;

function maxString(s1,s2:String):String;
var
  res:String;
begin
  res := minString(s1,s2);
  if res=s1 then
    result := s2;
end;

function GetFileSize(FileName: string): Int64;
var
  info: TWin32FileAttributeData;
begin
try
  if not getFileAttributesEX(Pchar(FileName),GetFileExInfoStandard, @info)  then
    EXIT;
  result := Int64(info.nFileSizeLow);
except
  Result := -1;
end;
end;

procedure TfmFileSortMain.FormCreate(Sender: TObject);
begin
  bstop:=true;
  chunksList := TSTringList.Create;
end;

end.
