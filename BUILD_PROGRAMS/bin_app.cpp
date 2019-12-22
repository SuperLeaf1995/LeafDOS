// bin_app.cpp
// appends binary to somewhere

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FILE *from;
FILE *to;

size_t i;
size_t fileSize;
unsigned char *buf;

int shutUpMode;

int main(int argc, char* argv[]) {
	if(argc < 2) {
		printf("No engough arguments (%u)\n",argc);
		return -1;
	}
	from = fopen(argv[1],"rb"); //File from
	if(!from) {
		printf("File %s not found\n",argv[1]);
		return -2;
	}
	to = fopen(argv[2],"ab"); //File to
	if(!to) {
		printf("File %s not found\n",argv[2]);
		return -3;
	}

	//A third ARGV?
	if(argv[3] != NULL
		&& strlen(argv[3]) != 0) {
		if(strcmp("--shut-up-mode",argv[3]) == 0
			|| strcmp("-stfu",argv[3]) == 0) {
			shutUpMode = 1;
		} else {
			shutUpMode = 0;
		}
	}

	if(shutUpMode != 1) {
		printf("bin_app v0.1\n");
		printf("made by Jesus Antonio Diaz, aka Superleaf1995\n");
	}

	//Arguments 1 and 2 are always file "from" and "to" respectively
	//Other arguments indicate stuff

	//Copy all FROM file to TO file, append at end
	i = 0; //Infinite loop until EOF is reached
	while(fgetc(from) != EOF) { //Get file size
		i++;
	}
	fileSize = i;

	buf = (unsigned char *)malloc(fileSize+1);
	if(buf == NULL) {
		printf("Memory allocation error. Could not allocate %u bytes\n",fileSize+1);
		return -5;
	}

	fseek(from,0,SEEK_SET);

	fread(buf,sizeof(unsigned char),fileSize,from); //Copy
	fwrite(buf,sizeof(unsigned char),fileSize,to); //Paste

	if(shutUpMode != 1) {
		printf("Finished, copied and appended %u bytes (%4.2f KB) from %s to %s\n",i,(float)(i/1000),argv[1],argv[2]);
	} else {
		printf("Copied %u bytes\n",i);
	}

	fclose(from); //Finally finish
	fclose(to);
	free(buf);
	return 0;
}
