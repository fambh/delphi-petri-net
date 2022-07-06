unit RPLib;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Math;

type
  TRPAction = (raNone, raSelect, raPosicao, raTransicao, raConexaoStart, raConexaoEnd);

  TRPCurvePoints = array[1..4] of TPoint;

  TRPRede = class;
  TRPPosicoes = class;
  TRPPosicao = class;
  TRPTransicoes = class;
  TRPTransicao = class;
  TRPElemento = class;
  TRPConexao = class;
  TRPConexoes = class;

  TRPRede = class(TComponent)
    procedure ShapeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ShapeMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ShapeMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    FActiveAction: TRPAction;
    FParent: TPanel;
    FPosicoes: TRPPosicoes;
    FTransicoes: TRPTransicoes;
    FConexoes: TRPConexoes;
    FSelectedElemento: TRPElemento;
    FSelectedConexao: TRPConexao;
    FCreatingConexao: TRPConexao;
    FMouseDown: Boolean;
    FStatusText: String;
    procedure SetActiveAction(const Value: TRPAction);
  public
    property Parent: TPanel read FParent write FParent;
    property Posicoes: TRPPosicoes read FPosicoes write FPosicoes;
    property Transicoes: TRPTransicoes read FTransicoes write FTransicoes;
    property Conexoes: TRPConexoes read FConexoes write FConexoes;
    property ActiveAction: TRPAction read FActiveAction write SetActiveAction;
    property StatusText: String read FStatusText;
    procedure UnSelectAll;
    procedure Ready;
    procedure HideElements;
    procedure ShowElements;
    procedure Refresh;
    function GetElementoByShape(AShape: TShape): TRPElemento;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TRPElemento = class (TCollectionItem)
  private
    FRede: TRPRede;
    FCaption: String;
    FShape: TShape;
    FSelected: Boolean;
    FIsMoving: Boolean;
    procedure SetSelected(const Value: Boolean);
    procedure RedrawArrows;
  public
    property Caption: String read FCaption write FCaption;
    property Selected: Boolean read FSelected write SetSelected;
    destructor Destroy; override;
  end;

  TRPPosicoes = class (TCollection)
  private
    FRede: TRPRede;
    function GetItem(Index: Integer): TRPPosicao;
    procedure SetItem(Index: Integer; const Value: TRPPosicao);
  public
    property Rede: TRPRede read FRede write FRede;
    property Items[Index: Integer]: TRPPosicao read GetItem write SetItem; default;
    function Add(Caption: String; APoint: TPoint): TRPPosicao;
    function GetPosicaoByShape(AShape: TShape): TRPPosicao;
    procedure Delete(Index: Integer);
    constructor Create(Owner: TRPRede);
  end;

  TRPPosicao = class (TRPElemento)
  private

  public

  end;

  TRPTransicoes = class (TCollection)
  private
    FRede: TRPRede;
    function GetItem(Index: Integer): TRPTransicao;
    procedure SetItem(Index: Integer; const Value: TRPTransicao);
  public
    property Rede: TRPRede read FRede write FRede;
    property Items[Index: Integer]: TRPTransicao read GetItem write SetItem; default;
    function Add(Caption: String; APoint: TPoint): TRPTransicao;
    function GetTransicaoByShape(AShape: TShape): TRPTransicao;
    procedure Delete(Index: Integer);
    constructor Create(Owner: TRPRede);
  end;

  TRPTransicao = class (TRPElemento)
  private

  public

  end;

  TRPConexoes = class (TCollection)
  private
    FRede: TRPRede;
    function GetItem(Index: Integer): TRPConexao;
    procedure SetItem(Index: Integer; const Value: TRPConexao);
  public
    property Rede: TRPRede read FRede write FRede;
    property Items[Index: Integer]: TRPConexao read GetItem write SetItem; default;
    function Add: TRPConexao;
    procedure Delete(Index: Integer);
    constructor Create(Owner: TRPRede);
  end;

  TRPConexao = class (TCollectionItem)
  private
    FRede: TRPRede;

    FSelected: Boolean;
    FElementoOrigem: TRPElemento;
    FElementoDestino: TRPElemento;
    FPosicaoHorariaAncoraOrigem: Integer;
    FPosicaoHorariaAncoraDestino: Integer;
    FCurvePoint: TRPCurvePoints;
    procedure SetSelected(const Value: Boolean);
    procedure Realiza;
    procedure DesenhaFlecha;
  public
    FImage: TImage;
    procedure Refresh;
    property Selected: Boolean read FSelected write SetSelected;
    property ElementoOrigem: TRPElemento read FElementoOrigem write FElementoOrigem;
    property ElementoDestino: TRPElemento read FElementoDestino write FElementoDestino;
    destructor Destroy; override;
  end;

implementation

const
  _ShapePosicaoSize = 50;
  _ShapeTransicaoSize = 30;
  _IndicePosAncoragem = 0.8;
  _SetaSize = 12;

{ TRPPosicoes }

function iif(Condition: Boolean; ThenValue, ElseValue: Variant): Variant;
begin
  Result := IfThen(Condition, ThenValue, ElseValue);
end;

function TRPPosicoes.Add(Caption: String; APoint: TPoint): TRPPosicao;
var
  shp: TShape;
begin
  Result := inherited Add as TRPPosicao;
  Result.FCaption   := Caption;
  Result.FRede      := FRede;

  shp := TShape.Create(FRede.FParent);
  shp.Parent := FRede.FParent;
  shp.Shape  := stCircle;
  shp.Top    := APoint.Y - (_ShapePosicaoSize div 2);
  shp.Left   := APoint.X - (_ShapePosicaoSize div 2);
  shp.Width  := _ShapePosicaoSize;
  shp.Height := _ShapePosicaoSize;
  shp.OnMouseDown := FRede.ShapeMouseDown;
  shp.OnMouseUp   := FRede.ShapeMouseUp;
  shp.OnMouseMove := FRede.ShapeMouseMove;

  Result.FShape := shp;
//  Result.Selected := True;
end;

constructor TRPPosicoes.Create(Owner: TRPRede);
begin
  inherited Create(TRPPosicao);
  FRede := Owner;
end;

procedure TRPPosicoes.Delete(Index: Integer);
begin
  if Assigned(Items[Index].FShape) then
  begin
    Items[Index].FShape.Free;
    Items[Index].FShape := nil;
  end;
  inherited Delete(Index);
end;

function TRPPosicoes.GetItem(Index: Integer): TRPPosicao;
begin
  Result := inherited Items[Index] as TRPPosicao;
end;

function TRPPosicoes.GetPosicaoByShape(AShape: TShape): TRPPosicao;
var i: Integer;
begin
  Result := nil;
  for i := 0 to Self.Count - 1 do
    if Items[i].FShape = AShape then
    begin
      Result := Items[i];
      Exit;
    end;
end;

procedure TRPPosicoes.SetItem(Index: Integer; const Value: TRPPosicao);
begin
  inherited Items[Index] := Value;
end;

{ TRPRede }


{ TRPRede }

constructor TRPRede.Create(AOwner: TComponent);
begin
  inherited;
  FPosicoes     := TRPPosicoes.Create(Self);
  FTransicoes   := TRPTransicoes.Create(Self);
  FConexoes     := TRPConexoes.Create(Self);
  FActiveAction := raNone;
  FMouseDown    := False;
  Ready;
end;

destructor TRPRede.Destroy;
begin
  FPosicoes.Destroy;
  FTransicoes.Destroy;
  FConexoes.Destroy;
  inherited;
end;

function TRPRede.GetElementoByShape(AShape: TShape): TRPElemento;
begin
  Result := FPosicoes.GetPosicaoByShape(AShape);
  if not Assigned(Result) then
    Result := FTransicoes.GetTransicaoByShape(AShape);
end;

procedure TRPRede.HideElements;
var i: Integer;
begin
  for i := 0 to FPosicoes.Count-1 do
    FPosicoes.Items[i].FShape.Visible := False;

  for i := 0 to FTransicoes.Count-1 do
    FTransicoes.Items[i].FShape.Visible := False;
end;

procedure TRPRede.Ready;
begin
  FStatusText := 'Pronto';
end;

procedure TRPRede.Refresh;
begin
  Exit;
  if FConexoes.Count > 0 then  // Resolve BUG em que a tela fica preta depois de redimensionar
    FConexoes[0].Refresh;
end;

procedure TRPRede.SetActiveAction(const Value: TRPAction);
begin
  FActiveAction := Value;
  if FActiveAction <> raSelect then
    UnSelectAll;
end;

procedure TRPRede.ShapeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  elem: TRPElemento;
  con: TRPConexao;
begin
  FMouseDown := True;

  if FActiveAction = raSelect then
  begin
    elem := GetElementoByShape(TShape(Sender));
    if Assigned(elem) then
    begin
      elem.Selected := True;
      elem.FIsMoving := True;
    end;
  end
  else
  if FActiveAction = raConexaoStart then
  begin
    elem := GetElementoByShape(TShape(Sender));
    if Assigned(elem) then
    begin
      elem.Selected := True;
      FStatusText := 'Selecione o elemento de destino';

      con := FConexoes.Add;
      con.FElementoOrigem := elem;

      FCreatingConexao := con;
    end;
  end
  else
  if FActiveAction = raConexaoEnd then
  begin
    elem := GetElementoByShape(TShape(Sender));
    if Assigned(elem) then
      elem.Selected := True;
    Ready;
  end;
end;

procedure TRPRede.ShapeMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FSelectedElemento) and FSelectedElemento.FIsMoving then
  begin
    FSelectedElemento.FShape.Top  := FSelectedElemento.FShape.Top + Y - (FSelectedElemento.FShape.Height div 2);
    FSelectedElemento.FShape.Left := FSelectedElemento.FShape.Left + X - (FSelectedElemento.FShape.Width div 2);

    FSelectedElemento.RedrawArrows;

    Self.Refresh;

    FStatusText := Format('(%d, %d)', [FSelectedElemento.FShape.Left + FSelectedElemento.FShape.Width div 2, FSelectedElemento.FShape.Top + FSelectedElemento.FShape.Height div 2]);
  end;
end;

procedure TRPRede.ShapeMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var elem: TRPElemento;
begin
  FMouseDown := False;

  if FActiveAction = raSelect then
  begin
    elem := GetElementoByShape(TShape(Sender));
    if Assigned(elem) then
    begin
      elem.FIsMoving := False;
      Ready;
    end;
  end
  else
  if FActiveAction = raConexaoStart then
  begin
    FActiveAction := raConexaoEnd;
  end
  else
  if FActiveAction = raConexaoEnd then
  begin
    elem := GetElementoByShape(TShape(Sender));
    if Assigned(elem) and Assigned(FCreatingConexao) then
    begin
      FCreatingConexao.FElementoDestino := elem;
      FCreatingConexao.Realiza;
      UnSelectAll;
      ActiveAction := raConexaoStart;
    end;
  end;
end;

procedure TRPRede.ShowElements;
var i: Integer;
begin
  for i := 0 to FPosicoes.Count-1 do
    FPosicoes.Items[i].FShape.Visible := True;

  for i := 0 to FTransicoes.Count-1 do
    FTransicoes.Items[i].FShape.Visible := True;
end;

procedure TRPRede.UnSelectAll;
var i: Integer;
begin
  FSelectedElemento := nil;
  FSelectedConexao  := nil;

  for i := 0 to FPosicoes.Count - 1 do
    FPosicoes.Items[i].Selected := False;
  for i := 0 to FTransicoes.Count - 1 do
    FTransicoes.Items[i].Selected := False;
end;

{ TRPTransicoes }

function TRPTransicoes.Add(Caption: String; APoint: TPoint): TRPTransicao;
var
  shp: TShape;
begin
  Result := inherited Add as TRPTransicao;
  Result.FCaption   := Caption;
  Result.FRede      := FRede;

  shp := TShape.Create(FRede.FParent);
  shp.Parent := FRede.FParent;
  shp.Shape  := stSquare;
  shp.Top    := APoint.Y - (_ShapeTransicaoSize div 2);
  shp.Left   := APoint.X - (_ShapeTransicaoSize div 2);
  shp.Width  := _ShapeTransicaoSize;
  shp.Height := _ShapeTransicaoSize;
  shp.OnMouseDown := FRede.ShapeMouseDown;
  shp.OnMouseUp   := FRede.ShapeMouseUp;
  shp.OnMouseMove := FRede.ShapeMouseMove;

  Result.FShape := shp;
//  Result.Selected := True;
end;

constructor TRPTransicoes.Create(Owner: TRPRede);
begin
  inherited Create(TRPTransicao);
  FRede := Owner;
end;

procedure TRPTransicoes.Delete(Index: Integer);
begin
  if Assigned(Items[Index].FShape) then
  begin
    Items[Index].FShape.Free;
    Items[Index].FShape := nil;
  end;
  inherited Delete(Index);
end;

function TRPTransicoes.GetItem(Index: Integer): TRPTransicao;
begin
  Result := inherited Items[Index] as TRPTransicao;
end;

function TRPTransicoes.GetTransicaoByShape(AShape: TShape): TRPTransicao;
var i: Integer;
begin
  Result := nil;
  for i := 0 to Self.Count - 1 do
    if Items[i].FShape = AShape then
    begin
      Result := Items[i];
      Exit;
    end;
end;

procedure TRPTransicoes.SetItem(Index: Integer; const Value: TRPTransicao);
begin
  inherited Items[Index] := Value;
end;

{ TRPElemento }

destructor TRPElemento.Destroy;
begin
  if Assigned(FShape) then
    FShape.Free;
  inherited;
end;

procedure TRPElemento.RedrawArrows;
var i: Integer;
begin
  for i := 0 to FRede.FConexoes.Count-1 do
  begin
    if (FRede.FConexoes[i].FElementoOrigem = Self) or (FRede.FConexoes[i].FElementoDestino = Self) then
      FRede.FConexoes[i].Realiza;
  end;
end;

procedure TRPElemento.SetSelected(const Value: Boolean);
begin
  FSelected := Value;
  if FSelected then
  begin
    FRede.UnSelectAll;
    FRede.FSelectedElemento := Self;
    Self.FShape.Pen.Width := 2;
    Self.FShape.Pen.Color := clBlue;
  end
  else
  begin
    Self.FShape.Pen.Width := 1;
    Self.FShape.Pen.Color := clBlack;
  end;
end;

{ TRPConexoes }

function TRPConexoes.Add: TRPConexao;
var
  img: TImage;
begin
  Result := inherited Add as TRPConexao;
  Result.FRede      := FRede;

  img := TImage.Create(FRede.FParent);
  img.Parent      := FRede.FParent;
  img.Align       := alClient;
  img.OnMouseDown := FRede.FParent.OnMouseDown;
  img.Transparent := True;
  img.SendToBack;

  Result.FImage := img;

  Result.FSelected := True;
end;

constructor TRPConexoes.Create(Owner: TRPRede);
begin
  inherited Create(TRPConexao);
  FRede := Owner;
end;

procedure TRPConexoes.Delete(Index: Integer);
begin
  if Assigned(Items[Index].FImage) then
  begin
    Items[Index].FImage.Free;
    Items[Index].FImage := nil;
  end;
  inherited Delete(Index);
end;

function TRPConexoes.GetItem(Index: Integer): TRPConexao;
begin
  Result := inherited Items[Index] as TRPConexao;
end;

procedure TRPConexoes.SetItem(Index: Integer; const Value: TRPConexao);
begin
  inherited Items[Index] := Value;
end;

{ TRPConexao }

function GetShapeMiddlePoint(AElemento: TRPElemento): TPoint;
begin
  if AElemento is TRPPosicao then
  begin
    Result.X := AElemento.FShape.Left + (_ShapePosicaoSize div 2);
    Result.Y := AElemento.FShape.Top  + (_ShapePosicaoSize div 2);
  end
  else if AElemento is TRPTransicao then
  begin
    Result.X := AElemento.FShape.Left + (_ShapeTransicaoSize div 2);
    Result.Y := AElemento.FShape.Top  + (_ShapeTransicaoSize div 2);
  end
end;

function GetPontoAncoragem(AElemento: TRPElemento; APosicaoAncora: Integer): TPoint;
begin
  if AElemento is TRPTransicao then
  begin
    case APosicaoAncora of
      1:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapeTransicaoSize * _IndicePosAncoragem);
        Result.Y := AElemento.FShape.Top - 1;
      end;
      2:
      begin
        Result.X := AElemento.FShape.Left + _ShapeTransicaoSize;
        Result.Y := AElemento.FShape.Top + Round(_ShapeTransicaoSize * (1-_IndicePosAncoragem));
      end;
      3:
      begin
        Result.X := AElemento.FShape.Left + _ShapeTransicaoSize;
        Result.Y := AElemento.FShape.Top + (_ShapeTransicaoSize div 2);
      end;
      4:
      begin
        Result.X := AElemento.FShape.Left + _ShapeTransicaoSize;
        Result.Y := AElemento.FShape.Top + Round(_ShapeTransicaoSize * _IndicePosAncoragem);
      end;
      5:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapeTransicaoSize * _IndicePosAncoragem);
        Result.Y := AElemento.FShape.Top + _ShapeTransicaoSize;
      end;
      6:
      begin
        Result.X := AElemento.FShape.Left + (_ShapeTransicaoSize div 2);
        Result.Y := AElemento.FShape.Top + _ShapeTransicaoSize;
      end;
      7:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapeTransicaoSize * (1-_IndicePosAncoragem));
        Result.Y := AElemento.FShape.Top + _ShapeTransicaoSize;
      end;
      8:
      begin
        Result.X := AElemento.FShape.Left - 1;
        Result.Y := AElemento.FShape.Top + Round(_ShapeTransicaoSize * _IndicePosAncoragem);
      end;
      9:
      begin
        Result.X := AElemento.FShape.Left - 1;
        Result.Y := AElemento.FShape.Top + (_ShapeTransicaoSize div 2);
      end;
      10:
      begin
        Result.X := AElemento.FShape.Left - 1;
        Result.Y := AElemento.FShape.Top + Round(_ShapeTransicaoSize * (1-_IndicePosAncoragem));
      end;
      11:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapeTransicaoSize * (1-_IndicePosAncoragem));
        Result.Y := AElemento.FShape.Top - 1;
      end;
      12:
      begin
        Result.X := AElemento.FShape.Left + (_ShapeTransicaoSize div 2);
        Result.Y := AElemento.FShape.Top - 1;
      end;
      else
        Result.X := 0;
        Result.Y := 0;
    end;
  end
  else
  if AElemento is TRPPosicao then
  begin
    case APosicaoAncora of
      1:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.8);
        Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.1);
        //Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.75);
        //Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.134);
      end;
      2:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.9);
        Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.2);
        //Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.866);
        //Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.25);
      end;
      3:
      begin
        Result.X := AElemento.FShape.Left + _ShapePosicaoSize;
        Result.Y := AElemento.FShape.Top + (_ShapePosicaoSize div 2);
      end;
      4:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.9);
        Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.8);
        //Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.866);
        //Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.75);
      end;
      5:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.8);
        Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.9);
        //Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.75);
        //Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.866);
      end;
      6:
      begin
        Result.X := AElemento.FShape.Left + (_ShapePosicaoSize div 2);
        Result.Y := AElemento.FShape.Top + _ShapePosicaoSize;
      end;
      7:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.2);
        Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.9);
        //Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.25);
        //Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.866);
      end;
      8:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.1);
        Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.8);
        //Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.134);
        //Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.75);
      end;
      9:
      begin
        Result.X := AElemento.FShape.Left-1;
        Result.Y := AElemento.FShape.Top + (_ShapePosicaoSize div 2);
      end;
      10:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.1);
        Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.2);
        //Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.134);
        //Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.25);
      end;
      11:
      begin
        Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.2);
        Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.1);
        //Result.X := AElemento.FShape.Left + Round(_ShapePosicaoSize * 0.25);
        //Result.Y := AElemento.FShape.Top + Round(_ShapePosicaoSize * 0.134);
      end;
      12:
      begin
        Result.X := AElemento.FShape.Left + (_ShapePosicaoSize div 2);
        Result.Y := AElemento.FShape.Top-1;
      end;
      else
        Result.X := 0;
        Result.Y := 0;
    end;
  end;
end;

function AjustaAncoragemTransicao(APosicao: Integer): Integer;
begin
  case APosicao of
    2, 3, 4:  Result := 3;
    5, 6, 7:  Result := 6;
    8, 9, 10: Result := 9;
    else      Result := 12;
  end;
end;

procedure TRPConexao.DesenhaFlecha;
var
  a0, a1, a2: Extended; // Ângulos para desenho das setas
  pArrow: array[1..3] of TPoint;
begin
  FImage.Canvas.Brush.Color := clWhite;
  FImage.Canvas.FillRect(Rect(0,0,Self.FImage.Width,Self.FImage.Height));

  //Self.FImage.Canvas.MoveTo(FCurvePoint[1].X, FCurvePoint[1].Y);
  //Self.FImage.Canvas.LineTo(FCurvePoint[4].X, FCurvePoint[4].Y);
  FImage.Canvas.PolyBezier(FCurvePoint);

  { Ponta da Seta }

  pArrow[1] := FCurvePoint[4];


  if FCurvePoint[4].X = FCurvePoint[1].X then
    a0 := pi/2
  else
    a0 := ArcTan( -1*(FCurvePoint[4].Y - FCurvePoint[1].Y) / (FCurvePoint[4].X - FCurvePoint[1].X) );

  a1 := DegToRad(30) - a0;
  a2 := DegToRad(60) - a0;

  if (FCurvePoint[4].X > FCurvePoint[1].X) or ((FCurvePoint[4].X = FCurvePoint[1].X) and (FCurvePoint[4].Y < FCurvePoint[1].Y)) then
  begin

    pArrow[2].X := FCurvePoint[4].X - Round(_SetaSize*cos(a1));
    pArrow[2].Y := FCurvePoint[4].Y - Round(_SetaSize*sin(a1));

    pArrow[3].X := FCurvePoint[4].X - Round(_SetaSize*sin(a2));
    pArrow[3].Y := FCurvePoint[4].Y + Round(_SetaSize*cos(a2));

  end
  else
  begin

    pArrow[2].X := FCurvePoint[4].X + Round(_SetaSize*cos(a1));
    pArrow[2].Y := FCurvePoint[4].Y + Round(_SetaSize*sin(a1));

    pArrow[3].X := FCurvePoint[4].X + Round(_SetaSize*sin(a2));
    pArrow[3].Y := FCurvePoint[4].Y - Round(_SetaSize*cos(a2));

  end;

  FImage.Canvas.Brush.Style := bsSolid;
  FImage.Canvas.Brush.Color := clBlack;
  FImage.Canvas.Polygon(pArrow);
  FImage.Canvas.Brush.Color := clWhite;
end;

destructor TRPConexao.Destroy;
begin
  if Assigned(FImage) then
    FImage.Free;
  inherited;
end;

procedure TRPConexao.Realiza;
var
  bValida: Boolean;
  pOrigem, pDestino: TPoint;
  pAncoraOrigem, pAncoraDestino: TPoint;
  angulo: Extended;

begin
  bValida := (FElementoOrigem is TRPTransicao) and (FElementoDestino is TRPPosicao);
  bValida := bValida or ((FElementoOrigem is TRPPosicao) and (FElementoDestino is TRPTransicao));
  if not bValida then
  begin
    FRede.FConexoes.Delete(Self.Index);
    FRede.FStatusText := 'Conexão inválida.';
    Exit;
  end;

  pOrigem  := GetShapeMiddlePoint(FElementoOrigem);
  pDestino := GetShapeMiddlePoint(FElementoDestino);

  if (pDestino.X >= pOrigem.X) and (pDestino.Y <= pOrigem.Y) then // Quadrante 1
    if pDestino.X = pOrigem.X then
      angulo := 90
    else
      angulo := ( ArcTan( -1*(pDestino.Y - pOrigem.Y) / (pDestino.X - pOrigem.X) ) ) * 180 / pi
  else if (pDestino.X < pOrigem.X) and (pDestino.Y <= pOrigem.Y) then // Quadrante 2
    angulo := 180 + ( ArcTan( -1*(pDestino.Y - pOrigem.Y) / (pDestino.X - pOrigem.X) ) ) * 180 / pi
  else if (pDestino.X < pOrigem.X) and (pDestino.Y > pOrigem.Y) then // Quadrante 3
    angulo := 180 + ( ArcTan( -1*(pDestino.Y - pOrigem.Y) / (pDestino.X - pOrigem.X) ) ) * 180 / pi
  else // Quadrante 4
    if pDestino.X = pOrigem.X then
      angulo := 270
    else
      angulo := 360 + ( ArcTan( -1*(pDestino.Y - pOrigem.Y) / (pDestino.X - pOrigem.X) ) ) * 180 / pi;


  if (angulo > 345) or (angulo <= 15) then
  begin
    FPosicaoHorariaAncoraOrigem  := 3;
    FPosicaoHorariaAncoraDestino := 9;
  end
  else if (angulo > 15) and (angulo <= 45) then
  begin
    FPosicaoHorariaAncoraOrigem  := 2;
    FPosicaoHorariaAncoraDestino := 8;
  end
  else if (angulo > 45) and (angulo <= 75) then
  begin
    FPosicaoHorariaAncoraOrigem  := 1;
    FPosicaoHorariaAncoraDestino := 7;
  end
  else if (angulo > 75) and (angulo <= 105) then
  begin
    FPosicaoHorariaAncoraOrigem  := 12;
    FPosicaoHorariaAncoraDestino := 6;
  end
  else if (angulo > 105) and (angulo <= 135) then
  begin
    FPosicaoHorariaAncoraOrigem  := 11;
    FPosicaoHorariaAncoraDestino := 5;
  end
  else if (angulo > 135) and (angulo <= 165) then
  begin
    FPosicaoHorariaAncoraOrigem  := 10;
    FPosicaoHorariaAncoraDestino := 4;
  end
  else if (angulo > 165) and (angulo <= 195) then
  begin
    FPosicaoHorariaAncoraOrigem  := 9;
    FPosicaoHorariaAncoraDestino := 3;
  end
  else if (angulo > 195) and (angulo <= 225) then
  begin
    FPosicaoHorariaAncoraOrigem  := 8;
    FPosicaoHorariaAncoraDestino := 2;
  end
  else if (angulo > 225) and (angulo <= 255) then
  begin
    FPosicaoHorariaAncoraOrigem  := 7;
    FPosicaoHorariaAncoraDestino := 1;
  end
  else if (angulo > 255) and (angulo <= 285) then
  begin
    FPosicaoHorariaAncoraOrigem  := 6;
    FPosicaoHorariaAncoraDestino := 12;
  end
  else if (angulo > 285) and (angulo <= 315) then
  begin
    FPosicaoHorariaAncoraOrigem  := 5;
    FPosicaoHorariaAncoraDestino := 11;
  end
  else
  begin
    FPosicaoHorariaAncoraOrigem  := 4;
    FPosicaoHorariaAncoraDestino := 10;
  end;

  if FElementoOrigem is TRPTransicao then
    FPosicaoHorariaAncoraOrigem := AjustaAncoragemTransicao(FPosicaoHorariaAncoraOrigem)
  else if FElementoDestino is TRPTransicao then
    FPosicaoHorariaAncoraDestino := AjustaAncoragemTransicao(FPosicaoHorariaAncoraDestino);


  pAncoraOrigem  := GetPontoAncoragem(FElementoOrigem,  FPosicaoHorariaAncoraOrigem);
  pAncoraDestino := GetPontoAncoragem(FElementoDestino, FPosicaoHorariaAncoraDestino);

  FCurvePoint[1] := Point(pAncoraOrigem.X, pAncoraOrigem.Y);
  FCurvePoint[2] := Point(pAncoraOrigem.X, pAncoraOrigem.Y);
  FCurvePoint[3] := Point(pAncoraDestino.X, pAncoraDestino.Y);
  FCurvePoint[4] := Point(pAncoraDestino.X, pAncoraDestino.Y);

  DesenhaFlecha;
end;

procedure TRPConexao.Refresh;
begin
  FImage.Transparent := False;
  Application.ProcessMessages;
  FImage.Transparent := True;
end;

procedure TRPConexao.SetSelected(const Value: Boolean);
begin
  FSelected := Value;
  if FSelected then
  begin
    FRede.UnSelectAll;
    FRede.FSelectedConexao := Self;

  end
  else
  begin

  end;
end;

end.
