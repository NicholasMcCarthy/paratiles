#!/usr/bin/python

# This is a python script for generating a single csv file from multiple columnar csv files using only
# specific (i.e. per class) rows
from os import listdir
from os.path import isfile,isdir,join
import fnmatch
import argparse
import re

# Parsing stdin args to script
p = argparse.ArgumentParser(description="Read directory to list and class to generate dataset for", prog="gen_dataset.py")
p.add_argument('-dir', required=True, help='Directory of column csv files')                                                               # Requires a directory location
p.add_argument('-class', nargs='+', required=True, help='Class labels to find in specified labels csv file')                                                  # Requires at least one class to be specified
p.add_argument('-labels', required=True, type=argparse.FileType('r'), help='Column csv of labels')                                # The labels file 
p.add_argument('-output', required = True, type=argparse.FileType('wb', 0), help='Name of output dataset.csv')                          # 

# args = vars(p.parse_args('-dir /home/nick/git/paratiles/datasets/final -class G3 G34 -labels /home/nick/git/paratiles/datasets/tile_info/labels.csv -output test.csv'.split()));

# args = vars(p.parse_args('-dir /home/nick/E/Dropbox/matlab/datasets/final/ -class G3 G34 -labels /home/nick/E/GitHub/paratiles/datasets/tile_info/labels.csv -output test.csv'.split()));

# args = vars(p.parse_args('-dir E:/Dropbox/matlab/datasets/final/ -class G3 G34 -labels E:/GitHub/paratiles/datasets/tile_info/labels.csv -output test.csv'.split()));

args = vars(p.parse_args())

if isdir(args['dir']) == False:
    print "Invalid feature directory supplied. Goober."
else:
    print "Specified feature directory: ", args['dir']
   
print "Classes supplied: ", args['class'] 


################################################################
# List all the CSV files in the specified directory
csvfiles = []
for dirc in listdir(args['dir']):
    if fnmatch.fnmatch(dirc, '*.csv'):
        csvfiles.append(dirc)

################################################################
# Convert filenames to CSV headers
headers = []
for filename in csvfiles:
    headers.append(re.sub(".csv", "", filename)) # removes .csv from end of filename

headers.append('class')
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
    
# N = idx # keep number of lines in file .. 

################################################################
# Write csv headers to output file
out = args['output']

header_line = ""
for header in headers:
    header_line += header + ','

header_line = header_line[0:len(header_line)-1] # strip final comma
header_line += '\n'                             # and append newline
out.write(header_line)
          
################################################################
# Extracting selected indices from each file

print "Reading", str(len(csvfiles)), 'files .. Please wait.'

data = []

for csvfile in csvfiles:                                            # for each file
    
    lines = open(args['dir']+'/'+csvfile, 'r').readlines()          # read all lines
    
    olines = []                                                     # olines is output lines
    i = 0;
    for idx in indices:                                             # iterate over each selected index    
        i += 1;
        olines.append(lines[idx].strip())                           # append the selected indices to olines list and remember to remove the newline char
        
    data.append(olines)                                             # then append all of the selected lines to the data list

data.append(labels)                    # Append label indices so they are the last column that get written to the output file

print " ... Done!"

num_nonzero_removed = 0		    # Keeping track of how many rows were removed for having no nonzero elements

print "Writing data to output file .. Please wait."

for row in range(0, len(indices)):              # for each row in data
    line = ''
    for col in range(0, len(data)):                     # for each col in data
        line += str(data[col][row]) + ','                    # concatenate the row feature vector
      
    line = line[0:len(line)-1] # remove last comma

    # Part for removing empty rows 
    nonzero_elements = False	
    for c in range(1,10): # checking if nonzero numbers are in the row string ..
      if str(c) in line[0:line.rfind(',')]: # checks up to last comma (since the last value is value and may have numbers
	 nonzero_elements = True 
	 break
   
    # Write line to output file, except if it it has no nonzero elements 
    if (nonzero_elements):
      line += '\n'    
      out.write(line)    
    else:
      num_nonzero_removed += 1

out.close()

print "Finished writing!"

print "Number of rows read: ", len(indices)
print "Zero-element rows removed: ", num_nonzero_removed

print "Aggregated dataset: ", args['output'].name
print "Number cols: " , len(data)-1
print "Number rows: " , len(indices)-num_nonzero_removed

