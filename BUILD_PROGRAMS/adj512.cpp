// adj512.cpp
// Adjusts files to 512 bytes or multiples of 512, because yes
// Used for LeafDOS

#include <stdio.h>
#include <stdlib.h>

FILE *fp;
size_t i; //iterator
size_t fileSize;
size_t stuffToAppend;

char zero = '\0';

int main(int argc, char* argv[]) {
	//adj512
	//get file
	if(argc < 1) {
		printf("Insufficient arguments\n");
		return 1;
	}
	fp = fopen(argv[1],"rb"); //open file provided in argument
	if(!fp) { //error
		printf("File err\n");
		return 2;
	}
	//this will be the perfect opportunity for getting the filesize
	i = 0;
	while(fgetc(fp) != EOF) {
		i++; //add...
	}
	//now that we have the filesize, we put it in its special variable
	fileSize = i;
	printf("%s has %u bytes\t",argv[1],fileSize);
	fclose(fp); //close file and reopen it again
	fp = fopen(argv[1],"ab"); //this time for appending
	if(!fp) {
		printf("File append err\n");
		return 3;
	}
	//how many stuff we should append?
	if(fileSize == 0) { //error on filesize
		printf("File size err\n");
		return 4;
	} else if(fileSize%512 == 0) {
		printf("File already adjusts to 512 boundary\n");
		return 5;
	}

	//calculate how much stuff to append
	stuffToAppend = 512-(fileSize%512);
	
	printf("%u bytes to be appended\n",stuffToAppend);

	for(i = stuffToAppend; i > 0; i--) {
		fwrite(&zero,sizeof(char),1,fp);
	}

	fclose(fp); //we finished, time to exit
	return 0;
}

