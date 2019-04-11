UNIT UTokenList;

{$MODE OBJFPC}

INTERFACE

TYPE TPTokenList = ^TTokenList;

     TTokenList = record
				TokenID: Word;
				Text : AnsiString ;
				IntVal : longint;
				lineno: Longint;
				colno : Word;
				Next : TPTokenList;
			  end;

var TokenList : TPTokenList;			  



PROCEDURE AddToken(VAR ATokenList:TPTokenList; ATokenID: Word; AText: AnsiString; AIntVal:longint; yylineno: longint; yycolno: word);			     
FUNCTION normalize(S: AnsiString) :AnsiString;
IMPLEMENTATION
uses sysutils;

FUNCTION normalize(S: AnsiString) :AnsiString;
var i : integer;
	
BEGIN
Result :='';
 for i := 1 to length(S) DO 
 BEGIN
  if (ord(s[i])>127) THEN  Result := Result + '#' + IntToStr(ord(S[i])) ELSE Result := Result + S[i];
 END;
END;

PROCEDURE AddToken(VAR ATokenList:TPTokenList; ATokenID: Word; AText: AnsiString; AIntVal:longint; yylineno: longint; yycolno: word);			     
BEGIN
	IF ATokenList <> nil THEN AddToken(ATokenList^.Next, ATokenID, AText, AIntVal, yylineno, yycolno)
	ELSE
	BEGIN
		New(ATokenList);
		ATokenList^.TokenID := ATokenID;
		ATokenList^.Text := AText;
		ATokenList^.IntVal := AIntVal;
		ATokenList^.lineno := yylineno;
		AtokenList^.colno := yycolno - 1;
		ATokenList^.Next := nil;
	END  
END;


END.			     