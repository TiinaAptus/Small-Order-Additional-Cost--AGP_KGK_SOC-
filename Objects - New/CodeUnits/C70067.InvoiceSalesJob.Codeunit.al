codeunit 70067 AGP_KGK_SOC_InvoiceSalesJob
{
    // Tööjärjekorra töö kutsub välja
    var
        PostingTime: Time;
        TimeBeforeTransport: Duration;

    trigger OnRun()
    var
        OrderFeeShipmentMethod: Record AGP_KGK_SOC_OrderFeeShpmnt;
        TempNextOrderFeeShipmentMethod: Record AGP_KGK_SOC_OrderFeeShpmnt temporary;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempNeedsInvoicing: Record "Sales Header" temporary;
        TempUniqueCustomers: Record "Sales Header" temporary;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        // _CombineShipments: Report "Combine Shipments";
        Errorlog: Record AGP_KGK_SYS_SalesDocPostErrLog;
        _CombineShipments: Report AGP_KGK_SOC_CombineShipments;
    // ShippedNotInvoiced: Boolean;
    begin
        TempNextOrderFeeShipmentMethod.Reset();
        TempNextOrderFeeShipmentMethod.DeleteAll();

        TempNeedsInvoicing.Reset();
        TempNeedsInvoicing.DeleteAll();


        // Otsi asukohad, mille veoring on 30 - 40 min pärast
        TimeBeforeTransport := 60 * 60 * 1000; // 40 min 
        PostingTime := Time + TimeBeforeTransport; // Hetkeaeg + 40 minutit
        // Otsijärgmised veoringid, mille tellimusi tuleb arveks konteerida
        OrderFeeShipmentMethod.Reset();
        // Veoringi aeg peab olema suurem, kui hetke aeg, aga väiksem, kui hetkeaeg + 40 min
        OrderFeeShipmentMethod.SetFilter("Transport Time", '>%1 & <%2 ', Time, PostingTime);
        // Käi need veoringid läbi, mille aeg on järgmise 40 min jooksul.
        if OrderFeeShipmentMethod.FindSet() then
            repeat
                TempNextOrderFeeShipmentMethod.Init();
                TempNextOrderFeeShipmentMethod := OrderFeeShipmentMethod;
                TempNextOrderFeeShipmentMethod.Insert();
            until OrderFeeShipmentMethod.Next() = 0;

        // Käi järgmised veoringid läbi ja otsi nende asukohtadele ja lähetamisviisidele vastavad tellimused, mida on lähetatud, aga on arveldamata
        TempNextOrderFeeShipmentMethod.Reset();
        if TempNextOrderFeeShipmentMethod.FindSet() then
            repeat
                SalesHeader.Reset();
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader.SetRange("Location Code", TempNextOrderFeeShipmentMethod."Location Code");
                SalesHeader.SetRange("Shipment Method Code", TempNextOrderFeeShipmentMethod."Shipment Method Code");
                // SalesHeader.SetFilter("Document Date", '13.03.2023'); // Testimise filter
                // SalesHeader.SetFilter("No.", '2342688'); // Testimise filter
                SalesHeader.SetAutoCalcFields("Invoice Period");
                if SalesHeader.FindSet() then
                    repeat
                        if SalesHeader."Invoice Period" = SalesHeader."Invoice Period"::" " then begin
                            SalesLine.Reset();
                            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                            SalesLine.SetRange("Document No.", SalesHeader."No.");
                            SalesLine.SetRange(Type, SalesLine.Type::Item);
                            // Testimiseks maha võetud, peab tagasi panema
                            SalesLine.setfilter("Qty. to Invoice", '> %1', 0);
                            // SalesLine.SetFilter("Quantity Invoiced", '< %1', SalesLine."Quantity Shipped");
                            SalesLine.setfilter("Qty. Shipped Not Invoiced", '> %1', 0);
                            if not SalesLine.IsEmpty() then begin // Tellimusel on rida, mis vajab arveldamist
                                                                  // if SalesLine.FindFirst() then begin
                                TempNeedsInvoicing.Reset();
                                TempNeedsInvoicing.Init();
                                TempNeedsInvoicing := SalesHeader;
                                TempNeedsInvoicing.Insert();
                            end;
                        end;
                    until SalesHeader.Next() = 0;
                // Kõik selle veoringi arveldamist vajavad tellimused on leitud

                // Kontrolli, kas samale kliendile on mitu tellimust
                TempUniqueCustomers.Reset();
                TempUniqueCustomers.DeleteAll();
                TempNeedsInvoicing.Reset();
                if TempNeedsInvoicing.FindSet() then
                    repeat
                        TempUniqueCustomers.Reset();
                        TempUniqueCustomers.SetRange("Sell-to Customer No.", TempNeedsInvoicing."Sell-to Customer No.");
                        if TempUniqueCustomers.IsEmpty then begin
                            TempUniqueCustomers := TempNeedsInvoicing;
                            TempUniqueCustomers.Insert();
                        end;
                    until TempNeedsInvoicing.Next() = 0;
                // TempUniqueCustomers tabelis on kliendid, kellele saadetised lähevad

                // Konteeri arveks
                TempUniqueCustomers.Reset();
                if TempUniqueCustomers.FindSet() then
                    repeat
                        TempNeedsInvoicing.Reset();
                        TempNeedsInvoicing.SetRange("Sell-to Customer No.", TempUniqueCustomers."Sell-to Customer No.");
                        if TempNeedsInvoicing.FindSet() then
                            if TempNeedsInvoicing.Count > 1 then begin
                                TempNeedsInvoicing.Reset();
                                // Tee nedest tellimustest koondarve
                                _CombineShipments.SetDates(WORKDATE(), WORKDATE());
                                TempNeedsInvoicing.SETRANGE("Sell-to Customer No.", TempUniqueCustomers."Sell-to Customer No.");
                                TempNeedsInvoicing.SETRANGE("Location Code", TempUniqueCustomers."Location Code");
                                _CombineShipments.SETTABLEVIEW(TempNeedsInvoicing);
                                _CombineShipments.SetHideDialog(true);
                                _CombineShipments.RUN();
                            end
                            else begin
                                // Kui kliendile on ainult 1 tellimus
                                // Update Sales Linele
                                SalesLine.Reset();
                                SalesLine.SETRANGE("Document Type", TempNeedsInvoicing."Document Type");
                                SalesLine.SETRANGE("Document No.", TempNeedsInvoicing."No.");
                                SalesLine.SETRANGE(Type, SalesLine.Type::Item);
                                SalesLine.SETFILTER("No.", '<>%1', '');
                                if SalesLine.FINDSET() then
                                    repeat
                                        Item.SETRANGE("No.", SalesLine."No.");
                                        Item.SETFILTER("Location Filter", SalesLine."Location Code");
                                        Item.SETAUTOCALCFIELDS(Inventory, "Qty. on Whse. Shipment Order");
                                        Item.FINDFIRST();
                                        if Item."Base Unit of Measure" <> SalesLine."Unit of Measure Code" then begin
                                            ItemUnitOfMeasure.GET(Item."No.", SalesLine."Unit of Measure Code");
                                            Item.Inventory := Item.Inventory / ItemUnitOfMeasure."Qty. per Unit of Measure";
                                            Item."Qty. on Whse. Shipment Order" := Item."Qty. on Whse. Shipment Order" / ItemUnitOfMeasure."Qty. per Unit of Measure";
                                        end;
                                        if ((Item.Inventory - Item."Qty. on Whse. Shipment Order") >= SalesLine."Outstanding Quantity") then
                                            SalesLine.VALIDATE("Qty. to Ship", SalesLine."Outstanding Quantity")
                                        else
                                            if (Item.Inventory - Item."Qty. on Whse. Shipment Order" > 0) then
                                                SalesLine.VALIDATE("Qty. to Ship", (Item.Inventory - Item."Qty. on Whse. Shipment Order"));
                                        SalesLine.MODIFY();
                                    until SalesLine.NEXT() = 0;

                                SalesHeader.Reset();
                                SalesHeader.get(TempNeedsInvoicing."Document Type", TempNeedsInvoicing."No.");

                                SalesHeader.Ship := true;
                                SalesHeader.Invoice := true;
                                COMMIT();

                                SalesHeader.VALIDATE("Posting Date", WORKDATE());
                                SalesHeader.VALIDATE("Document Date", WORKDATE());
                                SalesHeader.MODIFY();

                                // Kustuta Error Logi tabelist vana rida ära, kui see seal on
                                if Errorlog.Get(SalesHeader."Document Type", SalesHeader."No.", 'INVOICE') then
                                    Errorlog.Delete();

                                if not CODEUNIT.RUN(CODEUNIT::"Sales-Post", SalesHeader) then begin
                                    Errorlog.Reset();
                                    Errorlog.Init();
                                    Errorlog."Document Type" := SalesHeader."Document Type";
                                    Errorlog."Document No." := SalesHeader."No.";
                                    Errorlog."Type of Posting" := 'INVOICE';
                                    Errorlog."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Errorlog."Error Message"));
                                    Errorlog.Insert();
                                end;
                            end;
                    until TempUniqueCustomers.Next() = 0;
            until TempNextOrderFeeShipmentMethod.Next() = 0;
    end;
}