tableextension 50100 SalesLineTableExt extends "Sales Line"
{
    fields
    {
        field(50110; "SalesLineCount"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = Count("Sales Line" WHERE("No." = FIELD("No.")));
        }
    }
}
