UNIT USintactic;
{$MODE OBJFPC}
{$H+}{$R+}

INTERFACE

USES UTokenList;

PROCEDURE Sintactic(ATarget, ASubtarget: AnsiString);

var ClassicMode : Boolean;
	DebugMode : Boolean;
	Target, Subtarget: AnsiString;
	MaluvaUsed : Boolean;



IMPLEMENTATION

USES sysutils, UConstants, ULexTokens, USymbolList, UVocabularyTree, UMessageList, UCondacts, UConnections, UObjects, UProcess, UProcessCondactList, UCTLExtern,fpexprpars, strings, strutils;

VAR CurrentText: AnsiString;
	CurrentIntVal : Longint;
	CurrentTokenID : Word;
	CurrLineno : Longint;
	CurrColno : Word;
	CurrTokenPTR: TPTokenList;
	OnIfdefMode : boolean;
	OnElse :Boolean;
	
PROCEDURE SyntaxError(msg: String);
BEGIN
  Writeln(CurrLineno,':', CurrColno, ': ', msg,'.');
  Halt(1);
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

FUNCTION ExtractValue():Longint;
BEGIN
	IF (CurrentTokenID=T_STRING) THEN Result := GetExpressionValue() ELSE 
	IF (CurrentTokenID=T_NUMBER) OR (CurrentTokenID= T_IDENTIFIER) THEN Result := GetIdentifierValue() ELSE Result := MAXINT;
	IF (Result = MAXINT) AND (CurrentTokenID=T_STRING) THEN SyntaxError('"'+CurrentText+'" is not a valid expression');
	IF (Result = MAXINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
END;

PROCEDURE ParseDefine();
VAR Symbol : AnsiString;
	Value : Longint;	
BEGIN
	Scan();
	if (CurrentTokenID<>T_IDENTIFIER) THEN SyntaxError('Identifier expected after #define' );
	Symbol := CurrentText;
	Scan();
  Value := ExtractValue();
	if NOT AddSymbol(SymbolList, Symbol, Value) THEN SyntaxError('"' + Symbol + '" already defined');
END;

FUNCTION getMaluvaFilename(): String;
BEGIN
  IF (target='ZX') AND (Subtarget='P3') THEN Result:='MLV_P3.BIN' ELSE
  IF (target='ZX') AND (Subtarget='NEXT') THEN Result:='MLV_NEXT.BIN' ELSE
  IF (target='ZX') AND (Subtarget='ESXDOS') THEN Result:='MLV_ESX.BIN' ELSE
  IF target='MSX' THEN Result:='MLV_MSX.BIN' ELSE
  IF target='C64' THEN Result:='MLV_C64.BIN' ELSE
  IF target='CPC' THEN Result:='MLV_CPC.BIN' ELSE  Result:='MALUVA';
END;

PROCEDURE ParseExtern(ExternType: String);
VAR Filename : String;
BEGIN
	Scan();
	IF CurrentTokenID <> T_STRING THEN SyntaxError('Included extern file should be in between quotes');
	FileName := Copy(CurrentText, 2, length(CurrentText) - 2);
	IF Filename = 'MALUVA' THEN FileName := getMaluvaFilename();
	IF NOT FileExists(Filename) THEN SyntaxError('Extern file "'+FileName+'" not found');
	WriteLn('#'+ExternType+''' "' + Filename + '" processed.');
	AddCTL_Extern(CTLExternList, FileName, ExternType); // Adds the file to binary files to be included
END;


PROCEDURE ParseEcho();
BEGIN
 Scan();
 IF (CurrentTokenID<>T_STRING) THEN SyntaxError('Invalid string for #echo');
 WriteLn(CurrentText);
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
		T_IFDEF, T_IFNDEF: BEGIN
													IF OnIfdefMode or OnElse THEN SyntaxError('Nested #ifdef/#ifndef');
						 					 		if CurrTokenPTR^.Next = nil THEN SyntaxError('Unexpected end of file just after #ifdef/#ifndef');
	 												CurrTokenPTR := CurrTokenPTR^.Next;
													if CurrTokenPTR^.TokenID <> T_STRING THEN SyntaxError('Invalid #ifdef/#ifndef label, please include the label in betwween quotes');
	 												MyDefine := CurrTokenPTR^.Text;
	 												MyDefine := Copy(MyDefine, 2, Length(MyDefine) - 2);
	 												Evaluation:= GetSymbolValue(SymbolList, MyDefine)<>MAXINT;
	 												IF CurrentTokenID = T_IFNDEF THEN Evaluation:= not Evaluation;
													IF NOT Evaluation THEN // ifdef/ifndef failed
													BEGIN
														WHILE (CurrTokenPTR<>nil) AND (CurrTokenPTR^.TokenID<>T_ENDIF)  AND (CurrTokenPTR^.TokenID<>T_ELSE) DO 
		 												BEGIN
		 													CurrTokenPTR := CurrTokenPTR^.Next;
															IF CurrTokenPTR<>nil THEN
															BEGIN
																CurrentTokenID := CurrTokenPTR^.TokenID;
																IF (CurrentTokenID=T_IFDEF) OR (CurrentTokenID=T_IFNDEF) THEN SyntaxError('Nested #ifdef/#ifndef not allowed');
															END;	
														END;
														IF (CurrTokenPTR=nil) THEN SyntaxError('Unexpected end of file. #ifdef/#ifndef couldn''t find #endif while in failed condition "'+MyDefine+'"');
														IF (CurrentTokenID = T_ELSE) THEN
														BEGIN
															OnIfdefMode := true;
															OnElse := true;
														END;
													END
													ELSE 
													BEGIN // IF EVALUATION OK
														OnIfdefMode := true;
													END;	 
											 END;	
		T_ENDIF: BEGIN
							 IF NOT OnIfdefMode THEN SyntaxError('#endif without #ifdef/#ifndef');
							 OnIfdefMode := false;
               OnElse := false;
						 END;
		T_ELSE:  BEGIN // If we get to an ELSE directly, it means the #ifdef/#ifndef evaluation was succesful, so we must be in ifdefmode
						  IF OnElse THEN SyntaxError('Nested #else');
		          IF NOT OnIfdefMode THEN SyntaxError('#else without #ifdef/#ifndef');
							OnElse := true;
							// That also means the part after the #else should be skipped
							WHILE (CurrTokenPTR<>nil) AND (CurrTokenPTR^.TokenID<>T_ENDIF) DO 
							BEGIN
								CurrTokenPTR := CurrTokenPTR^.Next;
								IF CurrTokenPTR<>nil THEN
							  BEGIN
									CurrentTokenID := CurrTokenPTR^.TokenID;
									IF (CurrentTokenID=T_IFDEF) OR (CurrentTokenID=T_IFNDEF) OR (CurrentTokenID=T_ELSE) THEN SyntaxError('Nested #ifdef/#ifndef/#else not allowed');
								END;	
							END;
							IF (CurrTokenPTR=nil) THEN SyntaxError('Unexpected end of file. #ifdef/#ifndef couldn''t find #endif while in failed condition "'+MyDefine+'"');
						 END;
		T_ECHO: ParseEcho();
    T_EXTERN: ParseExtern('EXTERN');
		T_INT: ParseExtern('INT');
		T_SFX: ParseExtern('SFX');
		T_CLASSIC: ClassicMode := true;
		T_DEBUG: DebugMode := true;
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
		IF (CurrentTokenID <> T_LIST_ENTRY) THEN SyntaxError('Location entry expected but "'+CurrentText+'" found');
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
			IF CurrentIntVal<>CurrentObj THEN SyntaxError('Definition for object #' + IntToStr(Currentobj) + ' expected but object #' + IntToStr(CurrentIntVal) + ' found');
			IF (CurrentIntVal>=OTXCount) THEN SyntaxError ('Object #' + IntToStr(CurrentIntVal) + ' not defined');

			Scan(); // Get Initialy At
			IF (CurrentTokenID<>T_IDENTIFIER) AND (CurrentTokenID<>T_NUMBER) AND (CurrentTokenID<>T_UNDERSCORE) THEN SyntaxError('Object initial location expected but "'+CurrentText+'" found');
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
  IF AuxVocabularyPTR = nil THEN Result := MAXINT ELSE  Result := AuxVocabularyPTR^.Value;
END;

PROCEDURE ParseProcessCondacts(var SomeEntryCondacts :  TPProcessCondactList);
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
BEGIN
	REPEAT
		IF (SomeEntryCondacts<>nil) THEN Scan(); // Get Condact, skip first time when the condact list is empy cause it's already read
		IF (CurrentTokenID <> T_IDENTIFIER)  AND (CurrentTokenID<>T_UNDERSCORE)  AND (CurrentTokenID<>T_SECTION_PRO) AND (CurrentTokenID<>T_SECTION_END)   AND (CurrentTokenID<>T_INCBIN) 
		 AND (CurrentTokenID<>T_DB) AND (CurrentTokenID<>T_DW) AND (CurrentTokenID<>T_NUMBER) AND (CurrentTokenID<>T_HEX) AND (CurrentTokenID<>T_USERPTR)	 
		 AND (CurrentTokenID<>T_PROCESS_ENTRY_SIGN)	 THEN SyntaxError('Condact, new process entry or new process expected but "'+CurrentText+'" found');

		IF (CurrentTokenID<>T_INCBIN) AND (CurrentTokenID<>T_DB) AND (CurrentTokenID<>T_DW) AND (CurrentTokenID<>T_HEX) AND (CurrentTokenID<>T_USERPTR) THEN
		BEGIN
		  IF (CurrentTokenID = T_PROCESS_ENTRY_SIGN) OR (CurrentTokenID = T_SECTION_END) OR (CurrentTokenID = T_SECTION_PRO) THEN Opcode := -2 ELSE Opcode := GetCondact(CurrentText);
		    
			IF Opcode >= 0 THEN
			BEGIN
				// Check what to do with fake condacts
				IF Opcode>=NUM_CONDACTS THEN  
				BEGIN
					IF Opcode = XPICTURE_OPCODE THEN
					BEGIN
						IF GetSymbolValue(SymbolList, 'BIT16')<>MAXINT THEN Opcode := PICTURE_OPCODE  // If 16 bit machine, no XPICTURE
						ELSE IF target='PCW' THEN Opcode := PICTURE_OPCODE // If target PCW, no XPICTURE
						ELSE MaluvaUsed := true;
					END ELSE
					IF Opcode = XSAVE_OPCODE THEN
					BEGIN
						IF GetSymbolValue(SymbolList, 'BIT16')<>MAXINT THEN Opcode := SAVE_OPCODE  // If 16 bit machine, no XSAVE
						ELSE IF (Target='PCW') OR (Target='CPC') OR (Target='C64') THEN Opcode := SAVE_OPCODE // If target PCW/C64/CPC, no XSAVE
						ELSE MaluvaUsed := true;
					END ELSE
					IF Opcode = XLOAD_OPCODE THEN
					BEGIN
						IF GetSymbolValue(SymbolList, 'BIT16')<>MAXINT THEN Opcode := LOAD_OPCODE  // If 16 bit machine, no XLOAD
						ELSE IF (Target='PCW') OR (Target='CPC') OR (Target='C64') THEN Opcode := LOAD_OPCODE // If target PCW/C64/CPC, no XLOAD
						ELSE MaluvaUsed := true;
					END;
				END; 
				// Get Parameters
				FOR i:= 0 TO GetNumParams(Opcode) - 1 DO
				BEGIN
					Scan();
					CurrentCondactParams[i].Indirection := false;
					IF (CurrentTokenID = T_INDIRECT) THEN
					BEGIN
					  IF I>=MAX_PARAM_ACCEPTING_INDIRECTION THEN SyntaxError('Indirection is not allowed in this parameter');
					  CurrentCondactParams[i].Indirection := true;
					  Scan();
					END;
			
					IF (CurrentTokenID = T_STRING) AND (Opcode in [MESSAGE_OPCODE,MES_OPCODE, SYSMESS_OPCODE, XMES_OPCODE, XMESSAGE_OPCODE]) THEN  
					BEGIN
						CurrentText := Copy(CurrentText, 2, Length(CurrentText)-2);
						IF (Opcode IN [XMES_OPCODE, XMESSAGE_OPCODE]) AND (GetSymbolValue(SymbolList, 'BIT16')=MAXINT) THEN  
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
						  CurrentIntVal := insertMessageFromProcess(Opcode, CurrentText, ClassicMode);
						  MaXMESs :=MAX_MESSAGES_PER_TABLE;
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
					IF (CurrentTokenID <> T_NUMBER) AND (CurrentTokenID <> T_IDENTIFIER) AND (CurrentTokenID<> T_UNDERSCORE) AND (CurrentTokenID<>T_STRING) THEN SyntaxError('Invalid condact parameter');

					// Lets'de termine the value of the parameter
					Value := MAXINT;
					// IF a string then eveluate expression
					if CurrentTokenID = T_STRING THEN  Value  := GetExpressionValue();
					// If  an underscore, value is clear
					IF CurrentTokenID = T_UNDERSCORE THEN Value:= NO_WORD;
					// Otherwise if the condact accepts words as parameters, check vocabulary first
					IF (Value = MAXINT) AND  (Opcode in [SYNONYM_OPCODE, PREP_OPCODE, NOUN2_OPCODE, ADJECT1_OPCODE, ADVERB_OPCODE, ADJECT2_OPCODE]) THEN Value:= GetWordParamValue(CurrentText, Opcode, i);
					// Otherwise, check the symbol table
					IF Value = MAXINT THEN Value := GetIdentifierValue();
					// if still the value is not found, check the Vocavulary again, but more openly
					IF Value = MAXINT THEN Value:= GetWordParamValue(CurrentText, 255);
					// If still Maxint, then it should be a bad parameter
					IF Value = MAXINT THEN SyntaxError('Invalid parameter #' + IntToStr(i+1) + ': "'+CurrentText+'"');
					IF (Opcode=SKIP_OPCODE) AND (Value<0) THEN Value := 256 + Value;
					IF (Opcode in [XMES_OPCODE, XMESSAGE_OPCODE]) THEN 
					BEGIN
						IF (Value<0) THEN SyntaxError('Invalid parameter value "'+CurrentText+'"');
					END 
					ELSE IF (Value<0)  OR (Value>MAX_PARAMETER_RANGE) THEN SyntaxError('Invalid parameter value "'+CurrentText+'"');
					
					CurrentCondactParams[i].Value := Value;
				END;
				AddProcessCondact(SomeEntryCondacts, Opcode, GetNumParams(Opcode), CurrentCondactParams, false);
			END 
			ELSE
			BEGIN
			 IF (Opcode=-1) THEN SyntaxError('Unknown condact: "'+CurrentText+'"'); // If opcode = -1, it was an invalid condact, otherwise we have found entry end because of another entry, another process or \END
			END 
		END ELSE
		IF CurrentTokenID=T_USERPTR THEN  // USERPTR
		BEGIN
			Scan();
			IF (CurrentTokenID<>T_NUMBER) THEN SyntaxError('#userptr parameter should be numeric');
			IF (CurrentIntVal<0) OR (CurrentIntVal>9) THEN SyntaxError('#userptr parameter should be 0-9');
			WriteLn('#USERPTR ' + CurrentText + ' processed');
			CurrentCondactParams[0].Value := CurrentIntVal;
			CurrentCondactParams[0].Indirection := false;
			AddProcessCondact(SomeEntryCondacts, FAKE_USERPTR_CONDACT_CODE , 1, CurrentCondactParams, false); // adds a fake condact value as OPCODE and zero parameters
		END
		ELSE 	
		IF CurrentTokenID=T_DB THEN //DB
		BEGIN
			Scan();
			AuxLong := ExtractValue();
			IF (AuxLong=MAXINT) THEN SyntaxError('#DB Unknown value "'+CurrentText+'"');
			IF (AuxLong<0) OR (AuxLong>255) THEN SyntaxError('DB value should be between 0 and 255');
			WriteLn('#DB ' + CurrentText + '('+IntToStr(AuxLong)+') processed');
			AddProcessCondact(SomeEntryCondacts,CurrentIntVal , 0, CurrentCondactParams, true); // adds a fake condact, with the DB value as OPCODE and zero parameters
		END
		ELSE 	
		IF CurrentTokenID=T_DW THEN //DW
		BEGIN
			Scan();
			AuxLong := ExtractValue();
			IF (AuxLong=MAXINT) THEN SyntaxError('#DW Unknown value "'+CurrentText+'"');
			IF (AuxLong<0) OR (AuxLong>65535) THEN SyntaxError('DW value should be between 0 and 65535');
			WriteLn('#DW ' + CurrentText + '('+IntToStr(AuxLong)+') processed');
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
			WriteLn('#HEX ' + CurrentText + ' processed');
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
	UNTIL Opcode < 0;
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
BEGIN
	Scan(); // Get > sign or next process
	REPEAT
	 IF (CurrentTokenID<>T_PROCESS_ENTRY_SIGN) AND  (CurrentTokenID<>T_SECTION_PRO) AND  (CurrentTokenID<>T_SECTION_END) THEN SyntaxError('Entry sign expected ">" but "'+CurrentText+'" found');

     IF (CurrentTokenID <> T_SECTION_PRO) AND  (CurrentTokenID<>T_SECTION_END) THEN
     BEGIN
	      setLength(VerbNouns, 0);
	      REPEAT  // Repeat per each synonym entry (check comment above this procedure to see what synonym entries are)
		  	ParseVerbNoun(Verb, Noun);
			setLength(VerbNouns, Length(VerbNouns)+2);
			VerbNouns[High(VerbNouns)-1] := Verb;
			VerbNouns[High(VerbNouns)] := Noun;
		  	Scan();
		  UNTIL CurrentTokenID<>T_PROCESS_ENTRY_SIGN;
		  EntryCondacts := nil;
		  ParseProcessCondacts(EntryCondacts);
		  // Dump condacts once per each synonym entry
		  for i:=0 to ((Length(VerbNouns) DIV 2) -1) DO AddProcessEntry(Processes[CurrentProcess].Entries, VerbNouns[i*2], VerbNouns[i*2+1], EntryCondacts);
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
		IF (Procnum = MAXINT) THEN SyntaxError('"' +CurrentText + '" is not defined');
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
	OnIfdefMode := false;
	MTXCount := 0;
	STXCount := 0;
	LTXCount := 0;
	OTXCount := 0;
	Target := ATarget;
	Subtarget := ASubtarget;
	ParseCTL();
	ParseVOC();
	ParseSTX();
	ParseMTX();
	ParseOTX();
	ParseLTX();
	ParseCON();
	ParseOBJ();
	ParsePRO();
END;

END.
