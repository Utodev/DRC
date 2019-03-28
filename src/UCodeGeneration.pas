UNIT UCodeGeneration;

{$MODE OBJFPC}

INTERFACE


PROCEDURE GenerateOutput(OutputFilename: String; Target: String);



IMPLEMENTATION

USES  UJSONExport;



PROCEDURE GenerateOutput(OutputFilename: String; Target: String);
BEGIN
 GenerateJSON(OutputFileName);
END;
END.
