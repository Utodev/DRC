UNIT UJSONExport;

{$I+}

INTERFACE

PROCEDURE GenerateJSON(OutputFileName: string);

IMPLEMENTATION


USES sysutils, UConstants, UVocabularyTree, UMessageList, UConnections, UObjects, UProcess, UProcessCondactList, UCTLIncBin, USymbolTree, strutils;


VAR Indent : Byte;

FUNCTION tabs(): String;
VAR AuxStr : String;
    i : integer;
BEGIN
    AuxStr:='';
    for i := 1 to indent do AuxStr := AuxStr + #9; // tab
    tabs := AuxStr;
END;    

FUNCTION getSymbolsJSON(SymbolTree:TPSymbolTree): AnsiString;
BEGIN
 IF (SymbolTree = nil) THEN getSymbolsJSON := ''
                       ELSE getSymbolsJSON :=  getSymbolsJSON(SymbolTree^.Right) + tabs() + tabs() + '{"symbol":"' +  SymbolTree^.Symbol +'", "Value":' + IntToStr(SymbolTree^.Value) +'},'#10 +  getSymbolsJSON(SymbolTree^.Left);
END;

FUNCTION getVocabularyJSON(VocabularyTree:TPVocabularyTree): AnsiString;
BEGIN
 IF (VocabularyTree = nil) THEN getVocabularyJSON := ''
                       ELSE getVocabularyJSON :=  getVocabularyJSON(VocabularyTree^.Right) + tabs() + tabs() + '{"VocWord":"' +  VocabularyTree^.VocWord +'", "Value":' + IntToStr(VocabularyTree^.Value) +',"VocType":'+ IntToStr(Ord(VocabularyTree^.VocType)) +' },'#10 +  getVocabularyJSON(VocabularyTree^.Left);
END;

FUNCTION FixDoubleQuotes(Str: AnsiString):AnsiString;
BEGIN
  Str := AnsiReplaceStr(Str, '"','\"');
  Str := AnsiReplaceStr(Str, '\\"','\"');
  FixDoubleQuotes := Str;
END;  


PROCEDURE GenerateJSON(OutputFileName: string);
VAR JSON : Text;
    TempObjectList : TPObjectList;	
    Aux,i,j : Word;
    MessageListsArray : array [0..3] of TPMessageList;
    MessageListsnames : array [0..3] of String;
    TempMessageList : TPMessageList;
    TempEntriesList : TPProcessEntryList;
    TempCondactList : TPProcessCondactList;
    AuxAnsiString :AnsiString;

BEGIN
    Indent := 0;
    Assign(JSON, OutputFileName);
    Rewrite(JSON);
    WriteLn(JSON,tabs(),'{');
    // Symbols
    WriteLn(JSON,tabs(),'"symbols":');
    INC(Indent);     
    WriteLn(JSON,tabs(),'[');
    AuxAnsiString := getSymbolsJSON(SymbolTree);
    SetLength(AuxAnsiString, Length(AuxAnsiString) - 2);
    WriteLn(JSON,  AuxAnsiString);
    WriteLn(JSON,tabs(),'],');
    DEC(Indent);
    // Binaries, Externs
    WriteLn(JSON,tabs(),'"binaries":');
    INC(Indent);     
    WriteLn(JSON,tabs(),'[');
    IF Length(CTLIncBinList)> 0 THEN
    FOR i := 0 to Length(CTLIncBinList)-1 DO 
    BEGIN
      Write(JSON, tabs(), '{"FilePath":"',CTLIncBinList[i] , '"}');
      if (i<>Length(CTLIncBinList)-1) THEN WriteLN(JSON, ',') ELSE WriteLN(JSON);
    END;
    WriteLn(JSON,tabs(),'],');
    DEC(Indent);
    // Vocabulary
    WriteLn(JSON,tabs(),'"vocabulary":');
    INC(Indent);     
    WriteLn(JSON,tabs(),'[');
    AuxAnsiString := getVocabularyJSON(VocabularyTree);
    SetLength(AuxAnsiString, Length(AuxAnsiString) - 2);
    WriteLn(JSON,  AuxAnsiString);
    WriteLn(JSON,tabs(),'],');
    DEC(Indent);
    // Objects
    WriteLn(JSON,tabs(),'"object_data":');
    INC(Indent);
    WriteLn(JSON,tabs(),'[');
    TempObjectList := ObjectList;
    WHILE TempObjectList<>nil DO
    BEGIN
        WriteLn(JSON,tabs(),'{');
        INC(Indent);       
        WriteLn(JSON,tabs(),'"Value":', TempObjectList^.Value,',');
        WriteLn(JSON,tabs(),'"Noun":', TempObjectList^.Noun,',');
        WriteLn(JSON,tabs(),'"Adjective":', TempObjectList^.Adjective,',');
        IF TempObjectList^.Container THEN Aux := 1 ELSE Aux := 0;
        WriteLn(JSON,tabs(),'"Container":', Aux,',');
        IF TempObjectList^.Wearable THEN Aux := 1 ELSE Aux := 0;
        WriteLn(JSON,tabs(),'"Wearable":', Aux,',');
        WriteLn(JSON,tabs(),'"Flags":', TempObjectList^.Flags,',');
        WriteLn(JSON,tabs(),'"Weight":', TempObjectList^.Weight,',');
        WriteLn(JSON,tabs(),'"InitialyAt":', TempObjectList^.InitialyAt);
        DEC(Indent);
        Write(JSON, tabs(), '}');
        if (TempObjectList^.Next <> nil) THEN WriteLn(JSON,',') ELSE WriteLn(JSON);
        TempObjectList := TempObjectList^.Next;
    END;
    WriteLn(JSON,tabs(),'],');
    DEC(Indent);
    // Vocabulary

    // Texts
    MessageListsArray[0]:=MTX;
    MessageListsArray[1]:=STX;
    MessageListsArray[2]:=LTX;
    MessageListsArray[3]:=OTX;

    MessageListsnames[0]:='messages';
    MessageListsnames[1]:='sysmess';
    MessageListsnames[2]:='locations';
    MessageListsnames[3]:='objects';

    for i := 0 to 3 DO
    BEGIN
        TempMessageList := MessageListsArray[i];
        WriteLn(JSON,tabs(),'"',MessageListsnames[i],'":');
        INC(Indent);     
        WriteLn(JSON,tabs(),'[');
        WHILE TempMessageList<>nil DO
        BEGIN
            WriteLn(JSON,tabs(),'{');
            INC(Indent);       
            WriteLn(JSON,tabs(),'"Value":', TempMessageList^.MessageID,',');
            WriteLn(JSON,tabs(),'"Text":"', FixDoubleQuotes(TempMessageList^.Text),'"');
            DEC(Indent);
            Write(JSON, tabs(), '}');
            if (TempMessageList^.Next <> nil) THEN WriteLn(JSON,',') ELSE WriteLn(JSON);
            TempMessageList := TempMessageList^.Next;
        END;             
        WriteLn(JSON,tabs(),'],');
        DEC(Indent);
    END;
    // Processes
    WriteLn(JSON,tabs(),'"processes":');
    INC(Indent);     
    WriteLn(JSON,tabs(),'[');

    FOR i := 0 to ProcessCount - 1 DO // each process
    BEGIN
            WriteLn(JSON,tabs(),'{');
            INC(Indent);       
            WriteLn(JSON,tabs(),'"Value":', Processes[i].Value,',');
            WriteLn(JSON,tabs(),'"entries":');
            INC(Indent);
            WriteLn(JSON,tabs(),'[');
            TempEntriesList := Processes[i].Entries;
            WHILE TempEntriesList<> nil  DO  // Each entry
            BEGIN
                WriteLn(JSON,tabs(),'{');
                INC(Indent);       
                WriteLn(JSON,tabs(),'"Verb":', TempEntriesList^.Verb,',');
                WriteLn(JSON,tabs(),'"Noun":', TempEntriesList^.Noun,',');
                TempCondactList := TempEntriesList^.Condacts;
                WriteLn(JSON,tabs(),'"condacts":');
                INC(Indent);
                WriteLn(JSON,tabs(),'[');
                WHILE TempCondactList<> nil  DO  //  Each condact
                BEGIN
                    WriteLn(JSON,tabs(),'{');
                    INC(Indent);       
                    WriteLn(JSON,tabs(),'"Opcode":', TempCondactList^.Opcode,',');
                     IF TempCondactList^.NumParams>0 THEN 
                    BEGIN
                        IF TempCondactList^.Params[0].Indirection THEN Aux := 1 ELSE Aux := 0;
                        WriteLn(JSON,tabs(),'"Indirection1":', Aux,',');
                        FOR J := 0 to TempCondactList^.NumParams - 1 DO WriteLn(JSON,tabs(),'"Param',j+1,'":', TempCondactList^.Params[j].Value,',');                        
                    END;
                    WriteLn(JSON,tabs(),'"NumParams":', TempCondactList^.NumParams);
                    

                    DEC(Indent);
                    Write(JSON, tabs(), '}');
                    if (TempCondactList^.Next <> nil) THEN WriteLn(JSON,',') ELSE WriteLn(JSON);
                    TempCondactList:=TempCondactList^.Next;
                END;
                WriteLn(JSON,tabs(),']');
                DEC(Indent);
                DEC(Indent);
                Write(JSON, tabs(), '}');
                if (TempEntriesList^.Next <> nil) THEN WriteLn(JSON,',') ELSE WriteLn(JSON);
                TempEntriesList := TempEntriesList^.Next;
            END;
            WriteLn(JSON,tabs(),']');
            DEC(Indent);
            DEC(Indent);
            Write(JSON, tabs(), '}');
            if (i  < ProcessCount-1) THEN WriteLn(JSON,',') ELSE WriteLn(JSON);
    END;



    WriteLn(JSON,tabs(),']');
    DEC(Indent);


    WriteLn(JSON,tabs(),'}');
    Close(JSON);
    Writeln('JSON file exported.')
END;


END.

