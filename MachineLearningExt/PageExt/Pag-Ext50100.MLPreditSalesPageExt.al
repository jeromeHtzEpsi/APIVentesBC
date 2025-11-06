pageextension 50110 MLPreditSalesPageExt extends "Item Card"
{
    layout
    {
        addafter(ItemPicture)
        {
            part(MLPredictSalesPart; "SalesLine.Page.al")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }
    actions
    {
        addfirst(Processing)
        {
            action(PredictSales)
            {
                ApplicationArea = All;
                Caption = 'Prévoir les ventes';
                trigger OnAction()
                var
                    Pred: Decimal;
                    LastQuantity: Decimal;
                begin
                    LastQuantity := GetLastSaleQuantity(Rec."No.");
                    Message('Dernière quantité vendue : %1 unités', LastQuantity);
                    Pred := ML_PredictSales.PredictSales(Rec."No.", Rec."Unit Price", LastQuantity);
                    Message('Prévision de vente : %1 unités', Pred);
                end;
            }

            action(ExportToCSV)
            {
                ApplicationArea = All;
                Caption = 'Exporter les données de vente en CSV';
                trigger OnAction()
                begin
                    toCSV(Rec."No.");
                end;
            }
        }
    }

    procedure GetLastSaleQuantity(ItemNo: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        LastQty: Decimal;
    begin
        LastQty := 0;

        // Filtrer sur l'article et les lignes de vente
        SalesLine.SetRange("No.", ItemNo);

        // Parcourir toutes les lignes pour trouver la plus récente
        if SalesLine.FindSet() then
            repeat
                if SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then begin
                    if LastQty = 0 then
                        LastQty := SalesLine.Quantity
                    else if SalesHeader."Document Date" >= SalesHeader."Document Date" then
                        LastQty := SalesLine.Quantity;
                end;
            until SalesLine.Next() = 0;

        exit(LastQty);
    end;

    procedure toCSV(No: Code[20])
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        FileName: Text;
        TxtBuilder: TextBuilder;
        LastQuantity: Decimal;
    begin
        LastQuantity := GetLastSaleQuantity(Rec."No.");
        FileName := No + '_sales_data.csv';
        TxtBuilder.AppendLine('Item No.' + ';' + 'unitPrice' + ';' + 'quantity');
        Rec.Reset();
        Rec.SetRange("No.", No);
        // Rec.SetAutoCalcFields("Customer Comments");
        if Rec.FindSet() then
            repeat

                TxtBuilder.AppendLine(AddDoubleQuotes(Format(Rec."No.")) + ';' +
                                            Format(Rec."Unit Price") + ';' + Format(LastQuantity));
            until Rec.Next() = 0;
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(TxtBuilder.ToText());
        TempBlob.CreateInStream(InS);
        DownloadFromStream(InS, '', '', '', FileName);
    end;

    local procedure AddDoubleQuotes(FieldValue: Text): Text
    begin
        exit('"' + FieldValue + '"');
    end;



    var
        ML_PredictSales: Codeunit "ML Predict Sales";

}
