page 70065 "Order Fee Shipment Method" // 50065
{
    Caption = 'Väikese tellimuse teenustasu lähetusviisid';
    PageType = List;
    SourceTable = "AGP_KGK_SOC_OrderFeeShpmnt";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Transport Time"; Rec."Transport Time")
                {
                    Editable = OrderManager;
                    Enabled = OrderManager;
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    Editable = OrderManager;
                    Enabled = OrderManager;
                    ApplicationArea = All;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    Editable = OrderManager;
                    Enabled = OrderManager;
                    ApplicationArea = All;
                }
                field("Resource Code"; Rec."Resource Code")
                {
                    Editable = OrderManager;
                    Enabled = OrderManager;
                    ApplicationArea = All;
                }
                field("Small Order Fee"; Rec."Small Order Fee")
                {
                    Editable = OrderManager;
                    Enabled = OrderManager;
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestFindingLinesForShipment)
            {
                ApplicationArea = All;
                Image = TestFile;

                trigger OnAction()
                begin
                    CODEUNIT.RUN(CODEUNIT::AGP_KGK_SOC_ShipSalesJob)
                end;
            }
            action(TestFindingLinesForInvoicing)
            {
                ApplicationArea = All;
                Image = TestFile;

                trigger OnAction()
                begin
                    CODEUNIT.RUN(CODEUNIT::AGP_KGK_SOC_InvoiceSalesJob)
                end;
            }
        }
    }




    trigger OnOpenPage()
    begin
        DisableFields();
        if OrderManager = false then
            ERROR(NoOrderManagerLbl);
    end;

    var
        OrderManager: Boolean;
        NoOrderManagerLbl: Label 'Teil ei ole õigust kirjet (asukoht, lähetusviisi tähis) muuta.';
    // ShipSalesJob: Codeunit AGP_KGK_SOC_ShipSalesJob;

    local procedure DisableFields()
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.GET(USERID);
        OrderManager := UserSetup."Order Fee Manager";
    end;
}

