UNIT USymbolList;

{$MODE OBJFPC}


INTERFACE


TYPE TPSymbolList = ^TSymbolList;

     TSymbolList = record
				Symbol: AnsiString;
				Value: Longint;
				Next : TPSymbolList;
			  end;

VAR SymbolList : TPSymbolList;

(* Adds a new symbol and returns true if succcesful, otherwise (basically cause symbol already exists) returns false *)
FUNCTION AddSymbol(VAR ASymbolList: TPSymbolList; ASymbol: AnsiString; AValue : Longint):boolean;

(* Returns the value of a Symbol or MAXLONGINT if it does not exist) *)
FUNCTION GetSymbolValue(ASymbolList: TPSymbolList; ASymbol: AnsiString): Longint;

IMPLEMENTATION

uses sysutils, UConstants;

FUNCTION AddSymbol(VAR ASymbolList: TPSymbolList; ASymbol: AnsiString; AValue : Longint):boolean;
BEGIN
	ASymbol := AnsiUpperCase(ASymbol);
	if (ASymbolList = nil) THEN
	BEGIN
		New(ASymbolList);
		ASymbolList^.Symbol := ASymbol;
		ASymbolList^.Value := AValue;
		ASymbolList^.Next := nil;
		Result := true;
		IF Verbose AND (Copy(ASymbol, 1, 4)<>'_VOC') then WriteLn('Added Symbol: ', ASymbol, '=', Avalue);
	END 
	ELSE
	BEGIN
	 IF ASymbolList^.Symbol = AnsiUpperCase(ASymbol) THEN Result := false  // Symbol duplicated
	 ELSE Result := AddSymbol(ASymbolList^.Next, ASymbol, AValue);
	END; 
END;	

FUNCTION GetSymbolValue(ASymbolList: TPSymbolList; ASymbol: AnsiString): Longint;
BEGIN
	ASymbol := AnsiUpperCase(ASymbol);
	IF (ASymbolList = nil) THEN Result:= MAXLONGINT
	ELSE IF ASymbolList^.Symbol = ASymbol THEN Result := ASymbolList^.Value
	 ELSE Result := GetSymbolValue(ASymbolList^.Next, ASymbol);
END;

END.