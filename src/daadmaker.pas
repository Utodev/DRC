program daadmaker;

uses sysutils,strutils;

type TTapHeader = packed record
        BlockType : byte;
        BlockContent : byte;
        Filename : array[1..10] of char;
        LengthOfDataBlock: word;
        Parameter1: word;
        Parameter2: word;
        Checksum : byte;
       end; 

       TTapHeaderRAW = packed array[0..18] of byte;

       TBigBuffer = array[0..65535] of byte;

CONST SDGTMP = 'SDG.TMP';

//This next two arrays are actually a TAP file, including a basic loader which includes or not a loading screen. It can be replaced by adding a second tap file in command line
CONST BasicLoader : array[0..73] of byte =
(19, 0, 0, 0, 68, 65, 65, 68, 32, 32, 32, 32, 32, 32, 49, 0, 10, 0, 49, 0, 10, 51, 0, 255, 0, 10, 10, 0, 253, 176, 34, 50, 52, 53, 55, 53, 34, 13, 0, 20, 
16, 0, 32, 239, 34, 34, 175, 58, 239, 34, 34, 175, 58, 239, 34, 34, 175, 13, 0, 30, 11, 0, 249, 192, 176, 34, 50, 52, 53, 55, 54, 34, 13, 68);

CONST BasicLoaderWithSCR : array[0..112] of byte =
(19, 0, 0, 0, 68, 65, 65, 68, 32, 32, 32, 32, 32, 32, 88, 0, 10, 0, 88, 0, 10, 90, 0, 255, 0, 10, 27, 0, 253, 176, 34, 50, 52, 53, 55, 53, 34, 58, 244, 176, 
34, 50, 51, 55, 51, 57, 34, 44, 176, 34, 49, 49, 49, 34, 13, 0, 20, 21, 0, 239, 34, 34, 175, 58, 32, 239, 34, 34, 175, 58, 239, 34, 34, 175, 58, 239, 34, 34, 175, 13, 
0, 30, 28, 0, 244, 176, 34, 50, 51, 55, 51, 57, 34, 44, 176, 34, 50, 52, 52, 34, 58, 249, 192, 176, 34, 50, 52, 53, 55, 54, 34, 13, 62);

//  This is the default SDF file, in case is not provided, can always be replaced with another
CONST EmptyGraphics : array[0..2088] of byte = 
(7, 215, 247, 216, 247, 255, 255, 7, 0, 0, 12, 42, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 80, 48, 0, 112, 0, 0, 32, 0, 32, 32, 32, 32, 32, 0, 32, 0, 32, 
64, 136, 136, 112, 0, 0, 0, 40, 80, 160, 80, 40, 0, 0, 0, 160, 80, 40, 80, 160, 0, 32, 64, 0, 104, 152, 152, 104, 0, 16, 32, 112, 136, 248, 128, 120, 0, 16, 32, 0, 
96, 32, 32, 112, 0, 16, 32, 0, 112, 136, 136, 112, 0, 16, 32, 0, 136, 136, 136, 112, 0, 40, 80, 0, 176, 200, 136, 136, 0, 40, 80, 136, 200, 168, 152, 136, 0, 0, 112, 136, 
128, 136, 112, 32, 64, 112, 136, 128, 128, 136, 112, 32, 64, 0, 80, 0, 136, 136, 136, 112, 0, 80, 0, 136, 136, 136, 136, 112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 32, 32, 
32, 32, 0, 32, 0, 80, 80, 0, 0, 0, 0, 0, 0, 80, 248, 80, 80, 80, 248, 80, 0, 32, 248, 160, 248, 40, 248, 32, 0, 200, 200, 16, 32, 64, 152, 152, 0, 32, 80, 32, 
96, 152, 144, 104, 0, 32, 64, 0, 0, 0, 0, 0, 0, 8, 16, 16, 16, 16, 16, 8, 0, 64, 32, 32, 32, 32, 32, 64, 0, 168, 168, 112, 248, 112, 168, 168, 0, 0, 32, 32, 
248, 32, 32, 0, 0, 0, 0, 0, 0, 0, 16, 16, 32, 0, 0, 0, 120, 0, 0, 0, 0, 0, 0, 0, 0, 0, 48, 48, 0, 8, 8, 16, 32, 64, 128, 128, 0, 112, 152, 152, 
168, 200, 200, 112, 0, 32, 96, 32, 32, 32, 32, 112, 0, 112, 136, 8, 112, 128, 128, 248, 0, 112, 136, 8, 48, 8, 136, 112, 0, 16, 48, 80, 144, 248, 16, 16, 0, 248, 128, 128, 
240, 8, 136, 112, 0, 112, 136, 128, 240, 136, 136, 112, 0, 248, 8, 8, 16, 16, 32, 32, 0, 112, 136, 136, 112, 136, 136, 112, 0, 112, 136, 136, 120, 8, 136, 112, 0, 0, 0, 32, 
0, 0, 32, 0, 0, 0, 0, 32, 0, 0, 32, 32, 64, 0, 8, 16, 32, 32, 16, 8, 0, 0, 0, 0, 120, 0, 120, 0, 0, 0, 64, 32, 16, 16, 32, 64, 0, 112, 136, 136, 
16, 32, 0, 32, 0, 0, 112, 136, 168, 184, 128, 112, 0, 112, 136, 136, 248, 136, 136, 136, 0, 240, 136, 136, 240, 136, 136, 240, 0, 112, 136, 128, 128, 128, 136, 112, 0, 240, 136, 136, 
136, 136, 136, 240, 0, 248, 128, 128, 240, 128, 128, 248, 0, 248, 128, 128, 240, 128, 128, 128, 0, 112, 136, 128, 128, 152, 136, 112, 0, 136, 136, 136, 248, 136, 136, 136, 0, 112, 32, 32, 
32, 32, 32, 112, 0, 8, 8, 8, 8, 8, 136, 112, 0, 136, 144, 160, 192, 160, 144, 136, 0, 128, 128, 128, 128, 128, 128, 248, 0, 136, 216, 168, 136, 136, 136, 136, 0, 136, 136, 200, 
168, 152, 136, 136, 0, 112, 136, 136, 136, 136, 136, 112, 0, 240, 136, 136, 240, 128, 128, 128, 0, 112, 136, 136, 136, 168, 152, 120, 0, 240, 136, 136, 240, 144, 136, 136, 0, 112, 136, 128, 
112, 8, 136, 112, 0, 248, 32, 32, 32, 32, 32, 32, 0, 136, 136, 136, 136, 136, 136, 112, 0, 136, 136, 136, 136, 136, 80, 32, 0, 136, 136, 136, 136, 168, 168, 80, 0, 136, 136, 80, 
32, 80, 136, 136, 0, 136, 136, 80, 32, 32, 32, 32, 0, 248, 8, 16, 32, 64, 128, 248, 0, 56, 32, 32, 32, 32, 32, 56, 0, 128, 128, 64, 32, 16, 8, 8, 0, 112, 16, 16, 
16, 16, 16, 112, 0, 32, 112, 168, 32, 32, 32, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 48, 72, 64, 240, 64, 64, 248, 0, 0, 0, 104, 152, 136, 152, 104, 0, 128, 128, 176, 
200, 136, 200, 176, 0, 0, 0, 112, 136, 128, 136, 112, 0, 8, 8, 104, 152, 136, 152, 104, 0, 0, 0, 112, 136, 240, 128, 120, 0, 48, 72, 64, 96, 64, 64, 64, 0, 0, 0, 112, 
136, 136, 120, 8, 112, 128, 128, 176, 200, 136, 136, 136, 0, 32, 0, 96, 32, 32, 32, 112, 0, 16, 0, 16, 16, 16, 144, 96, 0, 128, 128, 128, 160, 192, 160, 144, 0, 64, 64, 64, 
64, 64, 64, 48, 0, 0, 0, 208, 168, 168, 168, 168, 0, 0, 0, 176, 200, 136, 136, 136, 0, 0, 0, 112, 136, 136, 136, 112, 0, 0, 0, 176, 200, 136, 240, 128, 128, 0, 0, 104, 
152, 136, 120, 8, 12, 0, 0, 176, 64, 64, 64, 64, 0, 0, 0, 112, 128, 112, 8, 240, 0, 0, 64, 224, 64, 64, 64, 48, 0, 0, 0, 136, 136, 136, 136, 112, 0, 0, 0, 136, 
136, 80, 80, 32, 0, 0, 0, 136, 168, 168, 168, 80, 0, 0, 0, 136, 80, 32, 80, 136, 0, 0, 0, 136, 136, 152, 104, 8, 112, 0, 0, 248, 16, 32, 64, 248, 0, 24, 32, 32, 
64, 32, 32, 24, 0, 16, 16, 16, 16, 16, 16, 16, 0, 96, 16, 16, 8, 16, 16, 96, 0, 0, 40, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 170, 174, 
202, 38, 85, 117, 86, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 2, 3, 4, 5, 6, 1, 205, 152, 215, 247, 216, 247, 222, 247, 227, 247, 
228, 247, 228, 255, 255, 255, 1, 0, 0);

CONST version_hi = 0;
      version_lo = 1;

var Buffer: TBigBuffer;
    TAPFilename, DDBFilename, SDGFilename, INTFilename, SCRFilename, LoaderFilename : string;
    FileTAP, FileDDB, FileSDG, FileSCR, FileINT, FileLoader : file;
    SDGAddress : word;
    GameName : ShortString;
    AuxStr : ShortString;
    i : integer;

procedure SYNTAX();
begin
    WriteLn('DAADMAKER ' , version_hi, '.', version_lo);
    Writeln('Creates ZX Spectrum TAP files from DAAD DDB file and database');
    Writeln('Syntax:');
    WriteLn('daadmaker <TAP file> <INT file> <DDB file> [SDG file] [SRC file] [loader file]');
    WriteLn();
    WriteLn('<TAP file> : output TAP file');
    WriteLn('<INT file> : ZX Spectrum interpreter file');
    WriteLn('<DDB file> : input DDB file');
    WriteLn('[SDG file] : input SDG file (optional)');
    WriteLn('[SRC file] : input SRC file (optional)');
    WriteLn('[loader file] : alternative basic loader, already in tap format (optional)');
    WriteLn();
    WriteLn('Please notice parameters after third one will be identified by file extension, depending on if it''s SDG, SRC or TAP');
    halt(1);
end;

function ExtractFileNameWithoutExt(Filenametouse:ShortString):ShortString;
begin
   ExtractFileNameWithoutExt := extractfilename(copy(Filenametouse,1,rpos(ExtractFileExt(Filenametouse),Filenametouse)-1));
end;

procedure Error(S:String);
begin
 WriteLn('Error: ',S,'.');
 halt(2);
end;


procedure SaveBlockFromBuffer(Blockname: ShortString; var Foutput: file; var buffer: TBigBuffer; size: word; Address: word);
var header: TTapHeader;
    blockLength : word;
    i : word;
    checksum : byte;
    aByte : byte;
begin
   // Save the header
    BlockLength:=19;
    Blockwrite(Foutput, BlockLength,2);
    header.BlockType := 0; // it's a header
    header.BlockContent := 3; // it's CODE block
    for i := 1 to 10 do header.filename[i] := Blockname[i];
    header.LengthOfDataBlock := size;
    header.Parameter1 := Address; // Load address
    header.Parameter2 := 32768; // All code blocks have this as Param2
    //Calculate the checksum of header
    checksum := 0;
    for i:= 0 to 17 do checksum := checksum XOR (TTapHeaderRAW(header))[i];
    header.checksum := checksum;
    BlockWrite(Foutput, header, 19);
    // Save the data
    BlockLength := Size+2;
    Blockwrite(Foutput, BlockLength,2);
    aByte := $FF; // It's data block
    Blockwrite(Foutput, aByte,1);
    Blockwrite(Foutput, buffer, size);
    checksum := $FF; // The flag is included in checksum, so we start with the FF flag
    for i:= 0 to Size -1 do checksum := checksum xor buffer[i];
    Blockwrite(Foutput, checksum,1);

end;

procedure SaveBlockFromFile(Blockname: ShortString; var Foutput: file;var Finput: file; Address: word);
begin
 Blockread(Finput, Buffer,  filesize(Finput));
 SaveBlockFromBuffer(Blockname,Foutput, Buffer, filesize(Finput), Address);
end;

procedure SaveLoader(var Foutput: file; GameName : String; withScreen: boolean );
var checksum : byte;
    headerSize : word;
begin
    if (withScreen) then begin
                          headerSize := sizeof(BasicLoaderWithSCR);
                          Move(BasicLoaderWithSCR, Buffer, headerSize);
                         end 
                    else begin
                            headerSize := sizeof(BasicLoader);
                            Move(BasicLoader, Buffer, headerSize);
                         end;   
    for i := 1 to 10 do Buffer[i+3] := Ord(GameName[i]);
    checksum := 0;
    for i:= 3 to 19 do checksum := checksum xor Buffer[i];
    Buffer[20] := checksum;
    BlockWrite(Foutput, buffer, headerSize);
end;


begin
    if (ParamCount<3) or (ParamCount>5) then Syntax();
    TAPFilename := ParamStr(1);
    INTFilename := ParamStr(2);
    DDBFilename := ParamStr(3);
    if not FileExists(DDBFilename) then Error('DDB file not found');
    if not FileExists(INTFilename) then Error('Interpreter file not found');
    SDGFilename := '';
    SCRFilename := '';
    LoaderFilename := '';
    for i := 4 to ParamCount() do
    begin
      AuxStr := ParamStr(i);
      if not FileExists(AuxStr) then Error(AuxStr + ' not found');
      if UpperCase(ExtractFileExt(AuxStr)) = '.SCR' then SCRFilename := AuxStr else 
      if UpperCase(ExtractFileExt(AuxStr)) = '.TAP' then LoaderFilename := AuxStr else 
      if UpperCase(ExtractFileExt(AuxStr)) = '.SDG' then SDGFilename := AuxStr else Error('Invalid extension '+UpperCase(ExtractFileExt(AuxStr))+', must be either SCR, TAP or SDG');
    end;

    if SDGFilename = '' then
    begin // No SDG file, create a fake one
         SDGFilename := SDGTMP;
         Assign(FileSDG, SDGFilename);
         Rewrite(FileSDG, 1);
         BlockWrite(FileSDG, EmptyGraphics, sizeof(EmptyGraphics));
         Close(FileSDG);
    end;

    GameName := UpperCase(ExtractFileNameWithoutExt(TAPFilename)) + '          ';
    if (length(GameName)>10)  then GameName := Copy(GameName, 1, 10);
    
    Assign(FileTAP, TAPFilename);
    Rewrite(FileTAP,1);
    Assign(FileDDB, DDBFilename);
    Reset(FileDDB,1);
    Assign(FileSDG, SDGFilename);
    Reset(FileSDG,1);
    Assign(FileINT, INTFilename);
    Reset(FileINT, 1);
    
    // Export the basic loader. There are three options: custom one, loader without SCREEN$ and loader with SCREEN$
    IF LoaderFilename<>''then  // Custom loader
    begin
        Assign(FileLoader, LoaderFilename);  
        Reset(FileLoader, 1);
        Blockread(FileLoader, Buffer, Sizeof(FileLoader));
        BlockWrite(FileTap, Buffer, sizeOf(FileLoader));
        Close(FileLoader);
    end
    else
    begin
        if (SCRFilename='') then SaveLoader(FileTAP, GameName, false) // Loader without SCREEN$
                            else 
                            begin 
                                SaveLoader(FileTAP, GameName, true); // Loader with SCREEN$
                                //Save SCREEN$
                                Assign(FileSCR, SCRFilename);
                                Reset(FileSCR,1);
                                if (filesize(FileSCR)<>6912) THEN Error('Invalid SCREEN$ file, size must be 6912 bytes');
                                GameName[10] := 'S';
                                SaveBlockFromFile(GameName,FileTAP, FileSCR, 16384);
                                Close(FileSCR);
                             end;
        

    end;                             
    // Save the interpreter
    GameName[10] := 'I';
    SaveBlockFromFile(GameName,FileTAP, FileINT, 24576);
    if (filesize(fileDDB)+ $8400 > $FFFF) then Error('DDB exceedes RAM size');
    // Save the DDB
    GameName[10] := 'D';
    SaveBlockFromFile(GameName,FileTAP, FileDDB, $8400);
    // Save the SDG
    SDGAddress := $FFFF - filesize(FileSDG) +1;
    if (filesize(fileDDB)+ $8400 > SDGAddress) then Error('DDB + SDG exceed RAM size');
    GameName[10] := 'G';
    SaveBlockFromFile(GameName,FileTAP, FileSDG, SDGAddress);
    Close(FileTap);
    Close(FileINT);
    Close(FileDDB);
    Close(FileSDG);
    if (SDGFilename=SDGTMP) then Erase(FileSDG);
    WriteLn('OK');
end.