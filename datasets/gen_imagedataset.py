#!/usr/bin/python
# Generate datasets by splitting on unique filenames.csv entries (i.e. each image)
# Inputs: 	feature directory(s) 
#			name of image (must be in supplied filenames csv)
#  			labels file
#			filenames file
#			assign-ids boolean (add row numbers to dataset )
from os import listdir
from os.path import isfile,isdir,join
import fnmatch
import argparse
import re
import random


# Parsing stdin args to script
p = argparse.ArgumentParser(description="Read directory to list and class to generate dataset for", prog="gen_dataset.py")
p.add_argument('-dir', nargs = '+', required=True, help='Directory of column csv files')                                         # Requires a directory location
p.add_argument('-image', nargs=1, required=True, help='The image dataset to generate.')										     # An image listed in the filenames file ..
p.add_argument('-labels', required=True, type=argparse.FileType('r'), help='Column csv of labels')					 			 # The labels file 
p.add_argument('-filenames', required=True, type=argparse.FileType('r'), help='Column csv of filenames')					     # The filenames file 
p.add_argument('-assign-ids', nargs=1, required=False, help='Assign sequential numbers to each image set.')
p.add_argument('-assign-classes', dest='assign-classes', action='store_true', help='Assign classes from labels file (limited to just classes in image) or assign all labels.')
p.add_argument('-no-assign-classes', dest='assign-classes', action='store_false', help='Assign classes from labels file (limited to just classes in image) or assign all labels.')

# args = vars(p.parse_args('-dir /home/nick/git/paratiles/datasets/HARALICK.features -image PCRC-BIMS_656-10S-B_B1-HE.scn -labels /home/nick/git/paratiles/datasets/class.info/labels.csv -no-assign-classes -filenames /home/nick/git/paratiles/datasets/class.info/filenames.csv '.split()));

# args = vars(p.parse_args('-dir /home/nick/git/paratiles/datasets/HARALICK.features -image PCRC-BIMS_656-10S-B_A1-HE.scn -labels /home/nick/git/paratiles/datasets/class.info/labels.csv -filenames /home/nick/git/paratiles/datasets/class.info/filenames.csv '.split()));

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

mydirs = args['dir']
mylabels = args['labels']
myimage = args['image'][0]
myfilenames = args['filenames']
myassignids = args['assign_ids']
myassignclasses = args['assign-classes']

###################################################
# List all the CSV files in the specified directory
csvfiles = []
for mydir in mydirs:
	for dirc in listdir(mydir):
		if fnmatch.fnmatch(dirc, '*.csv'):
		  mycsv = mydir + '/' + dirc
		  csvfiles.append(mycsv)

csvfiles = sorted(csvfiles)					# Sort CSV files (makes it easier to do feature extraction later)

print csvfiles

###################################################
# Convert filenames to CSV headers
headers = []
for filename in csvfiles:
	myheader = re.sub(".csv", "", filename)		       # remove the '.csv'
	myheader = myheader[myheader.rfind('/')+1:len(myheader)]    # remove the 'path/to/file/'
	headers.append(myheader)				       # append it to list of headers

###################################################
# Iterate over filenames csv / get indices of unique entries 

def finduniq(seq):
	noDupes = []
	[noDupes.append(i) for i in seq if not noDupes.count(i)]
	return noDupes

# Gets all filenames from csv file
filenames = [f.strip() for f in myfilenames.readlines()]

start = filenames.index(myimage)

idx = start
while idx < len(filenames) and filenames[idx] == myimage:
	idx+=1

end = idx

indices = xrange(start, end)
numBlocks = end - start;

print "Image: ", myimage
print "Range is", start, "-", end 
print "Total blocks: ", numBlocks

################################################################
# Open labels file, get indices that match the supplied classes
labels = []
idx = 0;

labels = mylabels.readlines();
labels = [labels[i].strip() for i in indices]
mylabels.close();

print "Num labels: ", len(labels)

################################################################
# Extracting selected indices from each file

print "Reading", str(len(csvfiles)), 'files .. Please wait.'

data = []

for csvfile in csvfiles:                                            # for each file
	
	lines = open(csvfile, 'r').readlines()                          # read all lines
	 
	olines = []                                                     # olines is output lines
	i = 0;
	for idx in indices:                                             # iterate over each selected index    
		i += 1;
		olines.append(lines[idx].strip())                           # append the selected indices to olines list and remember to remove the newline char
		  
	data.append(olines)                                             # then append all of the selected lines to the data list

data.append(labels)													# ARFF files will always have the label written to same file, in this case the final column ..


################################################################
# Writing to output file
# With ARFF files, headers and labels must be specified in the file itself, so no need to handle writing labels and headers to separate files.


outpath = re.sub('scn', 'arff', myimage)

print "Writing data to output file", outpath, " .. Please wait."

out = open(outpath, 'wb')

#######################
# Write ARFF info header 


out.write('% An ARFF dataset file generated by gen_imagedataset.py\n')
out.write('% Created by: Nick McCarthy <nicholas.mccarthy@gmail.com>\n\n')

#######################
# Write @RELATION section

relation_str = '@RELATION label-imagedata\n\n'

out.write(relation_str)

#######################
# Write @ATTRIBUTE section

for header in headers:		
	out.write('@ATTRIBUTE ' + header + ' NUMERIC\n')

if myassignclasses == True:
	class_str = '@ATTRIBUTE label {NON, TIS, G3, G34, G4, G45, G5}\n'
else:
	class_str = '@ATTRIBUTE label {'
	myclasses = sorted(finduniq(labels))

	for c in myclasses:
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

	line += '\n'
	out.write(line)

out.close()

# Print some summary data
print "--------------"
print "Dataset: \t", outpath
print "Number features: " , len(data)-1
print "Number observations: " , len(indices)-num_nonzero_removed
print "--------------"
