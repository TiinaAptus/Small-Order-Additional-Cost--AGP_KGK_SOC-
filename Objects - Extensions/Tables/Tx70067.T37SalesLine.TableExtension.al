tableextension 70067 AGP_KGK_SOC_SalesLineExt extends "Sales Line"
{
    fields
    {
        field(70065; "Bin Inventory"; Decimal)
        {
            CalcFormula = sum("Warehouse Entry".Quantity where("Location Code" = field("Location Code"),
                                                                "Bin Code" = const('VÄLJA'),
                                                                "Item No." = field("No."),
                                                                "Unit of Measure Code" = field("Unit of Measure Code")));
            FieldClass = FlowField;
        }
        field(70066; "Item Qty. on Whse. Ship Order"; Decimal)
        {
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Outstanding (Base)" where("Item No." = field("No."),
                                                                                         "Variant Code" = field("Variant Code"),
                                                                                         "Location Code" = field("Location Code")));
            Caption = 'Item Qty. on Whse. Ship Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(70067; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            AccessByPermission = TableData 110 = R;
            Caption = 'Shipping Advice';
            FieldClass = FlowField;
            CalcFormula = lookup("Sales Header"."Shipping Advice" where("Document Type" = field("Document Type"), "No." = field("Document No.")));
        }
        field(70068; "Whse. Ship. Exists"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Warehouse Shipment Line" where("Source Type" = const(37),
                                                                 "Source Subtype" = field("Document Type"),
                                                                 "Source No." = field("Document No."),
                                                                 "Source Line No." = field("Line No.")));
            Caption = 'Whse. Ship. Exists';
            Editable = false;
        }
        field(70069; AGP_KGK_SOC_IsTransportRow; Boolean)
        {
            Caption = 'Is Transport Row';
        }
    }
}