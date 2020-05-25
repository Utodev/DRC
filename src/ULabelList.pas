UNIT ULabelList;

{$MODE OBJFPC}



INTERFACE

USES UConstants;


TYPE TLabelData = record
    				SkipLabel: AnsiString;
	    			Process: Word;
                    Entry: Longint;
                    IsForward : Boolean;
			       end;

VAR LabelList : array[0..MAX_LABELS-1] of TLabelData;
VAR NextFreeLabelSlot : Longint;

(* Adds a new Label and returns index if succcesful, otherwise (basically cause label already exists) returns false *)
(* IsForward lets the system know the label is being added from a SKIP, so the Process/Entry values are false *)
FUNCTION AddLabel(ALabel: AnsiString; AProcess: Longint; AEntry : Longint; IsForward: Boolean):longint;

(* Returns TLabelData value for the requested label, if it exists returns the Array index as function value , otherwise returns -1 and TLabelData returned is not valid *)
FUNCTION GetLabelData(ALabel: AnsiString; var ALabelData:TLabelData): Longint;

IMPLEMENTATION

uses sysutils;

FUNCTION AddLabel(ALabel: AnsiString; AProcess: Longint; AEntry : Longint; IsForward: Boolean):longint;
VAR i: Longint;
 BEGIN
    Result := -1;

    FOR i:= 0 to NextFreeLabelSlot - 1 DO 
        IF(LabelList[i].SkipLabel = ALabel) THEN
        BEGIN
            IF (LabelList[i].IsForward and NOT IsForward) THEN // Time to update the data with real value
            BEGIN
                LabelList[i].Process := AProcess;
                LabelList[i].Entry := AEntry;
                LabelList[i].IsForward := false;
                Result := i; Exit;
            END;

            IF (LabelList[i].IsForward and IsForward)  THEN // One more forward reference
            BEGIN
                Result := i; Exit;
            END;        

            Result := - 1;              // Repeated non forward declaration
            Exit;
        END;

    // If we got here, the label is new

    // Let's first check if there is room for another one
    IF (NextFreeLabelSlot = MAX_LABELS) THEN
    BEGIN
     Result := i; Exit;  // Too many labels
    END;        

    // let's add a new one

    LabelList[NextFreeLabelSlot].SkipLabel := ALabel;
    LabelList[NextFreeLabelSlot].Process := AProcess;
    LabelList[NextFreeLabelSlot].Entry := AEntry;
    LabelList[NextFreeLabelSlot].IsForward := IsForward;
    Result := NextFreeLabelSlot;
    Inc(NextFreeLabelSlot);
END;	

FUNCTION GetLabelData(ALabel: AnsiString; var ALabelData:TLabelData): Longint;
VAR i : Longint;
BEGIN
    Result := -1;
    FOR i := 0 to NextFreeLabelSlot -1 DO
     IF (LabelList[i].SkipLabel = ALabel) AND (NOT LabelList[i].IsForward) THEN
     BEGIN
        ALabelData.Process := LabelList[i].Process;
        ALabelData.Entry := LabelList[i].Entry;
        ALabelData.SkipLabel := ALabel;
        Result := i;
     END;
END;

BEGIN
    NextFreeLabelSlot := 0;
END.