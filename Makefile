all:
		flex limbaj.l
		bison -v -d limbaj.y
		gcc ./lex.yy.c ./limbaj.tab.c
		./a.out ini.txt
