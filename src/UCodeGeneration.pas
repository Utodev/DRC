UNIT UCodeGeneration;

{$MODE OBJFPC}

INTERFACE


PROCEDURE GenerateOutput(OutputFilename: String; Target: String);



IMPLEMENTATION

USES sysutils, UConstants, UVocabularyTree, UMessageList, UConnections, UObjects, UProcess, UProcessCondactList, UCTLIncBin, UJSONExport;


PROCEDURE GenerateDDB(OutputFilename: String; Target: String);
BEGIN
  Writeln();
	WriteLn('**ERROR: DDB generation is not yet supported, only JSON.');
	Halt(2);
END;

PROCEDURE GenerateOutput(OutputFilename: String; Target: String);
BEGIN
 if(Target='JSON') THEN GenerateJSON(OutputFileName) ELSE GenerateDDB(OutputFileName, Target);
END;
END.
