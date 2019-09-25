unit UConsultar_WEBSERVICE;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, IPPeerClient,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, REST.Client,
  REST.Response.Adapter, Data.Bind.Components, Data.Bind.ObjectScope,
  REST.Types;
type
  TfrmConsultaWebService = class(TForm)
    RESTClient1: TRESTClient;
    RESTResponseDataSetAdapter1: TRESTResponseDataSetAdapter;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
    fdConsultaWS: TFDMemTable;
  private
    function SomenteNumeros(const s: string): string;
  public
    { Public declarations }
    function consultarCNPJ(cnpj : String) : Boolean;
    function consultarCEP(cep : String) : Boolean;

  end;

var
  frmConsultaWebService: TfrmConsultaWebService;

implementation

{$R *.fmx}

uses UntDM;

{ TfrmConsultaCNPJ }

function TfrmConsultaWebService.consultarCEP(cep: String): Boolean;
begin
  try
     cep := SomenteNumeros(cep);
     restClient1.BaseURL  := pChar('https://viacep.com.br/ws/'+ cep +'/json');
     RESTRequest1.Method := rmGET;
     RESTRequest1.Timeout := 15000;
     Try
        RESTRequest1.Execute;
     Except on E: Exception do
        begin
          Dm.Toast('[ATENÇÃO]'+sLineBreak+sLineBreak+'Erro ao efetuar consulta online de CEP: '+e.Message, 10);
          result := false;
        end;
     End;

     if (RESTResponse1.StatusCode = 200) then //SUCESSO
        result := true
     else begin
        Dm.Toast('[ATENÇÃO]'+sLineBreak+sLineBreak+'Não foi possível consultar o CEP informado!', 10);
        result := false;
     end;
  Except on E : Exception do Dm.Toast('CONSULTANDO CEP...'+sLineBreak+sLineBreak+'Mensagem: '+ e.Message, 10); end;
end;

function TfrmConsultaWebService.consultarCNPJ(cnpj: String) : Boolean;
begin
  try
     cnpj := SomenteNumeros(cnpj);
     restClient1.BaseURL  := pChar('https://www.receitaws.com.br/v1/cnpj/'+cnpj);
     RESTRequest1.Method := rmGET;
     RESTRequest1.Timeout := 15000;
     Try
        RESTRequest1.Execute;
     Except on E: Exception do
        begin
          Dm.Toast('[ATENÇÃO]'+sLineBreak+sLineBreak+'Erro ao efetuar consulta online de CNPJ: '+e.Message, 10);
          result := false;
        end;
     End;

     if (RESTResponse1.StatusCode = 200) then //SUCESSO
        result := true
     else begin
        Dm.Toast('[ATENÇÃO]'+sLineBreak+sLineBreak+'Não foi possível consultar o CNPJ informado!', 8);
        result := false;
     end;
  Except on E : Exception do Dm.Toast('CONSULTANDO CNPJ...'+sLineBreak+sLineBreak+'Mensagem: '+ e.Message, 10); end;
end;

function TfrmConsultaWebService.SomenteNumeros(const s: string): string;
var i: integer;
begin
  result := '';
  if (length(s) > 0) then
  begin
     for i := 0 to length(s) do
       if pos(s[i], '0123456789') > 0 then
         result := result + s[i];
  end;
end;

end.
