UNIT UCondacts;
{$MODE OBJFPC}

INTERFACE

USES UConstants;

type TParamType = (none, locno, objno, flagno, sysno, mesno, procno, value, locno_, percent, vocabulary, 
				   skip, string_,
				   window // 0-7
				   );

TYPE TCondact = record
				 NumParams : Byte;
				 Condact : String;
				 Type1: TParamType;
				 Type2: TParamType;
				end; 


CONST Condacts : ARRAY[0..NUM_CONDACTS+NUM_FAKE_CONDACTS - 1] OF TCondact = (
(NumParams:1;Condact:'AT'    ;Type1: locno; Type2: none), //   0
(NumParams:1;Condact:'NOTAT' ;Type1: locno; Type2: none), //   1
(NumParams:1;Condact:'ATGT'  ;Type1: locno; Type2: none), //   2
(NumParams:1;Condact:'ATLT'  ;Type1: locno; Type2:none), //   3
(NumParams:1;Condact:'PRESENT';Type1: objno; Type2: none), //   4
(NumParams:1;Condact:'ABSENT' ;Type1: objno; Type2: none), //   5
(NumParams:1;Condact:'WORN'  ;Type1: objno; Type2: none), //   6
(NumParams:1;Condact:'NOTWORN';Type1: objno; Type2: none), //   7
(NumParams:1;Condact:'CARRIED';Type1: objno; Type2: none), //   8
(NumParams:1;Condact:'NOTCARR';Type1: objno; Type2: none), //   9
(NumParams:1;Condact:'CHANCE' ;Type1: percent; Type2: none), //  10
(NumParams:1;Condact:'ZERO'  ;Type1: flagno; Type2: none), //  11
(NumParams:1;Condact:'NOTZERO';Type1: flagno; Type2: none), //  12
(NumParams:2;Condact:'EQ'    ;Type1: flagno; Type2: value), //  13
(NumParams:2;Condact:'GT'    ;Type1: flagno; Type2: value), //  14
(NumParams:2;Condact:'LT'    ;Type1: flagno; Type2: value), //  15
(NumParams:1;Condact:'ADJECT1';Type1: vocabulary; Type2: none), //  16
(NumParams:1;Condact:'ADVERB' ;Type1: vocabulary; Type2: none), //  17
(NumParams:2;Condact:'SFX'   ;Type1: value; Type2: value), //  18 
(NumParams:1;Condact:'DESC'  ;Type1: locno; Type2: none), //  19
(NumParams:0;Condact:'QUIT'  ;Type1: none; Type2: none), //  20
(NumParams:0;Condact:'END'   ;Type1: none; Type2: none), //  21
(NumParams:0;Condact:'DONE'  ;Type1: none; Type2: none), //  22
(NumParams:0;Condact:'OK'    ;Type1: none; Type2: none), //  23
(NumParams:0;Condact:'ANYKEY' ;Type1: none; Type2: none ), //  24
(NumParams:1;Condact:'SAVE'  ;Type1: value; Type2: none), //  25
(NumParams:1;Condact:'LOAD'  ;Type1: value; Type2: none), //  26
(NumParams:1;Condact:'DPRINT' ;Type1: flagno; Type2: none), //  27 
(NumParams:1;Condact:'DISPLAY';Type1: value; Type2: none), //  28 
(NumParams:0;Condact:'CLS'   ;Type1: none; Type2: none), //  29
(NumParams:0;Condact:'DROPALL';Type1: none; Type2: none), //  30
(NumParams:0;Condact:'AUTOG' ;Type1: none; Type2: none), //  31
(NumParams:0;Condact:'AUTOD' ;Type1: none; Type2: none), //  32
(NumParams:0;Condact:'AUTOW' ;Type1: none; Type2: none), //  33
(NumParams:0;Condact:'AUTOR' ;Type1: none; Type2: none), //  34
(NumParams:1;Condact:'PAUSE' ;Type1: none; Type2: none), //  35
(NumParams:2;Condact:'SYNONYM';Type1: vocabulary; Type2: vocabulary), //  36
(NumParams:1;Condact:'GOTO'  ;Type1: locno; Type2: none), //  37
(NumParams:1;Condact:'MESSAGE';Type1: mesno; Type2: none), //  38
(NumParams:1;Condact:'REMOVE' ;Type1: objno; Type2: none), //  39
(NumParams:1;Condact:'GET'   ;Type1: objno; Type2: none), //  40
(NumParams:1;Condact:'DROP'  ;Type1: objno; Type2: none), //  41
(NumParams:1;Condact:'WEAR'  ;Type1: objno; Type2: none), //  42
(NumParams:1;Condact:'DESTROY';Type1: objno; Type2: none), //  43
(NumParams:1;Condact:'CREATE' ;Type1: objno; Type2: none), //  44
(NumParams:2;Condact:'SWAP'  ;Type1: objno; Type2: objno), //  45
(NumParams:2;Condact:'PLACE' ;Type1: objno; Type2: locno_), //  46
(NumParams:1;Condact:'SET'   ;Type1: flagno; Type2: none), //  47
(NumParams:1;Condact:'CLEAR' ;Type1: flagno; Type2: none), //  48
(NumParams:2;Condact:'PLUS'  ;Type1: flagno; Type2: value), //  49
(NumParams:2;Condact:'MINUS' ;Type1: flagno; Type2: value), //  50
(NumParams:2;Condact:'LET'   ;Type1: flagno; Type2: value), //  51
(NumParams:0;Condact:'NEWLINE';Type1: none; Type2: none), //  52
(NumParams:1;Condact:'PRINT' ;Type1: flagno; Type2: none), //  53
(NumParams:1;Condact:'SYSMESS';Type1: sysno; Type2: none), //  54
(NumParams:2;Condact:'ISAT'  ;Type1: objno; Type2: locno_), //  55
(NumParams:1;Condact:'SETCO' ;Type1: objno; Type2: none), //  56  
(NumParams:0;Condact:'SPACE' ;Type1: none; Type2: none), //  57 
(NumParams:1;Condact:'HASAT' ;Type1: value; Type2: none), //  58  
(NumParams:1;Condact:'HASNAT' ;Type1: value; Type2: none), //  59 
(NumParams:0;Condact:'LISTOBJ';Type1: none; Type2: none), //  60
(NumParams:2;Condact:'EXTERN' ;Type1: value; Type2: value), //  61
(NumParams:0;Condact:'RAMSAVE';Type1: none; Type2: none), //  62
(NumParams:1;Condact:'RAMLOAD';Type1: flagno; Type2: none), //  63
(NumParams:2;Condact:'BEEP'  ;Type1: value; Type2: value), //  64
(NumParams:1;Condact:'PAPER' ;Type1: value; Type2: none), //  65
(NumParams:1;Condact:'INK'   ;Type1: value; Type2: none), //  66
(NumParams:1;Condact:'BORDER' ;Type1: value; Type2: none), //  67
(NumParams:1;Condact:'PREP'  ;Type1: vocabulary; Type2: none), //  68
(NumParams:1;Condact:'NOUN2' ;Type1: vocabulary; Type2: none), //  69
(NumParams:1;Condact:'ADJECT2';Type1: vocabulary; Type2: none), //  70
(NumParams:2;Condact:'ADD'   ;Type1: flagno; Type2: flagno), //  71
(NumParams:2;Condact:'SUB'   ;Type1: flagno; Type2: flagno), //  72
(NumParams:1;Condact:'PARSE' ;Type1: value; Type2: none), //  73
(NumParams:1;Condact:'LISTAT' ;Type1: locno_; Type2: none), //  74
(NumParams:1;Condact:'PROCESS';Type1: procno; Type2: none), //  75
(NumParams:2;Condact:'SAME'  ;Type1: flagno; Type2: flagno), //  76
(NumParams:1;Condact:'MES'   ;Type1: mesno; Type2: none), //  77
(NumParams:1;Condact:'WINDOW' ;Type1: window; Type2: none), //  78
(NumParams:2;Condact:'NOTEQ' ;Type1: flagno; Type2: value), //  79
(NumParams:2;Condact:'NOTSAME';Type1: flagno; Type2: flagno), //  80
(NumParams:1;Condact:'MODE'  ;Type1: value; Type2: none), //  81
(NumParams:2;Condact:'WINAT' ;Type1: value; Type2: value), //  82
(NumParams:2;Condact:'TIME'  ;Type1: value; Type2: value), //  83
(NumParams:1;Condact:'PICTURE';Type1: locno; Type2: none), //  84
(NumParams:1;Condact:'DOALL' ;Type1: locno_; Type2: none), //  85
(NumParams:1;Condact:'MOUSE' ;Type1: value; Type2: none), //  86
(NumParams:2;Condact:'GFX'   ;Type1: value; Type2: value), //  87
(NumParams:2;Condact:'ISNOTAT';Type1: objno; Type2: locno_), //  88
(NumParams:2;Condact:'WEIGH' ;Type1: objno; Type2: flagno), //  89
(NumParams:2;Condact:'PUTIN' ;Type1: objno; Type2: locno), //  90
(NumParams:2;Condact:'TAKEOUT';Type1: objno; Type2: flagno), //  91
(NumParams:0;Condact:'NEWTEXT';Type1: none; Type2: none), //  92
(NumParams:2;Condact:'ABILITY';Type1: value; Type2: value), //  93
(NumParams:1;Condact:'WEIGHT' ;Type1: objno; Type2: none), //  94
(NumParams:1;Condact:'RANDOM' ;Type1: flagno; Type2: none), //  95
(NumParams:2;Condact:'INPUT' ;Type1: value; Type2: value), //  96 
(NumParams:0;Condact:'SAVEAT' ;Type1: none; Type2: none), //  97
(NumParams:0;Condact:'BACKAT' ;Type1: none; Type2: none), //  98
(NumParams:2;Condact:'PRINTAT';Type1: value; Type2: value), //  99
(NumParams:0;Condact:'WHATO' ;Type1: none; Type2: none), // 100
(NumParams:1;Condact:'CALL'  ;Type1: value; Type2: none), // 101
(NumParams:1;Condact:'PUTO'  ;Type1: locno_; Type2: none), // 102 ;: revisart
(NumParams:0;Condact:'NOTDONE';Type1: none; Type2: none), // 103
(NumParams:1;Condact:'AUTOP' ;Type1: locno; Type2: none), // 104
(NumParams:1;Condact:'AUTOT' ;Type1: locno; Type2: none), // 105
(NumParams:1;Condact:'MOVE'  ;Type1: flagno; Type2: none), // 106
(NumParams:2;Condact:'WINSIZE';Type1: value; Type2: value), // 107
(NumParams:0;Condact:'REDO'  ;Type1: none; Type2: none), // 108
(NumParams:0;Condact:'CENTRE' ;Type1: none; Type2: none), // 109
(NumParams:1;Condact:'EXIT'  ;Type1: value; Type2: none), // 110
(NumParams:0;Condact:'INKEY' ;Type1: none; Type2: none), // 111 
(NumParams:2;Condact:'BIGGER' ;Type1: flagno; Type2: flagno), // 112
(NumParams:2;Condact:'SMALLER';Type1: flagno; Type2: flagno), // 113 
(NumParams:0;Condact:'ISDONE' ;Type1: none; Type2: none), // 114
(NumParams:0;Condact:'ISNDONE';Type1: none; Type2: none), // 115 
(NumParams:1;Condact:'SKIP'  ;Type1: skip; Type2: none), // 116 
(NumParams:0;Condact:'RESTART';Type1: none; Type2: none), // 117 
(NumParams:1;Condact:'TAB'   ;Type1: value; Type2: none), // 118
(NumParams:2;Condact:'COPYOF' ;Type1: objno; Type2: flagno), // 119
(NumParams:0;Condact:'dumb'  ;Type1: none; Type2: none), // 120 (according DAAD manual, internal;Type1: none; Type2: none)
(NumParams:2;Condact:'COPYOO' ;Type1: objno; Type2: objno), // 121 
(NumParams:0;Condact:'dumb'  ;Type1: none; Type2: none), // 122 (according DAAD manual, internal;Type1: none; Type2: none)
(NumParams:2;Condact:'COPYFO' ;Type1: flagno; Type2: objno), // 123
(NumParams:0;Condact:'dumb'  ;Type1: none; Type2: none), // 124 (according DAAD manual, internal;Type1: none; Type2: none)
(NumParams:2;Condact:'COPYFF' ;Type1: flagno; Type2: flagno), // 125 
(NumParams:2;Condact:'COPYBF' ;Type1: flagno; Type2: flagno), // 126 
(NumParams:0;Condact:'RESET' ;Type1: none; Type2: none),  // 127 

// Additional fake condacts
(Numparams:1;Condact:'XMES';Type1: string_; Type2: none),     //128
(Numparams:1;Condact:'XMESSAGE';Type1: string_; Type2: none),  //129
(Numparams:1;Condact:'XPICTURE';Type1: value; Type2: none),  //130
(Numparams:1;Condact:'XSAVE';Type1: value; Type2: none),    //131
(Numparams:1;Condact:'XLOAD';Type1: value; Type2: none),  //132
(Numparams:1;Condact:'XPART';Type1: value; Type2: none),  //133
(Numparams:1;Condact:'XPLAY';Type1: string_; Type2: none) //134
);

(* Returns the condact index in the codacts table, or -1 if not found*)
FUNCTION GetCondact(Condact : String): Integer;

(* Returns number of condacts for a given condact code *)
FUNCTION GetNumParams(Opcode: Byte): Byte;

(* Performs semantic check for parameters *)
FUNCTION SemanticCheck(Opcode: Byte; ParamNum: Byte; ParamValue: Byte): AnsiString;


IMPLEMENTATION	

USES SysUtils, UMessageList;

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
			IF NOT FOUND THEN Result := -1;
	END;
END;

FUNCTION GetNumParams(Opcode: Byte): Byte;
BEGIN
 IF Opcode = FAKE_DEBUG_CONDACT_CODE THEN Result :=0
									 ELSE Result := Condacts[Opcode].NumParams;
END;

FUNCTION GetParamType(Opcode:Byte; ParamNum: Byte): TParamType;
BEGIN
 if (ParamNum = 1) THEN Result := Condacts[Opcode].Type1
				   ELSE Result := Condacts[Opcode].Type2;
END;

FUNCTION SemanticCheck(Opcode: Byte; ParamNum: Byte; ParamValue: Byte): AnsiString;
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
	procno: Result := ''; // For the time being we don't check procno as there could be forward references
	value: Result := '';
	locno_: IF (ParamValue >= LTXCount) AND (ParamValue< 252) THEN Result := 'Location  ' + IntToStr(ParamValue) + ' does not exist';
	percent: IF ParamValue > 100 THEN Result := '';
	vocabulary : Result := ''; 
	skip: Result := '';
	string_ : Result := '';
	window :  IF ParamValue > 7  THEN Result := 'Invalid window number, must be in the 0-7 range';
	ELSE Result := '';
 END; //case
END;

END.
