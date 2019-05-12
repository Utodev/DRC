PROGRAM DRC;
{$MODE OBJFPC}
{$I-}


uses sysutils, ULexTokens, ULexLib, UTokenList, USintactic, UConstants, USymbolList, UCodeGeneration;


PROCEDURE SYNTAX();
VAR AppName :String;
BEGIN
	AppName := ChangeFileExt(ExtractFileName(ParamStr(0)),'');
	WriteLn('Syntax: ', AppName, ' <target> [subtarget] <file.DSF> [output.json] ');
  WriteLn();
	WriteLn('file.DSF is a DAAD', ' ', version_hi, '.', version_lo, ' source file.');
  WriteLn();
	WriteLn('<target> is the target machine, one of this list: ZX, CPC, C64, MSX, MSX2, PCW, PC, AMIGA or ST. The target machine will be added as if there were a ''#define <target> '' in the code, so you can make the code depend on target platform.');
  WriteLn();
	WriteLn('[subtarget] is an parameter only required when the target is MSX2 or PC. Will define the internal variable COLS, which can later be used in DAAD processes. For MSX2 values can be 5_6, 5_8, 6_6, 6_8, 7_6, 7_8, 8_6 or 8_8. The first number is the video mode (5-8), the second one is the characters width in pixels (6 or 8). For PC values can be VGA, EGA, CGA or TEXT.');
  WriteLn();
	WriteLn('[output.json] is optional file name for output json file, if missing, '+AppName+' will just use same name of input file, but with .json extension.');
	Halt(1);
END;

PROCEDURE yyerror(Msg : String);
BEGIN
	WriteLn(yylineno,':',yycolno, ': ', msg,'.');
END;

PROCEDURE ParamError(Msg : String);
BEGIN
	WriteLn(Msg, '.');
	Halt(2);
END;	

FUNCTION getMSX2ColsBySubtarget(SubTarget:AnsiString):Byte;
BEGIN
 IF Subtarget = '5_6' THEN Result := 42 ELSE
 IF Subtarget = '5_8' THEN Result := 32 ELSE
 IF Subtarget = '6_6' THEN Result := 85 ELSE
 IF Subtarget = '6_8' THEN Result := 64 ELSE
 IF Subtarget = '7_6' THEN Result := 85 ELSE
 IF Subtarget = '7_8' THEN Result := 64 ELSE
 IF Subtarget = '8_6' THEN Result := 42 ELSE
 IF Subtarget = '8_8' THEN Result := 32 
 ELSE Result :=42;  // Conservative
END;

FUNCTION getPCColsBySubtarget(SubTarget:AnsiString):Byte;
BEGIN
 IF Subtarget = 'VGA' THEN Result := 80
 ELSE Result :=53;  // Conservative
END;


FUNCTION getColsByTarget(Target:String;SubTarget:AnsiString):Byte;
BEGIN
 IF Target = 'PC' THEN Result := getPCColsBySubtarget(SubTarget) ELSE
 IF Target = 'ZX' THEN Result := 42 ELSE
 IF Target = 'C64' THEN Result := 40 ELSE
 IF Target = 'CPC' THEN Result := 40 ELSE
 IF Target = 'MSX' THEN Result := 42 ELSE
 IF Target = 'MSX2' THEN Result := getMSX2ColsBySubtarget(SubTarget) ELSE
 IF Target = 'ST' THEN Result := 53 ELSE
 IF Target = 'AMIGA' THEN Result := 53 ELSE
 IF Target = 'PCW' THEN Result := 90 
 ELSE Result :=42;  // Conservative
 END;

FUNCTION GetRowsByTarget(Target:String):Byte;
BEGIN
  IF Target = 'PCW' THEN Result := 32 ELSE
  IF Target = 'MSX2' THEN Result := 26 ELSE Result := 25;
END;

 FUNCTION targetUsesDstringsGraphics(Target:AnsiString): Boolean;
 BEGIN
  Result := (Target='ZX') OR (Target='CPC') OR (Target='C64') OR (Target='MSX');
 END;

// Global vars

VAR Target, SubTarget: AnsiString;
  	OutputFileName, InputFileName : String;
    AppName : String;
    NextParam : Byte;

{$i lexer.pas} 


PROCEDURE CompileForTarget(Target: String; Subtarget: AnsiString; OutputFileName: String);
var machine : AnsiString;
   cols: byte;
BEGIN
  Writeln('Reading ' + InputFileName);
  AssignFile(yyinput, InputFileName);
  Reset(yyinput);
  TokenList := nil;
  // This is a fake token we add, although it will be never loaded. Everytime Scan() is called, it goes to "next" so first time this fake one will be skipped.
  AddToken(TokenList, T_NOTHING, '', 0, 0, 0);
  // Parses whole file into TokenList
  yylex();
  // Create some useful built-in symbols
  // The target
  AddSymbol(SymbolList, Target, 1);
  if (SubTarget<>'') THEN AddSymbol(SymbolList, 'MODE_'+Subtarget, 1);
  machine :=AnsiUpperCase(Target);
  // The target superset BIT8 or BIT16
  if (machine='ZX') OR (machine='CPC') OR (machine='PCW') OR (machine='MSX') OR (machine='C64') or (MACHINE='MSX2') THEN AddSymbol(SymbolList, 'BIT8', 1);
  if (machine='PC') OR (machine='AMIGA') OR (machine='ST') THEN   AddSymbol(SymbolList, 'BIT16', 1);
  // add COLS Symbol
  cols := getColsByTarget(Target, SubTarget);
  if (cols<>0) THEN AddSymbol(SymbolList, 'COLS', cols);
  // add ROWS Symbol
  AddSymbol(SymbolList, 'ROWS', GetRowsByTarget(Target));
  // Add Dstrings Symbol
  if (targetUsesDstringsGraphics(Target)) THEN AddSymbol(SymbolList, 'DSTRINGS', 1);
  // Add common Symbols
  AddSymbol(SymbolList, 'CARRIED', LOC_CARRIED);
  AddSymbol(SymbolList, 'NOT_CREATED', LOC_NOT_CREATED);
  AddSymbol(SymbolList, 'NON_CREATED', LOC_NOT_CREATED);
  AddSymbol(SymbolList, 'WORN', LOC_WORN);
  AddSymbol(SymbolList, 'HERE', LOC_HERE);
  AddSymbol(SymbolList, 'HERE', LOC_HERE);
  WriteLn('Checking Syntax...');
  Sintactic();
  Write('Generating ',OutputFileName,' [Classic mode O');
  if (ClassicMode) THEN WriteLn('N]') ELSE WriteLn('FF]');
	GenerateOutput(OutputFileName, Target);
END;  

FUNCTION isValidSubTarget(Target, Subtarget: AnsiString): Boolean;
BEGIN
 if Target='MSX2' THEN  Result :=  (Subtarget = '5_6') OR (Subtarget = '5_8') OR  (Subtarget = '6_6') OR  (Subtarget = '6_8') OR  (Subtarget = '7_6') OR  (Subtarget = '7_8') OR  (Subtarget = '8_6') OR  (Subtarget = '8_8');
 if Target='PC'   THEN Result := (Subtarget = 'VGA') OR (Subtarget = 'EGA') OR  (Subtarget = 'CGA') OR  (Subtarget = 'TEXT');
END;

BEGIN
  AppName := ChangeFileExt(ExtractFileName(ParamStr(0)),'');
  Write('DAAD Reborn Compiler Frontend', ' ', version_hi, '.', version_lo, ' (C) Uto 2018');
  if (CurrentYear()<>2018) THEN Write('-', CurrentYear());
  WriteLn();
  // Check Parameters
  IF (ParamCount()>4) OR (ParamCount()<2) THEN SYNTAX();
  Target := UpperCase(ParamStr(1));
  NextParam := 2;
  SubTarget := '';
  IF (Target='MSX2') OR (Target='PC') THEN 
  BEGIN
   SubTarget := UpperCase(ParamStr(NextParam));
   if (NOT isValidSubTarget(Target,Subtarget)) THEN ParamError('"' + Subtarget + '" is not a valid subtarget for target "' + Target + '". Please specify a valid subtarget. Call DRF without parameters for more information.');
   Inc(NextParam);
  END;
  InputFileName := ParamStr(NextParam);
  Inc(NextParam);
  IF (NOT FileExists(InputFileName)) THEN ParamError('Input file not found: "'+InputFileName+'"');
  IF  ParamCount>NextParam THEN OutputFileName := ParamStr(NextParam)
                          ELSE OutputFileName := ChangeFileExt(InputFileName, '.json');
  CompileForTarget(Target, SubTarget, OutputFileName);
END.


