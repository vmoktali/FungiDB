'''
Program that accepts tab delimited file with phone numbers and names, the output is the numbers with the users sharing the same number

'''
#import packages and functions, bmmb included in dropbox folder
import re
import bmmb

#open file for processing
fname1 = 'telephone-dir.txt'

#defining dictionaries
tel_dir = {}
dict2 = {}
flipped = {}

#Extract columns using bmmb package
col1 = bmmb.getcolumn(fname1, 'Name')
col2 = bmmb.getcolumn(fname1, 'Number')

#populate dict with input data
for i,j in zip(col1,col2):
    tel_dir[i] = j

#regex to match the phone numbers in any variation
#number combination 3-3-4 is extracted with any other elements in between or at the end 
phonePattern = re.compile(r'''(\d{3})\D*(\d{3})\D*(\d{4})\D*(\d*)$''', re.VERBOSE)

#populate dict with extracted phone numbers and user names
for i in tel_dir:
    num = phonePattern.search(tel_dir[i]).groups()
    ph = ''.join(num)
    dict2[i] = ph
        
#flip the dict to identify duplicate numbers    
for key, value in dict2.items():
    if value not in flipped:
        flipped[value] = [key]
    else:
        flipped[value].append(key)

#print dict 
print "Number\tName(s)"        
for key,value in flipped.items():
    print "%s\t%s"%(key,', '.join(map(str, value)))


