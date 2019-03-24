UNIT USintactic;
{$MODE OBJFPC}

INTERFACE

USES UTokenList;

PROCEDURE Sintactic();




IMPLEMENTATION

USES sysutils, UConstants, ULexTokens, USymbolTree, UVocabularyTree, UMessageList, UCondacts, UConnections, UObjects, UProcess, UProcessCondactList, UCTLIncBin;

VAR CurrentText: AnsiString;
	CurrentIntVal : Longint;
	CurrentTokenID : Word;
	CurrLineno : Longint;
	CurrColno : Word;
	CurrTokenPTR: TPTokenList;
	OnIfdefMode : boolean;



PROCEDURE SyntaxError(msg: String);
BEGIN
  Writeln(CurrLineno,':', CurrColno, ': ', msg,'.');
  Halt(1);
END;


PROCEDURE Scan();
VAR MyDefine : AnsiString;
	Evaluation : Boolean;
BEGIN
	IF (CurrTokenPTR=nil) then SyntaxError('Unexpected end of file');
	CurrentTokenID := CurrTokenPTR^.TokenID;

	// Apply IFDEF/IFNDEF
	IF (CurrentTokenID=T_IFDEF) OR (CurrentTokenID=T_IFNDEF) THEN
	BEGIN
	 if CurrTokenPTR^.Next = nil THEN SyntaxError('Unexpected end of file');
	 CurrTokenPTR := CurrTokenPTR^.Next;
	 if CurrTokenPTR^.TokenID <> T_STRING THEN SyntaxError('Invalid #ifdef/#ifndef label, please include the label in betwween quotes');
	 MyDefine := CurrTokenPTR^.Text;
	 MyDefine := Copy(MyDefine, 2, Length(MyDefine) - 2);
	 Evaluation:= GetSymbolValue(SymbolTree, MyDefine)<>MAXINT;
	 IF CurrentTokenID = T_IFNDEF THEN Evaluation:= not Evaluation;

	 // IF directive failed, skip code until ENDIF
	 IF NOT Evaluation THEN
	 BEGIN
	 	IF CurrentTokenID = T_IFDEF THEN Write('#ifdef') ELSE Write('#ifndef');
	 	WriteLn(' for "' + MyDefine + '" failed.');
	 	WHILE (CurrTokenPTR<>nil) AND (CurrTokenPTR^.TokenID<>T_ENDIF) DO  CurrTokenPTR := CurrTokenPTR^.Next;
	 	IF (CurrTokenPTR=nil) THEN SyntaxError('Unexpected end of file');
	 	CurrTokenPTR:= CurrTokenPTR^.Next;
	 	IF (CurrTokenPTR=nil) THEN SyntaxError('Unexpected end of file');
	 	CurrentTokenID := CurrTokenPTR^.TokenID;
	 END ELSE
	 BEGIN
	 	IF CurrentTokenID = T_IFDEF THEN Write('#ifdef') ELSE Write('#ifndef');
	 	WriteLn(' for "' + MyDefine + '" succeeded.');
	 	CurrTokenPTR:= CurrTokenPTR^.Next;
	 	IF (CurrTokenPTR=nil) THEN SyntaxError('Unexpected end of file');
	 	CurrentTokenID := CurrTokenPTR^.TokenID;
	 	OnIfdefMode := true;
	 END;
	END;

	// Apply ENDIF
	IF (CurrentTokenID=T_ENDIF) THEN
	BEGIN
	  IF  OnIfdefMode THEN 
	  BEGIN
	 	CurrTokenPTR:= CurrTokenPTR^.Next;
	 	CurrentTokenID := CurrTokenPTR^.TokenID;
	  	OnIfdefMode:=false
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
		IF (Value = MAXINT) THEN SyntaxError('"' +CurrentText + '" is not defined')
		ELSE Result := Value;
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
	if NOT AddSymbol(SymbolTree, Symbol, Value) THEN SyntaxError('"' + Symbol + '" already defined');
END;

PROCEDURE ParseIncBin();
VAR Filename : String;
BEGIN
	Scan();
	IF CurrentTokenID <> T_STRING THEN SyntaxError('Included file should be in between quotes');
	FileName := Copy(CurrentText, 2, length(CurrentText) - 2);
	IF NOT FileExists(Filename) THEN SyntaxError('Included file not found');
	WriteLn('#incbin "' + Filename + '" processed.');
	AddCTL_IncBin(CTLIncBinList, FileName); // Adds the file to binary files to be included
END;

PROCEDURE ParseCTL();
BEGIN
	Scan();
	IF (CurrentTokenID<>T_SECTION_CTL) THEN SyntaxError('/CTL expected');
	REPEAT
		Scan();
		IF (CurrentTokenID = T_DEFINE) THEN ParseDefine()
		ELSE IF (CurrentTokenID  =T_INCBIN) THEN ParseIncBin()
		ELSE IF (CurrentTokenID<>T_SECTION_VOC) THEN SyntaxError('#define, #incbin or /VOC expected');
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
		IF (CurrentTokenID=T_IDENTIFIER) THEN ParseNewWord()
		ELSE IF (CurrentTokenID<>T_SECTION_STX) THEN SyntaxError('Vocabulary word definition or /STX expected')
	UNTIL CurrentTokenID =  T_SECTION_STX;
END;

PROCEDURE ParseMessageList(VAR AMessageList: TPMessageList; VAR AMessageCOunter: Longint; TerminatorToken : Word);
VAR Value: Longint;
	Message : String;
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
			IF (CurrentIntVal>=LTXCount) THEN SyntaxError ('Object #' + IntToStr(CurrentIntVal) + ' not defined');

			Scan(); // Get Initialy At
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) THEN SyntaxError('Object initial location expected');
			InitialyAt := GetIdentifierValue();
			IF (InitialyAt >= LTXCount) AND (InitialyAt <> LOC_NOT_CREATED) AND (InitialyAt <> LOC_WORN) AND (InitialyAt <> LOC_CARRIED) THEN SyntaxError('Invalid initial location');

			Scan(); // Get Weight
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) THEN SyntaxError('Object weight expected');
			Weight := GetIdentifierValue();
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
			IF (CurrentTokenID<>T_IDENTIFIER) THEN SyntaxError('Vocabulary noun expected');
			TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH);
			AuxVocabularyTree := GetVocabulary(VocabularyTree, TheWord, VOC_NOUN);
			IF AuxVocabularyTree = nil THEN SyntaxError('Noun not defined');
			Noun := AuxVocabularyTree^.Value;

			Scan(); // Get Adject
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_UNDERSCORE) THEN SyntaxError('Vocabulary adjective or underscore character expected');
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
					IF (CurrentTokenID <> T_NUMBER) AND (CurrentTokenID <> T_IDENTIFIER) THEN SyntaxError('Invalid condact parameter');
					Value := GetIdentifierValue();
					IF Value=MAXINT THEN  // Parameter was neither numeric, nor previously defined, let's check if it's a non-verb vocabulary word as last chance
					BEGIN
						TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH);
						AuxVocabularyPTR := GetVocabulary(VocabularyTree, TheWord, VOC_ANY);
						IF AuxVocabularyPTR = nil THEN SyntaxError('Invalid condact parameter');
						Value := AuxVocabularyPTR^.Value;
					END;
					CurrentCondactParams[i].Value := Value;
				END;
				AddProcessCondact(SomeEntryCondacts, Opcode, Condacts[Opcode].NumParams, CurrentCondactParams);
			END;
		END ELSE
		IF CurrentTokenID=T_DB THEN 
		BEGIN
			Scan();
			IF (CurrentTokenID<>T_NUMBER) THEN SyntaxError('DB value should be numeric');
			IF (CurrentIntVal<0) OR (CurrentIntVal>255) THEN SyntaxError('DB value should be between 0 and 255');
			WriteLn('#DB ' + CurrentText + ' processed');
			AddProcessCondact(SomeEntryCondacts,CurrentIntVal , 0, CurrentCondactParams); // adds a fake condact, with the DB value as OPCODE and zero parameters
		END
		ELSE 	
		IF CurrentTokenID=T_INCBIN THEN 
		BEGIN
			Scan();
			IF (CurrentTokenID<>T_STRING) THEN SyntaxError('Included file should be in between quotes');
			Filename := Copy(CurrentText, 2, Length(CurrentText)-2);
			IF NOT FileExists(Filename) THEN SyntaxError('Included file not found');
			AssignFile(IncludedFile, Filename);
			Reset(IncludedFile,1);
			WriteLn('#incbin "' + Filename + '" processed.');
			WHILE NOT EOF(IncludedFile) DO
			BEGIN
				BlockRead(IncludedFile, AuxByte, 1);
				AddProcessCondact(SomeEntryCondacts,AuxByte, 0, CurrentCondactParams); // Queues one fake condact as DB does above, pero byte in the file
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
                          IF (NOT ValidVerb) THEN SyntaxError('Verb not defined');
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
		IF ProcNum<>CurrentProcess THEN SyntaxError('Definition for process #' + IntToStr(CurrentProcess) + ' expected but process #' + IntToStr(ProcNum) + ' found');
		ProcessCount := ProcessCount + 1;
		ParseProcessEntries(CurrentProcess);
    Inc(CurrentProcess);
	UNTIL CurrentTokenID = T_SECTION_END;
END; 		

PROCEDURE Sintactic();
BEGIN
	CurrTokenPTR := TokenList;
	OnIfdefMode := false;
	MTXCount := 0;
	STXCount := 0;
	LTXCount := 0;
	OTXCount := 0;
	WriteLn('Control...');
	ParseCTL();
	WriteLn('Vocabulary...');
	ParseVOC();
	WriteLn('System Messages...');
	ParseSTX();
	WriteLn('Messages...');
	ParseMTX();
	WriteLn('Object Texts...');
	ParseOTX();
	WriteLn('Location Texts...');
	ParseLTX();
	WriteLn('Connections...');
	ParseCON();
	WriteLn('Object definitions...');
	ParseOBJ();
	WriteLn('Processes...');
	ParsePRO();
	WriteLn('Input file parse completed...');
END;

END.
