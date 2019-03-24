PROGRAM DRC;
{$MODE OBJFPC}

uses sysutils, ULexTokens, LexLib, UTokenList, USintactic, UConstants, USymbolTree, UCodeGeneration;


PROCEDURE SYNTAX();
VAR AppName :String;
BEGIN
	AppName := ChangeFileExt(ExtractFileName(ParamStr(0)),'');
	WriteLn('Syntax: ', AppName, ' <machine> <file.DSF> [output.DDB] ');
  WriteLn();
	WriteLn('file.DSF is a DAAD ', ' ', Version, '.', Minor, ' source file.');
  WriteLn();
	WriteLn('<machine> is the target machine, it may be CPC, ZX, MSX, C64, PCW, PC, ST or AMIGA.');
  WriteLn();
  WriteLn('You also may enter "JSON" as machine, which will export database to JSON format.');
  WriteLn();
	WriteLn('[output.DDB] is optional file name for output database file, if missing same base name as DSF file will be used, if target machine is JSON, extension for output file will be .json.');
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
  WriteLn('Generating output file...');
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
  if (Target<>'CPC') AND (Target<>'ZX') AND (Target<>'MSX') AND (Target<>'C64') AND (Target<>'PC') AND (Target<>'ST') AND (Target<>'AMIGA')  AND (Target<>'PCW')  AND (Target<>'JSON')  THEN ParamError('Invalid Target');
  IF  ParamCount>2 THEN OutputFileName := ParamStr(3)
                   ELSE 
                   BEGIN
                      if Target<>'JSON'  THEN OutputFileName := ChangeFileExt(InputFileName, '.DDB') ELSE OutputFileName := ChangeFileExt(InputFileName, '.json')
                   END;
  CompileForTarget(Target, OutputFileName);
END.


