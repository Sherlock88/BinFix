#include <stdio.h>
#include <stdlib.h>


int add_constant(int var_to_be_added_to)
{
	// FIXME: var_added = 40 + var_to_be_added_to
	return (30 + var_to_be_added_to);
}


int main(int argc, char* argv[])
{
	int var_to_be_added_to = atoi(argv[1]);
	int var_added = add_constant(var_to_be_added_to);
	printf("%d\n", var_added);
	return var_added;
}