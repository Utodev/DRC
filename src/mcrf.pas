PROGRAM MCRF;

// This code is made by Uto, but strongly based on original Hisoft C  code made my Tim Gilberts and maybe Graeme Yeandle. 
                     
// Creates a run file for the Amstrad CPC system. This combines the required interpreter with a given database and graphics
// database (all of which have a CPC header), also adds a CPC header to result file.

{$MODE OBJFPC}

USES sysutils, strutils;


CONST VERSION=02;     (* Increased from original 01 for non CP/M version *)
CONST FILEV=00;
CONST PATHLEN=64;
CONST IPSSIZE=128;
CONST DBADD=$2880;
CONST INTAT=$0840;
CONST SPARE=$0020;

TYPE cpcHeaderType =  ARRAY[0..127] of Byte;

VAR OutputFile, InputFile : FILE;
    cpcHeader: cpcHeaderType;
    c: integer;
    Buffer1Byte: Byte;
    FileLength :  Word;
    GraphicsLength : Word;
    RealDDBLength: Word;


FUNCTION ReadHeaderWord(index: byte): Word;
BEGIN
  Result := cpcHeader[index] + 256 * cpcHeader[index+1];
END;

PROCEDURE WriteHeaderWord(index: Byte; val: Word);
BEGIN
  cpcHeader[index] := val MOD 256;
  cpcHeader[index+1] := val DIV 256;
END;

PROCEDURE Error(S:String);
BEGIN
  Writeln(S + '.');
  Writeln();
  Halt(2);
END;


PROCEDURE SetHeader(LoadAddress, FileLength: Word; fullfileName:String; RunAddres: Word);
VAR AuxStr: String;
    j : byte;
    checksum: word;
BEGIN

  WriteLn('Load address   :', LoadAddress);
  WriteLn('Run address    :', RunAddres);
  Writeln('File size      :', FileLength);


  WriteHeaderWord(21, LoadAddress);
  WriteHeaderWord(26, RunAddres);
  WriteHeaderWord(24, FileLength);
  cpcHeader[66] := 0;
  WriteHeaderWord(64, FileLength); // together with previous line, 24 bits file length, just a copy 


  // Get file name
  AuxStr := ExtractFileName(UpperCase(fullfileName));
  AuxStr := ChangeFileExt(AuxStr,'');
  IF Length(AuxStr) > 8 THEN Error('Output file name too long, maximum 11 characters');
  AuxStr := PadRight(AuxStr,8);
  Move(AuxStr[1], cpcHeader[1],8);
  Writeln('File name      :', AuxStr);


  // Get file extension
  AuxStr := ExtractFileExt(UpperCase(fullfileName));
  AuxStr := Copy(AuxStr, 2, 100);
  AuxStr := PadRight(AuxStr,3);
  IF Length(AuxStr) > 3 THEN Error('Output file name extension too long, maximum 3 characters');
  Move(AuxStr[1], cpcHeader[9],3);
  Writeln('File extension :', AuxStr);
  
  // Calculate checksum
  checksum := 0;
  FOR j:= 0 TO 66  DO checksum := checksum + cpcHeader[j];
  WriteHeaderWord(67, checksum);
  Writeln('Checksum       :', checksum);
end; 


PROCEDURE Syntax();
BEGIN
  Writeln();
  WriteLn('SYNTAX: MCRF <target file> <interpreter file> <text DDB file> <graphics file>');
  Writeln();
  Writeln('Example: MCRF MYGAME.BIN INT.Z80 MYGAME.DDB MYGAME.GRA');
  Writeln();
  Writeln('Important: The interpreter and graphics files should have an AMSDOS header. The DDB (text database) one may have it or not, MCRF will auto-detect it.');
  Halt(1);
END;

BEGIN
  WriteLn('Make CPC run file on PC. VERSION ', VERSION, ' FILE VERSION ', FILEV);
  WriteLn('(c) 1989-2018 Infinite Imaginations.');
  WriteLn('Original code for CP/M written by T.J.Gilberts using Hisoft C.');
  WriteLn('Rebuilt in pascal by Uto in 2018');

  IF (ParamCount()<>4) THEN Syntax();

  AssignFile(OutputFile, ParamStr(1));
  TRY
  Rewrite(OutputFile, 1);
  EXCEPT
   on E: Exception DO Error('Invalid output file.');
  END; 

  WriteLn(ParamStr(1), ' open for output');

  AssignFile(InputFile, ParamStr(2));  // The interpreter
  TRY
  Reset(InputFile, 1);
  EXCEPT
   on E: Exception DO Error('Interpreter file not found or invalid.');
  END; 

  Write('Interpreter length is ');
  Blockread(InputFile, cpcHeader, 128); (* Get CPC header *)
  BlockWrite(OutputFile, cpcHeader, 128); (* Make dummy CPC header *)
  WriteLn(ReadHeaderWord(24), ' bytes.');

  FOR c:=1 TO ReadHeaderWord(24) DO
  BEGIN
    Blockread(InputFile, Buffer1Byte, 1); 
    BlockWrite(OutputFile, Buffer1Byte, 1);
  END;
  CloseFile(InputFile);

  IF ((DBADD-INTAT)> ReadHeaderWord(24)) THEN
  BEGIN
    WriteLn('Padding to db position using ',DBADD - INTAT - ReadHeaderWord(24),' bytes.');
    Buffer1Byte := 0;
    FOR c:= 1 TO DBADD - INTAT - ReadHeaderWord(24) DO
      BlockWrite(OutputFile, Buffer1Byte, 1);
  END;


  AssignFile(InputFile, ParamStr(3));  // The DDB file
  TRY
  Reset(InputFile, 1);
  EXCEPT
   on E: Exception DO Error('Text database file not found or invalid.');
  END; 

  Write('Text database file length is ');
  Blockread(InputFile, cpcHeader, 128); (* Get CPC header *)
  IF (FileSize(InputFile) = (ReadHeaderWord(24) + 128)  )  THEN  RealDDBLength := ReadHeaderWord(24) // has AMSDOS header
  ELSE
  BEGIN // Get from spare
    Seek(InputFile, SPARE);
    BlockRead(InputFile, RealDDBLength, 2);
    RealDDBLength := RealDDBLength - DBADD;
    Seek(InputFile, 0);  // Rewind
  END;
  WriteLn(RealDDBLength, ' bytes.');
  FOR c:=1 TO RealDDBLength DO
  BEGIN
    Blockread(InputFile, Buffer1Byte, 1); 
    BlockWrite(OutputFile, Buffer1Byte, 1);
  END;


  FileLength := DBADD - INTAT + RealDDBLength;
  CloseFile(InputFile);


  AssignFile(InputFile, ParamStr(4));  // The graphics database
  TRY
  Reset(InputFile, 1);
  EXCEPT
   on E: Exception DO Error('Graphics database file not found or invalid.');
  END; 

  Write('Graphics database file length is ');
  Blockread(InputFile, cpcHeader, 128); (* Get CPC header *)
  WriteLn(ReadHeaderWord(24), ' bytes.');
  FOR c:=1 TO ReadHeaderWord(24) DO
  BEGIN
    Blockread(InputFile, Buffer1Byte, 1); 
    BlockWrite(OutputFile, Buffer1Byte, 1);
  END;
  CloseFile(InputFile);


  GraphicsLength := ReadHeaderWord(24);
  FileLength :=  FileLength + GraphicsLength;

  Writeln('Creating valid CPC header block');
  Writeln('-------------------------------');
  SetHeader(INTAT,FileLength,ParamStr(1),INTAT);
  Seek(OutputFile,0); (* Rewind file to overwrite CPC interp header *)
  BlockWrite(OutputFile,cpcHeader,128); (* Make CPC header valid *)
  Seek(OutputFile,3+128); (* Move on to patch length of graphic data *)
  BlockWrite(OutputFile, GraphicsLength, 2);
  CloseFile(OutputFile);
  Writeln('Graphics length:', GraphicsLength);
  Writeln('-------------------------------');
  WriteLn('Complete. Files closed.');

END.