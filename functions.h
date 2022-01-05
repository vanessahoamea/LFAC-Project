#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

extern int yylineno;

int nrVars=0, nrFuns=0, nrStructs=0;
struct var_data
{
  char *type;
  char *name;
  char *value;
  char *scope;
  bool isConst;
} vars[200];
struct fun_data
{
  char *type;
  char *name;
  char *args;
} funs[200];
struct struct_data
{
  char *name;
  char *vars;
} structs[200];

/* functii pentru variabile */
int existsVar(char *name)
{
  for(int i=0;i<nrVars;i++)
    if(strcmp(vars[i].name, name)==0)
      return i;
  return -1;
}

char* getType(char *variable)
{
  if(variable[0]=='\'')
    return "char";
  if(variable[0]=='"')
    return "string";
  for(int i=0;i<strlen(variable);i++)
    if(variable[i]=='.')
      return "float";
  return "int";
}

void convertToInt(char *value)
{
  if(getType(value)=="float") //floor
  {
    for(int i=0;i<strlen(value);i++)
      if(value[i]=='.')
        value[i]='\0';
  }
  else if(getType(value)=="char") //va lua valoarea codului ASCII
  {
    strcpy(value, value+1);
    value[1]='\0';
    sprintf(value, "%d", value[0]);
  }
}

void convertToFloat(char *value)
{
  if(getType(value)=="int")
    strcat(value, ".0");
  else if(getType(value)=="char")
  {
    strcpy(value, value+1);
    value[1]='\0';
    sprintf(value, "%d.0", value[0]);
  }
}

void convertToChar(char *value)
{
  convertToInt(value);
  int aux=atoi(value);
  value[0]='\''; value[1]=(char)aux; value[2]='\'';
}

void convertValue(char *type, char *value)
{
  if(strcmp(type, "int")==0 && getType(value)!="int")
    convertToInt(value);
  if(strcmp(type, "float")==0 && getType(value)!="float")
    convertToFloat(value);
  if(strcmp(type, "bool")==0)
  {
    if(getType(value)!="int")
      convertToInt(value);
    if(atoi(value)>0)
      strcpy(value, "1");
    else strcpy(value, "0");
  }
  if(strcmp(type, "char")==0 && getType(value)!="char")
    convertToChar(value);
}

int addVar(char *type, char *name, char *value, char *scope, bool isConst)
{
  vars[nrVars].type=type;
  vars[nrVars].name=name;
  vars[nrVars].isConst=isConst;
  vars[nrVars].scope=scope;
  if(value==NULL)
    vars[nrVars].value="NULL";
  else
  {
    //valori string se pot asigna doar variabilelor string
    if(strcmp(type, "string")!=0 && getType(value)=="string" || strcmp(type, "string")==0 && getType(value)!="string")
      return 0;
    convertValue(type, value);
    vars[nrVars].value=value;
  }
  nrVars++;
  return 1;
}

int assignValue(char *name, char *value)
{
  char type[7];
  int pos=existsVar(name);
  strcpy(type, vars[pos].type);

  if(vars[pos].isConst==1)
  {
    printf("EROARE: variabila %s este constanta iar valoarea ei nu poate fi modificata.\n", name);
    exit(0);
  }

  //valori string se pot asigna doar variabilelor string
  if(strcmp(type, "string")!=0 && getType(value)=="string" || strcmp(type, "string")==0 && getType(value)!="string")
    return 0;
  convertValue(type, value);
  vars[pos].value=value;
  return 1;
}

/* functii pentru functii */
char* getType2(char *variable)
{
  if(variable[0]=='@')
  {
    int pos=existsVar(variable);
    if(pos==-1)
    {
      printf("EROARE: variabila %s nu a fost inca declarata.\n", variable);
      exit(0);
    }
    strcpy(variable, vars[pos].value);
  }
  return getType(variable);
}

int existsFun(char *type, char *name, char *args)
{
  for(int i=0;i<nrFuns;i++)
    if(strcmp(funs[i].type, type)==0 && strcmp(funs[i].name, name)==0 && strcmp(funs[i].args, args)==0)
      return i;
  return -1;
}

int existsFun2(char *name, char *args)
{
  if(strcmp(args, "-")!=0)
  {
    char aux[100], *token;
    bzero(aux, 100);
    token=strtok(args, ",");
    while(token)
    {
      strcat(aux, getType2(token));
      token=strtok(NULL, ",");
      if(token!=NULL)
        strcat(aux, ", ");
    }
    strcpy(args, aux);
  }
  for(int i=0;i<nrFuns;i++)
    if(strcmp(funs[i].name, name)==0 && strcmp(funs[i].args, args)==0)
      return i;
  return -1;
}

void addFun(char *type, char *name, char *args)
{
  funs[nrFuns].type=type;
  funs[nrFuns].name=name;
  if(args==NULL)
    funs[nrFuns].args="-";
  else funs[nrFuns].args=args;
  nrFuns++;
}

/* functii pentru structuri */
int existsStruct(char *name)
{
  for(int i=0;i<nrStructs;i++)
    if(strcmp(name, structs[i].name)==0)
      return i;
  return -1;
}

void addStruct(char *name, char *vars)
{
  structs[nrStructs].name=name;
  structs[nrStructs].vars=vars;
  nrStructs++;
}

void addStructElts(char *scope)
{
  char line[200], vartypes[50][10], varnames[50][50], funtypes[50][10], funnames[50][50], argslist[50][100];
  int i=0;
  FILE *vars_file=fopen("vars_stack.txt", "r");
  FILE *funs_file=fopen("funs_stack.txt", "r");
  while(fgets(line, 100, vars_file))
  {
    char *type=strtok(line, " ");
    char *name=strtok(NULL, "\n");
    strcpy(vartypes[i], type);
    strcpy(varnames[i], name);
    i++;
  }
  fclose(vars_file);
  for(int j=0;j<i;j++)
  {
    if(existsVar(varnames[j])==-1)
      addVar(vartypes[j], varnames[j], NULL, scope, 0);
  }

  i=0;
  while(fgets(line, 200, funs_file))
  {
    char *type=strtok(line, " ");
    char *name=strtok(NULL, "(");
    char *args=strtok(NULL, ")");
    strcpy(funtypes[i], type);
    strcpy(funnames[i], name);
    strcpy(argslist[i], args);
    i++;
  }
  fclose(funs_file);
  for(int j=0;j<i;j++)
  {
    if(existsFun(funtypes[j], funnames[j], argslist[j])==-1)
      addFun(funtypes[j], funnames[j], argslist[j]);
  }
}

void addDeclStack(char *name, char *object, char *scope)
{
  int pos=existsStruct(name);
  char elts[50]; strcpy(elts, structs[pos].vars);
  FILE *vars_file=fopen("vars_stack.txt", "a");
  FILE *funs_file=fopen("funs_stack.txt", "a");
  char *token=strtok(elts, ";");
  while(token)
  {
    int space=-1, is_function=0;
    if(token[0]==' ')
      token=token+1;
    for(int i=0;i<strlen(token);i++)
    {
      if(token[i]=='(')
          is_function=1;
      if(token[i]==' ' && space==-1)
          space=i;
    }
    char type[10], aux[30], name[50];
    strcpy(aux, token+space+1);
    token[space]='\0';
    strcpy(type, token);
    sprintf(name, "%s.%s", object, aux);
    if(is_function==0)
    {
      fputs(type, vars_file); fputs(" ", vars_file); fputs(name, vars_file);
      fputs("\n", vars_file);
    }
    else
    {
      fputs(token, funs_file); fputs(" ", funs_file); fputs(name, funs_file);
      fputs("\n", funs_file);
    }
    token=strtok(NULL, ";");
  }
  fclose(vars_file);
  fclose(funs_file);
  addStructElts(scope);
}
