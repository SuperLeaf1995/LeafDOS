// fill.cpp
// fills with zeros file until reached the desired size

#include <stdio.h>
#include <stdlib.h>

signed long long fileSize = 0;
signed long long i = 0;
signed long long toAppend = 0;

FILE *fp;

int main(int argc, char* argv[]) {
	if(argc < 2) {
		printf("error\n");
		return 1;
	}

	fp = fopen(argv[1],"rb"); //read mode
	if(!fp) {
		printf("file read error\n");
		return 2;
	}

	while(fgetc(fp) != EOF) {
		fileSize++; //filesize
	}

	fclose(fp);
	fp = fopen(argv[1],"ab"); //append mode
	if(!fp) {
		printf("file append error\n");
		return 7;
	}

	toAppend = atol(argv[2])-fileSize; //get desired filesize and pad it

	if(toAppend < 0) {
		printf("[%s]\t",__TIME__);
		printf("nothing to append\n",toAppend);
		return 4;
	}

	printf("[%s]\t",__TIME__);
	printf("appending %ul bytes\n",toAppend);

	for(i = 0; i < toAppend; i++) {
		fputc(0,fp); //put zeroes
	}

	printf("[%s]\t",__TIME__);
	printf("appended %ul bytes\n",toAppend);

	fclose(fp);
	return 0;
}

