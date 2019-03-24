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

PROCEDURE AddMessage(VAR AMessageList:TPMessageList; AMessageID: Longint; AText: AnsiString);			     

IMPLEMENTATION

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


END.			     