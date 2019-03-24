UNIT UCondacts;
{$MODE OBJFPC}

INTERFACE

USES UConstants;

TYPE TCondact = record
				 NumParams : Byte;
				 Condact : String
				end; 


CONST Condacts : ARRAY[0..NUM_CONDACTS - 1] OF TCondact = (
(NumParams:1;Condact:'AT'    ), //   0
(NumParams:1;Condact:'NOTAT' ), //   1
(NumParams:1;Condact:'ATGT'  ), //   2
(NumParams:1;Condact:'ATLT'  ), //   3
(NumParams:1;Condact:'PRESENT'), //   4
(NumParams:1;Condact:'ABSENT' ), //   5
(NumParams:1;Condact:'WORN'  ), //   6
(NumParams:1;Condact:'NOTWORN'), //   7
(NumParams:1;Condact:'CARRIED'), //   8
(NumParams:1;Condact:'NOTCARR'), //   9
(NumParams:1;Condact:'CHANCE' ), //  10
(NumParams:1;Condact:'ZERO'  ), //  11
(NumParams:1;Condact:'NOTZERO'), //  12
(NumParams:2;Condact:'EQ'    ), //  13
(NumParams:2;Condact:'GT'    ), //  14
(NumParams:2;Condact:'LT'    ), //  15
(NumParams:1;Condact:'ADJECT1'), //  16
(NumParams:1;Condact:'ADVERB' ), //  17
(NumParams:2;Condact:'SFX'   ), //  18
(NumParams:1;Condact:'DESC'  ), //  19
(NumParams:0;Condact:'QUIT'  ), //  20
(NumParams:0;Condact:'END'   ), //  21
(NumParams:0;Condact:'DONE'  ), //  22
(NumParams:0;Condact:'OK'    ), //  23
(NumParams:0;Condact:'ANYKEY' ), //  24
(NumParams:1;Condact:'SAVE'  ), //  25
(NumParams:1;Condact:'LOAD'  ), //  26
(NumParams:1;Condact:'DPRINT' ), //  27 *
(NumParams:1;Condact:'DISPLAY'), //  28 *
(NumParams:0;Condact:'CLS'   ), //  29
(NumParams:0;Condact:'DROPALL'), //  30
(NumParams:0;Condact:'AUTOG' ), //  31
(NumParams:0;Condact:'AUTOD' ), //  32
(NumParams:0;Condact:'AUTOW' ), //  33
(NumParams:0;Condact:'AUTOR' ), //  34
(NumParams:1;Condact:'PAUSE' ), //  35
(NumParams:2;Condact:'SYNONYM'), //  36 *
(NumParams:1;Condact:'GOTO'  ), //  37
(NumParams:1;Condact:'MESSAGE'), //  38
(NumParams:1;Condact:'REMOVE' ), //  39
(NumParams:1;Condact:'GET'   ), //  40
(NumParams:1;Condact:'DROP'  ), //  41
(NumParams:1;Condact:'WEAR'  ), //  42
(NumParams:1;Condact:'DESTROY'), //  43
(NumParams:1;Condact:'CREATE' ), //  44
(NumParams:2;Condact:'SWAP'  ), //  45
(NumParams:2;Condact:'PLACE' ), //  46
(NumParams:1;Condact:'SET'   ), //  47
(NumParams:1;Condact:'CLEAR' ), //  48
(NumParams:2;Condact:'PLUS'  ), //  49
(NumParams:2;Condact:'MINUS' ), //  50
(NumParams:2;Condact:'LET'   ), //  51
(NumParams:0;Condact:'NEWLINE'), //  52
(NumParams:1;Condact:'PRINT' ), //  53
(NumParams:1;Condact:'SYSMESS'), //  54
(NumParams:2;Condact:'ISAT'  ), //  55
(NumParams:1;Condact:'SETCO' ), //  56 
(NumParams:0;Condact:'SPACE' ), //  57 
(NumParams:1;Condact:'HASAT' ), //  58 
(NumParams:1;Condact:'HASNAT' ), //  59 
(NumParams:0;Condact:'LISTOBJ'), //  60
(NumParams:2;Condact:'EXTERN' ), //  61
(NumParams:0;Condact:'RAMSAVE'), //  62
(NumParams:1;Condact:'RAMLOAD'), //  63
(NumParams:2;Condact:'BEEP'  ), //  64
(NumParams:1;Condact:'PAPER' ), //  65
(NumParams:1;Condact:'INK'   ), //  66
(NumParams:1;Condact:'BORDER' ), //  67
(NumParams:1;Condact:'PREP'  ), //  68
(NumParams:1;Condact:'NOUN2' ), //  69
(NumParams:1;Condact:'ADJECT2'), //  70
(NumParams:2;Condact:'ADD'   ), //  71
(NumParams:2;Condact:'SUB'   ), //  72
(NumParams:1;Condact:'PARSE' ), //  73
(NumParams:1;Condact:'LISTAT' ), //  74
(NumParams:1;Condact:'PROCESS'), //  75
(NumParams:2;Condact:'SAME'  ), //  76
(NumParams:1;Condact:'MES'   ), //  77
(NumParams:1;Condact:'WINDOW' ), //  78
(NumParams:2;Condact:'NOTEQ' ), //  79
(NumParams:2;Condact:'NOTSAME'), //  80
(NumParams:1;Condact:'MODE'  ), //  81
(NumParams:2;Condact:'WINAT' ), //  82
(NumParams:2;Condact:'TIME'  ), //  83
(NumParams:1;Condact:'PICTURE'), //  84
(NumParams:1;Condact:'DOALL' ), //  85
(NumParams:1;Condact:'MOUSE' ), //  86
(NumParams:2;Condact:'GFX'   ), //  87
(NumParams:2;Condact:'ISNOTAT'), //  88
(NumParams:2;Condact:'WEIGH' ), //  89
(NumParams:2;Condact:'PUTIN' ), //  90
(NumParams:2;Condact:'TAKEOUT'), //  91
(NumParams:0;Condact:'NEWTEXT'), //  92
(NumParams:2;Condact:'ABILITY'), //  93
(NumParams:1;Condact:'WEIGHT' ), //  94
(NumParams:1;Condact:'RANDOM' ), //  95
(NumParams:2;Condact:'INPUT' ), //  96 
(NumParams:0;Condact:'SAVEAT' ), //  97
(NumParams:0;Condact:'BACKAT' ), //  98
(NumParams:2;Condact:'PRINTAT'), //  99
(NumParams:0;Condact:'WHATO' ), // 100
(NumParams:1;Condact:'CALL'  ), // 101
(NumParams:1;Condact:'PUTO'  ), // 102
(NumParams:0;Condact:'NOTDONE'), // 103
(NumParams:1;Condact:'AUTOP' ), // 104
(NumParams:1;Condact:'AUTOT' ), // 105
(NumParams:1;Condact:'MOVE'  ), // 106
(NumParams:2;Condact:'WINSIZE'), // 107
(NumParams:0;Condact:'REDO'  ), // 108
(NumParams:0;Condact:'CENTRE' ), // 109
(NumParams:1;Condact:'EXIT'  ), // 110
(NumParams:0;Condact:'INKEY' ), // 111 
(NumParams:2;Condact:'BIGGER' ), // 112
(NumParams:2;Condact:'SMALLER'), // 113 
(NumParams:0;Condact:'ISDONE' ), // 114
(NumParams:0;Condact:'ISNDONE'), // 115 
(NumParams:1;Condact:'SKIP'  ), // 116 
(NumParams:0;Condact:'RESTART'), // 117 
(NumParams:1;Condact:'TAB'   ), // 118
(NumParams:2;Condact:'COPYOF' ), // 119
(NumParams:0;Condact:'dumb'  ), // 120 (according DAAD manual, internal)
(NumParams:2;Condact:'COPYOO' ), // 121 
(NumParams:0;Condact:'dumb'  ), // 122 (according DAAD manual, internal)
(NumParams:2;Condact:'COPYFO' ), // 123
(NumParams:0;Condact:'dumb'  ), // 124 (according DAAD manual, internal)
(NumParams:2;Condact:'COPYFF' ), // 125 
(NumParams:2;Condact:'COPYBF' ), // 126 
(NumParams:0;Condact:'RESET' )  // 127 
);

(* Returns the condact index in the codacts table, or -1 if not found*)
FUNCTION GetCondact(Condact : String): Integer;

IMPLEMENTATION	

USES SysUtils;

FUNCTION GetCondact(Condact : String): Integer;
VAR i : integer;
	found : boolean;
BEGIN
	i := 0;
	found := false;
	while (i < 128) AND (NOT found) DO
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

END.
