UNIT USintactic;
{$MODE OBJFPC}

INTERFACE

USES UTokenList;

PROCEDURE Sintactic();

var ClassicMode : Boolean;



IMPLEMENTATION

USES sysutils, UConstants, ULexTokens, USymbolTree, UVocabularyTree, UMessageList, UCondacts, UConnections, UObjects, UProcess, UProcessCondactList, UCTLExtern;

VAR CurrentText: AnsiString;
	CurrentIntVal : Longint;
	CurrentTokenID : Word;
	CurrLineno : Longint;
	CurrColno : Word;
	CurrTokenPTR: TPTokenList;
	OnIfdefMode : boolean;
	OnElse : boolean;



PROCEDURE SyntaxError(msg: String);
BEGIN
  Writeln(CurrLineno,':', CurrColno, ': ', msg,'.');
  Halt(1);
END;


PROCEDURE Scan();
VAR MyDefine : AnsiString;
	Evaluation : Boolean;
	Label NextIfdef, ElsePoint,ELSEDoNotProcess ;
BEGIN
	IF (CurrTokenPTR=nil) then SyntaxError('Unexpected end of file');
	CurrentTokenID := CurrTokenPTR^.TokenID;


	// Apply IFDEF/IFNDEF
	IF (CurrentTokenID=T_IFDEF) OR (CurrentTokenID=T_IFNDEF) THEN
	BEGIN
	 NextIfdef:
	 if CurrTokenPTR^.Next = nil THEN SyntaxError('Unexpected end of file just after #ifdef/#ifndef');
	 CurrTokenPTR := CurrTokenPTR^.Next;
	 if CurrTokenPTR^.TokenID <> T_STRING THEN SyntaxError('Invalid #ifdef/#ifndef label, please include the label in betwween quotes');
	 MyDefine := CurrTokenPTR^.Text;
	 MyDefine := Copy(MyDefine, 2, Length(MyDefine) - 2);
	 Evaluation:= GetSymbolValue(SymbolTree, MyDefine)<>MAXINT;
	 IF CurrentTokenID = T_IFNDEF THEN Evaluation:= not Evaluation;

	 // IF directive failed, skip code until ENDIF or ELSE
	 IF NOT Evaluation THEN
	 BEGIN
	 	ELSEDoNotProcess:
		CurrTokenPTR := CurrTokenPTR^.Next;
	 	WHILE (CurrTokenPTR<>nil) AND (CurrTokenPTR^.TokenID<>T_ENDIF)  AND (CurrTokenPTR^.TokenID<>T_ELSE) DO 
		 BEGIN
		 	CurrTokenPTR := CurrTokenPTR^.Next;
			CurrentTokenID := CurrTokenPTR^.TokenID;
		END;	 
		IF (CurrTokenPTR=nil) THEN SyntaxError('Unexpected end of file. #ifdef/#ifndef couldn''t find #endif while in failed condition');
		
		IF (CurrentTokenID=T_ELSE) AND (NOT OnElse) THEN 
		BEGIN
		 OnElse := true;
		 GOTO ElsePoint;
		END; 
		IF (CurrentTokenID=T_ELSE) AND (OnElse) THEN SyntaxError('Nested #else');			
	 	CurrTokenPTR:= CurrTokenPTR^.Next;
	 	IF (CurrTokenPTR=nil) THEN SyntaxError('Unexpected end of file. #ifdef/#ifndef couldn''t find #endif while in failed condition');
	 	CurrentTokenID := CurrTokenPTR^.TokenID;
		IF ((CurrentTokenID = T_IFDEF) OR (CurrentTokenID = T_IFNDEF)) THEN goto NextIfdef;
	 END 
	 ELSE
	 BEGIN
	  ElsePoint:
	 	CurrTokenPTR:= CurrTokenPTR^.Next;
	 	IF (CurrTokenPTR=nil) THEN SyntaxError('Unexpected end of file. #ifdef/#ifndef(#else) couldn''t find #endif while in successful condition');
	 	CurrentTokenID := CurrTokenPTR^.TokenID;
	 	OnIfdefMode := true;
	 END;
	END;

	//Apply ELSE
	IF (CurrentTokenID=T_ELSE) THEN 
	BEGIN
    OnElse := true;
	  Goto ELSEDoNotProcess;
	END;	

	// Apply ENDIF
	IF (CurrentTokenID=T_ENDIF) THEN
	BEGIN
	  IF  OnIfdefMode THEN 
	  BEGIN
	 		CurrTokenPTR:= CurrTokenPTR^.Next;
	 		CurrentTokenID := CurrTokenPTR^.TokenID;
	  	OnIfdefMode:=false;
			OnElse := false;
			if ((CurrentTokenID = T_IFDEF) OR (CurrentTokenID = T_IFNDEF)) THEN goto NextIfdef;
	  END ELSE SyntaxError('#endif without #ifdef/#ifndef');
	END;


	CurrentText := CurrTokenPTR^.Text;

	CurrentIntVal := CurrTokenPTR^.IntVal;
	CurrLineno := CurrTokenPTR^.lineno;
	CurrColno := CurrTokenPTR^.colno;
	CurrTokenPTR := CurrTokenPTR^.Next;
END;

FUNCTION GetIdentifierValue(): Longint;
VAR Value : Longint;
BEGIN
	IF (CurrentTokenID = T_NUMBER) THEN Result := CurrentIntVal ELSE
	BEGIN
		Value := GetSymbolValue(SymbolTree,CurrentText);
		Result := Value;
	END;
END;

PROCEDURE ParseDefine();
VAR Symbol : AnsiString;
	Value : Longint;	
BEGIN
	Scan();
	if (CurrentTokenID<>T_IDENTIFIER) THEN SyntaxError('Identifier expected');
	Symbol := CurrentText;
	Scan();
	IF (CurrentTokenID=T_NUMBER) OR (CurrentTokenID= T_IDENTIFIER) THEN Value := GetIdentifierValue();
	IF (Value = MAXINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
	if NOT AddSymbol(SymbolTree, Symbol, Value) THEN SyntaxError('"' + Symbol + '" already defined');
END;

PROCEDURE ParseExtern();
VAR Filename : String;
BEGIN
	Scan();
	IF CurrentTokenID <> T_STRING THEN SyntaxError('Included extern file should be in between quotes');
	FileName := Copy(CurrentText, 2, length(CurrentText) - 2);
	IF NOT FileExists(Filename) THEN SyntaxError('Extern file "'+FileName+'" not found');
	WriteLn('#extern "' + Filename + '" processed.');
	AddCTL_Extern(CTLExternList, FileName); // Adds the file to binary files to be included
END;

PROCEDURE ParseClassic();
BEGIN
 ClassicMode := true;
END;

PROCEDURE ParseCTL();
BEGIN
	Scan();
	IF (CurrentTokenID<>T_SECTION_CTL) THEN SyntaxError('/CTL expected');
	REPEAT
		Scan();
		IF (CurrentTokenID = T_DEFINE) THEN ParseDefine()
		ELSE IF (CurrentTokenID = T_UNDERSCORE) THEN BEGIN END 
		ELSE IF (CurrentTokenID  =T_EXTERN) THEN ParseExtern()
		ELSE IF (CurrentTokenID  =T_CLASSIC) THEN ParseClassic()
		ELSE IF (CurrentTokenID<>T_SECTION_VOC) THEN SyntaxError('#define, #extern, #classic or /VOC expected');
	UNTIL CurrentTokenID = T_SECTION_VOC;
END;

PROCEDURE ParseNewWord();
VAR Value : Longint;
	TheWord : AnsiString;
	TheType :TVocType;
	AuxVocabularyTree: TPVocabularyTree;
BEGIN
	if (Length(CurrentText)>VOCABULARY_LENGTH) THEN TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH) ELSE TheWord := CurrentText;
	AuxVocabularyTree := GetVocabulary(VocabularyTree,TheWord, VOC_ANY);
	if (AuxVocabularyTree <> nil) THEN SyntaxError('Word "' + TheWord +'" already defined');
	Scan();
	IF (CurrentTokenID=T_NUMBER) OR (CurrentTokenID=T_IDENTIFIER) THEN Value := GetIdentifierValue() 
	ELSE SyntaxError('Number or Identifier expected');
	IF (Value = MAXINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
	Scan();
	IF (AnsiUpperCase(CurrentText)='VERB') THEN TheType :=VOC_VERB ELSE
	IF (AnsiUpperCase(CurrentText)='NOUN') THEN TheType :=VOC_NOUN ELSE
	IF (AnsiUpperCase(CurrentText)='ADJECTIVE') THEN TheType :=VOC_ADJECT ELSE
	IF (AnsiUpperCase(CurrentText)='PRONOUN') THEN TheType :=VOC_PRONOUN ELSE
	IF (AnsiUpperCase(CurrentText)='CONJUGATION') THEN TheType :=VOC_CONJUGATION ELSE
	IF (AnsiUpperCase(CurrentText)='PREPOSITION') THEN TheType :=VOC_PREPOSITION ELSE
	IF (AnsiUpperCase(CurrentText)='ADVERB') THEN TheType :=VOC_ADVERB
	ELSE SyntaxError('"' + CurrentText + '" is not a valid vocabulary word type');
	IF NOT AddVocabulary(VocabularyTree, TheWord, Value, TheType) THEN SyntaxError('Vocabulary word already exists or "_VOC_' + TheWord + '" already defined');
END;

PROCEDURE ParseVOC();
BEGIN
	REPEAT
		Scan();
		IF (CurrentTokenID=T_IDENTIFIER) OR (CurrentTokenID=T_NUMBER) THEN ParseNewWord()
		ELSE IF (CurrentTokenID<>T_SECTION_STX) THEN SyntaxError('Vocabulary word definition or /STX expected')
	UNTIL CurrentTokenID =  T_SECTION_STX;
END;

PROCEDURE ParseMessageList(VAR AMessageList: TPMessageList; VAR AMessageCOunter: Longint; TerminatorToken : Word);
VAR Value: Longint;
	Message : AnsiString;
BEGIN
	REPEAT
		Scan();
		IF (CurrentTokenID <> TerminatorToken)  THEN
		BEGIN
			IF (CurrentTokenID<>T_LIST_ENTRY) THEN SyntaxError('Entry number expected');
			Value := CurrentIntVal;
			Scan();
			IF (CurrentTokenID<>T_STRING) THEN SyntaxError('String between quotes expected');
			Message := Copy(CurrentText, 2, Length(CurrentText)-2);
			if (Value<>AMessageCOunter) THEN SyntaxError('Message/Locations/Object numbers must be consecutive');
			if (Value>=MAX_MESSAGES_PER_TABLE) THEN SyntaxError('Message number too high. Maximum message number is ' + IntToStr(MAX_MESSAGES_PER_TABLE-1));
			AddMessage(AMessageList,  Value, Message);
			Inc(AMessageCOunter);
		END;
	UNTIL CurrentTokenID = TerminatorToken;
END;	



PROCEDURE ParseOTX();
BEGIN
	ParseMessageList(OTX, OTXCount, T_SECTION_LTX);
END;

PROCEDURE ParseLTX();
BEGIN
	ParseMessageList(LTX, LTXCount, T_SECTION_CON);
END;


PROCEDURE ParseMTX();
BEGIN
	ParseMessageList(MTX, MTXCount, T_SECTION_OTX);
END;

PROCEDURE ParseSTX();
BEGIN
	ParseMessageList(STX, STXCount, T_SECTION_MTX);
END;

PROCEDURE ParseLocationConnections(Fromloc : Longint);
VAR AuxVocabularyTree: TPVocabularyTree;
	TheWord : AnsiString;
	Direction, ToLoc : Longint;
BEGIN
	REPEAT
		Scan();
		IF (CurrentTokenID<>T_LIST_ENTRY) AND (CurrentTokenID<>T_SECTION_OBJ) THEN
		BEGIN
			IF CurrentTokenID<>T_IDENTIFIER THEN SyntaxError('Connection vocabulary word expected');
			TheWord := Copy(CurrentText,1,VOCABULARY_LENGTH);
			AuxVocabularyTree := GetVocabulary(VocabularyTree, TheWord, VOC_ANY);
			IF (AuxVocabularyTree=nil) THEN SyntaxError('Direction is not defined');
			IF (AuxVocabularyTree^.Value > MAX_DIRECTION_VOCABULARY) 
			   OR (NOT (AuxVocabularyTree^.VocType IN [VOC_VERB,VOC_NOUN])) THEN SyntaxError('Only verbs and nouns with number up to ' + IntToStr(MAX_DIRECTION_VOCABULARY) + ' are valid for connections');
				Direction := AuxVocabularyTree^.Value;
			Scan();
			if (CurrentTokenID <> T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) THEN SyntaxError('Location number expected');
			ToLoc := GetIdentifierValue();
			IF (ToLoc = MAXINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
			IF FindConnection(Connections, FromLoc, ToLoc, Direction) THEN SyntaxError('Connection already defined');
			AddConnection(Connections, FromLoc, ToLoc, Direction);
		END;
	UNTIL (CurrentTokenID=T_LIST_ENTRY) OR (CurrentTokenID = T_SECTION_OBJ);
END;


PROCEDURE ParseCON();
VAR CurrentLoc : Longint;
BEGIN
	CurrentLoc := 0;
	Scan();
	REPEAT 
		IF (CurrentTokenID <> T_LIST_ENTRY) THEN SyntaxError('Location entry expected');
		IF CurrentIntVal<>CurrentLoc THEN SyntaxError('Connections for location #' + IntToStr(CurrentLoc) + ' expected but location #' + IntToStr(CurrentIntVal) + ' found');
		IF (CurrentIntVal>=LTXCount) THEN SyntaxError ('Location ' + IntToStr(CurrentIntVal) + ' is not defined');
		ParseLocationConnections(CurrentLoc);
		Inc(CurrentLoc);
	UNTIL CurrentTokenID = T_SECTION_OBJ;
	IF CurrentLoc < LTXCount THEN SyntaxError('Connections for location #' + IntToStr(CurrentLoc) + ' missing' );
END;	


PROCEDURE ParseOBJ();
VAR CurrentObj : Longint;
	InitialyAt : Longint;
	Weight : Longint;
	Container : Boolean;
	Wearable : Boolean;
	Flags : Word;
	Noun, Adjective : Longint;
	i : integer;
	AuxVocabularyTree :  TPVocabularyTree;
	TheWord : AnsiString;

BEGIN
	CurrentObj := 0;
	REPEAT 
		Scan();
		IF CurrentTokenID <> T_SECTION_PRO THEN
		BEGIN
			IF (CurrentTokenID <> T_LIST_ENTRY) THEN SyntaxError('Object entry expected');
			IF CurrentIntVal<>CurrentObj THEN SyntaxError('Definition for object #' + IntToStr(Currentobj) + ' expected but object #' + IntToStr(CurrentIntVal) + ' found');
			IF (CurrentIntVal>=OTXCount) THEN SyntaxError ('Object #' + IntToStr(CurrentIntVal) + ' not defined');

			Scan(); // Get Initialy At
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) AND (CurrentTokenID<>T_UNDERSCORE) THEN SyntaxError('Object initial location expected');
			IF (CurrentTokenID = T_UNDERSCORE) THEN InitialyAt := LOC_NOT_CREATED
			ELSE
			BEGIN
				InitialyAt:=GetIdentifierValue();
				IF (InitialyAt = MAXINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
			END;	
			IF (InitialyAt >= LTXCount) AND (InitialyAt <> LOC_NOT_CREATED) AND (InitialyAt <> LOC_WORN) AND (InitialyAt <> LOC_CARRIED) THEN SyntaxError('Invalid initial location' + IntToStr(InitialyAt));

			Scan(); // Get Weight
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) THEN SyntaxError('Object weight expected');
			Weight := GetIdentifierValue();
			IF (Weight = MAXINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
			IF (Weight >= MAX_FLAG_VALUE) THEN SyntaxError('Invalid weight');


			Scan(); // Get if container
			IF ((CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_UNDERSCORE))  
			   OR ((CurrentTokenID=T_IDENTIFIER) AND (AnsiUpperCase(CurrentText) <> 'Y') AND (AnsiUpperCase(CurrentText) <> 'N'))
			   THEN SyntaxError('"Y", "N" or "_" expected at container flag');
			Container := (CurrentTokenID=T_IDENTIFIER) AND (AnsiUpperCase(CurrentText) ='Y');

			Scan(); // Get if wearable
			IF ((CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_UNDERSCORE))  
			   OR ((CurrentTokenID=T_IDENTIFIER) AND (AnsiUpperCase(CurrentText) <> 'Y') AND (AnsiUpperCase(CurrentText) <> 'N'))
			   THEN SyntaxError('"Y", "N" or "_" expected at wearable flag');
			Wearable := (CurrentTokenID=T_IDENTIFIER) AND (AnsiUpperCase(CurrentText) ='Y');

			Flags := 0;
			FOR I := 15 DOWNTO 0 DO
			BEGIN
				Scan(); // Get flag
				IF ((CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_UNDERSCORE))  
				   OR ((CurrentTokenID=T_IDENTIFIER) AND (AnsiUpperCase(CurrentText) <> 'Y') AND (AnsiUpperCase(CurrentText) <> 'N'))
				   THEN SyntaxError('"Y", "N" or "_" expected at custom flag #' + IntToStr(i));
				Flags := Flags SHL 1;
				IF (CurrentTokenID=T_IDENTIFIER) AND (AnsiUpperCase(CurrentText) ='Y') THEN Inc(Flags);
			END;			

			Scan(); // Get Noun
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER)  AND (CurrentTokenID<>T_UNDERSCORE) THEN SyntaxError('Vocabulary noun or underscore expected');
			IF (CurrentTokenID=T_UNDERSCORE) THEN Noun := NO_WORD 
			ELSE
			BEGIN
				TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH);
				AuxVocabularyTree := GetVocabulary(VocabularyTree, TheWord, VOC_NOUN);
				IF AuxVocabularyTree = nil THEN SyntaxError('Noun not defined');
				Noun := AuxVocabularyTree^.Value;
			END;

			Scan(); // Get Adject
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) AND (CurrentTokenID<>T_UNDERSCORE) THEN SyntaxError('Vocabulary adjective or underscore character expected');
			IF CurrentTokenID = T_UNDERSCORE THEN Adjective := NO_WORD 
			ELSE
			BEGIN
				TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH);
				AuxVocabularyTree := GetVocabulary(VocabularyTree, TheWord, VOC_ADJECT);
				IF AuxVocabularyTree = nil THEN SyntaxError('Adjective not defined');
				Adjective := AuxVocabularyTree^.Value;
			END;
			AddObject(ObjectList, CurrentObj, Noun, Adjective, Weight, InitialyAt, Flags,  Container, Wearable);
			Inc(CurrentObj);
		END;	
	UNTIL CurrentTokenID = T_SECTION_PRO;
	IF CurrentObj < OTXCount THEN SyntaxError('Definition for object #' + IntToStr(CurrentObj) + ' missing' );
END;

PROCEDURE ParseProcessCondacts(var SomeEntryCondacts :  TPProcessCondactList);
VAR Opcode : Longint;
	CurrentCondactParams : TCondactParams;
	Value : Longint;
	AuxVocabularyPTR : TPVocabularyTree;
	i : integer;
	TheWord : String;
	FileName : String;
	IncludedFile: FILE;
	AuxByte: Byte;
BEGIN
	REPEAT
		Scan(); // Get Condact
		IF (CurrentTokenID <> T_IDENTIFIER)  AND (CurrentTokenID<>T_UNDERSCORE) 
		    AND (CurrentTokenID<>T_SECTION_PRO) AND (CurrentTokenID<>T_SECTION_END) 
		    AND (CurrentTokenID<>T_INCBIN) AND (CurrentTokenID<>T_DB) THEN SyntaxError('Condact or new process entry expected');
		IF (CurrentTokenID<>T_INCBIN) AND (CurrentTokenID<>T_DB) THEN
		BEGIN
			Opcode := GetCondact(CurrentText);
			IF Opcode <> - 1 THEN
			BEGIN
				FOR i:= 0 TO Condacts[Opcode].NumParams - 1 DO
				BEGIN
					Scan();
					CurrentCondactParams[i].Indirection := false;
					IF (CurrentTokenID = T_INDIRECT) THEN
					BEGIN
					  IF I>=MAX_PARAM_ACCEPTING_INDIRECTION THEN SyntaxError('Indirection is not allowed in this parameter');
					  CurrentCondactParams[i].Indirection := true;
					  Scan();
					END;
			
					IF (CurrentTokenID = T_STRING) AND (Opcode in [MESSAGE_OPCODE,MES_OPCODE, SYSMESS_OPCODE]) THEN  
					BEGIN
						CurrentText := Copy(CurrentText, 2, Length(CurrentText)-2);
						CurrentIntVal := insertMessageFromProcess(Opcode, CurrentText, ClassicMode);
	 				  IF CurrentIntVal>=MAX_MESSAGES_PER_TABLE THEN
						BEGIN
						 IF ClassicMode THEN SyntaxError('Too many messages, max messages per message table is ' +  IntToStr(MAX_MESSAGES_PER_TABLE))
						                ELSE SyntaxError('Too many messages, total messages in  MTX, STX and LTX tables, plus "MESSAGE" strings is ' +  IntToStr(3*MAX_MESSAGES_PER_TABLE));
						END;
	 					CurrentTokenID := T_NUMBER;
						Value := CurrentIntVal;
						CurrentText := IntToStr(Value);
					END;
					IF (CurrentTokenID <> T_NUMBER) AND (CurrentTokenID <> T_IDENTIFIER) AND (CurrentTokenID<> T_UNDERSCORE) THEN SyntaxError('Invalid condact parameter');
					Value := GetIdentifierValue();
					IF Value=MAXINT THEN  // Parameter was neither numeric, nor previously defined, let's check if it's a non-verb vocabulary word as last chance
					BEGIN
						IF (CurrentTokenID = T_UNDERSCORE) THEN Value:=NO_WORD
						ELSE
						BEGIN
							TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH);
							AuxVocabularyPTR := GetVocabulary(VocabularyTree, TheWord, VOC_ANY);
							IF AuxVocabularyPTR = nil THEN SyntaxError('Invalid condact parameter');
							Value := AuxVocabularyPTR^.Value;
						END;
					END;
					CurrentCondactParams[i].Value := Value;
				END;
				AddProcessCondact(SomeEntryCondacts, Opcode, Condacts[Opcode].NumParams, CurrentCondactParams, false);
			END;
		END ELSE
		IF CurrentTokenID=T_DB THEN 
		BEGIN
			Scan();
			IF (CurrentTokenID<>T_NUMBER) THEN SyntaxError('DB value should be numeric');
			IF (CurrentIntVal<0) OR (CurrentIntVal>255) THEN SyntaxError('DB value should be between 0 and 255');
			WriteLn('#DB ' + CurrentText + ' processed');
			AddProcessCondact(SomeEntryCondacts,CurrentIntVal , 0, CurrentCondactParams, true); // adds a fake condact, with the DB value as OPCODE and zero parameters
		END
		ELSE 	
		IF CurrentTokenID=T_INCBIN THEN 
		BEGIN
			Scan();
			IF (CurrentTokenID<>T_STRING) THEN SyntaxError('Included file should be in between quotes');
			Filename := Copy(CurrentText, 2, Length(CurrentText)-2);
			IF NOT FileExists(Filename) THEN SyntaxError('Included file "' + FileName + '" not found');
			AssignFile(IncludedFile, Filename);
			Reset(IncludedFile,1);
			WriteLn('#incbin "' + Filename + '" processed.');
			WHILE NOT EOF(IncludedFile) DO
			BEGIN
				BlockRead(IncludedFile, AuxByte, 1);
				AddProcessCondact(SomeEntryCondacts,AuxByte, 0, CurrentCondactParams, true); // Queues one fake condact as DB does above, per byte in the file
			END;
			CloseFile(IncludedFile);
		END;
	UNTIL Opcode = -1;
END;	


PROCEDURE ParseProcessEntries(CurrentProcess: Longint);
VAR TheWord: AnsiString;
	AuxVocabularyTree :  TPVocabularyTree;
	Verb, Noun : Longint;
	EntryCondacts :  TPProcessCondactList;
        ValidVerb : Boolean;
BEGIN
	Scan(); // Get Verb
	REPEAT
		IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_UNDERSCORE) AND (CurrentTokenID<>T_SECTION_PRO) THEN SyntaxError('Vocabulary verb expected');
                IF (CurrentTokenID <> T_SECTION_PRO) THEN
                BEGIN
		  IF (CurrentTokenID = T_UNDERSCORE) THEN Verb := NO_WORD
		  ELSE
		  BEGIN
			  TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH);
                          ValidVerb := false;
			  AuxVocabularyTree := GetVocabulary(VocabularyTree, TheWord, VOC_ANY);
			  IF (AuxVocabularyTree <> nil) THEN
                          BEGIN
                                IF (AuxVocabularyTree^.VocType=VOC_VERB) THEN ValidVerb := true
                                ELSE IF (AuxVocabularyTree^.VocType=VOC_NOUN) AND (AuxVocabularyTree^.Value<=MAX_CONVERTIBLE_NAME) THEN ValidVerb:= true
                          END;
                          IF (NOT ValidVerb) THEN SyntaxError('Verb not defined or invalid condact: ' + TheWord);
			  Verb := AuxVocabularyTree^.Value;
		  END;

		  Scan(); // Get Noun
		  IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_UNDERSCORE) THEN SyntaxError('Vocabulary noun expected');
		  IF (CurrentTokenID = T_UNDERSCORE) THEN Noun := NO_WORD
		  ELSE
		  BEGIN
			  TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH);
			  AuxVocabularyTree := GetVocabulary(VocabularyTree, TheWord, VOC_NOUN);
			  if (AuxVocabularyTree = nil) THEN SyntaxError('Noun not defined');
			  Noun := AuxVocabularyTree^.Value;
		  END;
		  EntryCondacts := nil;
		  ParseProcessCondacts(EntryCondacts);
		  AddProcessEntry(Processes[CurrentProcess].Entries, Verb, Noun, EntryCondacts);
                END;
        UNTIL (CurrentTokenID = T_SECTION_PRO) OR (CurrentTokenID = T_SECTION_END);
END;


PROCEDURE ParsePRO();
VAR CurrentProcess : Longint;
	ProcNum : Longint;
BEGIN
 	InitializeProcesses();
	CurrentProcess := 0;
	ProcessCount := 0;
	REPEAT
		Scan();
		IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) THEN SyntaxError('Process number expected');
		ProcNum := GetIdentifierValue();
		IF (Procnum = MAXINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
		IF ProcNum<>CurrentProcess THEN SyntaxError('Definition for process #' + IntToStr(CurrentProcess) + ' expected but process #' + IntToStr(ProcNum) + ' found');
		ProcessCount := ProcessCount + 1;
		ParseProcessEntries(CurrentProcess);
    Inc(CurrentProcess);
	UNTIL CurrentTokenID = T_SECTION_END;
END; 		

PROCEDURE Sintactic();
BEGIN
	CurrTokenPTR := TokenList;
	ClassicMode := false;
	OnIfdefMode := false;
	OnElse := false;
	MTXCount := 0;
	STXCount := 0;
	LTXCount := 0;
	OTXCount := 0;
	WriteLn('CTL...');
	ParseCTL();
	WriteLn('VOC...');
	ParseVOC();
	WriteLn('STX...');
	ParseSTX();
	WriteLn('MTX...');
	ParseMTX();
	WriteLn('OTX...');
	ParseOTX();
	WriteLn('LTX...');
	ParseLTX();
	WriteLn('CON...');
	ParseCON();
	WriteLn('OBJ...');
	ParseOBJ();
	WriteLn('PRO...');
	ParsePRO();
  WriteLn('Input file parse completed...');

END;

END.
