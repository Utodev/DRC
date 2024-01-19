UNIT UConnections;
{$MODE OBJFPC}

INTERFACE


TYPE TPConnectionList = ^TConnectionList;

	TConnectionList = RECORD
		FromLoc: Longint;
		ToLoc : Longint;
		Direction : Longint;
		Blockable : boolean;
		Blocked : boolean;
		Next : TPConnectionList;
	END;	

VAR Connections : TPConnectionList;	

PROCEDURE AddConnection(VAR AConnectionList:TPConnectionList; AFromLoc, AToLoc, ADirection: Longint; ABlockable: boolean; ABlocked: boolean);
FUNCTION FindConnection(AConnectionList:TPConnectionList; AFromLoc, AToLoc, ADirection: Longint; ABlockable, ABlocked: Boolean):boolean;

IMPLEMENTATION

PROCEDURE AddConnection(VAR AConnectionList:TPConnectionList; AFromLoc, AToLoc, ADirection: Longint; ABlockable: boolean; ABlocked: boolean);
BEGIN
	IF AConnectionList <> nil THEN AddConnection(AConnectionList^.Next, AFromLoc, AToLoc, ADirection, ABlockable, ABlocked)
	ELSE
	BEGIN
		New(AConnectionList);
		AConnectionList^.FromLoc := AFromLoc;
		AConnectionList^.ToLoc := AToLoc;
		AConnectionList^.Direction := ADirection;
		AConnectionList^.Blockable := ABlockable;
		AConnectionList^.Blocked := ABlocked;
		AConnectionList^.Next := nil;
	END  
END;


FUNCTION FindConnection(AConnectionList:TPConnectionList; AFromLoc, AToLoc, ADirection: Longint; ABlockable, ABlocked: Boolean):boolean;
BEGIN
	IF AConnectionList = nil THEN Result := false
	ELSE 
	IF (AConnectionList^.ToLoc = AToLoc) 
	   AND (AConnectionList^.FromLoc = AFromLoc) 
	   AND (AConnectionList^.Direction=ADirection)
	   AND (AConnectionList^.Blockable = ABlockable)
	   AND (AConnectionList^.Blocked = ABlocked)
	   THEN Result := true
	ELSE Result := FindConnection(AConnectionList^.Next, AFromLoc, AToLoc, ADirection, ABlockable, ABlocked);   
END;

END.			     