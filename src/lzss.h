/*
 * lzss.h
 *
 *  Created on: 6 Mar 2015
 *      Author: yarenty
 */

#ifndef LZSS_H_
#define LZSS_H_

class LZSS {

public:
	void decode(FILE *infile, FILE *outfile);
	void encode(FILE *infile, FILE *outfile);
};

#endif /* LZSS_H_ */
