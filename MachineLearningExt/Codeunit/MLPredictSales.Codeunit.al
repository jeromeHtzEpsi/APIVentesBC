codeunit 50110 "ML Predict Sales"
{
    procedure PredictSales(No: Code[20]; unitPrice: Decimal; LastQuantity: Decimal): Decimal
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        JsonResponse: JsonObject;
        JsonArray: JsonArray;
        JsonRequest: JsonObject;
        PredictedQty: Decimal;
        Token: JsonToken;
        RespText: Text;
        RequestText: Text;
        SalesHistory: Record "Sales Line";
        SalesHistoryArray: JsonArray;
        SalesHistoryObject: JsonObject;
    begin
        SalesHistory.SetRange("No.", No);

        // Construire le JSON avec JsonObject pour garantir le format
        SalesHistoryArray := SalesHistoryToJsonArray(SalesHistory);
        JsonRequest.Add('unitPrice', unitPrice);
        JsonRequest.Add('last_quantity', LastQuantity);
        JsonRequest.Add('history', SalesHistoryArray);
        JsonRequest.WriteTo(RequestText);
        Message(RequestText);
        JsonRequest.Add('name', No + '_sales_data.csv'); // Nom du fichier CSV
        
        // Convertir en texte
        JsonRequest.WriteTo(RequestText);
        
        // DEBUG
        MESSAGE('JSON envoyé : %1', RequestText);
        
        // Configurer le contenu
        Content.WriteFrom(RequestText);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');
        
        // Appeler l'API Python
        if Client.Post('https://uninstinctively-incompliant-kellee.ngrok-free.dev/predict', Content, Response) then begin
            if Response.IsSuccessStatusCode() then begin
                Response.Content.ReadAs(RespText);

                // DEBUG
                MESSAGE('JSON reçu : %1', RespText);
                
                if JsonResponse.ReadFrom(RespText) then
                    if JsonResponse.Get('predicted_quantity', Token) then begin
                        PredictedQty := Token.AsValue().AsDecimal();
                        exit(PredictedQty);
                    end;
                Error('Format de réponse invalide');
            end else begin
                Response.Content.ReadAs(RespText);
                Error('Erreur API : %1 - Détails : %2', Response.HttpStatusCode(), RespText);
            end;
        end else
            Error('Impossible de contacter le service ML.');
    end;


    procedure SalesHistoryToJsonArray(var SalesHistory: Record "Sales Line"): JsonArray
    var
        SalesHistoryArray: JsonArray;
        SalesHistoryObject: JsonObject;
    begin
        if SalesHistory.FindSet() then begin
            repeat
                Clear(SalesHistoryObject); // Réinitialiser pour chaque ligne
                SalesHistoryObject.Add('unitPrice', SalesHistory."Unit Price");
                SalesHistoryObject.Add('quantity', SalesHistory.Quantity);
                SalesHistoryArray.Add(SalesHistoryObject);
            until SalesHistory.Next() = 0;
        end;
        exit(SalesHistoryArray);
    end;

}
