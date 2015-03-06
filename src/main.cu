/* *
 * Copyright 1993-2012 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 */
#include <stdio.h>
#include <stdlib.h>
#include "lzss.h"

#include "lzss.cpp"
static const int WORK_SIZE = 256;
FILE *infile, *outfile;

/**
 * This macro checks return value of the CUDA runtime call and exits
 * the application if the call failed.
 */
#define CUDA_CHECK_RETURN(value) {											\
	cudaError_t _m_cudaStat = value;										\
	if (_m_cudaStat != cudaSuccess) {										\
		fprintf(stderr, "Error %s at line %d in file %s\n",					\
				cudaGetErrorString(_m_cudaStat), __LINE__, __FILE__);		\
		exit(1);															\
	} }

__host__ __device__ unsigned int bitreverse(unsigned int number) {
	number = ((0xf0f0f0f0 & number) >> 4) | ((0x0f0f0f0f & number) << 4);
	number = ((0xcccccccc & number) >> 2) | ((0x33333333 & number) << 2);
	number = ((0xaaaaaaaa & number) >> 1) | ((0x55555555 & number) << 1);
	return number;
}

/**
 * CUDA kernel function that reverses the order of bits in each element of the array.
 */
__global__ void bitreverse(void *data) {
	unsigned int *idata = (unsigned int*) data;
	idata[threadIdx.x] = bitreverse(idata[threadIdx.x]);
}

/**
 * Host function that prepares data array and passes it to the CUDA kernel.
 */
int main_cuda(void) {
	void *d = NULL;
	int i;
	unsigned int idata[WORK_SIZE], odata[WORK_SIZE];

	for (i = 0; i < WORK_SIZE; i++)
		idata[i] = (unsigned int) i;

	CUDA_CHECK_RETURN(cudaMalloc((void** ) &d, sizeof(int) * WORK_SIZE));
	CUDA_CHECK_RETURN(
			cudaMemcpy(d, idata, sizeof(int) * WORK_SIZE,
					cudaMemcpyHostToDevice));

	bitreverse<<<1, WORK_SIZE, WORK_SIZE * sizeof(int)>>>(d);

	CUDA_CHECK_RETURN(cudaThreadSynchronize());	// Wait for the GPU launched work to complete
	CUDA_CHECK_RETURN(cudaGetLastError());
	CUDA_CHECK_RETURN(
			cudaMemcpy(odata, d, sizeof(int) * WORK_SIZE,
					cudaMemcpyDeviceToHost));

	for (i = 0; i < WORK_SIZE; i++)
		printf("Input value: %u, device output: %u, host output: %u\n",
				idata[i], odata[i], bitreverse(idata[i]));

	CUDA_CHECK_RETURN(cudaFree((void* ) d));
	CUDA_CHECK_RETURN(cudaDeviceReset());

	return 0;
}

/*
 * @TODO:
 int main(int argc, char *argv[])
 {
 char  *s;

 if (argc != 4) {
 printf("'lzss e file1 file2' encodes file1 into file2.\n"
 "'lzss d file2 file1' decodes file2 into file1.\n");
 return EXIT_FAILURE;
 }
 if ((s = argv[1], s[1] || strpbrk(s, "DEde") == NULL)
 || (s = argv[2], (infile  = fopen(s, "rb")) == NULL)
 || (s = argv[3], (outfile = fopen(s, "wb")) == NULL)) {
 printf("??? %s\n", s);  return EXIT_FAILURE;
 }
 if (toupper(*argv[1]) == 'E') Encode();  else Decode();
 fclose(infile);  fclose(outfile);
 return EXIT_SUCCESS;
 }
 */

/**
 * MAIN!
 */
int main(int argc, char *argv[]) {
	int enc;
	char *s;
	clock_t time = clock();
	if (argc != 4) {
		printf("Usage: lzss e/d infile outfile\n\te = encode\td =decode\n");
		return 1;
	}

	s = argv[1];
	if (s[1] == 0 && (*s == 'd' || *s == 'D' || *s == 'e' || *s == 'E'))
		enc = (*s == 'e' || *s == 'E');
	else {
		printf("? %s\n", s);
		return 1;
	}
	if ((infile = fopen(argv[2], "rb")) == NULL) {
		printf("? %s\n", argv[2]);
		return 1;
	}
	if ((outfile = fopen(argv[3], "wb")) == NULL) {
		printf("? %s\n", argv[3]);
		return 1;
	}


	DefaultLZSS defaultLZSS;
	//LZSS *lzss = &defaultLZSS;

	if (enc)
		defaultLZSS.encode(infile, outfile);
	else
		defaultLZSS.decode(infile, outfile);
	fclose(infile);
	fclose(outfile);
	printf("time: %.2f \n", (double) (clock() - time) / CLOCKS_PER_SEC);
	return 0;
}

