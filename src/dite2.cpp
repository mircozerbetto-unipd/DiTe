/***********************************************************************************
 * Dite 2 v1.0 - Program to evaluae full diffusion tensor of flexible molecules    *
 * Copyright (C) 2018  Jonathan Campeggio, Antonino Polimeno, Mirco Zerbetto       * 
 *                                                                                 *
 * This program is free software; you can redistribute it and/or                   *
 * modify it under the terms of the GNU General Public License                     *
 * as published by the Free Software Foundation; either version 2                  *
 * of the License, or any later version.                                           *
 *                                                                                 *
 * This program is distributed in the hope that it will be useful,                 *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of                  *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                   *
 * GNU General Public License for more details.                                    *
 *                                                                                 *
 * You should have received a copy of the GNU General Public License               *
 * along with this program; if not, write to the Free Software                     *
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA. *
 ***********************************************************************************
 * Authors: Jonathan Campeggio, Antonino Polimeno, Mirco Zerbetto                  *
 * Dipartimento di Scienze Chimiche - Universita' di Padova - Italy                *
 * E-mail: mirco.zerbetto@unipd.it                                                 *
 ***********************************************************************************/

#include "DiTe2.h"

// Return the set of indexes for the scan

void getIdx (int s, int nq, int *scan, int *idx)
{
	int i, j, k;

        j = 0;

        for (i = nq - 1; i >= 0; --i)
	{
		if (scan[i] > 0)
		{
			k = (int)pow(scan[i] + 1, i);
			idx[i] = (s - j) / k;
			j += idx[i] * k;
		}
		else
			idx[i] = 0;
	}
	return;
}


// MAIN

int main(int argc, char *argv[])
{
	// Get call parameters

	if (argc < 2)
	{
		std::cout << std::endl << "ERROR: an input file must be specified while calling DiTe2" << std::endl << std::endl;
		exit(1);
	}

	// Start clock for input parsing
	int start_s_input = clock();

	// Check wether the program should stop just after the generation
	// of the Z-Matrix

	int stopAtZMatrix = 0;
	if (argc > 2)
		sscanf(argv[2], "%d", &stopAtZMatrix);
    

	// Parse the input file

	inputParser ip;
	ip.parseInputFile(argv[1], stopAtZMatrix);

	// Stop clock
	int stop_s_input = clock();


	// Set up the scan (if any)

	int Ns = 1;
	for (int j = 0;  j < ip.getNQ(); j++)
		Ns *= (ip.getScan(j) + 1);

	int *idx = new int[ip.getNQ()];

	double value;
	char buffer[65];

	// Start clock for diffusion tensor calculation
	int start_s_diff = clock();
		
	// Run diffusion tensor calculation

	std::string molFileName;
	std::string out1Name, out2Name;

	std::fstream scanLog;
	scanLog.open(ip.getPDBFileName() + ".scan.log", std::ios::out|std::ios::app);

	DiTe2 diff(&ip);

	for (int s = 0; s < Ns; ++s)
	{
		getIdx(s, ip.getNQ(), ip.getScan(), idx);

		scanLog << s << "\t"; 

		for (int i = 0; i < ip.getNQ(); ++i)
		{
			if (ip.getScan(i) > 0)
			{
				value = ip.getFirst(i) + (double)idx[i] * ip.getDelta(i);
				ip.changeZMatrix(i, value);
				scanLog << value << "\t";
			}
		}

		scanLog << std::endl;
		
		sprintf(buffer, "%d", s);

		molFileName = ip.getPDBFileName() + "." + buffer + ".xyz";
		ip.dumpMolecule(molFileName);

		out1Name = ip.getPDBFileName() + ".friction." + buffer;
		out2Name = ip.getPDBFileName() + ".diffusion." + buffer;

		diff.calculateDiffusionTensor(out1Name, out2Name);
	}

	scanLog.close();

	// Stop clock
	int stop_s_diff = clock();

	// Output run time
	cout << "Input parsed in: " << (stop_s_input - start_s_input) / double(CLOCKS_PER_SEC) << " s" << endl;
	cout << "Diffusion tensor calculated in: " << (stop_s_diff - start_s_diff)/double(CLOCKS_PER_SEC) << " s" << endl;


	return 0;
}


