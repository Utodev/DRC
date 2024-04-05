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
		BlockedOrdinal : Longint;
	END;	

VAR Connections : TPConnectionList;	
	BlockableCount : Byte;

PROCEDURE AddConnection(VAR AConnectionList:TPConnectionList; AFromLoc, AToLoc, ADirection: Longint; ABlockable: boolean; ABlocked: boolean);
FUNCTION FindConnection(AConnectionList:TPConnectionList; AFromLoc, AToLoc, ADirection: Longint; ABlockable, ABlocked: Boolean; Strict: boolean=true):boolean;
FUNCTION getConnectionOrdinalFromString(AString: String): Longint;

IMPLEMENTATION

USES UMessageList, UVocabularyTree, sysutils, uConstants;

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
		if (ABlockable) THEN AConnectionList^.BlockedOrdinal := BlockableCount ELSE AConnectionList^.BlockedOrdinal := -1;
		if (ABlockable) THEN BlockableCount := BlockableCount + 1;
		AConnectionList^.Next := nil;
	END  
END;


FUNCTION FindConnection(AConnectionList:TPConnectionList; AFromLoc, AToLoc, ADirection: Longint; ABlockable, ABlocked: Boolean; Strict: boolean=true):boolean;
BEGIN
	IF AConnectionList = nil THEN Result := false
	ELSE 
	IF (AConnectionList^.ToLoc = AToLoc) 
	   AND (AConnectionList^.FromLoc = AFromLoc) 
	   AND (AConnectionList^.Direction=ADirection)
	   AND (AConnectionList^.Blockable = ABlockable)
	   AND ((AConnectionList^.Blocked = ABlocked) OR (NOT Strict))
	   THEN Result := true
	ELSE Result := FindConnection(AConnectionList^.Next, AFromLoc, AToLoc, ADirection, ABlockable, ABlocked, Strict);   
END;

FUNCTION getConnectionOrdinalFromString(AString: String): Longint;
var p1, p2, p3: string;
	SpaceCount: Byte;
	PreservedString: String;
	FromLoc, ToLoc, Direction: Longint;
	AuxVocabularyTree :  TPVocabularyTree;
	AuxConnections : TPConnectionList;
BEGIN
	PreservedString := AString;
	SpaceCount := 0;

	// Check if three parameters are present
	WHILE ((pos(' ', AString) > 0) AND (SpaceCount<=2)) DO
	BEGIN
		delete(AString, 1, pos(' ', AString));
		SpaceCount := SpaceCount + 1;
	END;
	if (SpaceCount > 2) THEN // If more than 3, fails
	BEGIN
		Result := MAXLONGINT;
		Exit;
	END;

	// Extract the three parameters
	p1 := copy(PreservedString, 1, pos(' ', PreservedString)-1);
	delete(PreservedString, 1, pos(' ', PreservedString));
	p2 := copy(PreservedString, 1, pos(' ', PreservedString)-1);
	delete(PreservedString, 1, pos(' ', PreservedString));
	p3 := PreservedString;

	// Convert the first and third parameters to integers
	TRY
    	FromLoc := StrToInt(p1);
  	EXCEPT
    ON E : EConvertError do
	BEGIN
        Result := MAXLONGINT;		// If the conversion fails, return MAXLONGINT (failure signal)
		Exit;
	END;	
  	END;
	if (FromLoc<0) OR (FromLoc>LTXCount) THEN
	BEGIN
		Result := MAXLONGINT; // If the location is out of range, return MAXLONGINT (failure signal)
		Exit;
	END;

		TRY
    	ToLoc := StrToInt(p3);
  	EXCEPT
    ON E : EConvertError do
	BEGIN
        Result := MAXLONGINT;// If the conversion fails, return MAXLONGINT (failure signal)
		Exit;
	END;		
  	END;
	if (ToLoc<0) OR (ToLoc>LTXCount) THEN
	BEGIN
		Result := MAXLONGINT;// If the location is out of range, return MAXLONGINT (failure signal)
		Exit;
	END;

	// Convert the second parameter to a direction using the vocabulary table
	p2 := Copy(p2,1,VOCABULARY_LENGTH);
	AuxVocabularyTree := GetVocabulary(VocabularyTree, p2, VOC_ANY);
	IF (AuxVocabularyTree=nil) THEN
	BEGIN
		Result := MAXLONGINT;  // If not found, fails
		Exit;
	END;
	IF  (NOT (AuxVocabularyTree^.VocType IN [VOC_VERB,VOC_NOUN]) OR ((AuxVocabularyTree^.VocType = VOC_NOUN) AND (AuxVocabularyTree^.Value>MAX_CONVERTIBLE_NAME)) ) THEN 
	BEGIN
		Result := MAXLONGINT; // If found, but not a verb or a convertible noun, fails
		Exit;
	END;
	// Get the Direction value
	Direction := AuxVocabularyTree^.Value;
			


	// Search for the connection to get the ordinal
	AuxConnections := Connections;
	WHILE (AuxConnections<>nil) AND ((AuxConnections^.FromLoc<>FromLoc) OR (AuxConnections^.ToLoc<>ToLoc) OR (AuxConnections^.Direction<>Direction)) DO AuxConnections := AuxConnections^.Next;
	IF (AuxConnections<>nil) THEN Result := AuxConnections^.BlockedOrdinal // And return ordinal if found
	ELSE Result := MAXLONGINT; // or fail if not
END;

BEGIN
 BlockableCount := 0;
END.			     