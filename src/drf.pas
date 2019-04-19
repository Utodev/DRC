PROGRAM DRC;
{$MODE OBJFPC}
{$I-}


uses sysutils, ULexTokens, ULexLib, UTokenList, USintactic, UConstants, USymbolTree, UCodeGeneration;


PROCEDURE SYNTAX();
VAR AppName :String;
BEGIN
	AppName := ChangeFileExt(ExtractFileName(ParamStr(0)),'');
	WriteLn('Syntax: ', AppName, ' <target> [subtarget] <file.DSF> [output.json] ');
  WriteLn();
	WriteLn('file.DSF is a DAAD', ' ', Version, '.', Minor, ' source file.');
  WriteLn();
	WriteLn('<target> is the target machine, one of this list: ZX, CPC, C64, MSX, MSX2, PCW, PC, AMIGA or ST. The target machine will be added as if there were a ''#define <target> '' in the code, so you can make the code depend on target platform.');
  WriteLn();
	WriteLn('[subtarget] is an parameter only required when the target is MSX2, its value can be 5_6, 5_8, 6_6, 6_8, 7_6, 7_8, 8_6 or 8_8. The first number is the video mode, the second one is the text characters width in pixels.');
  WriteLn();
	WriteLn('[output.json] is optional file name for output json file, if missing same base name as DSF file will be used.');
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

FUNCTION getColsByTarget(Target:String;SubTarget:AnsiString):Byte;
BEGIN
 IF Target = 'PC' THEN Result := 53 ELSE
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
 Writeln('Opening ' + InputFileName);
  AssignFile(yyinput, InputFileName);
  Reset(yyinput);
  TokenList := nil;
  // Parses whole file into TokenList
  WriteLn('Checking Lexer...');
  yylex();
  // Create some useful built-in symbols
  // The target
  AddSymbol(SymbolTree, Target, 1);
  machine :=AnsiUpperCase(Target);
  // The target superset BIT8 or BIT16
  if (machine='ZX') OR (machine='CPC') OR (machine='PCW') OR (machine='MSX') OR (machine='C64') or (MACHINE='MSX2') THEN AddSymbol(SymbolTree, 'BIT8', 1);
  if (machine='PC') OR (machine='AMIGA') OR (machine='ST') THEN   AddSymbol(SymbolTree, 'BIT16', 1);
  // add COLS Symbol
  cols := getColsByTarget(Target, SubTarget);
  if (cols<>0) THEN AddSymbol(SymbolTree, 'COLS', cols);
    AddSymbol(SymbolTree, 'CARRIED', LOC_CARRIED);
  AddSymbol(SymbolTree, 'NOT_CREATED', LOC_NOT_CREATED);
  AddSymbol(SymbolTree, 'NON_CREATED', LOC_NOT_CREATED);
  AddSymbol(SymbolTree, 'WORN', LOC_WORN);
  AddSymbol(SymbolTree, 'HERE', LOC_HERE);
  AddSymbol(SymbolTree, 'HERE', LOC_HERE);
  
  WriteLn('Checking Syntax...');
  Sintactic();
  Write('Generating output [Classic mode O');
  if (ClassicMode) THEN WriteLn('N]') ELSE WriteLn('FF]');
	GenerateOutput(OutputFileName, Target);
END;  

BEGIN
  AppName := ChangeFileExt(ExtractFileName(ParamStr(0)),'');
  Write('DAAD Reborn Compiler Frontend', ' ', Version, '.', Minor, ' (C) Uto 2018');
  if (CurrentYear()<>2018) THEN Write('-', CurrentYear());
  WriteLn();
  // Check Parameters
  IF (ParamCount()>4) OR (ParamCount()<2) THEN SYNTAX();
  InputFileName := ParamStr(2);
  IF (NOT FileExists(InputFileName)) THEN ParamError('Input file not found');
  Target := UpperCase(ParamStr(1));
  NextParam := 3;
  SubTarget := '';
  IF Target='MSX2' THEN 
  BEGIN
   SubTarget := UpperCase(ParamStr(NextParam));
   Inc(NextParam);
  END;
  IF  ParamCount>NextParam THEN OutputFileName := ParamStr(NextParam)
                          ELSE OutputFileName := ChangeFileExt(InputFileName, '.json');
  CompileForTarget(Target, SubTarget, OutputFileName);
END.


