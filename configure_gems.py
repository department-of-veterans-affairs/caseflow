import subprocess
import re

#string = subprocess.check_output("gem query --local", shell=True)
#string = re.findall("(?![^\\(]*\\))[A-Za-z-_]+", string.decode("utf-8"))

with open("./gems.txt") as file:
    lines = [line.rstrip() for line in file]

for i in lines:
        print("bundle config build." + i + " --with-cflags=\"-Wno-error=incompatible-function-pointer-types\" --with-cppflags=\"-Wno-compound-token-split-by-macro\"")
        output = subprocess.check_output("bundle config build." + i + " --with-cflags=\"-Wno-error=incompatible-function-pointer-types\" --with-cppflags=\"-Wno-compound-token-split-by-macro\"", shell=True)
