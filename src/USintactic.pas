UNIT USintactic;
{$MODE OBJFPC}
{$H+}{$R+}

INTERFACE

USES UTokenList, ULabelList;

PROCEDURE Sintactic(ATarget, ASubtarget: AnsiString);
PROCEDURE FixForwardLabels();

// If the lexer finds invalid token will call this one
PROCEDURE LexerError(yylineno, yycolno: integer; yytext: AnsiString);

var ClassicMode : Boolean;
	DebugMode : Boolean;
	Target, Subtarget: AnsiString;
	MaluvaUsed : Boolean;
	GlobalNestedIfdefCount: Word;

IMPLEMENTATION

USES sysutils, UConstants, ULexTokens, USymbolList, UVocabularyTree, UMessageList, UCondacts, UConnections, UObjects, UProcess, UProcessCondactList, UCTLExtern,fpexprpars, strings, strutils, UInclude;

VAR CurrentText: AnsiString;
	CurrentIntVal : Longint;
	CurrentTokenID : Word;
	CurrLineno : Longint;
	CurrColno : Word;
	CurrTokenPTR: TPTokenList;
	

	
PROCEDURE SyntaxError(msg: String);
VAR IncludeData : TIncludeData;
BEGIN
  IncludeData := GetIncludeData(CurrLineno);
  Writeln(IncludeData.OriginalLine,':', CurrColno,':',IncludeData.originalFileName, ': ', msg,'.');
  Halt(1);
END;

PROCEDURE Warning(msg: String);
VAR IncludeData : TIncludeData;
BEGIN
  IncludeData := GetIncludeData(CurrLineno);
  Writeln('Warning: ',IncludeData.OriginalLine,':', CurrColno,':',IncludeData.originalFileName, ': ', msg,'.');
END;

PROCEDURE LexerError(yylineno, yycolno: integer; yytext: AnsiString);
BEGIN
 CurrLineno := yylineno;
 CurrColno := yycolno;
 SyntaxError('Unexpected character or string: "'+ yytext+'"');
END;

PROCEDURE FixForwardLabels();
var procno, entryno : Word;
	TempEntriesList : TPProcessEntryList;
    TempCondactList : TPProcessCondactList;
    
BEGIN
	FOR procno := 0 TO ProcessCount - 1 DO
	BEGIN
		TempEntriesList := Processes[procno].entries;
		entryno := 0;
		WHILE TempEntriesList<>nil DO
		BEGIN
			TempCondactList := TempEntriesList^.Condacts;
            WHILE TempCondactList<> nil  DO  //  Each condact
            BEGIN
				IF (TempCondactList^.Opcode = PENDINGSKIP_OPCODE) THEN
				BEGIN
					// Check if forward refence was finally defined
					IF LabelList[TempCondactList^.Params[0].Value].isForward THEN SyntaxError('Label ' + LabelList[TempCondactList^.Params[0].Value].SkipLabel + ' was referenced but then not defined');
					// If defined, let's check it's same process
					IF LabelList[TempCondactList^.Params[0].Value].Process<>procno THEN SyntaxError('Label '+LabelList[TempCondactList^.Params[0].Value].SkipLabel+' was referenced in one process but defined in a different process');
					// If same process, let´s calculate the jump and see if >128
					IF LabelList[TempCondactList^.Params[0].Value].Entry - EntryNo > 128 THEN SyntaxError('SKIP using label '+LabelList[TempCondactList^.Params[0].Value].SkipLabel+' trys to jump forward too much, maximum 128 entries jumped allowed');
					// Ok, now it's all OK, lets replace the PENDINGSKIP for a proper SKIP
					IF verbose THEN WriteLn('Forward reference of label "' + LabelList[TempCondactList^.Params[0].Value].SkipLabel + '" found at process #' + IntToStr(LabelList[TempCondactList^.Params[0].Value].Process) + ', entry #' + IntToStr(LabelList[TempCondactList^.Params[0].Value].Entry) + '.');
					TempCondactList^.Opcode := SKIP_OPCODE;
					TempCondactList^.Params[0].Value := LabelList[TempCondactList^.Params[0].Value].Entry - EntryNo - 1;
					break;
				END
				ELSE
				IF (TempCondactList^.Opcode AND 512 = 512) THEN // Pending forward local label
				BEGIN
					// Check if forward refence was finally defined
					IF LabelList[TempCondactList^.Params[TempCondactList^.NumParams -1].Value].isForward THEN SyntaxError('Local label ' + LabelList[TempCondactList^.Params[TempCondactList^.NumParams -1].Value].SkipLabel + ' was referenced but then not defined');
					// If defined, let's check it's same process
					IF LabelList[TempCondactList^.Params[TempCondactList^.NumParams -1].Value].Process<>procno THEN SyntaxError('Local label '+LabelList[TempCondactList^.Params[TempCondactList^.NumParams -1].Value].SkipLabel+' was referenced in one process but defined in a different process');
					// If defined, let's check it's same entry
					IF LabelList[TempCondactList^.Params[TempCondactList^.NumParams -1].Value].Entry<>Entryno+1 THEN SyntaxError('Local label '+LabelList[TempCondactList^.Params[TempCondactList^.NumParams -1].Value].SkipLabel+' was referenced in one entry but defined in a different one');
					// Ok, now it's all OK, lets go
					IF verbose THEN WriteLn('Forward reference of label "' + LabelList[TempCondactList^.Params[TempCondactList^.NumParams -1].Value].SkipLabel + '" found at process #' + IntToStr(LabelList[TempCondactList^.Params[TempCondactList^.NumParams -1].Value].Process) + ', entry #' + IntToStr(LabelList[TempCondactList^.Params[TempCondactList^.NumParams -1].Value].Entry) + '.');
					TempCondactList^.Opcode := TempCondactList^.Opcode AND 511; // remove the pending local label bit
					TempCondactList^.Params[TempCondactList^.NumParams -1].Value := LabelList[TempCondactList^.Params[TempCondactList^.NumParams -1].Value].Condact;
					break;
				END;

				TempCondactList := TempCondactList^.Next;
			END;
			Inc(Entryno);
			TempEntriesList := TempEntriesList^.Next;
		END;

	END;
END;

PROCEDURE Scan(); forward;


FUNCTION GetIdentifierValue(): Longint;
VAR Value : Longint;
BEGIN
	IF (CurrentTokenID = T_NUMBER) THEN Result := CurrentIntVal ELSE
	BEGIN
		Value := GetSymbolValue(SymbolList,CurrentText);
		Result := Value;
	END;
END;

FUNCTION GetExpressionValue():Longint;
var Parser: TFPExpressionParser;
		TempSymbolList: TPSymbolList;
		parserResult: TFPExpressionResult;
		AuxStr : ShortString;
		ExpressionValue :  Longint;
BEGIN
	TRY 
		Parser := TFPExpressionParser.Create(nil);
		Parser.BuiltIns := [bcMath];
		TempSymbolList := SymbolList;
		while TempSymbolList<> nil DO
		BEGIN
			Parser.Identifiers.AddFloatVariable(TempSymbolList^.Symbol, TempSymbolList^.Value);
			TempSymbolList := TempSymbolList^.Next;
		END;
		AuxStr := CurrentText;
		AuxStr := Copy(AuxStr, 2, length(AuxStr)-2); // Remove double quotes at the beginning and at the end
		TRY
			Parser.Expression := AuxStr;
			parserResult := Parser.Evaluate;
		EXCEPT
			ON E: Exception DO BEGIN SyntaxError('Invalid expression "'+AuxStr+'": '+ E.message); END;
		END 
	FINALLY 
	 Parser.free(); 
	END; 
	IF (parserResult.resultType = rtFloat) THEN ExpressionValue := trunc(parserResult.ResFloat) ELSE
	IF (parserResult.resultType = rtInteger) THEN ExpressionValue := parserResult.ResInteger ELSE
	SyntaxError('Expression ' + AuxStr + ' returned a non numeric value');
	
	Result :=  ExpressionValue;
END;	

FUNCTION ExtractValue(Symbol: AnsiString= ''):Longint;
BEGIN
	IF (CurrentTokenID=T_STRING) THEN Result := GetExpressionValue() ELSE 
	IF (CurrentTokenID=T_NUMBER) OR (CurrentTokenID= T_IDENTIFIER) THEN Result := GetIdentifierValue() ELSE Result := MAXLONGINT;
	IF (Result = MAXLONGINT) AND (CurrentTokenID=T_STRING) THEN SyntaxError('"'+CurrentText+'" is not a valid expression');
	IF (Result = MAXLONGINT) THEN 
	BEGIN
		IF Symbol<>'' THEN SyntaxError('Value for symbol "'+Symbol+'" is not valid: "' +CurrentText + '"')
					  ELSE SyntaxError('"' +CurrentText + '" is not defined. Check DB/DW value.');
	END;

END;

PROCEDURE ParseDefine();
VAR Symbol : AnsiString;
	Value : Longint;	
BEGIN
	Scan();
	if (CurrentTokenID<>T_IDENTIFIER) THEN SyntaxError('Identifier expected after #define' );
	Symbol := CurrentText;
	Scan();
  	Value := ExtractValue(Symbol);
	if NOT AddSymbol(SymbolList, Symbol, Value) THEN SyntaxError('"' + Symbol + '" already defined');
END;

FUNCTION getMaluvaFilename(): String;
BEGIN
  IF (target='ZX') AND (Subtarget='PLUS3') THEN Result:='MLV_P3.BIN' ELSE
  IF (target='ZX') AND (Subtarget='NEXT') THEN Result:='MLV_NEXT.BIN' ELSE
  IF (target='ZX') AND (Subtarget='UNO') THEN Result:='MLV_UNO.BIN' ELSE
  IF (target='ZX') AND (Subtarget='ESXDOS') THEN Result:='MLV_ESX.BIN' ELSE
  IF target='MSX' THEN Result:='MLV_MSX.BIN' ELSE
  IF target='C64' THEN Result:='MLV_C64.BIN' ELSE
  IF target='CP4' THEN Result:='MLV_CP4.BIN' ELSE
  IF target='CPC' THEN Result:='MLV_CPC.BIN' ELSE
  IF target='PCW' THEN Result:='MLV_PCW.BIN' ELSE
  IF target='MSX2' THEN Result:= 'MSX2' ELSE  Result:='MALUVA';
END;

PROCEDURE ParseExtern(ExternType: String);
VAR Filename : String;
BEGIN
	Scan();
	IF CurrentTokenID <> T_STRING THEN SyntaxError('Included extern file should be in between quotes');
	FileName := Copy(CurrentText, 2, length(CurrentText) - 2);
	IF Filename = 'MALUVA' THEN 
	BEGIN
			IF (target='MSX2') and (ExternType='EXTERN') THEN
			BEGIN
				WriteLn('#'+ExternType+''' "' + Filename + '" skipped as target is MSX2.');		
				Exit;
			END;
			FileName := getMaluvaFilename();
	END;
	IF NOT FileExists(Filename) THEN SyntaxError('Extern file "'+FileName+'" not found');
	WriteLn('#'+ExternType+''' "' + Filename + '" processed.');
	AddCTL_Extern(CTLExternList, FileName, ExternType); // Adds the file to binary files to be included
END;


PROCEDURE ParseEcho();
BEGIN
 Scan();
 IF (CurrentTokenID<>T_STRING) THEN SyntaxError('Invalid string for #echo');
 WriteLn(Copy(CurrentText, 2, Length(CurrentText) - 2));
END;

PROCEDURE SkipBlock(VAR CurrTokenPTR: TPTokenList);
VAR	NestedIfdefCount : Word;
	PreviousTokenPtr : TPTokenList;
BEGIN
	NestedIfdefCount := 1;
	WHILE (CurrTokenPTR<>nil) AND (NestedIfdefCount>0) DO 
	BEGIN
		PreviousTokenPtr := CurrTokenPTR;
		CurrTokenPTR := CurrTokenPTR^.Next;
		IF CurrTokenPTR<>nil THEN
		BEGIN
			CurrentTokenID := CurrTokenPTR^.TokenID;
			IF (CurrentTokenID=T_IFDEF) OR (CurrentTokenID=T_IFNDEF) THEN NestedIfdefCount := NestedIfdefCount + 1
			ELSE IF (CurrentTokenID=T_ENDIF) THEN NestedIfdefCount := NestedIfdefCount - 1
			ELSE IF (CurrentTokenID=T_ELSE) AND (NestedIfdefCount=1) THEN NestedIfdefCount := 0; // ELSE can only get you out of skip block if is the ELSE of the IFDEF that started it, otherwise else is ignored
		END;	
	END;
	IF (CurrTokenPTR=nil) THEN SyntaxError('Unexpected end of file. #ifdef/#ifndef couldn''t find #endif');
	// If we exit because of a #else we will just return pointing to the next token after else because after an else is basically the same than after an #ifdef/#ifndef
	//IF CurrentTokenID = T_ELSE THEN GlobalNestedIfdefCount := GlobalNestedIfdefCount + 1 
	//ELSE
	 IF CurrentTokenID = T_ENDIF  THEN CurrTokenPTR := PreviousTokenPtr;  // But it it's a #endif we rewind one step so it points to the #ifdef and the un-identation of nested #ifdef works naturally 
END;


PROCEDURE Scan();
VAR Evaluation: Boolean;
		MyDefine : AnsiString;
BEGIN
 IF (CurrTokenPTR=nil) then SyntaxError('Unexpected end of file');
 CurrTokenPTR := CurrTokenPTR^.Next;
 CurrentTokenID := CurrTokenPTR^.TokenID;
 
 IF (not (CurrentTokenID-256 in [T_DEFINE-256,T_IFDEF-256,T_IFNDEF-256,T_ENDIF-256,T_ELSE-256,T_ECHO-256,T_INT-256,T_SFX-256,T_EXTERN-256, T_DEBUG-256, T_CLASSIC-256])) THEN  // All minus 256 just to be able to use a SET and IN, which only work with 0-255 value
  BEGIN // If the token obtained is not one of the compiler directives that may appear anywhere in the code, and have to beapplied inmediatly we just return the token to the calling function
	CurrentText := CurrTokenPTR^.Text;
	CurrentIntVal := CurrTokenPTR^.IntVal;
	CurrLineno := CurrTokenPTR^.lineno;
	CurrColno := CurrTokenPTR^.colno;
 END
 ELSE
 BEGIN // otherwise, we have to apply those compiler directives, and then call Scan() again to return the value the calling function is expecting, that should be just after the compiler directive
       // Notice there is a scan() call just after the CASE/OF
	  //FI		 CurrentText := CurrTokenPTR^.Text; WriteLn('Fast # ' , CurrentTokenID, ' ', CurrentText);
		CASE CurrentTokenID of  // Firs parse the directive
		T_DEFINE: ParseDefine();
		T_ECHO: ParseEcho();
    	T_EXTERN: ParseExtern('EXTERN');
		T_INT: ParseExtern('INT');
		T_SFX: ParseExtern('SFX');
		T_CLASSIC: ClassicMode := true;
		T_DEBUG: DebugMode := true;
		T_ENDIF: BEGIN
					 IF GlobalNestedIfdefCount = 0 THEN SyntaxError('#endif without #ifdef/#ifndef');
					 GlobalNestedIfdefCount := GlobalNestedIfdefCount - 1;
				 END;
		T_ELSE:  BEGIN // You can only get to this T_ELSE if you are executing a #if(n)def that was succesful, so what we have to do here is skipping the "else" part
				  IF GlobalNestedIfdefCount = 0 THEN SyntaxError('#else without #ifdef/#ifndef');
		           SkipBlock(CurrTokenPTR);
				  END; 
		T_IFDEF, T_IFNDEF: 
		        BEGIN
					if CurrTokenPTR^.Next = nil THEN SyntaxError('Unexpected end of file just after #ifdef/#ifndef'); // No symbol after #ifdef

					// Get Symbol
					CurrTokenPTR := CurrTokenPTR^.Next;
					if CurrTokenPTR^.TokenID <> T_STRING THEN SyntaxError('Invalid #ifdef/#ifndef label, please include the label or expression in betwween quotes'); // Not a string
					// Evaluate symbol
					MyDefine := CurrTokenPTR^.Text;
					MyDefine := Copy(MyDefine, 2, Length(MyDefine) - 2);
					Evaluation:= GetSymbolValue(SymbolList, MyDefine) <> MAXLONGINT;
					// Negate result if it's #ifndef
					IF CurrentTokenID = T_IFNDEF THEN Evaluation:= not Evaluation;
					
					GlobalNestedIfdefCount := GlobalNestedIfdefCount +1;
					if (not Evaluation) THEN SkipBlock(CurrTokenPTR);  // If symbol does not exist we skip the block, which means skipping until next #endif or #else
					 
				END; // T_IFDEF, T_IFNDEF:
		END; // CASE
    Scan(); // Then scan again
 END;
END;





PROCEDURE ParseCTL();
BEGIN
	Scan();
	IF (CurrentTokenID<>T_SECTION_CTL) THEN SyntaxError('/CTL expected');
	REPEAT
		Scan();
		IF (CurrentTokenID = T_UNDERSCORE) THEN BEGIN END 
		ELSE IF (CurrentTokenID<>T_SECTION_VOC) THEN SyntaxError('/VOC expected' + IntToStr(CurrentTokenID));
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
	IF (Value = MAXLONGINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
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
			IF (CurrentTokenID<>T_LIST_ENTRY) THEN SyntaxError('List entry number expected');
			If CurrentIntVal = MAXLONGINT THEN CurrentIntVal := GetIdentifierValue();
			IF CurrentIntVal = MAXLONGINT THEN SyntaxError('Invalid or unknown symbol "' + CurrentText+ '"'); 
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
	AddSymbol(SymbolList, 'LAST_OBJECT', OTXCount -1);
	AddSymbol(SymbolList, 'NUM_OBJECTS', OTXCount);
END;

PROCEDURE ParseLTX();
BEGIN
	ParseMessageList(LTX, LTXCount, T_SECTION_CON);
	AddSymbol(SymbolList, 'LAST_LOCATION', LTXCount -1);
	AddSymbol(SymbolList, 'NUM_LOCATIONS', LTXCount);
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
			IF CurrentTokenID<>T_IDENTIFIER THEN SyntaxError('Connection vocabulary word expected but "'+CurrentText+'" found');
			TheWord := Copy(CurrentText,1,VOCABULARY_LENGTH);
			AuxVocabularyTree := GetVocabulary(VocabularyTree, TheWord, VOC_ANY);
			IF (AuxVocabularyTree=nil) THEN SyntaxError('Direction is not defined:"' + CurrentText+'"');
			IF  (NOT (AuxVocabularyTree^.VocType IN [VOC_VERB,VOC_NOUN])) THEN SyntaxError('Invalid connection word');
			Direction := AuxVocabularyTree^.Value;
			Scan();
			if (CurrentTokenID <> T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) THEN SyntaxError('Location number expected');
			ToLoc := GetIdentifierValue();
			IF (ToLoc = MAXLONGINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
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
		IF (CurrentTokenID <> T_LIST_ENTRY) THEN SyntaxError('Location entry expected but "'+CurrentText+'" found');
		If CurrentIntVal = MAXLONGINT THEN CurrentIntVal := GetIdentifierValue();
		IF CurrentIntVal = MAXLONGINT THEN SyntaxError('Invalid or unknown symbol "' + CurrentText+ '"'); 
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
			IF (CurrentTokenID <> T_LIST_ENTRY) THEN SyntaxError('Object entry expected but "'+CurrentText+'" found');
			If CurrentIntVal = MAXLONGINT THEN CurrentIntVal := GetIdentifierValue();
			IF CurrentIntVal = MAXLONGINT THEN SyntaxError('Invalid or unknown symbol "' + CurrentText+ '"'); 
			IF CurrentIntVal<>CurrentObj THEN SyntaxError('Definition for object #' + IntToStr(Currentobj) + ' expected but object #' + IntToStr(CurrentIntVal) + ' found');
			IF (CurrentIntVal>=OTXCount) THEN SyntaxError ('Object #' + IntToStr(CurrentIntVal) + ' not defined');

			Scan(); // Get Initialy At
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) AND (CurrentTokenID<>T_UNDERSCORE) THEN SyntaxError('Object initial location expected but "'+CurrentText+'" found');
			IF (CurrentTokenID = T_UNDERSCORE) THEN InitialyAt := LOC_NOT_CREATED
			ELSE
			BEGIN
				InitialyAt:=GetIdentifierValue();
				IF (InitialyAt = MAXLONGINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
			END;	
			IF (InitialyAt >= LTXCount) AND (InitialyAt <> LOC_NOT_CREATED) AND (InitialyAt <> LOC_WORN) AND (InitialyAt <> LOC_CARRIED) THEN SyntaxError('Invalid initial location' + IntToStr(InitialyAt));

			Scan(); // Get Weight
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) THEN SyntaxError('Object weight expected');
			Weight := GetIdentifierValue();
			IF (Weight = MAXLONGINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
			IF (Weight >= MAX_FLAG_VALUE) THEN SyntaxError('Invalid weight :' + CurrentText);


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
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER)  AND (CurrentTokenID<>T_UNDERSCORE) THEN SyntaxError('Vocabulary noun or underscore expected but "'+CurrentText+'" found');
			IF (CurrentTokenID=T_UNDERSCORE) THEN Noun := NO_WORD 
			ELSE
			BEGIN
				TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH);
				AuxVocabularyTree := GetVocabulary(VocabularyTree, TheWord, VOC_NOUN);
				IF AuxVocabularyTree = nil THEN SyntaxError('Noun not defined: "'+CurrentText+'"');
				Noun := AuxVocabularyTree^.Value;
			END;

			Scan(); // Get Adject
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) AND (CurrentTokenID<>T_UNDERSCORE) THEN SyntaxError('Vocabulary adjective or underscore character expected but "'+CurrentText+'" found');
			IF CurrentTokenID = T_UNDERSCORE THEN Adjective := NO_WORD 
			ELSE
			BEGIN
				TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH);
				AuxVocabularyTree := GetVocabulary(VocabularyTree, TheWord, VOC_ADJECT);
				IF AuxVocabularyTree = nil THEN SyntaxError('Adjective not defined: "' + CurrentText + '"');
				Adjective := AuxVocabularyTree^.Value;
			END;
			AddObject(ObjectList, CurrentObj, Noun, Adjective, Weight, InitialyAt, Flags,  Container, Wearable);
			Inc(CurrentObj);
		END;	
	UNTIL CurrentTokenID = T_SECTION_PRO;
	IF CurrentObj < OTXCount THEN SyntaxError('Definition for object #' + IntToStr(CurrentObj) + ' missing' );
END;

FUNCTION GetWordParamValue(Param: String; Opcode: Byte; ParameterNumber: Byte = 0): Integer;
var TheWord : String;
	AuxVocType : TVocType;
	AuxVocabularyPTR : TPVocabularyTree;
BEGIN
  TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH);
  AuxVocType := VOC_ANY;
  IF Opcode<>255 THEN CASE Opcode of
						ADJECT1_OPCODE: AuxVocType := VOC_ADJECT;
						ADJECT2_OPCODE: AuxVocType := VOC_ADJECT;
						ADVERB_OPCODE:  AuxVocType := VOC_ADVERB;
						NOUN2_OPCODE:   AuxVocType := VOC_NOUN;
						PREP_OPCODE:    AuxVocType := VOC_PREPOSITION;
						SYNONYM_OPCODE: IF ParameterNumber=0 THEN AuxVocType := VOC_VERB ELSE AuxVocType:= VOC_NOUN;
 					 END;
  AuxVocabularyPTR := GetVocabulary(VocabularyTree, TheWord, AuxVocType);
  IF AuxVocabularyPTR = nil THEN Result := MAXLONGINT ELSE  Result := AuxVocabularyPTR^.Value;
END;

FUNCTION ParseProcessCondacts(var SomeEntryCondacts :  TPProcessCondactList; CurrentProcess:Longint; CurrentEntry : Longint):boolean;
VAR Opcode : Longint;
	CurrentCondactParams : TCondactParams;
	Value : Longint;
	i : integer;
	FileName : String;
	IncludedFile: FILE;
	AuxByte: Byte;
	AuxLong :Longint;
	HexByte, HexString : AnsiString;
	MaXMESs : Longint;
	SemanticError : AnsiString;
	SemanticExempt : Boolean;
	LabelData: TLabelData;
	LabelID : Word;
	CurrentCondact  :Integer;
	HasJumps : boolean;

BEGIN
    CurrentCondact := 0;
	HasJumps := false;
	REPEAT
		IF (SomeEntryCondacts<>nil) THEN Scan(); // Get Condact, skip first time when the condact list is empty cause it's already read
		IF (CurrentTokenID <> T_IDENTIFIER)  AND (CurrentTokenID<>T_UNDERSCORE)  AND (CurrentTokenID<>T_SECTION_PRO) AND (CurrentTokenID<>T_SECTION_END) AND (CurrentTokenID<>T_INCBIN) 
		 AND (CurrentTokenID<>T_DB) AND (CurrentTokenID<>T_DW) AND (CurrentTokenID<>T_NUMBER) AND (CurrentTokenID<>T_HEX) AND (CurrentTokenID<>T_USERPTR) AND (CurrentTokenID<>T_LABEL)	 
		 AND (CurrentTokenID<>T_LOCAL_LABEL) AND (CurrentTokenID<>T_PROCESS_ENTRY_SIGN) THEN
		   SyntaxError('Condact, label, new process entry or new process expected but "'+CurrentText + '" found');

		IF (CurrentTokenID<>T_INCBIN) AND (CurrentTokenID<>T_LOCAL_LABEL) AND (CurrentTokenID<>T_DB) AND (CurrentTokenID<>T_DW) AND (CurrentTokenID<>T_HEX) AND (CurrentTokenID<>T_USERPTR) AND (CurrentTokenID<>T_LABEL) THEN
		BEGIN
		  IF (CurrentTokenID = T_PROCESS_ENTRY_SIGN) OR (CurrentTokenID = T_SECTION_END) OR (CurrentTokenID = T_SECTION_PRO) THEN Opcode := -2 ELSE Opcode := GetCondact(CurrentText);
		    
			IF Opcode >= 0 THEN
			BEGIN
				// Check what to do with fake condacts
				IF (Opcode>=NUM_CONDACTS) AND (Opcode <256) THEN  
				BEGIN
					IF Opcode = XPICTURE_OPCODE THEN
					BEGIN
						IF GetSymbolValue(SymbolList, 'BIT16')<>MAXLONGINT THEN Opcode := PICTURE_OPCODE  // If 16 bit machine, no XPICTURE
						ELSE IF (target='PCW')  THEN Opcode := PICTURE_OPCODE // If target PCW, no XPICTURE
						ELSE MaluvaUsed := true;
					END ELSE
					IF Opcode = XSAVE_OPCODE THEN
					BEGIN
						IF GetSymbolValue(SymbolList, 'BIT16')<>MAXLONGINT THEN Opcode := SAVE_OPCODE  // If 16 bit machine, no XSAVE
						ELSE IF (Target='PCW') OR (Target='CPC') OR (Target='C64') OR (Target='CP4')  THEN Opcode := SAVE_OPCODE // If target PCW/C64/CP4/CPC, no XSAVE
						ELSE MaluvaUsed := true;
					END ELSE
					IF Opcode = XLOAD_OPCODE THEN
					BEGIN
						IF GetSymbolValue(SymbolList, 'BIT16')<>MAXLONGINT THEN Opcode := LOAD_OPCODE  // If 16 bit machine, no XLOAD
						ELSE IF (Target='PCW') OR (Target='CPC') OR (Target='C64') OR (Target='CP4')  THEN Opcode := LOAD_OPCODE // If target PCW/C64/CP4/CPC, no XLOAD
						ELSE MaluvaUsed := true;
					END ELSE
					IF Opcode = XBEEP_OPCODE THEN
					BEGIN
						IF (Target<>'CPC') AND (Target<>'MSX')  THEN Opcode := BEEP_OPCODE 
						ELSE MaluvaUsed := true;  // Only CPC and MSX support XBEEP, the rest just use BEEP (which will do nothing in PCW, AMIGA, ST and PC, but will play in ZX, CP4 and C64)
					END;
				END; 
				// Get Parameters
				FOR i:= 0 TO GetNumParams(Opcode) - 1 DO
				BEGIN
					Scan();
					SemanticExempt := false;
					CurrentCondactParams[i].Indirection := false;
					IF (CurrentTokenID = T_INDIRECT) THEN
					BEGIN
					  IF I>=MAX_PARAM_ACCEPTING_INDIRECTION THEN SyntaxError('Indirection is not allowed in this parameter');
					  CurrentCondactParams[i].Indirection := true;
					  Scan();
					END;
			
					IF (CurrentTokenID = T_STRING) AND (Opcode in [MESSAGE_OPCODE,MES_OPCODE, SYSMESS_OPCODE, XMES_OPCODE, XMESSAGE_OPCODE, XPLAY_OPCODE]) THEN  
					BEGIN
						SemanticExempt := true;
						CurrentText := Copy(CurrentText, 2, Length(CurrentText)-2);
						
						// Implements the ForceXMessages parameter
						IF (Opcode IN [MES_OPCODE, MESSAGE_OPCODE]) AND (ForceXMessages) THEN
						BEGIN
							if Opcode = MES_OPCODE THEN Opcode := XMES_OPCODE
												   ELSE Opcode := XMESSAGE_OPCODE;
						END;

						IF (Opcode IN [XMES_OPCODE, XMESSAGE_OPCODE]) AND ( (GetSymbolValue(SymbolList, 'BIT16')=MAXLONGINT) OR (SubTarget='VGA256'))  AND (NOT ForceNormalMessages) THEN  
						BEGIN
							IF (length(CurrentText)>511) THEN SyntaxError('Extended messages can be only up to 511 characters long. Your message is ' + IntToStr(length(CurrentText))+ ' long.');
							// Convert XMESSAGE into XMES with a string with #n at the end
							IF Opcode = XMESSAGE_OPCODE THEN CurrentText := CurrentText + '#n';
							Opcode := XMES_OPCODE;
							CurrentIntVal := insertMessageFromProcessIntoSpecificList(XTX, CurrentText);
							MaXMESs := MAXLONGINT;
						END
						ELSE
						BEGIN
						 CASE Opcode OF  // In case we are in a 16 bit machine, XMESSAGES are converted to normal messages
							  XMES_OPCODE : Opcode := MES_OPCODE;
							  XMESSAGE_OPCODE :Opcode := MESSAGE_OPCODE;
						  END;
						  IF Opcode = XPLAY_OPCODE THEN 
						  BEGIN
						  	CurrentIntVal := insertMessageFromProcessIntoSpecificList(OtherTX, CurrentText);
							MaXMESs := MAXLONGINT;
						  END
						  ELSE
						  BEGIN
							CurrentIntVal := insertMessageFromProcess(Opcode, CurrentText, ClassicMode);
							MaXMESs :=MAX_MESSAGES_PER_TABLE;
						  END;
						END;   

	 				  IF CurrentIntVal>=MaXMESs THEN
						BEGIN
						 IF ClassicMode THEN SyntaxError('Too many messages, max messages per message table is ' +  IntToStr(MAX_MESSAGES_PER_TABLE))
						                ELSE SyntaxError('Too many messages, total messages in  MTX, STX and LTX tables, plus "MESSAGE" strings is ' +  IntToStr(3*MAX_MESSAGES_PER_TABLE));
						END;
	 					CurrentTokenID := T_NUMBER;
						Value := CurrentIntVal;
						CurrentText := IntToStr(Value);
					END;

					IF (CurrentTokenID = T_LOCAL_LABEL) AND  ((Opcode AND 256) =256) THEN // Jump Maluva condacts
					BEGIN
  	   				  HasJumps := true;
					  IF (GetLabelData(CurrentText, LabelData) <> -1) THEN // Local Label exists
					  BEGIN
					  	IF (CurrentProcess <> LabelData.Process) THEN SyntaxError('Label "'+CurrentText+'" is not in this entry');
						IF (LabelData.Entry <> CurrentEntry+1) THEN SyntaxError('Label "'+CurrentText+'" is not in this entry ' + IntToStr(LabelData.Entry) +'  '+ IntToStr(CurrentEntry));
						CurrentIntVal := LabelData.Condact;
						CurrentText := IntToStr(CurrentIntVal);
						CurrentTokenID := T_NUMBER;
					  END
					  ELSE
					  BEGIN // It's a jump to a forward label
					 	LabelID := AddLabel(CurrentText, CurrentProcess, CurrentEntry, true, -1); 
      					IF Verbose THEN WriteLn('Forward declaration of local label '+CurrentText+' created.');
						Opcode := Opcode OR 512; // Set the Opcode bit for pending forward label
						CurrentCondactParams[i].Value := LabelID; 
						CurrentTokenID := T_NUMBER;
						CurrentText:=IntToStr(CurrentCondactParams[i].Value);
						CurrentIntVal := CurrentCondactParams[i].Value;
					  END; 
					END;

					IF (CurrentTokenID = T_LABEL) ANd  (Opcode = SKIP_OPCODE) THEN
					BEGIN
					 IF (GetLabelData(CurrentText, LabelData) <> -1) THEN // Label exists, replace numeric value
					 BEGIN
						IF (CurrentProcess <> LabelData.Process) THEN SyntaxError('Label "'+CurrentText+'" is not in this process');
						// At this point we know the label, if exists, is beacuse it was defined before, so jump is always backwars. We only check if jump < -128
						IF (LabelData.Entry - CurrentEntry -  1 < -128) THEN SyntaxError('Label "'+CurrentText+'" is too far from SKIP call, maximum 128 entries far allowed');
						// At this point it's a valid label, we just replace the token so it works as if the real numeric value was there
						CurrentIntVal := LabelData.Entry - CurrentEntry -1;
						CurrentText := IntToStr(LabelData.Entry - CurrentEntry -1);
						CurrentTokenID := T_NUMBER;
					 END
					 ELSE
					 BEGIN  // The label was not yet available, it's a forward reference
					    // Add empty label
					 	LabelID := AddLabel(CurrentText, -1, -1, true, -1); 
      					IF Verbose THEN WriteLn('Forward declaration of label '+CurrentText+' created.');
						// Replace current condact with a PENDING_SKIP
						Opcode := PENDINGSKIP_OPCODE;
						CurrentCondactParams[0].Indirection := false;
						CurrentCondactParams[0].Value := LabelID;
						CurrentTokenID := T_NUMBER;
						CurrentText:=IntToStr(LabelID);
						CurrentIntVal := LabelID;
					 END;
					END;

					IF (CurrentTokenID  = T_LABEL) AND ((Opcode AND 256) = 256) THEN
					BEGIN
					END;

					IF (CurrentTokenID <> T_NUMBER) AND (CurrentTokenID <> T_IDENTIFIER) AND (CurrentTokenID<> T_UNDERSCORE) AND (CurrentTokenID<>T_STRING) THEN SyntaxError('Invalid condact parameter');

					// Lets' dtermine the value of the parameter
					Value := MAXLONGINT;
					// IF a string then evaluate expression
					if CurrentTokenID = T_STRING THEN  Value  := GetExpressionValue();
					// If  an underscore, value is clear
					IF CurrentTokenID = T_UNDERSCORE THEN Value:= NO_WORD;
					// Otherwise if the condact accepts words as parameters, check vocabulary first
					IF (Value = MAXLONGINT) AND  (Opcode in [SYNONYM_OPCODE, PREP_OPCODE, NOUN2_OPCODE, ADJECT1_OPCODE, ADVERB_OPCODE, ADJECT2_OPCODE]) THEN Value:= GetWordParamValue(CurrentText, Opcode, i);
					// Otherwise, check the symbol table
					IF Value = MAXLONGINT THEN Value := GetIdentifierValue();
					// if still the value is not found, check the Vocavulary again, but more openly
					IF Value = MAXLONGINT THEN Value:= GetWordParamValue(CurrentText, 255);
					// If still MAXLONGINT, then it should be a bad parameter
					IF Value = MAXLONGINT THEN SyntaxError('Invalid parameter #' + IntToStr(i+1) + ': "'+CurrentText+'" for condact '+ Condacts[Opcode].Condact);
					IF (Opcode=SKIP_OPCODE) AND (Value<0) THEN Value := 256 + Value;
					IF (Opcode in [XMES_OPCODE, XMESSAGE_OPCODE]) THEN 
					BEGIN
						IF (Value<0) THEN SyntaxError('Invalid parameter value "'+CurrentText+'" for condact '+ Condacts[Opcode].Condact);
					END 
					ELSE IF (Value<0)  OR (Value>MAX_PARAMETER_RANGE) THEN SyntaxError('Invalid parameter value "'+CurrentText+'" for condact '+ Condacts[Opcode].Condact);
					
					CurrentCondactParams[i].Value := Value;
					// Semantic Check
					IF (NOT CurrentCondactParams[i].Indirection) AND (NOT SemanticExempt) AND NOt (NoSemantic) THEN
					BEGIN
						SemanticError := SemanticCheck(Opcode, i+1, Value, CurrentText);
						if (SemanticError<>'') THEN 
						BEGIN
						 IF SemanticWarnings THEN Warning(SemanticError) 
						 					 ELSE SyntaxError(SemanticError);
						END; 
					END;

				END;
				AddProcessCondact(SomeEntryCondacts, Opcode, GetNumParams(Opcode), CurrentCondactParams, false);
			END 
			ELSE
			BEGIN
			 IF (Opcode=-1) THEN SyntaxError('Unknown condact: "'+CurrentText+'"'); // If opcode = -1, it was an invalid condact, otherwise we have found entry end because of another entry, another process or \END
			END 
		END ELSE
		IF CurrentTokenID=T_LOCAL_LABEL THEN // LOCAL_LABEL
		BEGIN
			IF (AddLabel(CurrentText, CurrentProcess, CurrentEntry+1, false, CurrentCondact)=-1) THEN SyntaxError('Label already defined ('+CurrentText+') or too many labels');
			IF Verbose THEN WriteLn('Local label '+CurrentText+' created at process #'+IntToStr(CurrentProcess)+', entry #', IntToStr(CurrentEntry+1), ', condact #',IntToStr(CurrentCondact),'.');
			IF (SomeEntryCondacts=nil) THEN Scan();
			CurrentCondact := CurrentCondact -1;
			Opcode := 0;
		END ELSE
		IF CurrentTokenID=T_LABEL THEN // LABEL
		BEGIN
		 IF (AddLabel(CurrentText, CurrentProcess, CurrentEntry+1, false, -1)=-1) THEN SyntaxError('Label already defined ('+CurrentText+') or too many labels');
		 IF Verbose THEN WriteLn('Label '+CurrentText+' created at process #'+IntToStr(CurrentProcess)+', entry #', IntToStr(CurrentEntry+1),'.');
		 Opcode := -1;
		 CurrentCondact := CurrentCondact - 1; // Because we don't want the condact counter to increase because of a label
		END ELSE
		IF CurrentTokenID=T_USERPTR THEN  // USERPTR
		BEGIN
			Scan();
			IF (CurrentTokenID<>T_NUMBER) THEN SyntaxError('#userptr parameter should be numeric');
			IF (CurrentIntVal<0) OR (CurrentIntVal>9) THEN SyntaxError('#userptr parameter should be 0-9');
			IF Verbose THEN WriteLn('#USERPTR ' + CurrentText + ' processed');
			CurrentCondactParams[0].Value := CurrentIntVal;
			CurrentCondactParams[0].Indirection := false;
			AddProcessCondact(SomeEntryCondacts, FAKE_USERPTR_CONDACT_CODE , 1, CurrentCondactParams, false); // adds a fake condact value as OPCODE and zero parameters
		END
		ELSE 	
		IF CurrentTokenID=T_DB THEN //DB
		BEGIN
			Scan();
			AuxLong := ExtractValue();
			IF (AuxLong=MAXLONGINT) THEN SyntaxError('#DB Unknown value "'+CurrentText+'"');
			IF (AuxLong<0) OR (AuxLong>255) THEN SyntaxError('DB value should be between 0 and 255');
			IF Verbose THEN WriteLn('#DB ' + CurrentText + '('+IntToStr(AuxLong)+') processed');
			AddProcessCondact(SomeEntryCondacts,CurrentIntVal , 0, CurrentCondactParams, true); // adds a fake condact, with the DB value as OPCODE and zero parameters
		END
		ELSE 	
		IF CurrentTokenID=T_DW THEN //DW
		BEGIN
			Scan();
			AuxLong := ExtractValue();
			IF (AuxLong=MAXLONGINT) THEN SyntaxError('#DW Unknown value "'+CurrentText+'"');
			IF (AuxLong<0) OR (AuxLong>65535) THEN SyntaxError('DW value should be between 0 and 65535');
			IF Verbose THEN WriteLn('#DW ' + CurrentText + '('+IntToStr(AuxLong)+') processed');
			AddProcessCondact(SomeEntryCondacts,CurrentIntVal AND $FF , 0, CurrentCondactParams, true); 
			AddProcessCondact(SomeEntryCondacts,(CurrentIntVal AND $FF00)>>8, 0, CurrentCondactParams, true); // adds DW as two DBs
		END 
		ELSE
		IF CurrentTokenID=T_HEX THEN // HEX
		BEGIN
			Scan();
			IF (CurrentTokenID<>T_STRING) THEN SyntaxError('HEX parameter should in between quotes');
			if (Length(CurrentText) MOD 2<>0) THEN SyntaxError('Invalid hexadecimal string');
			HexString := Copy(CurrentText, 2, Length(CurrentText)-2);
			WHILE (HexString<>'') DO
			BEGIN
			 HexByte := Copy(HexString, 1,2);
			 HexString := Copy(HexString,3,Length(HexString)-2);
			 AuxByte := Hex2Dec(HexByte);
			 AddProcessCondact(SomeEntryCondacts,AuxByte, 0, CurrentCondactParams, true); // Queues one fake condact per each hex value
			END;
			IF Verbose THEN WriteLn('#HEX ' + CurrentText + ' processed');
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
			IF Verbose THEN WriteLn('#incbin "' + Filename + '" processed.');
			WHILE NOT EOF(IncludedFile) DO
			BEGIN
				BlockRead(IncludedFile, AuxByte, 1);
				AddProcessCondact(SomeEntryCondacts,AuxByte, 0, CurrentCondactParams, true); // Queues one fake condact as DB does above, per byte in the file
			END;
			CloseFile(IncludedFile);
		END;
		CurrentCondact := CurrentCondact + 1;
	UNTIL Opcode < 0;	
	Result := HasJumps;
END;	

PROCEDURE ParseVerbNoun(var Verb: Longint; var  Noun: Longint);
VAR TheWord: AnsiString;
	AuxVocabularyTree :  TPVocabularyTree;
    ValidVerb : Boolean;
BEGIN
	Scan(); // Get the verb
	IF (CurrentTokenID<>T_NUMBER) AND (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_UNDERSCORE) THEN SyntaxError('Vocabulary verb expected but "'+CurrentText+'" found');
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
		IF (NOT ValidVerb) THEN SyntaxError('Verb not found in vocabulary: "' + CurrentText +'"');
		Verb := AuxVocabularyTree^.Value;
		END;

		Scan(); // Get Noun
		IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) AND (CurrentTokenID<>T_UNDERSCORE) THEN  SyntaxError('Vocabulary noun expected but "'+CurrentText+'" found');
		IF (CurrentTokenID = T_UNDERSCORE) THEN Noun := NO_WORD
		ELSE
		BEGIN
			TheWord := Copy(CurrentText, 1, VOCABULARY_LENGTH);
			AuxVocabularyTree := GetVocabulary(VocabularyTree, TheWord, VOC_NOUN);
			if (AuxVocabularyTree = nil) THEN SyntaxError('Noun not found in vocabulary: "'+CurrentText+'"');
			Noun := AuxVocabularyTree^.Value;
		END;
END;


(* Please notice entries can hav synonym entries, for instance:

> UNLOCK GATE
> OPEN DOOR
   AT lGatesOfDoom
   NOTCARR oKey
   MESSSAGE "You don't have the key."
   DONE

Its the same as:

> UNLOCK GATE
   AT lGatesOfDoom
   NOTCARR oKey
   MESSSAGE "You don't have the key."
   DONE

> OPEN DOOR
   AT lGatesOfDoom
   NOTCARR oKey
   MESSSAGE "You don't have the key."
   DONE
*)




PROCEDURE ParseProcessEntries(CurrentProcess: Longint);
VAR 	Verb, Noun : Longint;
	EntryCondacts :  TPProcessCondactList;
	VerbNouns : array of longint;
	i : integer;
	CurrentEntry : Word;
	HasJumps : boolean;
BEGIN
	CurrentEntry := 0;
	Scan(); // Get > sign, label,  or next process
	REPEAT
	 IF (CurrentTokenID<>T_PROCESS_ENTRY_SIGN) AND  (CurrentTokenID<>T_SECTION_PRO) AND  (CurrentTokenID<>T_SECTION_END) AND (CurrentTokenID<>T_LABEL) THEN SyntaxError('Label or entry sign ">" expected  but "'+CurrentText+'" found');

     IF (CurrentTokenID <> T_SECTION_PRO) AND  (CurrentTokenID<>T_SECTION_END) THEN
     BEGIN
	 	  IF (CurrentTokenID=T_LABEL) THEN // A label
		  BEGIN
		    // try to create a new label reference
		  	IF (AddLabel(CurrentText, CurrentProcess, CurrentEntry, false,-1)=-1) THEN SyntaxError('Label already defined ('+CurrentText+') or too many labels');
			IF Verbose THEN WriteLn('Label '+CurrentText+' created at process #'+IntToStr(CurrentProcess)+', entry #', IntToStr(CurrentEntry),'.');
			Scan();
		  END
		  ELSE
		  BEGIN // A entry
			setLength(VerbNouns, 0);
			REPEAT  // Repeat per each synonym entry (check comment above this procedure to see what synonym entries are)
				ParseVerbNoun(Verb, Noun);
				setLength(VerbNouns, Length(VerbNouns)+2);
				VerbNouns[High(VerbNouns)-1] := Verb;
				VerbNouns[High(VerbNouns)] := Noun;
				Scan();
			UNTIL CurrentTokenID<>T_PROCESS_ENTRY_SIGN;
			EntryCondacts := nil;
			HasJumps := ParseProcessCondacts(EntryCondacts, CurrentProcess, CurrentEntry);
			// Dump condacts once per each synonym entry
			for i:=0 to ((Length(VerbNouns) DIV 2) -1) DO AddProcessEntry(Processes[CurrentProcess].Entries, VerbNouns[i*2], VerbNouns[i*2+1], EntryCondacts, HasJumps);
			CurrentEntry := CurrentEntry + (Length(VerbNouns) DIV 2);
		END;
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
		IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) THEN SyntaxError('Process number expected but "'+CurrentText+'" found');
		ProcNum := GetIdentifierValue();
		IF (Procnum = MAXLONGINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
		IF ProcNum<>CurrentProcess THEN SyntaxError('Definition for process #' + IntToStr(CurrentProcess) + ' expected but process #' + IntToStr(ProcNum) + ' found');
		ProcessCount := ProcessCount + 1;
		ParseProcessEntries(CurrentProcess);
    	Inc(CurrentProcess);
	UNTIL CurrentTokenID = T_SECTION_END;
END; 		

PROCEDURE Sintactic(ATarget, ASubtarget: AnsiString);
BEGIN
	CurrTokenPTR := TokenList;
	ClassicMode := false;
	MaluvaUsed := false;
	DebugMode := false;
	MTXCount := 0;
	STXCount := 0;
	LTXCount := 0;
	OTXCount := 0;
	OtherTXCount := 0;
	Target := ATarget;
	Subtarget := ASubtarget;
	GlobalNestedIfdefCount := 0;
	ParseCTL();
	ParseVOC();
	ParseSTX();
	ParseMTX();
	ParseOTX();
	ParseLTX();
	ParseCON();
	ParseOBJ();
	ParsePRO();
	if (GlobalNestedIfdefCount<>0) THEN SyntaxError( IntToStr(GlobalNestedIfdefCount)+' #endif(s) missing.');
END;

END.
