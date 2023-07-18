pageextension 70065 AGP_KON_SOC_UserSetupExt extends "User Setup"
{
    layout
    {
        addlast(Control1)
        {
            field("Order Fee Manager"; Rec."Order Fee Manager")
            {
                ApplicationArea = All;
            }
        }
    }
}