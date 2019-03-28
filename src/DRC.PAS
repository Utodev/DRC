PROGRAM DRC;
{$MODE OBJFPC}

uses sysutils, ULexTokens, LexLib, UTokenList, USintactic, UConstants, USymbolTree, UCodeGeneration;


PROCEDURE SYNTAX();
VAR AppName :String;
BEGIN
	AppName := ChangeFileExt(ExtractFileName(ParamStr(0)),'');
	WriteLn('Syntax: ', AppName, ' <define> <file.DSF> [output.json] ');
  WriteLn();
	WriteLn('file.DSF is a DAAD', ' ', Version, '.', Minor, ' source file.');
  WriteLn();
	WriteLn('<define> is a symbol that is automatically defined when compiling. Main use is writing there the target machine, and then add #ifdefs in the code. If you don''t understand what that is for, just write any word there, for instance "dummy"');
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

// Global vars

VAR Target: String;
  	OutputFileName, InputFileName : String;
    AppName : String;

{$i lexer.pas} 


PROCEDURE CompileForTarget(Target: String; OutputFileName: String);
BEGIN
 Writeln('Opening ' + InputFileName);
  AssignFile(yyinput, InputFileName);
  Reset(yyinput);
  TokenList := nil;
  // Parses whole file into TokenList
  WriteLn('Checking Lexer...');
  yylex();
  // Create some useful built-in symbols
  AddSymbol(SymbolTree, Target, 1);
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
  Write('DAAD Reborn Compiler', ' ', Version, '.', Minor, ' (C) Uto 2018');
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


