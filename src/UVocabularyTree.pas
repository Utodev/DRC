UNIT UVocabularyTree;

{$MODE OBJFPC}


INTERFACE


TYPE TVocType = (VOC_VERB,VOC_ADVERB,VOC_NOUN,  VOC_ADJECT, VOC_PREPOSITION, VOC_CONJUGATION,  VOC_PRONOUN, VOC_ANY);

	TPVocabularyTree = ^TVocabularyTree;

     TVocabularyTree = record
				VocWord: AnsiString;
				Value: Longint;
				VocType : TVocType;
				Right : TPVocabularyTree;
				Left : TPVocabularyTree;
			  end;

VAR VocabularyTree : TPVocabularyTree;

(* Adds a new Vocabulary and returns true if succcesful, otherwise (basically cause word already exists) returns false *)
FUNCTION AddVocabulary(VAR AVocabularyTree: TPVocabularyTree; AVocabularyWord: AnsiString; AValue : Longint; AVocabularyType: TVocType):boolean;

(* Returns a pointer to word or nil if does not exist *)
FUNCTION GetVocabulary(AVocabularyTree: TPVocabularyTree; AVocabularyWord: AnsiString; AVocabularyType : TVocType): TPVocabularyTree;

IMPLEMENTATION

uses sysutils, USymbolTree;

FUNCTION AddVocabulary(VAR AVocabularyTree: TPVocabularyTree; AVocabularyWord: AnsiString; AValue : Longint; AVocabularyType: TVocType):boolean;
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
	 	AVocabularyTree^.VocWord := AnsiUpperCase(AVocabularyWord);
	 	AVocabularyTree^.Value := AValue;
	 	AVocabularyTree^.VocType := AVocabularyType;
	 	AVocabularyTree^.Left := nil;
	 	AVocabularyTree^.Right := nil;
		IF NOT AddSymbol(SymbolTree, '_VOC_'+ AVocabularyTree^.VocWord, AValue) THEN Result := false
		ELSE Result := true;
	 END;
END;

FUNCTION GetVocabulary(AVocabularyTree: TPVocabularyTree; AVocabularyWord: AnsiString; AVocabularyType : TVocType): TPVocabularyTree;
BEGIN
	AVocabularyWord := AnsiUpperCase(AVocabularyWord);
	IF (AVocabularyTree = nil) THEN Result:= nil
	ELSE
	IF (AVocabularyTree^.VocWord = AVocabularyWord) AND ((AVocabularyType=VOC_ANY) OR (AVocabularyTree^.VocType = AVocabularyType)) THEN Result := AVocabularyTree ELSE
	IF (AVocabularyTree^.VocWord > AVocabularyWord) THEN Result := GetVocabulary(AVocabularyTree^.Left, AVocabularyWord, AVocabularyType)
	ELSE Result := GetVocabulary(AVocabularyTree^.Right, AVocabularyWord, AVocabularyType);
END;


END.