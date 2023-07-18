codeunit 70066 AGP_KGK_SOC_ShipSalesJob
{
    // Tööjärjekorra kanne kutsub välja mingi intervalliga
    // Teeb esialgu täpselt sama tegevuse, mida teeb Läheta action täitmata tellimuste pagel, aga mitmele tellimusele järjest

    trigger OnRun()
    var
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLineAsHeader: Record "Sales Line" temporary;
        SalesLineOpenOrder: Record "Sales Line";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        TempSalesHeader: Record "Sales Header" temporary;
        CompletShipChekcBuffer: Record "Variable Buffer" temporary;
        WhseRqst: Record "Warehouse Request";
        Errorlog: Record AGP_KGK_SYS_SalesDocPostErrLog;
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        LocHasBin: Boolean;
    begin
        // Tühjenda puhver
        CompletShipChekcBuffer.Reset();
        CompletShipChekcBuffer.DeleteAll();

        TempSalesLineAsHeader.Reset();
        TempSalesLineAsHeader.DeleteAll();

        TempSalesLine.Reset();
        TempSalesLine.DeleteAll();

        TempSalesHeader.Reset();
        TempSalesHeader.DeleteAll();

        // Leia Sales Line tabelist lähetuseks valmis olevad read
        SalesLine.Reset();
        SalesLine.ClearMarks();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetFilter("Outstanding Quantity", '> 0');
        SalesLine.SetFilter("Planned Delivery Date", '13.03.2023'); // Testimise filter

        // Käi kõik Sales Line read läbi ja mark true, kui vastab tingimustele
        if SalesLine.FindSet() then
            repeat
                // Otsi Bin-i info
                LocHasBin := false;
                if Location.GET(SalesLine."Location Code") then
                    if Location."Shipment Bin Code" <> '' then
                        LocHasBin := true;
                SalesLine.CalcFields("Shipping Advice", "Item Qty. on Whse. Ship Order", "Bin Inventory", "Item Inventory", "Whse. Ship. Exists");

                if LocHasBin then begin
                    if (SalesLine."Shipping Advice" = SalesLine."Shipping Advice"::Partial) and
                        ((SalesLine."Bin Inventory" - SalesLine."Item Qty. on Whse. Ship Order") > 0) and
                        (not (SalesLine."Whse. Ship. Exists")) then begin
                        TempSalesLine.Init();
                        TempSalesLine := SalesLine;
                        TempSalesLine.Insert();
                    end
                    else begin
                        if (SalesLine."Shipping Advice" = SalesLine."Shipping Advice"::Complete) and
                        (not (SalesLine."Whse. Ship. Exists")) then
                            if not CompletShipChekcBuffer.GET(SalesLine."Document No.") then begin
                                CompletShipChekcBuffer.INIT();
                                CompletShipChekcBuffer.Code := SalesLine."Document No.";
                                if (SalesLine."Bin Inventory" - SalesLine."Item Qty. on Whse. Ship Order") >= SalesLine.Quantity then begin
                                    SalesLineOpenOrder.RESET();
                                    SalesLineOpenOrder.SETRANGE("Document Type", SalesLine."Document Type");
                                    SalesLineOpenOrder.SETRANGE("Document No.", SalesLine."Document No.");
                                    SalesLineOpenOrder.SETRANGE(Type, SalesLine.Type::Item);
                                    SalesLineOpenOrder.SETFILTER("No.", '<>%1');
                                    SalesLineOpenOrder.SETFILTER("Line No.", '<>%1', SalesLine."Line No.");
                                    SalesLineOpenOrder.SETAUTOCALCFIELDS("Bin Inventory", "Item Qty. on Whse. Ship Order");
                                    CompletShipChekcBuffer."Bool 1" := true;
                                    if SalesLineOpenOrder.FINDSET() then
                                        repeat
                                            CompletShipChekcBuffer."Bool 1" := (SalesLineOpenOrder."Bin Inventory" - SalesLineOpenOrder."Item Qty. on Whse. Ship Order") >= SalesLineOpenOrder.Quantity;
                                        until (SalesLineOpenOrder.NEXT() = 0) or (not CompletShipChekcBuffer."Bool 1");
                                end;
                                CompletShipChekcBuffer.INSERT();
                            end;
                        if CompletShipChekcBuffer."Bool 1" then begin
                            TempSalesLine.Init();
                            TempSalesLine := SalesLine;
                            TempSalesLine.Insert();
                        end;
                    end;
                end
                else// Bini ei ole  
                    if (SalesLine."Shipping Advice" = SalesLine."Shipping Advice"::Partial) and
                    ((SalesLine."Item Inventory" - SalesLine."Item Qty. on Whse. Ship Order") > 0) and
                    (not (SalesLine."Whse. Ship. Exists")) then begin
                        TempSalesLine.Init();
                        TempSalesLine := SalesLine;
                        TempSalesLine.Insert();
                    end
                    else
                        if (SalesLine."Shipping Advice" = SalesLine."Shipping Advice"::Complete) and
                        (not (SalesLine."Whse. Ship. Exists")) then begin
                            if not CompletShipChekcBuffer.GET(SalesLine."Document No.") then begin
                                CompletShipChekcBuffer.INIT();
                                CompletShipChekcBuffer.Code := SalesLine."Document No.";
                                if (SalesLine."Item Inventory" - SalesLine."Item Qty. on Whse. Ship Order") >= SalesLine.Quantity then begin
                                    SalesLineOpenOrder.RESET();
                                    SalesLineOpenOrder.SETRANGE("Document Type", SalesLine."Document Type");
                                    SalesLineOpenOrder.SETRANGE("Document No.", SalesLine."Document No.");
                                    SalesLineOpenOrder.SETRANGE(Type, SalesLine.Type::Item);
                                    SalesLineOpenOrder.SETFILTER("No.", '<>%1');
                                    SalesLineOpenOrder.SETFILTER("Line No.", '<>%1', SalesLine."Line No.");
                                    SalesLineOpenOrder.SETAUTOCALCFIELDS("Item Inventory", "Item Qty. on Whse. Ship Order");
                                    CompletShipChekcBuffer."Bool 1" := true;
                                    if SalesLineOpenOrder.FINDSET() then
                                        repeat
                                            CompletShipChekcBuffer."Bool 1" := (SalesLineOpenOrder."Item Inventory" - SalesLineOpenOrder."Item Qty. on Whse. Ship Order") >= SalesLineOpenOrder.Quantity;
                                        until (SalesLineOpenOrder.NEXT() = 0) or (not CompletShipChekcBuffer."Bool 1");
                                end;
                                CompletShipChekcBuffer.INSERT();
                            end;
                            if CompletShipChekcBuffer."Bool 1" then begin
                                TempSalesLine.Init();
                                TempSalesLine := SalesLine;
                                TempSalesLine.Insert();
                            end;
                        end;
            until SalesLine.Next() = 0;

        // Võta ainult märgitud Sales Line read 
        TempSalesLine.Reset();
        if TempSalesLine.FindSet() then
            repeat
                if SalesHeader.get(TempSalesLine."Document Type", TempSalesLine."Document No.") then begin
                    TempSalesHeader.Init();
                    TempSalesHeader := SalesHeader;
                    if TempSalesHeader.Insert() then;
                end;
            until TempSalesLine.Next() = 0;

        // Testimiseks
        /* TempSalesHeader.Reset();
        Page.RunModal(Page::"Sales List", TempSalesHeader);
        exit; */

        TempSalesHeader.Reset();
        if TempSalesHeader.FindSet() then
            repeat
                SalesHeader.GET(TempSalesHeader."Document Type", TempSalesHeader."No.");
                // Check Customer Credit Limit before Transaction
                SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                CustCheckCreditLimit.SalesHeaderCheck(SalesHeader);
                SalesHeader."Document Type" := SalesHeader."Document Type"::Order;

                // Release and Ship
                ReleaseSalesDocument.RUN(SalesHeader);

                // Kustuta Error Logi tabelist vana rida ära, kui see seal on
                if Errorlog.Get(SalesHeader."Document Type", SalesHeader."No.", 'SHIP') then
                    Errorlog.Delete();

                WhseRqst.SETRANGE(Type, WhseRqst.Type::Outbound);
                WhseRqst.SETRANGE("Source Type", DATABASE::"Sales Line");
                WhseRqst.SETRANGE("Source Subtype", SalesHeader."Document Type");
                WhseRqst.SETRANGE("Source No.", SalesHeader."No.");
                if WhseRqst.ISEMPTY then begin
                    // Kustuta Error Logi tabelist vana rida ära, kui see seal on
                    if Errorlog.Get(SalesHeader."Document Type", SalesHeader."No.", 'SHIP') then
                        Errorlog.Delete();
                    if not CODEUNIT.RUN(CODEUNIT::"Sales-Post", SalesHeader) then begin
                        Errorlog.Reset();
                        Errorlog.Init();
                        Errorlog."Document Type" := SalesHeader."Document Type";
                        Errorlog."Document No." := SalesHeader."No.";
                        Errorlog."Type of Posting" := 'SHIP';
                        Errorlog."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Errorlog."Error Message"));
                        Errorlog.Insert();
                    end;
                end
                else begin
                    // Kustuta Error Logi tabelist vana rida ära, kui see seal on
                    if Errorlog.Get(SalesHeader."Document Type", SalesHeader."No.", 'CREATESHIP') then
                        Errorlog.Delete();
                    // CheckUserLocation(SalesHeader);  // VP:006
                    if not TryToCreateFromSalesOrder(SalesHeader) then begin
                        Errorlog.Reset();
                        Errorlog.Init();
                        Errorlog."Document Type" := SalesHeader."Document Type";
                        Errorlog."Document No." := SalesHeader."No.";
                        Errorlog."Type of Posting" := 'CREATESHIP';
                        Errorlog."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Errorlog."Error Message"));
                        Errorlog.Insert();
                    end;
                end;
            until TempSalesLineAsHeader.Next() = 0;
    end;

    // Try
    [TryFunction]
    local procedure TryToCreateFromSalesOrder(SalesHeader: Record "Sales Header")
    var
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        GetSourceDocOutbound.CreateFromSalesOrder(SalesHeader);
    end;
}