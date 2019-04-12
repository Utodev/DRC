UNIT UVocabularyTree;

{$MODE OBJFPC}


INTERFACE


TYPE TVocType = (VOC_VERB,VOC_ADVERB,VOC_NOUN,  VOC_ADJECT, VOC_PREPOSITION, VOC_CONJUGATION,  VOC_PRONOUN, VOC_ANY);

	TPVocabularyTree = ^TVocabularyTree;

     TVocabularyTree = record
				VocWord: String;
				Value: Longint;
				VocType : TVocType;
				Right : TPVocabularyTree;
				Left : TPVocabularyTree;
			  end;

VAR VocabularyTree : TPVocabularyTree;

(* Adds a new Vocabulary and returns true if succcesful, otherwise (basically cause word already exists) returns false *)
FUNCTION AddVocabulary(VAR AVocabularyTree: TPVocabularyTree; AVocabularyWord: String; AValue : Longint; AVocabularyType: TVocType):boolean;

(* Returns a pointer to word or nil if does not exist *)
FUNCTION GetVocabulary(AVocabularyTree: TPVocabularyTree; AVocabularyWord: String; AVocabularyType : TVocType): TPVocabularyTree;

(* Returns a pointer to word or nil if does not exist *)
FUNCTION GetVocabularyByNumber(AVocabularyTree: TPVocabularyTree; AVocabularyValue: Longint; AVocabularyType : TVocType): TPVocabularyTree;

IMPLEMENTATION

uses sysutils, USymbolTree;

FUNCTION FixSpanishChars(S:String):String;
BEGIN

		S := StringReplace(S,'Á','á',[rfReplaceAll]);
		S := StringReplace(S,'É','é',[rfReplaceAll]);
		S := StringReplace(S,'Í','í',[rfReplaceAll]);
		S := StringReplace(S,'Ó','ó',[rfReplaceAll]);
		S := StringReplace(S,'Ú','ú',[rfReplaceAll]);
		S := StringReplace(S,'Ü','ü',[rfReplaceAll]);
		S := StringReplace(S,'Ñ','ñ',[rfReplaceAll]);
		S := StringReplace(S,'Ç','ç',[rfReplaceAll]);

		Result := S;
END;

FUNCTION AddVocabulary(VAR AVocabularyTree: TPVocabularyTree; AVocabularyWord: String; AValue : Longint; AVocabularyType: TVocType):boolean;
BEGIN
	IF (AVocabularyTree <> nil) THEN
	BEGIN
	  IF (AVocabularyWord > AVocabularyTree^.VocWord) THEN Result := AddVocabulary(AVocabularyTree^.Right, AVocabularyWord, AValue, AVocabularyType)
	  ELSE IF (AVocabularyWord < AVocabularyTree^.VocWord) THEN Result := AddVocabulary(AVocabularyTree^.Left, AVocabularyWord, AValue, AVocabularyType)
	  ELSE Result := false;
	 END
	 ELSE
	 BEGIN
	 	New(AVocabularyTree);
	 	AVocabularyTree^.VocWord := FixSpanishChars(AnsiUpperCase(AVocabularyWord));
	 	AVocabularyTree^.Value := AValue;
	 	AVocabularyTree^.VocType := AVocabularyType;
	 	AVocabularyTree^.Left := nil;
	 	AVocabularyTree^.Right := nil;
		IF NOT AddSymbol(SymbolTree, '_VOC_'+ AVocabularyTree^.VocWord, AValue) THEN Result := false
		ELSE Result := true;
	 END;
END;

FUNCTION GetVocabulary(AVocabularyTree: TPVocabularyTree; AVocabularyWord: String; AVocabularyType : TVocType): TPVocabularyTree;
BEGIN
	AVocabularyWord := FixSpanishChars((AnsiUpperCase(AVocabularyWord)));
	IF (AVocabularyTree = nil) THEN Result:= nil
	ELSE
	IF (AVocabularyTree^.VocWord = AVocabularyWord) AND ((AVocabularyType=VOC_ANY) OR (AVocabularyTree^.VocType = AVocabularyType)) THEN Result := AVocabularyTree ELSE
	IF (AVocabularyTree^.VocWord > AVocabularyWord) THEN Result := GetVocabulary(AVocabularyTree^.Left, AVocabularyWord, AVocabularyType)
	ELSE Result := GetVocabulary(AVocabularyTree^.Right, AVocabularyWord, AVocabularyType);
END;

FUNCTION GetVocabularyByNumber(AVocabularyTree: TPVocabularyTree; AVocabularyValue: Longint; AVocabularyType : TVocType): TPVocabularyTree;
VAR PTR1, PTR2 : TPVocabularyTree;
BEGIN
	IF (AVocabularyTree = nil) THEN Result:= nil
	ELSE
	IF (AVocabularyTree^.Value = AVocabularyValue) AND ((AVocabularyType=VOC_ANY) OR (AVocabularyTree^.VocType = AVocabularyType)) THEN Result := AVocabularyTree ELSE
	BEGIN
	    PTR1 := GetVocabularyByNumber(AVocabularyTree^.Left, AVocabularyValue, AVocabularyType);
		PTR2 := GetVocabularyByNumber(AVocabularyTree^.Right, AVocabularyValue, AVocabularyType);
		IF PTR1<>nil then Result := PTR1 ELSE
		IF PTR2<>nil then Result := PTR2 ELSE Result := nil;
	END;
END;


END.