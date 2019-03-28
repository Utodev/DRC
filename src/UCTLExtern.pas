UNIT UCTLExtern;

INTERFACE

TYPE  TCTLExternList =  ARRAY OF AnsiString;
VAR CTLExternList: TCTLExternList;	 

PROCEDURE AddCTL_Extern(VAR ACTLExternList: TCTLExternList; FileName:AnsiString);

IMPLEMENTATION

PROCEDURE AddCTL_Extern(VAR ACTLExternList: TCTLExternList; FileName:AnsiString);
BEGIN
 SetLength(ACTLExternList, Length(ACTLExternList) + 1);
 ACTLExternList[Length(ACTLExternList)-1] := FileName;
END;

END. 
