codeunit 70065 SCOFunctions
{
    // Enne ridade konteerimist
    [EventSubscriber(ObjectType::Codeunit, 80, 'OnBeforePostSalesLines', '', false, false)]
    local procedure C_80_PostSalesLines(var SalesHeader: Record "Sales Header";
                                        var TempSalesLineGlobal: Record "Sales Line" temporary;
                                        var TempVATAmountLine: Record "VAT Amount Line" temporary;
                                        var EverythingInvoiced: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        Customer: Record "Customer";
        WebLine: Record "Sales Line";
        OrderFeeShipmentMethod: Record AGP_KGK_SOC_OrderFeeShpmnt;
        Resources: Record Resource;
        WebLineNo: Integer;
    begin
        if SalesHeader.Ship and not (SalesHeader.Invoice) then
            exit;
        SalesSetup.get();
        SalesHeader.CALCFIELDS(Amount);
        Customer.get(SalesHeader."Sell-to Customer No.");
        if SalesSetup."Web Order Enable" then
            if (SalesSetup."WEB Order Margin" > 0) and (SalesSetup."WEB Order Resource" <> '') then
                if ((SalesSetup."WEB Order Margin" > SalesHeader.Amount) and (not Customer."NO WEB Order Fee")) then begin
                    OrderFeeShipmentMethod.SetRange("Location Code", SalesHeader."Location Code");
                    OrderFeeShipmentMethod.SetRange("Shipment Method Code", SalesHeader."Shipment Method Code");
                    OrderFeeShipmentMethod.SetFilter("Small Order Fee", '%1', true);
                    if OrderFeeShipmentMethod.FindFirst() then begin
                        Resources.Get(OrderFeeShipmentMethod."Resource Code");
                        TempSalesLineGlobal.RESET();
                        if TempSalesLineGlobal.FINDLAST() then
                            WebLineNo := (TempSalesLineGlobal."Line No." + 10000);

                        TempSalesLineGlobal.RESET();
                        TempSalesLineGlobal.Init();
                        TempSalesLineGlobal.VALIDATE("Document Type", SalesHeader."Document Type");
                        TempSalesLineGlobal.VALIDATE("Document No.", SalesHeader."No.");
                        TempSalesLineGlobal.VALIDATE("Line No.", WebLineNo);
                        TempSalesLineGlobal.SuspendStatusCheck(true);
                        TempSalesLineGlobal.VALIDATE(Type, WebLine.Type::Resource);
                        TempSalesLineGlobal.INSERT();
                        // COMMIT();

                        TempSalesLineGlobal.VALIDATE("No.", Resources."No.");
                        TempSalesLineGlobal.VALIDATE(Quantity, 1);
                        TempSalesLineGlobal.VALIDATE("Qty. to Invoice", SalesHeader."Document Type".AsInteger());
                        TempSalesLineGlobal.AGP_KGK_SOC_IsTransportRow := true;
                        TempSalesLineGlobal.MODIFY();
                        TempSalesLineGlobal.SuspendStatusCheck(false);
                    end;
                end;
    end;

    // Ridade update peale konteerimist - kui on transpordi rida, siis mine mööda
    [EventSubscriber(ObjectType::Codeunit, 80, 'OnBeforePostUpdateOrderLineModifyTempLine', '', false, false)]
    local procedure C_80_PostUpdateOrderLine(var TempSalesLine: Record "Sales Line" temporary;
                                                WhseShip: Boolean;
                                                WhseReceive: Boolean;
                                                CommitIsSuppressed: Boolean;
                                                var IsHandled: Boolean;
                                                SalesHeader: Record "Sales Header")
    begin
        if IsHandled then
            exit;

        if TempSalesLine.AGP_KGK_SOC_IsTransportRow then
            IsHandled := true;
    end;

    
}