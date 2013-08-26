#!/usr/bin/python

# Generate datasets by splitting on unique filenames.csv entries (i.e. each image)

from os import listdir
from os.path import isfile,isdir,join
import fnmatch
import argparse
import re
import random

# Inputs: 	feature directory(s) 
#			output file 			
#  			
#
#

# Parsing stdin args to script
p = argparse.ArgumentParser(description="Read directory to list and class to generate dataset for", prog="gen_dataset.py")
p.add_argument('-dir', nargs = '+', required=True, help='Directory of column csv files')                                                               # Requires a directory location
p.add_argument('-output', required = True, type=argparse.FileType('wb', 0), help='Name of output dataset.csv')				  # The output file
p.add_argument('-labels', required=True, type=argparse.FileType('r'), help='Column csv of labels')					  # The labels file 
p.add_argument('-filenames', required=True, type=argparse.FileType('r'), help='Column csv of filenames')					  # The filenames file 
p.add_argument('-assign-ids', nargs=1, required=False, help='Assign sequential numbers to each image set.')

# args = vars(p.parse_args('-dir /home/nick/git/paratiles/datasets/HARALICK.features -class G5 G3 TIS -labels /home/nick/git/paratiles/datasets/class.info/labels.csv -output test.csv -limit-obs 5000 -assign-zeros NON'.split()));

args = vars(p.parse_args())

parse_error = False

for mydir in args['dir']:
	if isdir(mydir) == False:
		print "Invalid feature directory supplied. Goober."
		parse_error = True
	else:
		print "Specified feature directory: ", mydir 
	
if args['assign_ids'] == True:				              
	print "Numbering each row by image."
else:
	print "Not numbering each row by image."

if parse_error:
	print "Exiting .. "
	os.system('exit')



################################################################
# List all the CSV files in the specified directory
csvfiles = []
for mydir in args['dir']:
	for dirc in listdir(mydir):
		if fnmatch.fnmatch(dirc, '*.csv'):
		  mycsv = mydir + '/' + dirc
		  csvfiles.append(mycsv)

csvfiles = sorted(csvfiles)					# Sort CSV files (makes it easier to do feature extraction later)

print csvfiles

################################################################
# Convert filenames to CSV headers
headers = []
for filename in csvfiles:
	myheader = re.sub(".csv", "", filename)		       # remove the '.csv'
	myheader = myheader[myheader.rfind('/')+1:len(myheader)]    # remove the 'path/to/file/'
	headers.append(myheader)				       # append it to list of headers

################################################################
# Iterate over filenames csv / get indices of unique entries 

# Gets unique entries in a list
def f4(seq): 
   # order preserving
   noDupes = []
   [noDupes.append(i) for i in seq if not noDupes.count(i)]
   return noDupes

# 0. Get each line in filenames.csv
# 1. Get each unique entry in filenames (each image)
# 2. Get starting and end indices for each unique entry
# 3. Map indices to unique entries
# 4. loop over code below with selected range(start, end) for each unique index

# Gets all filenames from csv file
filenames = args['filenames'].readlines();

# Gets unique filename entries
Uf = f4(filenames)
# Strip trailing newline chars
Uf = [u.strip() for u in Uf]


for idx in range(0, len(filenames))
	





################################################################
# Open labels file, get indices that match the supplied classes

indices = []
labels = []
idx = 0;

for line in args['labels']:
	if line.strip() in args['class']:
		indices.append(idx)
		labels.append(line.strip())
	idx+=1

args['labels'].close()

print "Number of obs read:", len(labels)

# Set maximum number of obs of ANY class, rather than class specifics .. 
if args['limit_obs'] is not None:

	limit = int(args['limit_obs'][0])
	sampled_idx = []

	print "Maximum number of obs. will be limited to: ", limit

	for C in args['class']:				# For each class

		class_idx = [idx for idx,val in enumerate(labels) if val == C]   # Get list indices that match this class

		if len(class_idx) > limit: 										# If it's greater than the limit
			print "Sampling", C, "as limit is reached."
			class_idx = random.sample(class_idx, limit) 			 	# Sample up to the max allowed 

		sampled_idx = sampled_idx + class_idx							# Append the selected class_idx (sampled or otherwise) to the sampled_idx list


	labels = [labels[i] for i in sorted(sampled_idx)]					# Technically the sorted is not needed here, but why not keep it neat .. 
	indices = [indices[i] for i in sorted(sampled_idx)]

################################################################
# Extracting selected indices from each file

print "Reading", str(len(csvfiles)), 'files .. Please wait.'

data = []

for csvfile in csvfiles:                                           # for each file
	
	lines = open(csvfile, 'r').readlines()                          # read all lines
	 
	olines = []                                                     # olines is output lines
	i = 0;
	for idx in indices:                                             # iterate over each selected index    
		i += 1;
		olines.append(lines[idx].strip())                            # append the selected indices to olines list and remember to remove the newline char
		  
	data.append(olines)                                             # then append all of the selected lines to the data list

data.append(labels)													# ARFF files will always have the label written to same file, in this case the final column ..


################################################################
# Writing to output file

# With ARFF files, headers and labels must be specified in the file itself, so no need to handle writing labels and headers to separate files.

print "Writing data to output file .. Please wait."

out = args['output']

#######################
# Write ARFF info header 

out.write('% An ARFF dataset file generated by gen_dataset_arff.py\n')
out.write('% Created by: Nick McCarthy <nicholas.mccarthy@gmail.com>\n\n')

#######################
# Write @RELATION section

relation_str = '@RELATION '
for c in args['class']:
	relation_str += c + '-'

relation_str += 'data\n\n'

out.write(relation_str)


#######################
# Write @ATTRIBUTE section

for header in headers:		
	out.write('@ATTRIBUTE ' + header + ' NUMERIC\n')

class_str = '@ATTRIBUTE label {'
for c in args['class']:
	class_str += c + ','

class_str = class_str[0:len(class_str)-1] + '}\n\n'					

out.write(class_str)   # The last @ATTRIBUTE line that specifies the classes

#######################
# Write @DATA section

out.write('@DATA \n')

num_nonzero_removed = 0		                                               # Keeping track of how many rows were removed for having no nonzero elements

for row in range(0, len(indices)):                                        # for each row in data
	line = ''
	for col in range(0, len(data)):                                        # for each col in data
		line += str(data[col][row]) + ','                                   # concatenate the row feature vector
		
	line = line[0:len(line)-1]                                             # remove last comma

	if args['assign_zeros'] is None: 	# Part for removing empty rows 
		nonzero_elements = False	
		for c in range(1,10):                                                  # checking if nonzero numbers are in the row string ..
			if str(c) in line[0:line.rfind(',')]:                               # checks up to last comma (since the last value is value and may have numbers
				nonzero_elements = True 
				break
		
		# Write line to output file, except if it it has no nonzero elements 
		if (nonzero_elements):
			line += '\n'    
			out.write(line)
								
		else:
			num_nonzero_removed += 1

	else:
		line += '\n'
		out.write(line)

out.close()

# Print some summary data

print "Number of rows read: ", len(indices)

if args['assign_zeros'] is None:
	print "Zero-element rows removed: ", num_nonzero_removed
else:
	print "Zero-element rows assigned label", str(args['assign_zeros'][0])

print "--------------"
print "Dataset: \t", args['output'].name
print "Number features: " , len(data)-1
print "Number observations: " , len(indices)-num_nonzero_removed
print "--------------"
