// (C) Uto 2019 - This code is released under the GPL v3 license

PROGRAM DRC;
{$MODE OBJFPC}
{$I-}


uses strutils, sysutils, ULexTokens, ULexLib, UTokenList, USintactic, UConstants, USymbolList, UCodeGeneration, UCondacts;


PROCEDURE SYNTAX();
VAR AppName :String;
BEGIN
	AppName := ChangeFileExt(ExtractFileName(ParamStr(0)),'');
	WriteLn('Syntax: ', AppName, ' <target> [subtarget] <file.DSF> [output.json] [options] [additional symbols]');
  WriteLn();
	WriteLn('file.DSF is a DAAD', ' ', version_hi, '.', version_lo, ' source file.');
  WriteLn();
	WriteLn('<target> is the target machine, one of this list: ZX, CPC, C64, MSX, MSX2, PCW, PC, AMIGA or ST. The target machine will be added as if there were a ''#define <target> '' in the code, so you can make the code depend on target platform.');
  WriteLn();
	WriteLn('[subtarget] is an parameter only required when the target is ZX, MSX2 or PC. Will define the internal variable COLS, which can later be used in DAAD processes. For MSX2 values can be 5_6, 5_8, 6_6, 6_8, 7_6, 7_8, 8_6 or 8_8. The first number is the video mode (5-8), the second one is the characters width in pixels (6 or 8). For PC values can be VGA, EGA, CGA or TEXT. For ZX the values can be PLUS3, ESXDOS or NEXT.');
  WriteLn('Please notice subtarget for ZX is only relevant if you use Maluva, if you don''t use it or you don''t know what it is, choose any of the targets, i.e. plus3');
  WriteLn();
	WriteLn('[output.json] is optional file name for output json file, if missing, '+AppName+' will just use same name of input file, but with .json extension.');
  WriteLn();
  WriteLn('[options] may be or more of the following:');
  WriteLn('          -verbose: verbose output');
  WriteLn('          -no-semantic: DRF won''t make a semantic analysis so condacts like MESSAGE x where message #x does not exist will be ignored.');
  WriteLn('          -semantic-warnings: DRF will just show semantic errors as warnings, but won''t stop compilation');
  WriteLn('          -force-normal-messages: all xmessages will be treated as normal messages');
  WriteLn();
	WriteLn('[additional symbols] is an optional comma separated list of other symbols that would be created, so for instance if that parameter is "p3", then #ifdef "p3" will be true, and if that parameter is "p3,p4" then also #ifdef "p4" would be true.');
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
 IF Subtarget = 'TEXT' THEN Result := 80
 ELSE Result :=53;  // Conservative
END;

FUNCTION CheckEND(Filename: String):Boolean;
VAR T: TEXT;
    S: WideString;
    Found : Boolean;
BEGIN
 Assign(T, Filename);
 Reset(T);
 Found := false;
 WHILE (NOT EOF(T)) AND (NOT Found)
 DO
 BEGIN
  ReadLn(T, S);
  S := Trim(S);
  IF (S='/END') THEN Found := True;
 END;
 Close(T);
 Result := Found;
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
    AdditionalSymbols : String;
    AuxString : String;
    AppName : String;
    NextParam : Byte;

{$i lexer.pas} 


PROCEDURE CompileForTarget(Target: AnsiString; Subtarget: AnsiString; OutputFileName: String; AdditionalSymbols: String);
var machine : AnsiString;
    cols: byte;
    i :byte;
BEGIN
  IF Verbose THEN
  BEGIN
   Write('Target: ', target);
   IF SubTarget<>'' THEN Write(' | Subtarget:', subtarget);
   WriteLn;
  END; 
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
  // Add additionalSymbols if present
  i := 1;
  REPEAT
    AuxString := ExtractWord(i, AdditionalSymbols, [',']);
    if (AuxString<>'') THEN 
    BEGIN
     AddSymbol(SymbolList, AuxString, i);
    END;
    Inc(i);
  UNTIL AuxString='';
  WriteLn('Checking Syntax...');
  Sintactic(target, subtarget);
  Write('Generating ',OutputFileName,' [Classic mode O');
  if (ClassicMode) THEN WriteLn('N]') ELSE WriteLn('FF]');
	GenerateOutput(OutputFileName, Target);
END;  

FUNCTION isValidSubTarget(Target, Subtarget: AnsiString): Boolean;
BEGIN
 if Target='MSX2' THEN  Result :=  (Subtarget = '5_6') OR (Subtarget = '5_8') OR  (Subtarget = '6_6') OR  (Subtarget = '6_8') OR  (Subtarget = '7_6') OR  (Subtarget = '7_8') OR  (Subtarget = '8_6') OR  (Subtarget = '8_8');
 if Target='PC'   THEN Result := (Subtarget = 'VGA') OR (Subtarget = 'EGA') OR  (Subtarget = 'CGA') OR  (Subtarget = 'TEXT');
 if Target='ZX' THEN Result :=  (Subtarget = 'PLUS3') OR (Subtarget = 'ESXDOS') OR  (Subtarget = 'NEXT');
END;

BEGIN
  AppName := ChangeFileExt(ExtractFileName(ParamStr(0)),'');
  Write('DAAD Reborn Compiler Frontend', ' ', version_hi, '.', version_lo, ' (C) Uto 2018');
  if (CurrentYear()<>2018) THEN Write('-', CurrentYear());
  WriteLn();
  // Check Parameters
  IF (ParamCount()<2) THEN SYNTAX();
  Target := UpperCase(ParamStr(1));
  NextParam := 2;
  SubTarget := '';
  IF (Target='MSX2') OR (Target='PC') OR (Target='ZX') THEN 
  BEGIN
   SubTarget := UpperCase(ParamStr(NextParam));
   if (NOT isValidSubTarget(Target,Subtarget)) THEN ParamError('"' + Subtarget + '" is not a valid subtarget for target "' + Target + '". Please specify a valid subtarget. Call DRF without parameters for more information.');
   Inc(NextParam);
  END;
  InputFileName := ParamStr(NextParam);
  IF (NOT FileExists(InputFileName)) THEN ParamError('Input file not found: "'+InputFileName+'"');
  Inc(NextParam);
  IF  ParamCount>= NextParam THEN AuxString := ParamStr(NextParam);
  IF Pos('.',AuxString) <> 0 THEN 
                              BEGIN
                                OutputFileName := AuxString;
                                Inc(NextParam);
                              END
                              ELSE 
                              BEGIN
                                OutputFileName := ChangeFileExt(InputFileName, '.json');
                              END;
  AdditionalSymbols := '';
  WHILE ParamCount>= NextParam DO
  BEGIN
   AuxString := ParamStr(NextParam);
   if (copy(AuxString, 1,1)<>'-') THEN AdditionalSymbols := AuxString   // If next parameter starts by '--' it's an option, otherwise it's a symbol list
                                   ELSE
                                   BEGIN
                                    IF AuxString = '-verbose' THEN 
                                    BEGIN 
                                      Verbose := true;
                                      WriteLn('Verbose mode ON'); 
                                    END ELSE
                                    IF AuxString = '-no-semantic' THEN 
                                    BEGIN 
                                      NoSemantic := true;
                                      if Verbose THEN WriteLn('Warning: DRF won''t make semantic analysis'); 
                                    END ELSE
                                    IF AuxString = '-semantic-warnings' THEN
                                    BEGIN 
                                      SemanticWarnings := true; 
                                      if Verbose THEN WriteLn('Warning: Semantic analysys errors will just generate warnings'); 
                                    END 
                                    ELSE
                                    IF AuxString = '-force-normal-messages' THEN
                                    BEGIN 
                                      ForceNormalMessages := true;
                                      if Verbose THEN WriteLn('Warning: Forced Normal Messages'); 
                                    END
                                    ELSE ParamError('Invalid option: ' + AuxString);
                                   END;
   Inc(NextParam);
  END;

  IF NoSemantic AND SemanticWarnings THEN ParamError('You can''t avoid semantic checking and at the same time expect semantic warnings.');

  //LoadPlugins(); 
  IF NOT CheckEND(InputFileName) THEN ParamError('Input file has no /END section');
  CompileForTarget(Target, SubTarget, OutputFileName, AdditionalSymbols);
END.


