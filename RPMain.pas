unit RPMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ActnCtrls, ToolWin, ActnMan, ActnMenus,
  ImgList, ActnList, StdActns, StdCtrls, ExtCtrls, RPLib, Types,
  ComCtrls, Menus, XPStyleActnCtrls;

type
  TfrmRPMain = class(TForm)
    acmMain: TActionManager;
    imlMain: TImageList;
    EditCut1: TEditCut;
    EditCopy1: TEditCopy;
    EditPaste1: TEditPaste;
    EditSelectAll1: TEditSelectAll;
    EditDelete1: TEditDelete;
    Action1: TAction;
    Action2: TAction;
    actAddPosicao: TAction;
    actAddTransicao: TAction;
    actSelect: TAction;
    actAddConexao: TAction;
    sbrMain: TStatusBar;
    tmrMain: TTimer;
    scbMain: TScrollBox;
    pnlPage: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    MainMenu1: TMainMenu;
    Rede1: TMenuItem;
    Lugar1: TMenuItem;
    ransicao1: TMenuItem;
    Arco1: TMenuItem;
    Selecionar1: TMenuItem;
    Editar1: TMenuItem;
    Ajuda1: TMenuItem;
    Arquivi1: TMenuItem;
    ActionToolBar1: TActionToolBar;
    N1: TMenuItem;
    procedure EditCut1Execute(Sender: TObject);
    procedure scbMainMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure actSelectExecute(Sender: TObject);
    procedure tmrMainTimer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    procedure UpdateActiveAction;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmRPMain: TfrmRPMain;
  Rede: TRPRede;

implementation

{$R *.dfm}

procedure TfrmRPMain.UpdateActiveAction;
begin
  if actSelect.Checked then
  begin
    Rede.ActiveAction := raSelect;
  end
  else
  if actAddPosicao.Checked then
  begin
    Rede.ActiveAction := raPosicao;
  end
  else
  if actAddTransicao.Checked then
  begin
    Rede.ActiveAction := raTransicao;
  end
  else
  if actAddConexao.Checked then
  begin
    Rede.ActiveAction := raConexaoStart;
  end;
end;

procedure TfrmRPMain.actSelectExecute(Sender: TObject);
var i: Integer;
begin
  for i := 0 to acmMain.ActionCount-1 do
    if (acmMain.Actions[i].Category = 'Rede') and (acmMain.Actions[i] <> TAction(Sender)) then
      TAction(acmMain.Actions[i]).Checked := False;
  UpdateActiveAction;
end;

procedure TfrmRPMain.Button1Click(Sender: TObject);
begin
  Rede.HideElements;
end;

procedure TfrmRPMain.Button2Click(Sender: TObject);
begin
  Rede.ShowElements;
end;

procedure TfrmRPMain.EditCut1Execute(Sender: TObject);
begin
  ShowMessage('teste');
end;

procedure TfrmRPMain.FormDestroy(Sender: TObject);
begin
  Rede.Free;
end;

procedure TfrmRPMain.FormResize(Sender: TObject);
begin
  if Assigned(Rede) then
    Rede.Refresh;
end;

procedure TfrmRPMain.FormShow(Sender: TObject);
begin
  pnlPage.Top := 0;
  pnlPage.Left := 0;
  pnlPage.Width  := 2000;
  pnlPage.Height := 1500;

  Rede := TRPRede.Create(nil);
  Rede.Parent := pnlPage;
end;

procedure TfrmRPMain.scbMainMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Rede.ActiveAction = raPosicao then
  begin
    Rede.Posicoes.Add('p1', Point(X,Y));
  end
  else
  if Rede.ActiveAction = raTransicao then
  begin
    Rede.Transicoes.Add('t1', Point(X,Y));
  end
  else
  if Rede.ActiveAction = raConexaoStart then
  begin

  end;
  {
  actSelect.Checked := True;
  actSelectExecute(actSelect);
  }
end;

procedure TfrmRPMain.tmrMainTimer(Sender: TObject);
begin
  sbrMain.SimpleText := Rede.StatusText;
end;

end.
