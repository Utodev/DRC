PROGRAM MCRF;

// This code is made by Uto, but strongly based on original Hisoft C  code made my Tim Gilberts and maybe Graeme Yeandle. 
                     
// Creates a run file for the Amstrad CPC system. This combines the required interpreter with a given database and graphics
// database (all of which have a CPC header), also adds a CPC header to result file.

{$MODE OBJFPC}

USES sysutils, strutils;


CONST DUMMY_HEADER : array[0..127] of byte = ($00 , $47 , $49 , $4C , $42 , $45 , $52 , $54 , $53 , $42 , $49 , $4E , $00 , $00 , $00 , $00 , $00 , $00 , $02 , $00 , $00 , $40 , $08 , $00 , $45 , $1D , $79 , $24 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $45 , $1D , $00 , $E0 , $04 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00 , $00);
CONST VERSION='3.1';     
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
    RealInterpreterLength: Word;
    CharsetOffset : Word;


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
  WriteLn('SYNTAX: MCRF <target file> <interpreter file> <text DDB file> <graphics file> [font file]');
  Writeln();
  Writeln('Example: MCRF MYGAME.BIN INT.Z80 MYGAME.DDB MYGAME.GRA');
  Writeln('Example: MCRF MYGAME.BIN INT.Z80 MYGAME.DDB MYGAME.GRA PAW1.CHR');
  Writeln();
  Writeln('Important: The graphics file should have an AMSDOS header. The DDB (text database) and the interpreter files may have it or not, MCRF will auto-detect it.');
  WriteLn('CHR files are raw definition of 8x8 characters, 256 total, so it should be a 256 x 8 bytes file (2048). If an Amsdos header is present, it will be ignored.');
  Halt(1);
END;

BEGIN
  WriteLn('Make CPC run file on PC. VERSION ', VERSION, ' FILE VERSION ', FILEV);
  WriteLn('(c) 1989-2018 Infinite Imaginations.');
  WriteLn('Original code for CP/M written by T.J.Gilberts using Hisoft C.');
  WriteLn('Rebuilt in pascal by Uto in 2018');

  IF NOT(ParamCount() IN [4,5]) THEN Syntax();

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
  IF (FileSize(InputFile) = (ReadHeaderWord(24) + 128)  )  THEN
  BEGIN
    RealInterpreterLength := ReadHeaderWord(24); // has AMSDOS header
    BlockWrite(OutputFile, cpcHeader, 128); (* Make dummy CPC header *)
  END
  ELSE
  BEGIN
    RealInterpreterLength := FileSize(InputFile); // doesn't have AMSDOS header
    FOR c:=0 TO 127 DO        (* Make dummy CPC header *)
    BEGIN
      Buffer1Byte := DUMMY_HEADER[c];
      BlockWrite(OutputFile, Buffer1Byte, 1);
    END;
    Seek(InputFile, 0);  // Rewind
  END;
    
  WriteLn(RealInterpreterLength, ' bytes.');

  FOR c:=1 TO RealInterpreterLength DO
  BEGIN
    Blockread(InputFile, Buffer1Byte, 1); 
    BlockWrite(OutputFile, Buffer1Byte, 1);
  END;
  CloseFile(InputFile);

  IF ((DBADD-INTAT)> RealInterpreterLength) THEN
  BEGIN
    WriteLn('Padding to DDB position using ',DBADD - INTAT - RealInterpreterLength,' bytes.');
    Buffer1Byte := 0;
    FOR c:= 1 TO DBADD - INTAT - RealInterpreterLength DO
      BlockWrite(OutputFile, Buffer1Byte, 1);
  END;


  AssignFile(InputFile, ParamStr(3));  // The DDB file
  TRY
  Reset(InputFile, 1);
  EXCEPT
   on E: Exception DO Error('DDB file not found or invalid.');
  END; 

  Write('DDB length is ');
  Blockread(InputFile, cpcHeader, 128); (* Get CPC header *)
  IF (FileSize(InputFile) = (ReadHeaderWord(24) + 128)  )  THEN  RealDDBLength := ReadHeaderWord(24) // has AMSDOS header
  ELSE
  BEGIN // Get from ral file
    RealDDBLength := FileSize(InputFile);
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

  CharsetOffset := Filepos(OutputFile);
  
  AssignFile(InputFile, ParamStr(4));  // The graphics database
  TRY
  Reset(InputFile, 1);
  EXCEPT
   on E: Exception DO Error('Graphics file not found or invalid.');
  END; 

  Write('Graphics database length is ');
  Blockread(InputFile, cpcHeader, 128); (* Get CPC header *)
  WriteLn(ReadHeaderWord(24), ' bytes.');
  FOR c:=1 TO ReadHeaderWord(24) DO
  BEGIN
    Blockread(InputFile, Buffer1Byte, 1); 
    BlockWrite(OutputFile, Buffer1Byte, 1);
  END;
  CloseFile(InputFile);

  IF (ParamCount>4) THEN
  BEGIN
    AssignFile(InputFile, ParamStr(5));  // The font file
    TRY
      Reset(InputFile, 1);
    EXCEPT
    on E: Exception DO Error('Font file not found or invalid.');
    END; 
    //Seek(OutputFile, FileSize(OutputFile)-128);
    Seek(OutputFile, CharsetOffset +48);
    WriteLn('Updating font file.');
    IF (fileSize(InputFile)<>2048) AND (fileSize(InputFile)<>2048+128)  THEN  Error('Invalid font file size.');
    IF fileSize(InputFile)=2048+128 THEN Seek(InputFile, 128);
    FOR C:=1 TO 2048 DO
    BEGIN
      BlockRead(InputFile, Buffer1Byte, 1);
      BlockWrite(OutputFile, Buffer1Byte, 1);
    END;  
    CloseFile(InputFile);
  END;


  GraphicsLength := ReadHeaderWord(24);
  FileLength :=  FileLength + GraphicsLength;

  if (FileLength + INTAT) >= $A6FC THEN  // A6FC is the variable area, after which is C000 the vram. We could write here if we didn't use the firmware, but we do.
    Error('Final file too large for CPC system. Please reduce size of DDB or graphics files.'); 
     

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