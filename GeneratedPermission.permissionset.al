permissionset 70065 AGP_KGK_SOC_GenPerm
{
    Assignable = true;
    Permissions = tabledata AGP_KGK_SOC_OrderFeeShpmnt = RIMD,
        table AGP_KGK_SOC_OrderFeeShpmnt = X,
        codeunit SCOFunctions = X,
        page "Order Fee Shipment Method" = X,
        codeunit AGP_KGK_SOC_InvoiceSalesJob = X,
        codeunit AGP_KGK_SOC_ShipSalesJob = X;
}