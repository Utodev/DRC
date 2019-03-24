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

IMPLEMENTATION

PROCEDURE AddToken(VAR ATokenList:TPTokenList; ATokenID: Word; AText: AnsiString; AIntVal:longint; yylineno: longint; yycolno: word);			     
BEGIN
	IF ATokenList <> nil THEN AddToken(ATokenList^.Next, ATokenID, AText, AIntVal, yylineno, yycolno)
	ELSE
	BEGIN
		//WriteLn('Adding: ', AText);
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