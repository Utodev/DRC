UNIT UProcess;
{$MODE OBJFPC}

INTERFACE


USES UProcessCondactList, UConstants;


TYPE TPProcessEntryList = ^TProcessEntryList;

	TProcessEntryList = RECORD
		Verb, Noun : Longint;
		SkipLabel: AnsiString;
		Condacts : TPProcessCondactList;
		Next : TPProcessEntryList;
	END;	

	TProcess =  RECORD
		Value :	Longint;
		Entries : TPProcessEntryList
	END;

VAR Processes : ARRAY [0..MAX_PROCESSES] OF TProcess;
	LastProcess : Longint;

PROCEDURE InitializeProcesses();

PROCEDURE AddProcessEntry(VAR AProcessEntryList:TPProcessEntryList; AVerb, ANoun : Longint; ACondacts : TPProcessCondactList);

IMPLEMENTATION

PROCEDURE InitializeProcesses();
VAR i : integer;
BEGIN
 FOR i:= 0 to MAX_PROCESSES DO
 BEGIN
 	Processes[i].Value := i;
 	Processes[i].Entries := nil;
 END;
END;

PROCEDURE AddProcessEntry(VAR AProcessEntryList:TPProcessEntryList; AVerb, ANoun : Longint; ACondacts : TPProcessCondactList);
BEGIN
	IF AProcessEntryList <> nil THEN AddProcessEntry(AProcessEntryList^.Next, AVerb, ANoun, ACondacts)
	ELSE
	BEGIN
		New(AProcessEntryList);
		AProcessEntryList^.Verb := Averb;
		AProcessEntryList^.Noun := ANoun;
		AProcessEntryList^.Condacts := ACondacts;
		AProcessEntryList^.Next := nil;
	END  
END;

END.			     
