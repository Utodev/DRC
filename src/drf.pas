PROGRAM DRC;
{$MODE OBJFPC}
{$I-}


uses sysutils, ULexTokens, ULexLib, UTokenList, USintactic, UConstants, USymbolTree, UCodeGeneration;


PROCEDURE SYNTAX();
VAR AppName :String;
BEGIN
	AppName := ChangeFileExt(ExtractFileName(ParamStr(0)),'');
	WriteLn('Syntax: ', AppName, ' <define> <file.DSF> [output.json] ');
  WriteLn();
	WriteLn('file.DSF is a DAAD', ' ', Version, '.', Minor, ' source file.');
  WriteLn();
	WriteLn('is an automatically defined symbol at compiling time. Its main use is to be able to target a specific machine adding #ifdefs code blocks for such machine. If you don''t understand what it is for, just type any word there, for instance "dummy".');
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

FUNCTION getColsByTarget(Target:String):Byte;
BEGIN
 IF Target = 'PC' THEN Result := 53 ELSE
 IF Target = 'ZX' THEN Result := 42 ELSE
 IF Target = 'C64' THEN Result := 40 ELSE
 IF Target = 'CPC' THEN Result := 40 ELSE
 IF Target = 'MSX' THEN Result := 42 ELSE
 IF Target = 'ST' THEN Result := 53 ELSE
 IF Target = 'AMIGA' THEN Result := 53 ELSE
 IF Target = 'PCW' THEN Result := 90 
 ELSE Result :=42;  // Conservative
 END;

// Global vars

VAR Target: String;
  	OutputFileName, InputFileName : String;
    AppName : String;

{$i lexer.pas} 


PROCEDURE CompileForTarget(Target: String; OutputFileName: String);
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
  cols := getColsByTarget(Target);
  if (cols<>0) THEN AddSymbol(SymbolTree, 'COLS', cols);
    AddSymbol(SymbolTree, 'CARRIED', LOC_CARRIED);
  AddSymbol(SymbolTree, 'NOT_CREATED', LOC_NOT_CREATED);
  AddSymbol(SymbolTree, 'NON_CREATED', LOC_NOT_CREATED);
  AddSymbol(SymbolTree, 'WORN', LOC_WORN);
  AddSymbol(SymbolTree, 'HERE', LOC_HERE);
  AddSymbol(SymbolTree, 'HERE', LOC_HERE);
  
  WriteLn('Checking Syntax...');
  Sintactic();
  WriteLn('Generating output...');
  GenerateOutput(OutputFileName, Target);
END;  

BEGIN
  AppName := ChangeFileExt(ExtractFileName(ParamStr(0)),'');
  Write('DAAD Reborn Compiler Frontend', ' ', Version, '.', Minor, ' (C) Uto 2018');
  if (CurrentYear()<>2018) THEN Write('-', CurrentYear());
  WriteLn();
  // Check Parameters
  IF (ParamCount()>3) OR (ParamCount()<2) THEN SYNTAX();
  InputFileName := ParamStr(2);
  IF (NOT FileExists(InputFileName)) THEN ParamError('Input file not found');
  Target := UpperCase(ParamStr(1));
  IF  ParamCount>2 THEN OutputFileName := ParamStr(3)
                   ELSE OutputFileName := ChangeFileExt(InputFileName, '.json');
  CompileForTarget(Target, OutputFileName);
END.


