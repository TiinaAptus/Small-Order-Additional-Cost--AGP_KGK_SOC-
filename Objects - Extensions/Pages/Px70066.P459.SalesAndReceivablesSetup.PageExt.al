pageextension 70066 AGP_KGK_SOC_SalesReceSetupExt extends "Sales & Receivables Setup"
{
    layout
    {
        addlast(content)
        {
            group("Tellimuse lisatasu")
            {
                Caption = 'Tellimuse lisatasu';
                field("Web Order Enable"; Rec."Web Order Enable")
                {
                    Editable = OrderManager;
                    ApplicationArea = All;
                }
                field("WEB Order Margin"; Rec."WEB Order Margin")
                {
                    Caption = 'Piirmäär, lisatakse sellest väiksemale ';
                    Editable = OrderManager;
                    ApplicationArea = All;
                }
                field("WEB Order Resource"; Rec."WEB Order Resource")
                {
                    Editable = OrderManager;
                    TableRelation = Resource where("Order Fee Resource" = const(true));
                    ApplicationArea = All;
                }
                field(ShippmentMethod; ShippmentMethod)
                {
                    Caption = 'Asukoht, lähetusviisitähis';
                    Style = StandardAccent;
                    /* DrillDown = true;
                    DrillDownPageID = "Order Fee Shipment Method"; */
                    Editable = false;
                    Lookup = true;
                    LookupPageID = "Order Fee Shipment Method";
                    TableRelation = "Order Fee Shipment Method";
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShippmentMethod := '';
    end;

    trigger OnAfterGetRecord()
    begin
        ShippmentMethod := 'Vaata siit';
        DisableFields();
    end;

    var
        OrderManager: Boolean;
        ShippmentMethod: Text[250];

    local procedure DisableFields()
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.GET(USERID);
        OrderManager := UserSetup."Order Fee Manager";
    end;
}
