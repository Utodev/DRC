UNIT UConnections;
{$MODE OBJFPC}

INTERFACE


TYPE TPConnectionList = ^TConnectionList;

	TConnectionList = RECORD
		FromLoc: Longint;
		ToLoc : Longint;
		Direction : Longint;
		Next : TPConnectionList;
	END;	

VAR Connections : TPConnectionList;	

PROCEDURE AddConnection(VAR AConnectionList:TPConnectionList; AFromLoc, AToLoc, ADirection: Longint);
FUNCTION FindConnection(AConnectionList:TPConnectionList; AFromLoc, AToLoc, ADirection: Longint):boolean;

IMPLEMENTATION

PROCEDURE AddConnection(VAR AConnectionList:TPConnectionList; AFromLoc, AToLoc, ADirection: Longint);
BEGIN
	IF AConnectionList <> nil THEN AddConnection(AConnectionList^.Next, AFromLoc, AToLoc, ADirection)
	ELSE
	BEGIN
		New(AConnectionList);
		AConnectionList^.FromLoc := AFromLoc;
		AConnectionList^.ToLoc := AToLoc;
		AConnectionList^.Direction := ADirection;
		AConnectionList^.Next := nil;
	END  
END;


FUNCTION FindConnection(AConnectionList:TPConnectionList; AFromLoc, AToLoc, ADirection: Longint):boolean;
BEGIN
	IF AConnectionList = nil THEN Result := false
	ELSE 
	IF (AConnectionList^.ToLoc = AToLoc) 
	   AND (AConnectionList^.FromLoc = AFromLoc) 
	   AND (AConnectionList^.Direction=ADirection)
	   THEN Result := true
	ELSE Result := FindConnection(AConnectionList^.Next, AFromLoc, AToLoc, ADirection);   
END;

END.			     