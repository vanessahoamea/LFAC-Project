// conversie infix->postfix
int infixExpression(char expr[50], char *tokens[50])
{
  int nrtok=-1;
  char *p=strtok(expr, " ");
  while(p)
  {
    tokens[++nrtok]=p;
    p=strtok(NULL, " ");
  }
  return nrtok;
}

char *stack[50], *tokens[50], *result[50];
int top=-1;

void push(char *item)
{
  if(top>50)
	{
		printf("EROARE: expresia este prea lunga.\n");
    exit(0);
	}
	else stack[++top]=item;
}

char* pop()
{
  char *item;
  if(top<0)
  {
    printf("EROARE: stiva goala.\n");
    exit(0);
  }
  else
  {
    item=stack[top];
    top--;
  }
  return item;
}

int precedence(char *symbol)
{
  if(strcmp(symbol, "*")==0 || strcmp(symbol, "/")==0)
		return 2;
	if(strcmp(symbol, "+")==0 || strcmp(symbol, "-")==0)
		return 1;
	return 0;
}

int isOperator(char *item)
{
  if(strcmp(item, "+")==0 || strcmp(item, "-")==0 || strcmp(item, "*")==0 || strcmp(item, "/")==0)
      return 1;
  return 0;
}

int infixToPostfix(char *infix[200], char *postfix[200], int nrtok)
{
  int i=0, j=0;
  char *x, *item=infix[0];

  push("(");
  infix[nrtok+1]=")";

  while(i<nrtok+2)
  {
    if(strcmp(item, "(")==0)
      push(item);
    else if(strcmp(item, ")")==0)
    {
      x=pop();
      while(strcmp(x, "(")!=0)
      {
          postfix[j++]=x;
          x=pop();
      }
    }
    else if(isOperator(item)==1)
    {
      x=pop();
      while(isOperator(x)==1 && precedence(x)>=precedence(item))
      {
          postfix[j++]=x;
          x=pop();
      }
      push(x);
      push(item);
    }
    else postfix[j++]=item;

    i++;
    item=infix[i];
  }

  return j-1;
}

//arbore
struct node
{
  char *value, *type;
  struct node *right, *left;
  struct node *next; //urmatorul din stiva
} *head=NULL; //capul stivei

struct node* add_node(char *value)
{
  struct node *n=(struct node*)malloc(sizeof(struct node));
  n->value=value;
  n->left=NULL;
  n->right=NULL;
  if(strcmp(value, "\\")==0)
    n->type="OTHER";
  else if(value[0]=='@')
  {
    int is_array=0;
    if(value[strlen(value)-1]==']')
    {
      is_array=1;
      n->type="ARRAY_ELEM";
    }
    if(is_array==0)
      n->type="IDENTIFIER";
  }
  else if(strcmp(value, "+")==0 || strcmp(value, "-")==0 || strcmp(value, "*")==0 || strcmp(value, "/")==0)
    n->type="OP";
  else n->type="NUMBER";
  return n;
}

void push_stack(struct node* n)
{
  if(head!=NULL)
    n->next=head;
  head=n;
}

struct node* pop_stack()
{
  struct node *top=head;
  head=head->next;
  return top;
}

void printPreorder(struct node *root, int level) //functie pentru a vizualiza arborele AST
{
  for(int i=1;i<=level;i++)
    printf("   ");
  if(root==NULL)
    printf(".\n");
  else
  {
    printf("%s\n", root->value);
    printPreorder(root->left, level+1);
    printPreorder(root->right, level+1);
  }
}

void buildAST(char *expr[], int size)
{
  struct node *x, *y, *z;
  for(int i=0;i<=size;i++)
    if(isOperator(expr[i])==1)
    {
      z=add_node(expr[i]);
      x=pop_stack();
      y=pop_stack();
      z->left=y;
      z->right=x;
      push_stack(z);
    }
    else
    {
      z=add_node(expr[i]);
      push_stack(z);
    }
}

int evalAST(struct node *root)
{
  if(strcmp(root->type, "OP")==0)
  {
    if(strcmp(root->value, "+")==0)
        return evalAST(root->left)+evalAST(root->right);
    if(strcmp(root->value, "-")==0)
        return evalAST(root->left)-evalAST(root->right);
    if(strcmp(root->value, "*")==0)
        return evalAST(root->left)*evalAST(root->right);
    if(strcmp(root->value, "/")==0)
        return evalAST(root->left)/evalAST(root->right);
  }
  else if(strcmp(root->type, "NUMBER")==0)
    return atoi(root->value);
  else if(strcmp(root->type, "IDENTIFIER")==0 || strcmp(root->type, "ARRAY_ELEM")==0)
  {
    char aux[20]; strcpy(aux, vars[existsVar(root->value)].value); convertToInt(aux);
    return atoi(aux);
  }
  else return 0;
}
