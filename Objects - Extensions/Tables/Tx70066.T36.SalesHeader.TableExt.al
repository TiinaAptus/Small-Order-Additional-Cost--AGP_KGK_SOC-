tableextension 70066 AGP_KGK_SOP_SalesHeaderExt extends "Sales Header"
{
    fields
    {
        field(70065; "Invoice Period"; Option)
        {
            Caption = 'Koondarve tüüp';
            Description = 'PK';
            FieldClass = FlowField;
            OptionCaption = ' ,päeva arve,nädala arve,kahe nädala arve,kuu arve';
            OptionMembers = " ","1","2","3","4";
            CalcFormula = lookup(Customer."Invoice Period" where("No." = field("Sell-to Customer No.")));
        }
    }
    procedure WhseShpmntConflict(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
                                    DocNo: Code[20];
                                    ShippingAdvice: Option Partial,Complete)
                                    : Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if ShippingAdvice <> ShippingAdvice::Complete then
            exit(false);
        WarehouseShipmentLine.SETCURRENTKEY("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseShipmentLine.SETRANGE("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SETRANGE("Source Subtype", DocType);
        WarehouseShipmentLine.SETRANGE("Source No.", DocNo);
        if WarehouseShipmentLine.ISEMPTY then
            exit(false);
        exit(true);
    end;
}