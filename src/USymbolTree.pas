UNIT USymbolTree;

{$MODE OBJFPC}


INTERFACE


TYPE TPSymbolTree = ^TSymbolTree;

     TSymbolTree = record
				Symbol: AnsiString;
				Value: Longint;
				Right : TPSymbolTree;
				Left : TPSymbolTree;
			  end;

VAR SymbolTree : TPSymbolTree;

(* Adds a new symbol and returns true if succcesful, otherwise (basically cause symbol already exists) returns false *)
FUNCTION AddSymbol(VAR ASymbolTree: TPSymbolTree; ASymbol: AnsiString; AValue : Longint):boolean;

(* Returns the value of a Symbol or MAXINT if it does not exist) *)
FUNCTION GetSymbolValue(ASymbolTree: TPSymbolTree; ASymbol: AnsiString): Longint;

IMPLEMENTATION

uses sysutils;

FUNCTION AddSymbol(VAR ASymbolTree: TPSymbolTree; ASymbol: AnsiString; AValue : Longint):boolean;
BEGIN
	ASymbol := AnsiUpperCase(ASymbol);
	IF (ASymbolTree <> nil) THEN
	BEGIN
	  IF (ASymbol > ASymbolTree^.Symbol) THEN Result := AddSymbol(ASymbolTree^.Right, ASymbol, AValue)
	  ELSE IF (ASymbol < ASymbolTree^.Symbol) THEN Result := AddSymbol(ASymbolTree^.Left, ASymbol, AValue)
	  ELSE Result := false;
	 END
	 ELSE
	 BEGIN
	 	New(ASymbolTree);
	 	ASymbolTree^.Symbol := ASymbol;
	 	ASymbolTree^.Value := AValue;
	 	ASymbolTree^.Left := nil;
	 	ASymbolTree^.Right := nil;
	 	Result := true;
	 END;
END;

FUNCTION GetSymbolValue(ASymbolTree: TPSymbolTree; ASymbol: AnsiString): Longint;
BEGIN
	ASymbol := AnsiUpperCase(ASymbol);
	IF (ASymbolTree = nil) THEN Result:= MAXINT
	ELSE
	IF (ASymbolTree^.Symbol = ASymbol) THEN Result := ASymbolTree^.Value ELSE
	IF (ASymbolTree^.Symbol > ASymbol) THEN Result := GetSymbolValue(ASymbolTree^.Left, ASymbol)
	ELSE Result := GetSymbolValue(ASymbolTree^.Right, ASymbol);
END;

END.