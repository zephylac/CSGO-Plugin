from os import path
import sys
import os

def rmLine2(filename, string):
	with open(filename) as i, open('/tmp/temp.txt', 'w') as o:
    		for line in i:
       			if line.startswith(string):
				line = ''        			
       			o.write(line)

	os.rename('/tmp/temp.txt', filename)


argv = sys.argv[1:]
argc = len(argv)
userFound = 0
exist = 0
temp = '&&&&&&&'
temp2 = 0
if argc != 2:
    print("need a file ans steam ID")
    exit();

dataDir = path.join(path.dirname(__file__), argv[0])
data = open(dataDir, "r+")

lines = data.read().split("\n")
lines = [l.strip() for l in lines if l != ""]
extract = {}
i = 2
while lines[i] != "}":
    name = lines[i].replace('"', '')
    extract[name] = []
    i+=1
    while lines[i] != "}":
        tab = lines[i].split('"')
        tab = filter(str.strip, tab)
	if tab[0] == "identity" and tab[1] == argv[1]:
		userFound = 1		
		print(i)
		temp2 = i
	if tab[0] == "group" and tab[1] == "test" and userFound == 1:	
		temp = "                "+lines[i]
		rmLine2("/root/a.txt",temp)		
        i+=1
    exist = 0
    userFound = 0
    i+=1
data.close()
