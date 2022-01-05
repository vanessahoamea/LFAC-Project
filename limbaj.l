%{
  #include <stdio.h>
  #include "limbaj.tab.h"
%}

%option noyywrap

%%
"int"|"float"|"bool"|"char"|"string" {yylval.dataType=strdup(yytext); return TYPE;}
"main" {return MAIN;}
"if" {return IF;}
"else" {return ELSE;}
"while" {return WHILE;}
"for" {return FOR;}
"return" {return RETURN;}
"#DEFINE" {return CONST;}
[0-9]+ {yylval.strVal=strdup(yytext); return INT;}
[0-9]+\.?[0-9]* {yylval.strVal=strdup(yytext); return FLOAT;}
"struct" {yylval.dataType=strdup(yytext); return STRUCT;}
\'[a-zA-Z]\' {yylval.strVal=strdup(yytext); return CHAR;}
\"(\\.|[^"])*\" {yylval.strVal=strdup(yytext); return STRING;}
@[a-zA-Z][_a-zA-Z0-9]*(\.@[a-zA-Z][_a-zA-Z0-9]*)? {yylval.strVal=strdup(yytext); return ID;}
@[a-zA-Z][_a-zA-Z0-9]*\[[0-9]+\] {yylval.strVal=strdup(yytext); return ARRAY;}
"+" {return PLUS;}
"-" {return MINUS;}
"*" {return MUL;}
"/" {return DIV;}
":=" {return IS;}
"=="|"!="|"<"|"<="|">"|">=" {return COMP;}
"&"|"|" {return BOOL_OP;}
"!" {return NOT;}
"/*"[^*]*"*/" {return COMMENT;}
"begin" {return BGIN;}
"end" {return END;}
"Print" {return PRINT;}
[ \t] ;
\n|\r\n {yylineno++;}
. {return yytext[0];}
%%
