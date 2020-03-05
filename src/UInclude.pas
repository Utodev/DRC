UNIT UInclude;

{$MODE OBJFPC}



INTERFACE

TYPE TIncludeData = record
					OriginalLine: longint;
					originalFileName: AnsiString;
				   end;

VAR IncludeList: array of TIncludeData;				   	


(* Adds a new line *)
PROCEDURE AddLine(AMainLine: Longint; IncludeData: TIncludeData);

FUNCTION GetIncludeData(AMainLine: Longint): TIncludeData;

(* Returns the value of a Symbol or MAXLONGINT if it does not exist) *)

IMPLEMENTATION

PROCEDURE AddLine(AMainLine: Longint; IncludeData: TIncludeData);
BEGIN
	SetLength(IncludeList, AMainLine);
	IncludeList[AMainLine-1] := IncludeData;
END;

FUNCTION GetIncludeData(AMainLine: Longint): TIncludeData;
BEGIN
   Result := IncludeList[AMainLine-1];
END;


END.