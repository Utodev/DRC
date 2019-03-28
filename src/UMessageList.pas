UNIT UMessageList;

{$MODE OBJFPC}

INTERFACE

TYPE TPMessageList = ^TMessageList;

     TMessageList = record
				MessageID: Longint;
				Text : AnsiString ;
				Next : TPMessageList;
			  end;

var MTX, STX, LTX, OTX : TPMessageList;	
	MTXCount, STXCount, LTXCount, OTXCount : Longint;		  

FUNCTION insertMessageFromProcess(Var Opcode: Longint; AText : AnsiString; ClassicMode: Boolean ): Longint;

PROCEDURE AddMessage(VAR AMessageList:TPMessageList; AMessageID: Longint; AText: AnsiString);			     

IMPLEMENTATION


Uses UConstants;

PROCEDURE AddMessage(VAR AMessageList:TPMessageList; AMessageID: Longint; AText: AnsiString);			     
BEGIN
	IF AMessageList <> nil THEN AddMessage(AMessageList^.Next, AMessageID, AText)
	ELSE
	BEGIN
		New(AMessageList);
		AMessageList^.MessageID := AMessageID;
		AMessageList^.Text := AText;
		AMessageList^.Next := nil;
	END  
END;


FUNCTION insertMessageFromProcessIntoSpecificList(VAR AMessageList: TPMessageList; Var AText : AnsiString ): Longint;
VAR TmpMessageList : TPMessageList;
	LastMessageID : longint;
BEGIN
    IF (AMessageList = nil) THEN
	BEGIN
		AddMessage(AMessageList, 0, AText);
		Result := 0;
	END
	ELSE
	BEGIN
		TmpMessageList := AMessageList;
		WHILE (TmpMessageList <> nil)  DO
		BEGIN
			IF (AText = TmpMessageList^.Text) THEN 
			BEGIN
				Result := TmpMessageList^.MessageID;
				exit;
			END;
			LastMessageID := TmpMessageList^.MessageID;
			TmpMessageList := TmpMessageList^.next;
		END;
		If LastMessageID = MAX_MESSAGES_PER_TABLE-1 THEN
		BEGIN
		  Result := Maxint; // Return Maxint to signal error
		  exit;
		END;
		AddMessage(AMessageList, LastMessageID + 1, AText);
		Result :=  LastMessageID + 1;
	END;
END;

FUNCTION insertMessageFromProcess(Var Opcode: Longint; AText : AnsiString; ClassicMode: Boolean ): Longint;
VAR MessageID : Longint;
BEGIN
  // First try to do it with the proper message list
  IF Opcode =  SYSMESS_OPCODE THEN MessageID := insertMessageFromProcessIntoSpecificList(STX, AText) 
							   ELSE MessageID := insertMessageFromProcessIntoSpecificList(MTX, AText);
  if (MessageID<MAX_MESSAGES_PER_TABLE)THEN 
  BEGIN
   Result := MessageID;
   exit;
  END;
	if (ClassicMode) THEN
  BEGIN
   Result := Maxint;
   exit;
  END;


  // There was no room for the message in the proper table, so lets try in the other message table (STX/MTX)
  IF Opcode = MESSAGE_OPCODE THEN AText := AText + '\n'; // If it was MESSAGE, add a carriage return as other condacts don't add it

  IF Opcode =  SYSMESS_OPCODE THEN MessageID := insertMessageFromProcessIntoSpecificList(MTX, AText) 
							   ELSE MessageID := insertMessageFromProcessIntoSpecificList(STX, AText);
  if (MessageID<MAX_MESSAGES_PER_TABLE) THEN 
  BEGIN
   IF Opcode = SYSMESS_OPCODE THEN Opcode := MES_OPCODE ELSE Opcode := SYSMESS_OPCODE; // Change the condact
   Result := MessageID;
   exit;
  END;
  // Finally, if both STX and MTX are full, try to use /LTX and DESC opcode
  MessageID := insertMessageFromProcessIntoSpecificList(LTX, AText);
  Opcode := DESC_OPCODE;
  Result := MessageID;
END;


END.			     