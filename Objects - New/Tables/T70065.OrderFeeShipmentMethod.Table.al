table 70065 AGP_KGK_SOC_OrderFeeShpmnt // 50011
{
    fields
    {
        field(1; "Transport Time"; Time)
        {
            DataClassification = CustomerContent;
            Caption = 'Transport Time';
        }
        field(2; "Location Code"; Code[10])
        {
            TableRelation = Location.Code;
            DataClassification = CustomerContent;
            Caption = 'Location Code';
        }
        field(3; "Shipment Method Code"; Code[10])
        {
            TableRelation = "Shipment Method".Code;
            DataClassification = CustomerContent;
            Caption = 'Shipment Method Code';
        }
        field(4; "Resource Code"; Code[20])
        {
            TableRelation = Resource."No.";
            DataClassification = CustomerContent;
            Caption = 'Resource Code';
        }
        field(5; "Small Order Fee"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Small Order Fee';
        }
    }

    keys
    {
        key(Key1; "Transport Time", "Location Code", "Shipment Method Code")
        {
            Clustered = true;
        }
    }
}