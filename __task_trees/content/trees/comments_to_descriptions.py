#!/usr/bin/env python3

import re
import sys
import os
import glob

START_PATTERN = '^##$'
END_PATTERN = '^class .*Task'


def extract_class_comments(rbfile):
    with open(rbfile) as file:
        match = False
        classname = None
        newfile = ""

        for line in file:
            if re.match(START_PATTERN, line):
                match = True
                continue
            elif re.match(END_PATTERN, line):
                # extract the Task classname for looking up the description file later
                classname = line.split()[1]
                match = False
                continue
            elif match:
                # remove comment symbol and space '# ' at the start of lines
                newline = re.sub(r'^#+ ?', '', line)
                # convert lines starting with uppercase letter into bullets
                newline = re.sub(r'^([A-Z])',  r'* \1', newline)
                # indent other lines that start with lowercase or bullet symbol
                newline = re.sub(r'^([^A-Z\*\-])', r'  \1', newline)
                newfile += newline
        return classname, newfile.strip()


COMMENTS_BEGIN_TAG = '<!-- class_comments:begin -->'
DO_NOT_MODIFY_MSG = '<!-- Do not modify within this block; modify associated rb file instead and run comments_to_descriptions.py. -->'
COMMENTS_END_TAG = '<!-- class_comments:end -->'
TASK_RB_DIR = 'app/models/tasks'


def find_files_with_suffix(baseDir, suffix):
    pattern = f'{baseDir}/{TASK_RB_DIR}/**/*{suffix}'
    return glob.glob(pattern, recursive=True)


def extract_comments_to_files(baseDir, commentsDir):
    os.path.isdir(commentsDir) or os.mkdir(commentsDir)

    for rbfile in find_files_with_suffix(baseDir, '.rb'):
        print(f'Processing {rbfile}')
        classname, comment = extract_class_comments(rbfile)
        mdFile = commentsDir+"/"+os.path.basename(classname+'.md')
        if len(comment) > 0 and not os.path.exists(mdFile):
            print(f'Writing to {mdFile}')
            with open(mdFile, 'w') as commentFile:
                commentFile.write(COMMENTS_BEGIN_TAG+"\n")
                commentFile.write(DO_NOT_MODIFY_MSG+"\n")
                commentFile.write("Code comments extracted from Ruby file:\n")
                commentFile.write(comment+'\n')
                commentFile.write(COMMENTS_END_TAG)


def find_corresponding_descr_file(targetdir, mdfilename):
    descrFile = targetdir+"/"+mdfilename.replace('.md', '_Organization.md')
    if not os.path.exists(descrFile):
        descrFile = targetdir+"/"+mdfilename.replace('.md', '_User.md')
    if not os.path.exists(descrFile):
        descrFile = None
    return descrFile


def insert_into_descr_file(sourceDir, targetdir):
    mdfiles = [f for f in os.listdir(sourceDir) if re.match(r'.*\.md', f)]
    for mdfilename in mdfiles:
        mdFile = sourceDir+"/"+mdfilename

        descrFile = find_corresponding_descr_file(targetdir, mdfilename)
        if not descrFile:
            print(f"\nWARNING: description file does not exist for {mdfilename} (usually because the task is abstract and/or doesn't exist in prod)")
            continue

        oldContent = None
        with open(descrFile, 'r') as descrFileInput:
            oldContent = descrFileInput.read()
        if not descrFile:
            print(f"\nWARNING: could not read from description file {descrFile}; will create new file.")
            oldContent = ""

        comment = None
        with open(mdFile, 'r') as mdFileInput:
            comment = mdFileInput.read().strip()
        if not comment:
            print(f"\nINFO: no code comments in {mdfilename}; skipping.")
            continue

        print(f'Inserting {mdFile} contents into {descrFile}')
        with open(descrFile, 'w') as descrFileOutput:
            if COMMENTS_BEGIN_TAG in oldContent and COMMENTS_END_TAG in oldContent:
                # replace existing class_comments block
                newContent = re.sub(f'{COMMENTS_BEGIN_TAG}.*{COMMENTS_END_TAG}',
                                     comment, oldContent, flags=re.S)
            else:
                # append at the end of the file
                newContent = oldContent + '\n' + comment + '\n'
            descrFileOutput.write(newContent)


COMMENT_DIR='/tmp/task_comments'

def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <caseflow_dir>")
        print(f'''
This Python 3.7 script reads Task class files from the {TASK_RB_DIR} directory in your Caseflow
source code directory and extracts the class comments into files located in {COMMENT_DIR}.
Note: The files in {COMMENT_DIR} will not be updated if they exist.
      To have them be updated, delete the files in that directory.

It then inserts those comments into corresponding description md files in the `task_descr` subdirectory.
The comments will be between `{COMMENTS_BEGIN_TAG}` and `{COMMENTS_END_TAG}` tags.
        ''')
        sys.exit(1)

    if not os.path.isdir(sys.argv[1]):
      print(f"!!! Error: directory does not exist: {sys.argv[1]}")
      sys.exit(2)

    print(f"::group:: Extracting class comments to md files in {COMMENT_DIR}")
    extract_comments_to_files(sys.argv[1], COMMENT_DIR)
    print("::endgroup::\n")

    print("::group:: Writing to task description files in subdirectory task_descr")
    insert_into_descr_file(COMMENT_DIR, 'task_descr')
    print("::endgroup::")


if __name__ == "__main__":
    main()
