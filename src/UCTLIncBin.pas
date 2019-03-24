UNIT UCTLIncBin;

INTERFACE

TYPE  TCTLIncBinList =  ARRAY OF AnsiString;
VAR CTLIncBinList: TCTLIncBinList;	 

PROCEDURE AddCTL_IncBin(VAR ACTLIncBinList: TCTLIncBinList; FileName:AnsiString);

IMPLEMENTATION

PROCEDURE AddCTL_IncBin(VAR ACTLIncBinList: TCTLIncBinList; FileName:AnsiString);
BEGIN
 SetLength(ACTLIncBinList, Length(ACTLIncBinList) + 1);
 ACTLIncBinList[Length(ACTLIncBinList)-1] := FileName;
END;

END. 
