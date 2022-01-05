%{
  #include "functions.h"
  #include "AST.h"
  extern FILE* yyin;
  extern char* yytext;
  extern int yylineno;
  int yylex();
  void yyerror(const char *s);
%}

/* pentru erori detaliate */
%define parse.lac full
%define parse.error verbose

%union
{
  char* strVal;
  char* dataType;
}

/* tipuri de date */
%token<strVal> INT
%token<strVal> FLOAT
%token<strVal> CHAR
%token<strVal> STRING
/* variabile */
%token<strVal> ID
%token<strVal> ARRAY
/* alte tokenuri */
%token<dataType> TYPE
%token<dataType> STRUCT
%token<strVal> PLUS MINUS MUL DIV
%token IF ELSE WHILE FOR RETURN CONST MAIN
%token COMMENT BGIN END PRINT
%token IS COMP BOOL_OP NOT
/* tipuri pentru neterminali */
%type<strVal> NR_VAL
%type<strVal> CH_VAL
%type<strVal> VAR_VAL

%type<strVal> ARG_LIST
%type<strVal> ARG_LIST_CALL

%type<strVal> STRUCT_BODY
%type<strVal> DECL

%type<strVal> PRINT_FUN
%type<strVal> EXPR
/* precendenta */
%left PLUS MINUS
%left MUL DIV
%left BOOL_OP NOT

%start progr

%%
progr: HEADER DECL2 MAIN BODY {printf("\nProgram corect sintactic.\n\n");}
     ;

NR_VAL: INT
      | FLOAT
      | MINUS INT {sprintf($2, "-%d", atoi($2)); $$=strdup($2);}
      | MINUS FLOAT {sprintf($2, "-%f", atof($2)); $$=strdup($2);}
      ;

CH_VAL: CHAR
      | STRING
      ;

VAR_VAL: ID
       | ARRAY
       ;

RETURN_CALL: RETURN NR_VAL
           | RETURN CH_VAL
           | RETURN VAR_VAL
           ;

HEADER: %empty
      | HEADER CONST_DECL
      | HEADER DECL ';'
      ;

DECL2: FUNCT ';'
     | DECL2 FUNCT ';'
     | STRUCT_TYPE ';'
     | DECL2 STRUCT_TYPE ';'
     | COMMENT
     | DECL2 COMMENT
     ;

BLOCK: BGIN BODY END
    ;

BODY: F_DECL ';'
    | BODY F_DECL ';'
    | ASSIGN ';'
    | BODY ASSIGN ';'
    | FUNCT_CALL ';'
    | BODY FUNCT_CALL ';'
    | IF_LOOP ';'
    | BODY IF_LOOP ';'
    | WHILE_LOOP ';'
    | BODY WHILE_LOOP ';'
    | FOR_LOOP ';'
    | BODY FOR_LOOP ';'
    | COMMENT
    | BODY COMMENT
    | PRINT_FUN ';'
    | BODY PRINT_FUN ';'
    | RETURN_CALL ';'
    | BODY RETURN_CALL ';'
    ;

/* valori constante */
CONST_DECL: CONST ID NR_VAL {if(existsVar($2)==-1)
                               addVar(getType($3), $2, $3, "global", 1);
                             else {printf("EROARE: variabila %s este deja declarata.\n", $2); exit(0);}}
          | CONST ID CH_VAL {if(existsVar($2)==-1)
                               addVar(getType($3), $2, $3, "global", 1);
                             else {printf("EROARE: variabila %s este deja declarata.\n", $2); exit(0);}}
          ;

/* valori neconstante */
DECL: TYPE VAR_VAL {if(existsVar($2)==-1)
                      addVar($1, $2, NULL, "global", 0);
                    else {printf("EROARE: variabila %s este deja declarata.\n", $2); exit(0);}}
    | TYPE VAR_VAL IS CH_VAL {if(existsVar($2)==-1)
                                {if(addVar($1, $2, $4, "global", 0)==0)
                                   {printf("EROARE: valoarea lui %s este incompatibila cu tipul sau.\n", $2);
                                    exit(0);}}
                              else {printf("EROARE: variabila %s este deja declarata.\n", $2); exit(0);}}
    | TYPE VAR_VAL IS EXPR {char *infix[50], *postfix[50], result[10];
                            int n=infixExpression($4, infix);
                            int m=infixToPostfix(infix, postfix, n);
                            buildAST(postfix, m);
                            struct node *root=pop_stack();
                            sprintf(result, "%d", evalAST(root));
                            strcpy($4, result);
                            if(existsVar($2)==-1)
                               {if(addVar($1, $2, $4, "global", 0)==0)
                                  {printf("EROARE: valoarea lui %s este incompatibila cu tipul sau.\n", $2);
                                   exit(0);}}
                            else {printf("EROARE: variabila %s este deja declarata.\n", $2); exit(0);}}
    /* custom type */
    | STRUCT ID ID {if(existsStruct($2)==-1)
                      {printf("EROARE: structura %s nu a fost inca declarata.\n", $2); exit(0);}
                    else
                    {if(existsVar($3)==-1)
                        addDeclStack($2, $3, "global");
                     else {printf("EROARE: variabila %s este deja declarata.\n", $3); exit(0);}
                    }}
    ;

ASSIGN: VAR_VAL IS CH_VAL {if(existsVar($1)==-1)
                             {printf("EROARE: variabila %s nu a fost inca declarata.\n", $1); exit(0);}
                           else if(assignValue($1, $3)==0)
                              {printf("EROARE: valoarea lui %s este incompatibila cu tipul sau.\n", $1); exit(0);}}
      | VAR_VAL IS EXPR {char *infix[50], *postfix[50], result[10];
                         int n=infixExpression($3, infix);
                         int m=infixToPostfix(infix, postfix, n);
                         buildAST(postfix, m);
                         struct node *root=pop_stack();
                         sprintf(result, "%d", evalAST(root));
                         strcpy($3, result);
                         if(existsVar($1)==-1)
                            {printf("EROARE: variabila %s nu a fost inca declarata.\n", $1); exit(0);}
                         else if(assignValue($1, $3)==0)
                            {printf("EROARE: valoarea lui %s este incompatibila cu tipul sau.\n", $1); exit(0);}}
      ;

/* functii */
FUNCT: TYPE ID '(' ')' {if(existsFun($1, $2, NULL)==-1)
                          addFun($1, $2, NULL);
                        else {printf("EROARE: functia %s este deja declarata.\n", $2); exit(0);}}
     | TYPE ID '(' ARG_LIST ')' {if(existsFun($1, $2, $4)==-1)
                                   addFun($1, $2, $4);
                                 else {printf("EROARE: functia %s este deja declarata.\n", $2); exit(0);}}
     | TYPE ID '(' ')' F_BLOCK {if(existsFun($1, $2, NULL)==-1)
                                  addFun($1, $2, NULL);
                                else {printf("EROARE: functia %s este deja declarata.\n", $2); exit(0);}}
     | TYPE ID '(' ARG_LIST ')' F_BLOCK {if(existsFun($1, $2, $4)==-1)
                                           addFun($1, $2, $4);
                                         else {printf("EROARE: functia %s este deja declarata.\n", $2); exit(0);}}
     ;

F_BLOCK: BGIN F_BODY END
       ;

F_BODY: F_DECL ';'
      | F_BODY F_DECL ';'
      | ASSIGN ';'
      | F_BODY ASSIGN ';'
      | IF_LOOP ';'
      | F_BODY IF_LOOP ';'
      | WHILE_LOOP ';'
      | F_BODY WHILE_LOOP ';'
      | FOR_LOOP ';'
      | F_BODY FOR_LOOP ';'
      | COMMENT
      | F_BODY COMMENT
      | PRINT_FUN ';'
      | F_BODY PRINT_FUN ';'
      | RETURN_CALL ';'
      | F_BODY RETURN_CALL ';'
      ;

F_DECL: TYPE VAR_VAL {if(existsVar($2)==-1)
                        addVar($1, $2, NULL, "local", 0);
                      else {printf("EROARE: variabila %s este deja declarata.\n", $2); exit(0);}}
      | TYPE VAR_VAL IS CH_VAL {if(existsVar($2)==-1)
                                  {if(addVar($1, $2, $4, "local", 0)==0)
                                     {printf("EROARE: valoarea lui %s este incompatibila cu tipul sau.\n", $2);
                                      exit(0);}}
                                else {printf("EROARE: variabila %s este deja declarata.\n", $2); exit(0);}}
      | TYPE VAR_VAL IS EXPR {char *infix[50], *postfix[50], result[10];
                              int n=infixExpression($4, infix);
                              int m=infixToPostfix(infix, postfix, n);
                              buildAST(postfix, m);
                              struct node *root=pop_stack();
                              sprintf(result, "%d", evalAST(root));
                              strcpy($4, result);
                              if(existsVar($2)==-1)
                                 {if(addVar($1, $2, $4, "local", 0)==0)
                                    {printf("EROARE: valoarea lui %s este incompatibila cu tipul sau.\n", $2);
                                     exit(0);}}
                              else {printf("EROARE: variabila %s este deja declarata.\n", $2); exit(0);}}
      /* custom type */
      | STRUCT ID ID {if(existsStruct($2)==-1)
                        {printf("EROARE: structura %s nu a fost inca declarata.\n", $2); exit(0);}
                      else
                      {if(existsVar($3)==-1)
                          addDeclStack($2, $3, "local");
                       else {printf("EROARE: variabila %s este deja declarata.\n", $3); exit(0);}
                      }}
      ;

ARG_LIST: TYPE ID {strcpy($$, $1);}
        | ARG_LIST ',' TYPE ID {strcat($$, ", "); strcat($$, $3);}
        ;

FUNCT_CALL: ID '(' ')' {if(existsFun2($1, "-")==-1)
                          {printf("EROARE: functia %s nu a fost inca declarata.\n", $1); exit(0);}}
          | ID '(' ARG_LIST_CALL ')' {if(existsFun2($1, $3)==-1)
                                        {printf("EROARE: functia %s nu a fost inca declarata.\n", $1); exit(0);}}
          ;

ARG_LIST_CALL: VAR_VAL {strcpy($$, $1);}
             | NR_VAL {strcpy($$, $1);}
             | CH_VAL {strcpy($$, $1);}
             | ARG_LIST_CALL ',' VAR_VAL {strcat($$, ","); strcat($$, $3);}
             | ARG_LIST_CALL ',' NR_VAL {strcat($$, ","); strcat($$, $3);}
             | ARG_LIST_CALL ',' CH_VAL {strcat($$, ","); strcat($$, $3);}
             ;

/* struct */
STRUCT_TYPE: STRUCT ID BGIN STRUCT_BODY END {if(existsStruct($2)==-1)
                                               addStruct($2, $4);
                                             else
                                                {printf("EROARE: structura %s este deja declarata.\n", $2); exit(0);}}
           ;

STRUCT_BODY: TYPE ID ';' {sprintf($$, "%s %s", $1, $2);}
           | TYPE ID '(' ')' ';' {sprintf($$, "%s %s", $1, $2);}
           | TYPE ID '(' ')' F_BLOCK ';' {sprintf($$, "%s %s", $1, $2);}
           | TYPE ID '(' ARG_LIST ')' ';' {sprintf($$, "%s %s(%s)", $1, $2, $4);}
           | TYPE ID '(' ARG_LIST ')' F_BLOCK ';' {sprintf($$, "%s %s(%s)", $1, $2, $4);}
           | STRUCT_BODY TYPE ID ';' {strcat($$, "; "); strcat($$, $2); strcat($$, " "); strcat($$, $3);}
           | STRUCT_BODY TYPE ID '(' ')' ';' {strcat($$, "; "); strcat($$, $2); strcat($$, " "); strcat($$, $3);
                                              strcat($$, "("); strcat($$, ")");}
           | STRUCT_BODY TYPE ID '(' ')' F_BLOCK ';' {strcat($$, "; "); strcat($$, $2); strcat($$, " ");
                                                      strcat($$, $3); strcat($$, "("); strcat($$, ")");}
           | STRUCT_BODY TYPE ID '(' ARG_LIST ')' ';' {strcat($$, "; "); strcat($$, $2); strcat($$, " ");
                                                       strcat($$, $3); strcat($$, "("); strcat($$, $5);
                                                       strcat($$, ")");}
           | STRUCT_BODY TYPE ID '(' ARG_LIST ')' F_BLOCK ';' {strcat($$, "; "); strcat($$, $2); strcat($$, " ");
                                                               strcat($$, $3); strcat($$, "("); strcat($$, $5);
                                                               strcat($$, ")");}
           ;

/* control statements */
IF_LOOP: IF '(' CONDITION ')' BLOCK
       | IF '(' CONDITION ')' BLOCK ELSE BLOCK
       ;

WHILE_LOOP: WHILE '(' CONDITION ')' BLOCK
          ;

FOR_LOOP: FOR '(' ASSIGN ';' CONDITION ';' ASSIGN ')' BLOCK
        ;

CONDITION: '(' CONDITION ')'
         | CONDITION BOOL_OP CONDITION
         | NOT CONDITION
         | EXPR COMP EXPR
         ;

/* print */
PRINT_FUN: PRINT '(' STRING ',' EXPR ')' {char *infix[50], *postfix[50], result[10];
                                          int n=infixExpression($5, infix);
                                          int m=infixToPostfix(infix, postfix, n);
                                          buildAST(postfix, m);
                                          struct node *root=pop_stack();
                                          sprintf(result, "%d", evalAST(root));
                                          strcpy($3, $3+1); $3[strlen($3)-1]='\0';
                                          printf("%s %s\n", $3, result);}
         | PRINT '(' VAR_VAL ',' EXPR ')' {if(existsVar($3)==-1)
                                             {printf("EROARE: variabila %s nu a fost inca declarata.\n", $3);
                                              exit(0);}
                                           else if(strcmp(vars[existsVar($3)].type, "string")!=0)
                                              {printf("EROARE: variabila %s nu e de tip string.\n", $3); exit(0);}
                                           else
                                           {
                                             char *infix[50], *postfix[50], result[10];
                                             int n=infixExpression($5, infix);
                                             int m=infixToPostfix(infix, postfix, n);
                                             buildAST(postfix, m);
                                             struct node *root=pop_stack();
                                             sprintf(result, "%d", evalAST(root));
                                             strcpy($3, vars[existsVar($3)].value);
                                             strcpy($3, $3+1); $3[strlen($3)-1]='\0';
                                             printf("%s %s\n", $3, result);
                                           }}
         ;

EXPR: NR_VAL
    | VAR_VAL {if(existsVar($1)==-1)
                 {printf("EROARE: variabila %s nu a fost inca declarata.\n", $1); exit(0);}
               if(strcmp(vars[existsVar($1)].type, "string")==0 || strcmp(vars[existsVar($1)].type, "char")==0)
                  {printf("EROARE: expresiile nu pot contine char-uri sau string-uri.\n"); exit(0);}}
    | FUNCT_CALL {strcpy($$, "0");}
    | '(' EXPR ')' {sprintf($$, "( %s )", $2);}
    | EXPR PLUS EXPR {sprintf($$, "%s + %s", $1, $3);}
    | EXPR MINUS EXPR {sprintf($$, "%s - %s", $1, $3);}
    | EXPR MUL EXPR {sprintf($$, "%s * %s", $1, $3);}
    | EXPR DIV EXPR {sprintf($$, "%s / %s", $1, $3);}
    ;
%%

void yyerror(const char* s)
{
  printf("EROARE: %s la linia %d\n", s, yylineno);
  exit(0);
}

int main(int argc, char** argv)
{
  yyin=fopen(argv[1], "r");
  yyparse();

  //golim continutul stivelor
  FILE *file=fopen("vars_stack.txt", "w"); fclose(file);
  file=fopen("funs_stack.txt", "w"); fclose(file);

  FILE *symbols=fopen("symbols.txt", "w");
  fprintf(symbols, "Lista variabilelor folosite:\n");
  for(int i=0;i<nrVars;i++)
  {
    if(vars[i].isConst==1)
    {
      fprintf(symbols, "Tip: const %s | Nume: %s | Valoare: %s | Scope: %s\n", vars[i].type, vars[i].name,
      vars[i].value, vars[i].scope);
    }
    else
    {
      fprintf(symbols, "Tip: %s | Nume: %s | Valoare: %s | Scope: %s\n", vars[i].type,
      vars[i].name, vars[i].value, vars[i].scope);
    }
  }
  fprintf(symbols, "-------------------------------------------------------\nLista functiilor folosite:\n");
  for(int i=0;i<nrFuns;i++)
    fprintf(symbols, "Tip: %s | Nume: %s | Argumente: %s\n", funs[i].type, funs[i].name, funs[i].args);
  fprintf(symbols, "-------------------------------------------------------\nLista structorilor folosite:\n");
  for(int i=0;i<nrStructs;i++)
    fprintf(symbols, "Nume: %s | Elemente: %s\n", structs[i].name, structs[i].vars);
  fclose(symbols);
}
