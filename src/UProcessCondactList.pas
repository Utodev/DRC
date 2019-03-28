UNIT UProcessCondactList;
{$MODE OBJFPC}

INTERFACE

USES UConstants;



TYPE TParam =  RECORD
				Value : Longint;
				Indirection : boolean;
			   END;	

	TCondactParams = ARRAY [0 .. MAX_CONDACT_PARAMS - 1] OF TParam;


	TPProcessCondactList = ^TProcessCondactList;

	TProcessCondactList = RECORD
		Opcode: Longint;
		IsDB : boolean; // Fake condact coming from a #DB pseudo-opcode
		NumParams : Byte;
		Params : TCondactParams;
		Next : TPProcessCondactList;
	END;	


PROCEDURE AddProcessCondact(VAR AProcessCondactList:TPProcessCondactList; AOpcode: Longint; ANumParams: Byte; SomeParams: TCondactParams; IsDB: boolean);

IMPLEMENTATION

PROCEDURE AddProcessCondact(VAR AProcessCondactList:TPProcessCondactList; AOpcode: Longint; ANumParams: Byte; SomeParams: TCondactParams; IsDB: boolean);
VAR i : integer;
BEGIN
	IF AProcessCondactList <> nil THEN AddProcessCondact(AProcessCondactList^.Next, AOpcode, ANumParams, SomeParams, IsDB)
	ELSE
	BEGIN
		New(AProcessCondactList);
		AProcessCondactList^.Opcode := AOpcode;
		AProcessCondactList^.NumParams := ANumParams;
		AProcessCondactList^.IsDB := IsDB;

		FOR i:=0 TO MAX_CONDACT_PARAMS - 1 DO 
		BEGIN
			AProcessCondactList^.Params[i].Value := SomeParams[i].Value;
			AProcessCondactList^.Params[i].Indirection := SomeParams[i].Indirection;
		END;
		AProcessCondactList^.Next := nil;
	END  
END;



END.			     