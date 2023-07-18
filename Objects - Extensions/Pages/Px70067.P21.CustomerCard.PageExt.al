pageextension 70067 AGP_KON_SOC_CustomerCardExt extends "Customer Card"
{
    layout
    {
        addlast("Add-on")
        {
            field("NO WEB Order Fee"; Rec."NO WEB Order Fee")
            {
                Caption = 'Ära arvesta transporditasu';
                Editable = OrderManager;
                ApplicationArea = All;
            }
        }
    }
    trigger OnOpenPage()
    begin
        DisableFields();
    end;

    var
        UserSetup: Record "User Setup";
        OrderManager: Boolean;

    local procedure DisableFields()
    begin
        UserSetup.GET(USERID);
        // ClientManager := UserSetup."Client Manager";
        OrderManager := UserSetup."Order Fee Manager";
        // SUManager := UserSetup."SU Client Manager";
    end;
}