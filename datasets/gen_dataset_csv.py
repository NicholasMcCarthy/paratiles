#!/usr/bin/python

# This is a python script for generating a single csv file from multiple columnar csv files using only
# specific (i.e. per class) rows
from os import listdir
from os.path import isfile,isdir,join
import fnmatch
import argparse
import re
import random

# Parsing stdin args to script
p = argparse.ArgumentParser(description="Read directory to list and class to generate dataset for", prog="gen_dataset.py")
p.add_argument('-dir', nargs = '+', required=True, help='Directory of column csv files')                                                               # Requires a directory location
p.add_argument('-class', nargs='+', required=True, help='Class labels to find in specified labels csv file')                              # Requires at least one class to be specified
p.add_argument('-labels', required=True, type=argparse.FileType('r'), help='Column csv of labels')					  # The labels file 
p.add_argument('-output', required = True, type=argparse.FileType('wb', 0), help='Name of output dataset.csv')				  # The output file

p.add_argument('-labelfile', dest='labelfile', action='store_true', help='Specify a specific file to write the labels column to.')
p.add_argument('-no-labelfile', dest='labelfile', action='store_false', help='Write labels as a column in the main csv file.')
p.set_defaults(labelfile=True)

p.add_argument('-headerfile', dest='headerfile', action='store_true', help='Specify a specific file to write the headers row to.')
p.add_argument('-no-headerfile', dest='headfile', action='store_false', help='Write headers as the top row in the main csv file.')
p.set_defaults(headerfile=False)

p.add_argument('-limit-obs', nargs='+', required=False, help="Limit the number of obs. per class")

# args = vars(p.parse_args('-dir /home/nick/git/paratiles/datasets/HARALICK.features -class G3 -labels /home/nick/git/paratiles/datasets/class.info/labels.csv -output test.csv -limit-obs 5000 -no-labelfile -no-headerfile'.split()));

# args = vars(p.parse_args('-dir /home/nick/E/Dropbox/matlab/datasets/final/ -class G3 G34 -labels /home/nick/E/GitHub/paratiles/datasets/tile_info/labels.csv -output test.csv'.split()));

# args = vars(p.parse_args('-dir E:/Dropbox/matlab/datasets/final/ -class G3 G34 -labels E:/GitHub/paratiles/datasets/tile_info/labels.csv -output test.csv'.split()));

args = vars(p.parse_args())

parse_error = False

for mydir in args['dir']:
	if isdir(mydir) == False:
		print "Invalid feature directory supplied. Goober."
		parse_error = True
	else:
		print "Specified feature directory: ", mydir 
	
print "Classes supplied: ", args['class'] 

# Don't use the limit option, as I could not get random.sample to work .. 
if args['limit_obs'] is not None:				                 # if limits are set
	if len(args['limit_obs']) == len(args['class']):	        # If the number of limits specified matches the number of classes
		limit_counts = []					                          # Create new empty vector for limit counts
		for i in range(0, len(args['class'])):
			limit_counts.append(0);
	else:	                                                     # Otherwise
		parse_error = True				       # Parse error!
		print "Must specify observation limit for each class specified"

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

if args['labelfile'] == False:		  # If labels are being written to the same file, append the header here
	headers.append('label')

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

# Reducing number of obs  
if args['limit_obs'] is not None:	     # If limiting the number of obs per class .. 
	
	limit = int(args['limit_obs'][0])
	print "Limit specified:", limit

	if len(args['class']) == 1:			  # Only limiting number of selected obs when 1 class is selected (for now - as it is a pain to get working)

		# if len(args['class']) == len(args['limit_obs']) # Multiple classes with multiple limitations .. 

		if len(labels) > limit:			# Check that the limit is lower than the current length of the labels vector

			print "Sampling ", limit, " observations."
			sample_idx = sorted(random.sample(range(0, len(indices)), limit ))

			indices = [indices[i] for i in sample_idx]
			labels = [labels[i] for i in sample_idx]

		else:

			print "Invalid limit specified. Limit is higher than population!"
	else:
		print "Currently only limiting number of observations when one class is set."
	
	# Whatever way I was trying to do this caused an error, so fuck it! We'll limit in preproc

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

################################################################
# Write csv headers to output file, or seperate file is -headerfile flag is specified

# If headerfile flag is set, write headers to separate file
if args['headerfile'] == True:
	headers_output = re.sub('csv', 'headers.csv', args['output'].name) # Name of headers file
	print "Separate headers file specified:", headers_output
	headerfile = open(headers_output, 'wb')
else:
	headerfile = args['output']

header_line = ""

for header in headers:
	header_line += header + ','

header_line = header_line[0:len(header_line)-1] # strip final comma
header_line += '\n'                             # and append newline
headerfile.write(header_line)

#################################################################
# Writing to output file

out = args['output']

if args['labelfile'] == True:                                             # if labels should be written to a separate file .. 
  
	labels_output = re.sub('.csv', '.labels.csv', args['output'].name)	  # This will break if the output file is not a .csv file .... 
	print "Separate labels file specified:", labels_output
	labelfile = open(labels_output, 'wb')				                       # Open a new file

	if args['headerfile']:                                                 # AND If headers are being written (an edge case)
		labelfile.write('label\n')						                          # then write the header here .. 

else:
	data.append(labels)						                                   # Append label indices so they are the last column that get written to the output file

print "Writing data to output file .. Please wait."

num_nonzero_removed = 0		                                               # Keeping track of how many rows were removed for having no nonzero elements

for row in range(0, len(indices)):                                        # for each row in data
	line = ''
	for col in range(0, len(data)):                                        # for each col in data
		line += str(data[col][row]) + ','                                   # concatenate the row feature vector
		
	line = line[0:len(line)-1]                                             # remove last comma

	# Part for removing empty rows 
	nonzero_elements = False	
	for c in range(1,10):                                                  # checking if nonzero numbers are in the row string ..
		if str(c) in line[0:line.rfind(',')]:                               # checks up to last comma (since the last value is value and may have numbers
			nonzero_elements = True 
			break
	
	# Write line to output file, except if it it has no nonzero elements 
	if (nonzero_elements):
		line += '\n'    
		out.write(line)

		if args['labelfile'] == True:                                       # If labels are written to a separate file .. 
			labelfile.write(labels[row]+ '\n')                               # Write the row index from the labels list, and add a newline
							
	else:
		num_nonzero_removed += 1

out.close()

if args['headerfile']:                                                     # If a headerfile was written
  headerfile.close()                                                       # close the file handle

if args['labelfile']:                                                      # And do the same for the labelfile .. 
	labelfile.close()


# Print some summary data

print "Number of rows read: ", len(indices)
print "Zero-element rows removed: ", num_nonzero_removed

print "--------------"
print "Dataset: \t", args['output'].name

if args['labelfile']:
  print "Labels: \t", labels_output

if args['headerfile']:
  print "Headers: \t", headers_output 

print "Number cols: " , len(data)-1
print "Number rows: " , len(indices)-num_nonzero_removed

print "--------------"
