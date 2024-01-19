UNIT UCondacts;
{$MODE OBJFPC}

INTERFACE

USES UConstants;

type TParamType = (none, locno, objno, flagno, sysno, mesno, procno, value, locno_, percent, 
				  vocabularyVerb, vocabularyNoun, vocabularyPrep, vocabularyAdverb, vocabularyAdjective, 
				  skip, string_,mesno2,
				  window, // 0-7
				  bitno // 0-15
				  );

TYPE TCondact = record
				 NumParams : Byte;
				 Condact : String;
				 Type1: TParamType;
				 Type2: TParamType;
				 Type3: TParamType;
				 CanBeJump : Boolean; // If true, its a condition that can be converted into Maluva JUMP
				end; 


CONST Condacts : ARRAY[0..NUM_CONDACTS+NUM_FAKE_CONDACTS - 1] OF TCondact = (
(NumParams:1;Condact:'AT'    ;Type1: locno; Type2: none; Type3: none; CanBeJump: true), //   0
(NumParams:1;Condact:'NOTAT' ;Type1: locno; Type2: none; Type3: none; CanBeJump: true), //   1
(NumParams:1;Condact:'ATGT'  ;Type1: locno; Type2: none; Type3: none; CanBeJump: true), //   2
(NumParams:1;Condact:'ATLT'  ;Type1: locno; Type2:none; Type3: none; CanBeJump: true), //   3
(NumParams:1;Condact:'PRESENT';Type1: objno; Type2: none; Type3: none; CanBeJump: true), //   4
(NumParams:1;Condact:'ABSENT' ;Type1: objno; Type2: none; Type3: none; CanBeJump: true), //   5
(NumParams:1;Condact:'WORN'  ;Type1: objno; Type2: none; Type3: none; CanBeJump: true), //   6
(NumParams:1;Condact:'NOTWORN';Type1: objno; Type2: none; Type3: none; CanBeJump: true), //   7
(NumParams:1;Condact:'CARRIED';Type1: objno; Type2: none; Type3: none; CanBeJump: true), //   8
(NumParams:1;Condact:'NOTCARR';Type1: objno; Type2: none; Type3: none; CanBeJump: true), //   9
(NumParams:1;Condact:'CHANCE' ;Type1: percent; Type2: none; Type3: none; CanBeJump: true), //  10
(NumParams:1;Condact:'ZERO'  ;Type1: flagno; Type2: none; Type3: none; CanBeJump: true), //  11
(NumParams:1;Condact:'NOTZERO';Type1: flagno; Type2: none; Type3: none; CanBeJump: true), //  12
(NumParams:2;Condact:'EQ'    ;Type1: flagno; Type2: value; Type3: none; CanBeJump: true), //  13
(NumParams:2;Condact:'GT'    ;Type1: flagno; Type2: value; Type3: none; CanBeJump: true), //  14
(NumParams:2;Condact:'LT'    ;Type1: flagno; Type2: value; Type3: none; CanBeJump: true), //  15
(NumParams:1;Condact:'ADJECT1';Type1: vocabularyAdjective; Type2: none; Type3: none; CanBeJump: true), //  16
(NumParams:1;Condact:'ADVERB' ;Type1: vocabularyAdverb; Type2: none; Type3: none; CanBeJump: true), //  17
(NumParams:2;Condact:'SFX'   ;Type1: value; Type2: value; Type3: none; CanBeJump: false), //  18 
(NumParams:1;Condact:'DESC'  ;Type1: locno; Type2: none; Type3: none; CanBeJump: false), //  19
(NumParams:0;Condact:'QUIT'  ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  20
(NumParams:0;Condact:'END'   ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  21
(NumParams:0;Condact:'DONE'  ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  22
(NumParams:0;Condact:'OK'    ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  23
(NumParams:0;Condact:'ANYKEY' ;Type1: none; Type2: none ; Type3: none; CanBeJump: false), //  24
(NumParams:1;Condact:'SAVE'  ;Type1: value; Type2: none; Type3: none; CanBeJump: false), //  25
(NumParams:1;Condact:'LOAD'  ;Type1: value; Type2: none; Type3: none; CanBeJump: false), //  26
(NumParams:1;Condact:'DPRINT' ;Type1: flagno; Type2: none; Type3: none; CanBeJump: false), //  27 
(NumParams:1;Condact:'DISPLAY';Type1: value; Type2: none; Type3: none; CanBeJump: false), //  28 
(NumParams:0;Condact:'CLS'   ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  29
(NumParams:0;Condact:'DROPALL';Type1: none; Type2: none; Type3: none; CanBeJump: false), //  30
(NumParams:0;Condact:'AUTOG' ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  31
(NumParams:0;Condact:'AUTOD' ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  32
(NumParams:0;Condact:'AUTOW' ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  33
(NumParams:0;Condact:'AUTOR' ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  34
(NumParams:1;Condact:'PAUSE' ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  35
(NumParams:2;Condact:'SYNONYM';Type1: vocabularyVerb; Type2: vocabularyNoun; Type3: none; CanBeJump: false), //  36
(NumParams:1;Condact:'GOTO'  ;Type1: locno; Type2: none; Type3: none; CanBeJump: false), //  37
(NumParams:1;Condact:'MESSAGE';Type1: mesno; Type2: none; Type3: none; CanBeJump: false), //  38
(NumParams:1;Condact:'REMOVE' ;Type1: objno; Type2: none; Type3: none; CanBeJump: false), //  39
(NumParams:1;Condact:'GET'   ;Type1: objno; Type2: none; Type3: none; CanBeJump: false), //  40
(NumParams:1;Condact:'DROP'  ;Type1: objno; Type2: none; Type3: none; CanBeJump: false), //  41
(NumParams:1;Condact:'WEAR'  ;Type1: objno; Type2: none; Type3: none; CanBeJump: false), //  42
(NumParams:1;Condact:'DESTROY';Type1: objno; Type2: none; Type3: none; CanBeJump: false), //  43
(NumParams:1;Condact:'CREATE' ;Type1: objno; Type2: none; Type3: none; CanBeJump: false), //  44
(NumParams:2;Condact:'SWAP'  ;Type1: objno; Type2: objno; Type3: none; CanBeJump: false), //  45
(NumParams:2;Condact:'PLACE' ;Type1: objno; Type2: locno_; Type3: none; CanBeJump: false), //  46
(NumParams:1;Condact:'SET'   ;Type1: flagno; Type2: none; Type3: none; CanBeJump: false), //  47
(NumParams:1;Condact:'CLEAR' ;Type1: flagno; Type2: none; Type3: none; CanBeJump: false), //  48
(NumParams:2;Condact:'PLUS'  ;Type1: flagno; Type2: value; Type3: none; CanBeJump: false), //  49
(NumParams:2;Condact:'MINUS' ;Type1: flagno; Type2: value; Type3: none; CanBeJump: false), //  50
(NumParams:2;Condact:'LET'   ;Type1: flagno; Type2: value; Type3: none; CanBeJump: false), //  51
(NumParams:0;Condact:'NEWLINE';Type1: none; Type2: none; Type3: none; CanBeJump: false), //  52
(NumParams:1;Condact:'PRINT' ;Type1: flagno; Type2: none; Type3: none; CanBeJump: false), //  53
(NumParams:1;Condact:'SYSMESS';Type1: sysno; Type2: none; Type3: none; CanBeJump: false), //  54
(NumParams:2;Condact:'ISAT'  ;Type1: objno; Type2: locno_; Type3: none; CanBeJump: true), //  55
(NumParams:1;Condact:'SETCO' ;Type1: objno; Type2: none; Type3: none; CanBeJump: false), //  56  
(NumParams:0;Condact:'SPACE' ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  57 
(NumParams:1;Condact:'HASAT' ;Type1: value; Type2: none; Type3: none; CanBeJump: true), //  58  
(NumParams:1;Condact:'HASNAT' ;Type1: value; Type2: none; Type3: none; CanBeJump: true), //  59 
(NumParams:0;Condact:'LISTOBJ';Type1: none; Type2: none; Type3: none; CanBeJump: false), //  60
(NumParams:2;Condact:'EXTERN' ;Type1: value; Type2: value; Type3: none; CanBeJump: false), //  61
(NumParams:0;Condact:'RAMSAVE';Type1: none; Type2: none; Type3: none; CanBeJump: false), //  62
(NumParams:1;Condact:'RAMLOAD';Type1: flagno; Type2: none; Type3: none; CanBeJump: false), //  63
(NumParams:2;Condact:'BEEP'  ;Type1: value; Type2: value; Type3: none; CanBeJump: false), //  64
(NumParams:1;Condact:'PAPER' ;Type1: value; Type2: none; Type3: none; CanBeJump: false), //  65
(NumParams:1;Condact:'INK'   ;Type1: value; Type2: none; Type3: none; CanBeJump: false), //  66
(NumParams:1;Condact:'BORDER' ;Type1: value; Type2: none; Type3: none; CanBeJump: false), //  67
(NumParams:1;Condact:'PREP'  ;Type1: vocabularyPrep; Type2: none; Type3: none; CanBeJump: true), //  68
(NumParams:1;Condact:'NOUN2' ;Type1: vocabularyNoun; Type2: none; Type3: none; CanBeJump: true), //  69
(NumParams:1;Condact:'ADJECT2';Type1: vocabularyAdjective; Type2: none; Type3: none; CanBeJump: true), //  70
(NumParams:2;Condact:'ADD'   ;Type1: flagno; Type2: flagno; Type3: none; CanBeJump: false), //  71
(NumParams:2;Condact:'SUB'   ;Type1: flagno; Type2: flagno; Type3: none; CanBeJump: false), //  72
(NumParams:1;Condact:'PARSE' ;Type1: value; Type2: none; Type3: none; CanBeJump: false), //  73
(NumParams:1;Condact:'LISTAT' ;Type1: locno_; Type2: none; Type3: none; CanBeJump: false), //  74
(NumParams:1;Condact:'PROCESS';Type1: procno; Type2: none; Type3: none; CanBeJump: false), //  75
(NumParams:2;Condact:'SAME'  ;Type1: flagno; Type2: flagno; Type3: none; CanBeJump: true), //  76
(NumParams:1;Condact:'MES'   ;Type1: mesno; Type2: none; Type3: none; CanBeJump: false), //  77
(NumParams:1;Condact:'WINDOW' ;Type1: window; Type2: none; Type3: none; CanBeJump: false), //  78
(NumParams:2;Condact:'NOTEQ' ;Type1: flagno; Type2: value; Type3: none; CanBeJump: true), //  79
(NumParams:2;Condact:'NOTSAME';Type1: flagno; Type2: flagno; Type3: none; CanBeJump: true), //  80
(NumParams:1;Condact:'MODE'  ;Type1: value; Type2: none; Type3: none; CanBeJump: false), //  81
(NumParams:2;Condact:'WINAT' ;Type1: value; Type2: value; Type3: none; CanBeJump: false), //  82
(NumParams:2;Condact:'TIME'  ;Type1: value; Type2: value; Type3: none; CanBeJump: false), //  83
(NumParams:1;Condact:'PICTURE';Type1: value; Type2: none; Type3: none; CanBeJump: false), //  84
(NumParams:1;Condact:'DOALL' ;Type1: locno_; Type2: none; Type3: none; CanBeJump: false), //  85
(NumParams:1;Condact:'MOUSE' ;Type1: value; Type2: none; Type3: none; CanBeJump: false), //  86
(NumParams:2;Condact:'GFX'   ;Type1: value; Type2: value; Type3: none; CanBeJump: false), //  87
(NumParams:2;Condact:'ISNOTAT';Type1: objno; Type2: locno_; Type3: none; CanBeJump: true), //  88
(NumParams:2;Condact:'WEIGH' ;Type1: objno; Type2: flagno; Type3: none; CanBeJump: false), //  89
(NumParams:2;Condact:'PUTIN' ;Type1: objno; Type2: locno; Type3: none; CanBeJump: false), //  90
(NumParams:2;Condact:'TAKEOUT';Type1: objno; Type2: locno; Type3: none; CanBeJump: false), //  91
(NumParams:0;Condact:'NEWTEXT';Type1: none; Type2: none; Type3: none; CanBeJump: false), //  92
(NumParams:2;Condact:'ABILITY';Type1: value; Type2: value; Type3: none; CanBeJump: false), //  93
(NumParams:1;Condact:'WEIGHT' ;Type1: flagno; Type2: none; Type3: none; CanBeJump: false), //  94
(NumParams:1;Condact:'RANDOM' ;Type1: flagno; Type2: none; Type3: none; CanBeJump: false), //  95
(NumParams:2;Condact:'INPUT' ;Type1: value; Type2: value; Type3: none; CanBeJump: false), //  96 
(NumParams:0;Condact:'SAVEAT' ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  97
(NumParams:0;Condact:'BACKAT' ;Type1: none; Type2: none; Type3: none; CanBeJump: false), //  98
(NumParams:2;Condact:'PRINTAT';Type1: value; Type2: value; Type3: none; CanBeJump: false), //  99
(NumParams:0;Condact:'WHATO' ;Type1: none; Type2: none; Type3: none; CanBeJump: false), // 100
(NumParams:2;Condact:'CALL'  ;Type1: value; Type2: value; Type3: none; CanBeJump: false), // 101
(NumParams:1;Condact:'PUTO'  ;Type1: locno_; Type2: none; Type3: none; CanBeJump: false), // 102 ;: revisart
(NumParams:0;Condact:'NOTDONE';Type1: none; Type2: none; Type3: none; CanBeJump: false), // 103
(NumParams:1;Condact:'AUTOP' ;Type1: locno; Type2: none; Type3: none; CanBeJump: false), // 104
(NumParams:1;Condact:'AUTOT' ;Type1: locno; Type2: none; Type3: none; CanBeJump: false), // 105
(NumParams:1;Condact:'MOVE'  ;Type1: flagno; Type2: none; Type3: none; CanBeJump: false), // 106
(NumParams:2;Condact:'WINSIZE';Type1: value; Type2: value; Type3: none; CanBeJump: false), // 107
(NumParams:0;Condact:'REDO'  ;Type1: none; Type2: none; Type3: none; CanBeJump: false), // 108
(NumParams:0;Condact:'CENTRE' ;Type1: none; Type2: none; Type3: none; CanBeJump: false), // 109
(NumParams:1;Condact:'EXIT'  ;Type1: value; Type2: none; Type3: none; CanBeJump: false), // 110
(NumParams:0;Condact:'INKEY' ;Type1: none; Type2: none; Type3: none; CanBeJump: false), // 111 
(NumParams:2;Condact:'BIGGER' ;Type1: flagno; Type2: flagno; Type3: none; CanBeJump: true), // 112
(NumParams:2;Condact:'SMALLER';Type1: flagno; Type2: flagno; Type3: none; CanBeJump: true), // 113 
(NumParams:0;Condact:'ISDONE' ;Type1: none; Type2: none; Type3: none; CanBeJump: true), // 114
(NumParams:0;Condact:'ISNDONE';Type1: none; Type2: none; Type3: none; CanBeJump: true), // 115 
(NumParams:1;Condact:'SKIP'  ;Type1: skip; Type2: none; Type3: none; CanBeJump: false), // 116 
(NumParams:0;Condact:'RESTART';Type1: none; Type2: none; Type3: none; CanBeJump: false), // 117 
(NumParams:1;Condact:'TAB'   ;Type1: value; Type2: none; Type3: none; CanBeJump: false), // 118
(NumParams:2;Condact:'COPYOF' ;Type1: objno; Type2: flagno; Type3: none; CanBeJump: false), // 119
(NumParams:0;Condact:'dumb'  ;Type1: none; Type2: none; Type3: none; CanBeJump: false), // 120 // In V3, this is PREFIX for prefixed condacts
(NumParams:2;Condact:'COPYOO' ;Type1: objno; Type2: objno; Type3: none; CanBeJump: false), // 121 
(NumParams:0;Condact:'dumb'  ;Type1: none; Type2: none; Type3: none; CanBeJump: false), // 122 // In V3, this is SETP2
(NumParams:2;Condact:'COPYFO' ;Type1: flagno; Type2: objno; Type3: none; CanBeJump: false), // 123
(NumParams:0;Condact:'dumb'  ;Type1: none; Type2: none; Type3: none; CanBeJump: false), // 124 // In V3, this is SETP2
(NumParams:2;Condact:'COPYFF' ;Type1: flagno; Type2: flagno; Type3: none; CanBeJump: false), // 125 
(NumParams:2;Condact:'COPYBF' ;Type1: flagno; Type2: flagno; Type3: none; CanBeJump: false), // 126 
(NumParams:0;Condact:'RESET' ;Type1: none; Type2: none; Type3: none; CanBeJump: false),  // 127 

// Additional fake condacts
(Numparams:1;Condact:'XMES';Type1: string_; Type2: none; Type3: none; CanBeJump: false),     //128
(Numparams:1;Condact:'XMESSAGE';Type1: string_; Type2: none; Type3: none; CanBeJump: false),  //129
(Numparams:1;Condact:'XPICTURE';Type1: value; Type2: none; Type3: none; CanBeJump: false),  //130
(Numparams:1;Condact:'XSAVE';Type1: value; Type2: none; Type3: none; CanBeJump: false),    //131
(Numparams:1;Condact:'XLOAD';Type1: value; Type2: none; Type3: none; CanBeJump: false),  //132
(Numparams:1;Condact:'XPART';Type1: value; Type2: none; Type3: none; CanBeJump: false),  //133
(Numparams:1;Condact:'XPLAY';Type1: string_; Type2: none; Type3: none; CanBeJump: false), //134
(Numparams:2;Condact:'XBEEP';Type1: value; Type2: value; Type3: none; CanBeJump: false), // 135
(Numparams:1;Condact:'XSPLITSCR';Type1: value; Type2: none; Type3: none; CanBeJump: false), //136
(Numparams:0;Condact:'XUNDONE';Type1: none; Type2: none; Type3: none; CanBeJump: false), //137
(Numparams:0;Condact:'XNEXTCLS';Type1: none; Type2: none; Type3: none; CanBeJump: false), //138
(Numparams:0;Condact:'XNEXTRST';Type1: none; Type2: none; Type3: none; CanBeJump: false), //139
(Numparams:1;Condact:'XSPEED';Type1: value; Type2: none; Type3: none; CanBeJump: false), //140
(Numparams:1;Condact:'PENDINGSKIP';Type1: value;Type2:none; Type3: none; CanBeJump: false), //141  This one is used internally by the compiler only
(Numparams:1;Condact:'XDATA';Type1: string_; Type2: none; Type3: none; CanBeJump: false) //142
);

CONST PrefixCondacts : ARRAY[0..NUM_PREFIX_CONDACTS-1] OF TCondact = (
	(Numparams:2;Condact:'BSET';Type1: flagno; Type2: bitno; Type3: none; CanBeJump: false), //0  BSET flagno bitno
	(Numparams:2;Condact:'BCLEAR';Type1: flagno; Type2: bitno; Type3: none; CanBeJump: false), //1 BCLEAR flagno bitno
	(Numparams:2;Condact:'BTOGGLE';Type1: flagno; Type2: bitno; Type3: none; CanBeJump: false), //2 BTOGGLE flagno bitno
	(Numparams:2;Condact:'BZERO';Type1: flagno; Type2: bitno; Type3: none; CanBeJump: false), //3 BZERO flagno bitno
	(Numparams:2;Condact:'BNOTZERO';Type1: flagno; Type2: bitno; Type3: none; CanBeJump: false), //4 BNOTZERO flagno bitno
	(Numparams:1;Condact:'SELECT';Type1: flagno; Type2: none; Type3: none; CanBeJump: false), //5 SELECT flagno 
	(Numparams:2;Condact:'OPTION';Type1: value; Type2:string_; Type3: none; CanBeJump: false), //6 OPTION value "option"
	(Numparams:0;Condact:'CHOICE';Type1: none; Type2: none; Type3: none; CanBeJump: false), //7 CHOICE 
	(Numparams:1;Condact:'TOGGLECON';Type1: vocabularyVerb; Type2: none; Type3: none; CanBeJump: false), //8 TOGGLECON verb
	(Numparams:1;Condact:'MES2';Type1: mesno2; Type2: none; Type3: none; CanBeJump: false) //9 MES2 mesno, internal condact, not documented nor usable from DSF file

	 
);

(* Returns the condact index in the codacts table, or -1 if not found*)
FUNCTION GetCondact(Condact : String): Integer;

(* Returns number of condacts for a given condact code *)
FUNCTION GetNumParams(Opcode: Longint): Byte;

(* Performs semantic check for parameters *)
FUNCTION SemanticCheck(Opcode: Longint; ParamNum: Byte; ParamValue: Byte;ParamAsString: AnsiString): AnsiString;


IMPLEMENTATION	

USES SysUtils, UMessageList, UVocabularyTree;

FUNCTION GetCondact(Condact : String): Integer;
VAR i : integer;
	found : boolean;
BEGIN
  IF (UpperCase(Condact)=FAKE_DEBUG_CONDACT_TEXT) THEN
	BEGIN
	 Result := FAKE_DEBUG_CONDACT_CODE;
	END
	ELSE
	BEGIN 
		i := 0;
		found := false;
		while (i < NUM_CONDACTS+NUM_FAKE_CONDACTS) AND (NOT found) DO
		BEGIN
			if (AnsiUpperCase(Condact) = AnsiUpperCase(Condacts[i].Condact)) THEN
			BEGIN
				Result := i;
				found := true;
			END;
			Inc(i);	
		END;
		
		IF (NOT FOUND) AND (V3CODE) THEN // Search for Prefixed Condacts
		BEGIN
			i := 0;
			while (i < NUM_PREFIX_CONDACTS) AND (NOT found) DO
			BEGIN
				if (AnsiUpperCase(Condact) = AnsiUpperCase(PrefixCondacts[i].Condact)) THEN
				BEGIN
					Result := i + 512; // returns the condact id + 512
					found := true;
				END;
				Inc(i);	
			END;
		END;
		IF NOT FOUND THEN Result := -1;
	END;
END;

FUNCTION GetNumParams(Opcode: Longint): Byte;
BEGIN
 IF Opcode = FAKE_DEBUG_CONDACT_CODE THEN Result :=0 
   ELSE IF (((Opcode AND 512) = 512) AND V3CODE) THEN Result := PrefixCondacts[Opcode - 512].NumParams 
												 ELSE Result := Condacts[Opcode].NumParams;
END;

FUNCTION GetParamType(Opcode:Longint; ParamNum: Byte): TParamType;
BEGIN
 IF (((Opcode AND 512) = 512) AND V3CODE) THEN
 BEGIN
	if (ParamNum = 1) THEN Result := PrefixCondacts[Opcode-512].Type1
		ELSE if (ParamNum = 2) THEN Result := PrefixCondacts[Opcode - 512].Type2
			ELSE Result := PrefixCondacts[Opcode-512].Type3;
 END
 ELSE
 BEGIN
	if (ParamNum = 1) THEN Result := Condacts[Opcode].Type1
		ELSE if (ParamNum = 2) THEN Result := Condacts[Opcode].Type2
			ELSE Result := Condacts[Opcode].Type3;
  END;		
END;

FUNCTION SemanticVocabularyCheck(VocType: TVocType; AWord: AnsiString):AnsiString;
VAR	AVocabularyTree: TPVocabularyTree;
BEGIN
	IF Aword='_' THEN Result := ''
	ELSE
	BEGIN
		if (Length(AWord)>5) THEN AWord := Copy(Aword, 1, 5);
		Aword := AnsiUpperCase(AWord);
		AVocabularyTree := GetVocabulary(VocabularyTree,AWord,VocType);
		IF AVocabularyTree = nil THEN Result:='Word not defined in vocabulary or it has an unexpected word type : ' + AWord
								ELSE Result := '';
    END;								
END;


FUNCTION SemanticCheck(Opcode: Longint; ParamNum: Byte; ParamValue: Byte; ParamAsString: AnsiString): AnsiString;
VAR ExpectedType : TParamType;
BEGIN
 ExpectedType := GetParamType(Opcode, ParamNum);
 Result := '';
 CASE ExpectedType OF
	locno: IF ParamValue >= LTXCount THEN Result := 'Location ' + IntToStr(ParamValue) + ' does not exist';
	objno: IF ParamValue >= OTXCount THEN Result := 'Object ' + IntToStr(ParamValue) + ' does not exist';
	flagno: Result := '';
	sysno: IF ParamValue >= STXCount THEN Result := 'System message ' + IntToStr(ParamValue) + ' does not exist';
	mesno: IF ParamValue >= MTXCount THEN Result := 'Message ' + IntToStr(ParamValue) + ' does not exist';
	mesno2: IF ParamValue >= MTX2Count THEN Result := 'Message ' + IntToStr(ParamValue) + ' does not exist';
	procno: Result := ''; // For the time being we don't check procno as there could be forward references
	value: Result := '';
	locno_: IF (ParamValue >= LTXCount) AND (ParamValue< 252) THEN Result := 'Location  ' + IntToStr(ParamValue) + ' does not exist';
	percent: IF (ParamValue >= 100) OR (ParamValue=0) THEN Result := 'Invalid percent value, must be in the 1-99 range';
	vocabularyVerb : Result := SemanticVocabularyCheck(VOC_VERB, ParamAsString);
	vocabularyNoun : Result := SemanticVocabularyCheck(VOC_NOUN, ParamAsString);
	vocabularyPrep : Result := SemanticVocabularyCheck(VOC_PREPOSITION, ParamAsString);
	vocabularyAdjective : Result := SemanticVocabularyCheck(VOC_ADJECT, ParamAsString);
	vocabularyAdverb : Result := SemanticVocabularyCheck(VOC_ADVERB, ParamAsString);
	skip: Result := '';
	string_ : Result := '';
	window :  IF ParamValue > 7  THEN Result := 'Invalid window number, must be in the 0-7 range';
	ELSE Result := '';
 END; //case
END;


END.
