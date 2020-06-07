UNIT UJSONExport;

{$I+}

INTERFACE

PROCEDURE GenerateJSON(OutputFileName: string);

IMPLEMENTATION


USES sysutils, UConstants, UVocabularyTree, UMessageList, UConnections, UObjects, UProcess, UProcessCondactList, UCTLExtern, USymbolList, strutils, UCondacts, USintactic;


VAR Indent : Byte;

FUNCTION tabs(): AnsiString;
VAR AuxStr : AnsiString;
    i : integer;
BEGIN
    AuxStr:='';
    for i := 1 to indent do AuxStr := AuxStr + #9; // tab
    tabs := AuxStr;
END;    

FUNCTION getSymbolsJSON(SymbolList:TPSymbolList): AnsiString;
BEGIN
 IF (SymbolList = nil) THEN getSymbolsJSON := ''
                       ELSE getSymbolsJSON :=  getSymbolsJSON(SymbolList^.Next) + tabs() + tabs() + '{"symbol":"' +  SymbolList^.Symbol +'", "Value":' + IntToStr(SymbolList^.Value) +'},'#10;
END;

FUNCTION getVocabularyJSON(VocabularyTree:TPVocabularyTree): AnsiString;
BEGIN
 IF (VocabularyTree = nil) THEN getVocabularyJSON := ''
                       ELSE getVocabularyJSON :=  getVocabularyJSON(VocabularyTree^.Left) + tabs() + tabs() + '{"VocWord":"' +  VocabularyTree^.VocWord +'", "Value":' + IntToStr(VocabularyTree^.Value) +',"VocType":'+ IntToStr(Ord(VocabularyTree^.VocType)) +' },'#10 +  getVocabularyJSON(VocabularyTree^.Right);
END;

FUNCTION FixDoubleQuotes(Str: AnsiString):AnsiString;
BEGIN
  Str := AnsiReplaceStr(Str, '"','\"');
  Str := AnsiReplaceStr(Str, '\\"','\"');
  FixDoubleQuotes := Str;
END;  

FUNCTION ConvertChars(Str: AnsiString):AnsiString;
var i: integer;
    strOut : AnsiString;
BEGIN
// First replace international chars. Please notice AnsiReplaceStr(Str, 'á', '\u0015') doesn't work. Probably a bug of the compiler library.
// That is the reason why all replacements are done the way you see below, which is a little complicate. Codes in the CASE statement are the
// ISO 8559-1 LATIN1 code for each of the characters. The replacement values are the ASCII codes DAAD uses for the Spanish characters (first
// part) and the #gX#t combination we use for the new international characters.
strOut := '';
for i := 1 to Length(Str) DO 
BEGIN
  CASE (Ord(Str[i])) OF
  // Old spanish chars
   170: strOut := strOut + '\u0010'; //ª - 16
   161: strOut := strOut + '\u0011'; //¡ - 17
   191: strOut := strOut + '\u0012'; //¿ - 18
   171: strOut := strOut + '\u0013'; //<< - 19
   187: strOut := strOut + '\u0014'; //<< - 20
   225: strOut := strOut + '\u0015'; //á - 21
   233: strOut := strOut + '\u0016'; //é - 22
   237: strOut := strOut + '\u0017'; //í - 23
   243: strOut := strOut + '\u0018'; //ó - 24
   250: strOut := strOut + '\u0019'; //ú - 26
   241: strOut := strOut + '\u001A'; //ñ - 27
   209: strOut := strOut + '\u001B'; //Ñ - 28
   231: strOut := strOut + '\u001C'; //ç - 28
   199: strOut := strOut + '\u001D'; //Ç - 29
   252: strOut := strOut + '\u001E'; //ü - 30
   220: strOut := strOut + '\u001F'; //Ü - 31
   // New international chars
   224: strOut := strOut + '#g\u0010#t'; //à - 16
   227: strOut := strOut + '#g\u0011#t'; //ã - 17
   228: strOut := strOut + '#g\u0012#t'; //ä - 18
   226: strOut := strOut + '#g\u0013#t'; //â - 19
   232: strOut := strOut + '#g\u0014#t'; //è - 20
   235: strOut := strOut + '#g\u0015#t'; //ë - 21
   234: strOut := strOut + '#g\u0016#t'; //ê - 22
   236: strOut := strOut + '#g\u0017#t'; //ì - 23
   239: strOut := strOut + '#g\u0018#t'; //ï - 24
   238: strOut := strOut + '#g\u0019#t'; //î - 26
   242: strOut := strOut + '#g\u001A#t'; //ò - 27
   245: strOut := strOut + '#g\u001B#t'; //õ - 28
   246: strOut := strOut + '#g\u001C#t'; //ö - 28
   244: strOut := strOut + '#g\u001D#t'; //ô - 29
   249: strOut := strOut + '#g\u001E#t'; //ù - 30
   251: strOut := strOut + '#g\u001F#t'; //û - 31
   223: strOut := strOut + '#g\u0023#t'; //ß - 35
   ELSE StrOut := strOut +  Str[i];
  END;
END;  
// Now replace escape sequences

  StrOut := AnsiReplaceStr(StrOut, '#g', '\u000e');
  StrOut := AnsiReplaceStr(StrOut, '#t', '\u000f');
  StrOut := AnsiReplaceStr(StrOut, '#b', '\u000b');
  StrOut := AnsiReplaceStr(StrOut, '#b', '\u000b');
  StrOut := AnsiReplaceStr(StrOut, '#s', ' ');
  StrOut := AnsiReplaceStr(StrOut, '#f', '\u007f');
  StrOut := AnsiReplaceStr(StrOut, '#k', '\u000c');
  StrOut := AnsiReplaceStr(StrOut, '#n', '\u000d');
  StrOut := AnsiReplaceStr(StrOut, '#r', '\u000d');
  StrOut := AnsiReplaceStr(StrOut, '\n', '\u000d');
  // Add #A to #P to replacements array
  for i := ord('A') to ord('P') DO StrOut := AnsiReplaceStr(StrOut, '#' + chr(i), '\u00' + IntToHex(i +$10 - ord('A'),2));

  ConvertChars := StrOut;
END;

PROCEDURE GenerateJSON(OutputFileName: string);
VAR JSON : Text;
    TempObjectList : TPObjectList;	
    Aux,i,j : Word;
    MessageListsArray : array [0..5] of TPMessageList;
    MessageListsnames : array [0..5] of String;
    TempMessageList : TPMessageList;
    TempEntriesList : TPProcessEntryList;
    TempCondactList : TPProcessCondactList;
    TempConnectionList : TPConnectionList;
    AuxAnsiString :AnsiString;
    VerbStr, NounStr : String;
    VerbPtr, NounPtr : TPVocabularyTree;

BEGIN
    Indent := 0;
    Assign(JSON, OutputFileName);
    Rewrite(JSON);
    WriteLn(JSON,tabs(),'{');
    // Settings
    WriteLn(JSON,tabs(),'"settings":');
    INC(Indent);     
    WriteLn(JSON,tabs(),'[');
    WriteLn(JSON,tabs(),'{"classic_mode":', byte(ClassicMode), ', "debug_mode":', byte(DebugMode) , ', "maluva_used":', byte(MaluvaUsed), '}');
    WriteLn(JSON,tabs(),'],');
    DEC(Indent);
    // Symbols
    WriteLn(JSON,tabs(),'"symbols":');
    INC(Indent);     
    WriteLn(JSON,tabs(),'[');
    AuxAnsiString := getSymbolsJSON(SymbolList);
    SetLength(AuxAnsiString, Length(AuxAnsiString) - 2);
    WriteLn(JSON,  AuxAnsiString);
    WriteLn(JSON,tabs(),'],');
    DEC(Indent);
    // Externs
    WriteLn(JSON,tabs(),'"externs":');
    INC(Indent);     
    WriteLn(JSON,tabs(),'[');
    IF Length(CTLExternList)> 0 THEN
    FOR i := 0 to Length(CTLExternList)-1 DO 
    BEGIN
      Write(JSON, tabs(), '{"FilePath":"',CTLExternList[i] , '"}');
      if (i<>Length(CTLExternList)-1) THEN WriteLN(JSON, ',') ELSE WriteLN(JSON);
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
    // Connections

    TempConnectionList := Connections;
    WriteLn(JSON,tabs(),'"connections":');
    INC(Indent);
    WriteLn(JSON,tabs(),'[');
    WHILE TempConnectionList<>nil DO
    BEGIN
        WriteLn(JSON,tabs(),'{');
        INC(Indent);       
        WriteLn(JSON,tabs(),'"FromLoc":', TempConnectionList^.FromLoc,',');
        WriteLn(JSON,tabs(),'"ToLoc":', TempConnectionList^.ToLoc,',');
        WriteLn(JSON,tabs(),'"Direction":', TempConnectionList^.Direction);
        DEC(Indent);
        Write(JSON, tabs(), '}');
        if (TempConnectionList^.Next <> nil) THEN WriteLn(JSON,',') ELSE WriteLn(JSON);
        TempConnectionList := TempConnectionList^.Next;
    END;
    WriteLn(JSON,tabs(),'],');
    DEC(Indent);
   

    // Texts
    MessageListsArray[0]:=MTX;
    MessageListsArray[1]:=STX;
    MessageListsArray[2]:=LTX;
    MessageListsArray[3]:=OTX;
    MessageListsArray[4]:=XTX;
    MessageListsArray[5]:=OtherTX;

    MessageListsnames[0]:='messages';
    MessageListsnames[1]:='sysmess';
    MessageListsnames[2]:='locations';
    MessageListsnames[3]:='objects';
    MessageListsnames[4]:='xmessages';
    MessageListsnames[5]:='other_strings';

    for i := 0 to 5 DO
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
            WriteLn(JSON,tabs(),'"Text":"', ConvertChars(FixDoubleQuotes(TempMessageList^.Text)),'"');
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
                IF (TempEntriesList^.Verb = 255) THEN VerbStr := '_' ELSE
                BEGIN
                  VerbPtr := GetVocabularyByNumber(VocabularyTree,TempEntriesList^.Verb, VOC_VERB);
                  IF (VerbPtr = nil) AND (TempEntriesList^.Verb <= MAX_CONVERTIBLE_NAME) THEN VerbPtr := GetVocabularyByNumber(VocabularyTree,TempEntriesList^.Verb, VOC_NOUN);
                  IF VerbPtr = nil then VerbStr := '?' ELSE VerbStr := VerbPtr^.VocWord;
                END;  
                IF (TempEntriesList^.Noun = 255) THEN NounStr := '_' ELSE
                BEGIN
                  NounPtr := GetVocabularyByNumber(VocabularyTree,TempEntriesList^.Noun, VOC_NOUN);
                  IF NounPtr = nil then NounStr := '?' ELSE NounStr := NounPtr^.VocWord;
                END;  
                WriteLn(JSON,tabs(),'"Entry":"', VerbStr,' ',NounStr,'",');               
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
                    IF (TempCondactList^.isDB) THEN WriteLn(JSON,tabs(),'"Condact":"#DB/#INCBIN",') 
                    ELSE IF (TempCondactList^.Opcode = FAKE_USERPTR_CONDACT_CODE) THEN WriteLn(JSON,tabs(),'"Condact":"#USERPTR",') 
                    ELSE IF (TempCondactList^.Opcode = FAKE_DEBUG_CONDACT_CODE) THEN WriteLn(JSON,tabs(),'"Condact":"DEBUG",') 
                    ELSE WriteLn(JSON,tabs(),'"Condact":"', Condacts[TempCondactList^.Opcode].Condact,'",');

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
    Writeln(OutputFileName + ' generated.')
END;


END.

