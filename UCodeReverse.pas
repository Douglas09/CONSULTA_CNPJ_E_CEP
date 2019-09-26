unit UCodeReverse;

{
  25.03.19 - Utilizando API do google GeoCodeReverse
  Douglas Colombo

  27.03.19 - Update v2 Magno Lima :)
  
  27.03.19 - Update v3 Walter D Faria :)
  Adicionado recurso consulta CNPJ (Site: receitaws )
}
interface

uses
    FMX.Dialogs, System.SysUtils, System.Classes, System.Json,
    System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent;

Type

    TNetConsultaCNPJ = class
     private

        obj: TJSONObject;
        arr: TJSONArray;

        FRazao: String;
        FFantasia: String;

        FCnpj: String;
        FInscricao: String;

        FTelefone: String;
        FEmail: String;

        FEndereco: String;
        FNumero: String;
        FBairro: String;
        FCidade: String;
        FUF: String;
        FCEP: String;

        FErro: String;
        FAPIKey: String;

        procedure Resetar;

        procedure SetAPIKey(const Value: String);
        procedure SetBairro(const Value: String);
        procedure SetCEP(const Value: String);
        procedure SetCidade(const Value: String);
        procedure SetEndereco(const Value: String);
        procedure SetErro(const Value: String);
        procedure SetNumero(const Value: String);
        procedure SetUF(const Value: String);
        procedure SetCNPJ(const Value: String);
        procedure SetEmail(const Value: String);
        procedure SetTelefone(const Value: String);
    procedure SetFantasia(const Value: String);
    procedure SetRazao(const Value: String);

     public

        function CapturarDados: Boolean;

        property Bairro: String read FBairro write SetBairro;
        property CEP: String read FCEP write SetCEP;
        property Cidade: String read FCidade write SetCidade;
        property Endereco: String read FEndereco write SetEndereco;
        property Numero: String read FNumero write SetNumero;
        property UF: String read FUF write SetUF;
        property APIKey: String read FAPIKey write SetAPIKey;
        property Erro: String read FErro write SetErro;

        property CNPJ: String read FCNPJ write SetCNPJ;
        property Telefone: String read FTelefone write SetTelefone;
        property Email: String read FEmail write SetEmail;

        property Razao: String read FRazao write SetRazao;
        property Fantasia: String read FFantasia write SetFantasia;

        constructor Create; reintroduce;
        Destructor Destroy; reintroduce;

    end;

    TNetEndereco = class
    private
        obj: TJSONObject;
        arr: TJSONArray;
        FBairro: String;
        FCidade: String;
        FUF: String;
        FCEP: String;
        FEndereco: String;
        FEnderecoNumero: String;
        FLatitude: Double;
        FLongitude: Double;
        FErro: String;
        FAPIKey: String;
        procedure Resetar;
    public
        function CapturarEndereco: Boolean;
        property Bairro: String read FBairro;
        property CEP: String read FCEP;
        property Cidade: String read FCidade;
        property Endereco: String read FEndereco;
        property EnderecoNumero: String read FEnderecoNumero;
        property UF: String read FUF;
        property Latitude: Double read FLatitude write FLatitude;
        property Longitude: Double read FLongitude write FLongitude;
        property APIKey: String read FAPIKey write FAPIKey;
        property Erro: String read FErro;
        constructor Create; reintroduce;
        Destructor Destroy; reintroduce;
    end;

implementation

{ TNetEndereco }

function TNetEndereco.CapturarEndereco: Boolean;
Var
    resp: TStringStream;
    tempLat, tempLon: String;
    Net: TNetHTTPClient;
    decSep: Char;
    offSet: Integer;
begin
    Result := False;

    decSep := FormatSettings.DecimalSeparator;
    FormatSettings.DecimalSeparator := '.';

    Resetar;
    Try
        resp := TStringStream.Create;
        resp.Position := 0;
        Net := TNetHTTPClient.Create(nil);
        Net.Asynchronous := False;
        Net.ConnectionTimeout := 5000;
        Net.ResponseTimeout := 5000;

        try
            Net.Get('https://maps.googleapis.com/maps/api/geocode/json?latlng='
              + Latitude.ToString + ',' + Longitude.ToString + '&key=' +
              APIKey, resp);

        Except
            on E: Exception do
                FErro := 'Api: ' + E.Message;
        End;

        if (resp.DataString.Contains('"status" : "OK"')) then
        begin
            obj := TJSONObject.ParseJSONValue(resp.DataString) As TJSONObject;
            arr := obj.GetValue('results') as TJSONArray;
            obj := arr.Get(0) as TJSONObject;
            arr := obj.GetValue('address_components') as TJSONArray;
            obj := arr.Items[0] as TJSONObject; // Endereço Número
            FEnderecoNumero := Utf8ToString(obj.GetValue('long_name').Value);

            obj := arr.Items[1] as TJSONObject; // Endereço
            FEndereco := Utf8ToString(obj.GetValue('long_name').Value);
            offSet := 0;

            if (arr.Count = 7) then { com bairro }
            begin
                offSet := 1;
                obj := arr.Items[2] as TJSONObject; // BAIRRO
                FCidade := Utf8ToString(obj.GetValue('long_name').Value);
            end;

            obj := arr.Items[2 + offSet] as TJSONObject; // CIDADE
            FCidade := Utf8ToString(obj.GetValue('long_name').Value);

            obj := arr.Items[3 + offSet] as TJSONObject; // UF
            FUF := obj.GetValue('short_name').Value;

            obj := arr.Items[5 + offSet] as TJSONObject; // CEP
            FCEP := obj.GetValue('long_name').Value;

            Result := true;

        end
        else
        begin
            obj := TJSONObject.ParseJSONValue(resp.DataString) As TJSONObject;
            FErro := 'API Retorno: ' + obj.GetValue('status').Value;

        end;

    finally
        FormatSettings.DecimalSeparator := decSep;
        resp.DisposeOf;
        Net.DisposeOf;
        Net := nil;
    end;

end;

constructor TNetEndereco.Create;
begin
    Inherited Create;
end;

destructor TNetEndereco.Destroy;
begin
    Try
        arr.DisposeOf;
        arr := nil;
    Except
    End;
    Try
        obj.DisposeOf;
        obj := nil;
    Except
    End;
end;

procedure TNetEndereco.Resetar;
begin
    FBairro := '';
    FCidade := '';
    FCEP := '';
    FErro := '';
    FEndereco := '';
    FEnderecoNumero := '';
    FUF := '';
end;

{ TNetConsultaCNPJ }

function TNetConsultaCNPJ.CapturarDados: Boolean;
Var
    resp: TStringStream;
    tempLat, tempLon: String;
    Net: TNetHTTPClient;
begin
    Result := False;

    Resetar;
    Try
        resp := TStringStream.Create;
        resp.Position := 0;
        Net := TNetHTTPClient.Create(nil);
        Net.Asynchronous := False;
        Net.ConnectionTimeout := 5000;
        Net.ResponseTimeout := 5000;

        try
            Net.Get('https://www.receitaws.com.br/v1/cnpj/13243808000141', resp);

        Except
            on E: Exception do
                FErro := 'Api: ' + E.Message;
        End;

        if (resp.DataString.Contains('"status": "OK"')) then
        begin
            obj := TJSONObject.ParseJSONValue(resp.DataString) As TJSONObject;
            obj.GetValue('status').Value;

            FInscricao:= '';
            FCnpj := Utf8ToString(obj.GetValue('cnpj').Value);
            FRazao := Utf8ToString(obj.GetValue('nome').Value);
            FFantasia := Utf8ToString(obj.GetValue('fantasia').Value);
            FEmail := Utf8ToString(obj.GetValue('email').Value);
            FTelefone := Utf8ToString(obj.GetValue('telefone').Value);

            FCEP := Utf8ToString(obj.GetValue('cep').Value);
            FNumero := Utf8ToString(obj.GetValue('numero').Value);
            FEndereco := Utf8ToString(obj.GetValue('logradouro').Value);
            FBairro := Utf8ToString(obj.GetValue('bairro').Value);
            FCidade := Utf8ToString(obj.GetValue('municipio').Value);
            FUF := obj.GetValue('uf').Value;

            Result := true;

        end
        else
        begin
            obj := TJSONObject.ParseJSONValue(resp.DataString) As TJSONObject;
            FErro := 'API Retorno: ' + obj.GetValue('status').Value;
        end;

    finally
        resp.DisposeOf;
        Net.DisposeOf;
        Net := nil;
    end;
end;

constructor TNetConsultaCNPJ.Create;
begin
 Inherited Create;
end;

destructor TNetConsultaCNPJ.Destroy;
begin
    Try
        arr.DisposeOf;
        arr := nil;
    Except
    End;
    Try
        obj.DisposeOf;
        obj := nil;
    Except
    End;
end;

procedure TNetConsultaCNPJ.Resetar;
begin
 FCnpj:= ''; FTelefone:= ''; FEmail:= ''; FRazao:= ''; FFantasia:= ''; FBairro := ''; FCidade := ''; FCEP := ''; FErro := ''; FEndereco := ''; FNumero := ''; FUF := '';
end;

procedure TNetConsultaCNPJ.SetAPIKey(const Value: String);
begin
  FAPIKey := Value;
end;

procedure TNetConsultaCNPJ.SetBairro(const Value: String);
begin
  FBairro := Value;
end;

procedure TNetConsultaCNPJ.SetCEP(const Value: String);
begin
  FCEP := Value;
end;

procedure TNetConsultaCNPJ.SetCidade(const Value: String);
begin
  FCidade := Value;
end;

procedure TNetConsultaCNPJ.SetCNPJ(const Value: String);
begin
  FCNPJ := Value;
end;

procedure TNetConsultaCNPJ.SetEmail(const Value: String);
begin
  FEmail := Value;
end;

procedure TNetConsultaCNPJ.SetEndereco(const Value: String);
begin
  FEndereco := Value;
end;

procedure TNetConsultaCNPJ.SetErro(const Value: String);
begin
  FErro := Value;
end;

procedure TNetConsultaCNPJ.SetFantasia(const Value: String);
begin
  FFantasia := Value;
end;

procedure TNetConsultaCNPJ.SetNumero(const Value: String);
begin
  FNumero := Value;
end;

procedure TNetConsultaCNPJ.SetRazao(const Value: String);
begin
  FRazao := Value;
end;

procedure TNetConsultaCNPJ.SetTelefone(const Value: String);
begin
  FTelefone := Value;
end;

procedure TNetConsultaCNPJ.SetUF(const Value: String);
begin
  FUF := Value;
end;

end.

