#include <stdio.h>

int main()
{
	int c;
	printf("Enter number: ");
	scanf("%d", &c);
	if(c)
		printf("Non-zero\n");
	else
		printf("Zero\n");
	return 0;
}