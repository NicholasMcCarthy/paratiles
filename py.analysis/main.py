#!/usr/bin/python

# This is the main script (for now) used by Python / Scipy / Numpy for data analysis.
# This will be a learning experience .. 

#####################
# Import statements #
#####################
from PyML import *
from PyML.containers import VectorDataSet
import csv

###################
# Parse Arguments #
###################

# required: datafile
# optional: labelfile
# optional: headerfile


################################################

datafile  = '/home/nick/git/paratiles/datasets/G3-G4_CICM-HIST.test.csv'

_data = csv.reader(open(datafile, 'r'), delimiter=',')

headers = _data.next()

print "Reading data file .. "
data = []
for row in _data:
	data.append(row)

print "Converting values to numeric .."
# Convert all string values in data matrix to floats (C doubles)
data = [[ float(col) for col in row] for row in data]

# Reading labels
print "Reading labels file .."
labelfile = '/home/nick/git/paratiles/datasets/G3-G4_CICM-HIST.test.labels.csv'
_labels = open(labelfile, 'r')

labels = []

for row in _labels:
	labels.append(row)

_labels.close()


# print "Reading headers file .. "
# headerfile = '/home/nick/git/paratiles/datasets/G3-G4_CICM-HIST.test.headers.csv'
# _headers = open(headerfile, 'r')

# headers = []
# for row in _headers:
# 	headers.append(row)

# _headers.close()

mydata = VectorDataSet(data, L=labels, featureID = headers)


print "Attaching to data matrix .."
mydata.attachLabels(Labels(labels))

# # Subsetting data
# data2 = data.__class__(data, classes=['G3', 'G4']) 	
# # Deleting classes
# data3 = datafunc.DataSet(data, eliminateClasses = ['G34'])

# print "Subsetting data .."
# mydata2 = mydata.__class__(mydata, classes=['G3', 'G4'])

###############################################
# Training an SVM classifier

print "Training SVM Classifier .. "

model = svm.SVM(C = 1)

k = 5

print "Performing", k, "fold cross-validation"

results = model.cv(mydata, k)







print "FIN"