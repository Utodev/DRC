UNIT UObjects;
{$MODE OBJFPC}

INTERFACE


TYPE TPObjectList = ^TObjectList;

	TObjectList = RECORD
		Value: Longint;
		Noun, Adjective : Longint;
		Container, Wearable :  Boolean;
		Weight, InitialyAt : Longint;
		Flags :  Word;
		Next : TPObjectList;
	END;	

VAR ObjectList : TPObjectList;	

PROCEDURE AddObject(VAR AObjectList:TPObjectList; AValue, ANoun, AnAdjective, AWeight, AnInitiallyAt : Longint; SomeFlags : Word; AContainer, AWearable : Boolean);

FUNCTION FindObject(AObjectList:TPObjectList; ANoun, AnAdjective : Longint):boolean;

IMPLEMENTATION

PROCEDURE AddObject(VAR AObjectList:TPObjectList; AValue, ANoun, AnAdjective, AWeight, AnInitiallyAt : Longint; SomeFlags : Word; AContainer, AWearable : Boolean);
BEGIN
	IF AObjectList <> nil THEN AddObject(AObjectList^.Next, AValue, ANoun, AnAdjective, AWeight, AnInitiallyAt, SomeFlags, AContainer, AWearable)
	ELSE
	BEGIN
		New(AObjectList);
		AObjectList^.Value := AValue;
		AObjectList^.InitialyAt := AnInitiallyAt;
		AObjectList^.Weight := AWeight;
		AObjectList^.Container := AContainer;
		AObjectList^.Wearable := AWearable;
		AObjectList^.Flags := SomeFlags;
		AObjectList^.Noun := ANoun;
		AObjectList^.Adjective := AnAdjective;
		AObjectList^.Next := nil;
	END  
END;


FUNCTION FindObject(AObjectList:TPObjectList; ANoun, AnAdjective : Longint):boolean;
BEGIN
	IF AObjectList = nil THEN Result := false
	ELSE 
	IF (AObjectList^.Noun = ANoun) AND (AObjectList^.Adjective = AnAdjective) THEN Result := true
	ELSE Result := FindObject(AObjectList^.Next, ANoun, AnAdjective);   
END;

END.			     