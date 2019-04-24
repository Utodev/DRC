//This is the Lex (TPLex) lex file, the tokenizer

// ————————————————————————————————————————————————————————————————————————————————————————————————————————
// This comment intentionally includes some characters to get your attraction if you open the  file with
//  some encoding that is not the original ISO-8859-1. You will see a lot of trash below instead 
// of several accented N, (n-tilde) characters) if that happens.
// ————————————————————————————————————————————————————————————————————————————————————————————————————————

%{



%}
%%
\/CTL			BEGIN  AddToken(TokenList, T_SECTION_CTL, yytext, MaxLongInt, yylineno, yycolno);  END;
\/STX			BEGIN  AddToken(TokenList, T_SECTION_STX, yytext, MaxLongInt, yylineno, yycolno);  END;
\/CON			BEGIN  AddToken(TokenList, T_SECTION_CON, yytext, MaxLongInt, yylineno, yycolno); END;
\/MTX			BEGIN  AddToken(TokenList, T_SECTION_MTX, yytext, MaxLongInt, yylineno, yycolno); END;
\/LTX			BEGIN  AddToken(TokenList, T_SECTION_LTX, yytext, MaxLongInt, yylineno, yycolno); END;
\/OTX			BEGIN  AddToken(TokenList, T_SECTION_OTX, yytext, MaxLongInt, yylineno, yycolno); END;
\/OBJ			BEGIN  AddToken(TokenList, T_SECTION_OBJ, yytext, MaxLongInt, yylineno, yycolno); END;
\/VOC			BEGIN  AddToken(TokenList, T_SECTION_VOC, yytext, MaxLongInt, yylineno, yycolno); END;
\/PRO			BEGIN  AddToken(TokenList, T_SECTION_PRO, yytext, MaxLongInt, yylineno, yycolno); END;
\/END			BEGIN  AddToken(TokenList, T_SECTION_END, yytext, MaxLongInt, yylineno, yycolno); END;
#define			BEGIN  AddToken(TokenList, T_DEFINE, yytext, MaxLongInt, yylineno, yycolno); END;
#ifdef			BEGIN  AddToken(TokenList, T_IFDEF, yytext, MaxLongInt, yylineno, yycolno); END;
#if 			BEGIN  AddToken(TokenList, T_IFDEF, yytext, MaxLongInt, yylineno, yycolno); END;
#ifndef			BEGIN  AddToken(TokenList, T_IFNDEF, yytext, MaxLongInt, yylineno, yycolno); END;
#endif			BEGIN  AddToken(TokenList, T_ENDIF, yytext, MaxLongInt, yylineno, yycolno); END;
#else           BEGIN  AddToken(TokenList, T_ELSE, yytext, MaxLongInt, yylineno, yycolno); END;
#echo           BEGIN  AddToken(TokenList, T_ECHO, yytext, MaxLongInt, yylineno, yycolno); END;
#userptr        BEGIN  AddToken(TokenList, T_USERPTR, yytext, MaxLongInt, yylineno, yycolno); END;
#int            BEGIN  AddToken(TokenList, T_INT, yytext, MaxLongInt, yylineno, yycolno); END;
#sfx            BEGIN  AddToken(TokenList, T_SFX, yytext, MaxLongInt, yylineno, yycolno); END;
#hex            BEGIN  AddToken(TokenList, T_HEX, yytext, MaxLongInt, yylineno, yycolno); END;
#debug          BEGIN  AddToken(TokenList, T_DEBUG, yytext, MaxLongInt, yylineno, yycolno); END;
#db				BEGIN  AddToken(TokenList, T_DB, yytext, MaxLongInt, yylineno, yycolno); END;
#defb   		BEGIN  AddToken(TokenList, T_DB, yytext, MaxLongInt, yylineno, yycolno); END;
#dw             BEGIN  AddToken(TokenList, T_DW, yytext, MaxLongInt, yylineno, yycolno); END;
#defw           BEGIN  AddToken(TokenList, T_DW, yytext, MaxLongInt, yylineno, yycolno); END;
#extern			BEGIN  AddToken(TokenList, T_EXTERN, yytext, MaxLongInt, yylineno, yycolno); END;
#incbin			BEGIN  AddToken(TokenList, T_INCBIN, yytext, MaxLongInt, yylineno, yycolno); END;
#classic        BEGIN  AddToken(TokenList, T_CLASSIC, yytext, MaxLongInt, yylineno, yycolno); END;
\".*\"			BEGIN  AddToken(TokenList, T_STRING, yytext, MaxLongInt, yylineno, yycolno); END;
\'.*\''			BEGIN  AddToken(TokenList, T_STRING, UTF8Encode(yytext), MaxLongInt, yylineno, yycolno); END;
_				BEGIN  AddToken(TokenList, T_UNDERSCORE, yytext, MaxLongInt, yylineno, yycolno); END;
\/[0-9]+		BEGIN  AddToken(TokenList, T_LIST_ENTRY, yytext, StrToInt(Copy(yytext,2,Length(yytext)-1)), yylineno, yycolno); END;
;.*\n 			BEGIN  END;
-?[0-9]+        BEGIN  AddToken(TokenList, T_NUMBER, yytext, StrToInt(yytext), yylineno, yycolno); END;
[_,a-zA-Z0-9·ÈÌÛ˙¸¡…Õ”⁄‹Ò—Á«]+ BEGIN  AddToken(TokenList, T_IDENTIFIER, yytext, MaxLongInt, yylineno, yycolno); END;
\@				BEGIN  AddToken(TokenList, T_INDIRECT, yytext, MaxLongInt, yylineno, yycolno); END;
[ \t\n]         BEGIN  END;
.               BEGIN yyerror('Unexpected character'); Halt(1); END;
%%
