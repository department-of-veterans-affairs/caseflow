#!/bin/bash

# quit if anything fails
set -e

echo "Checking for required tools: Java and Graphviz's dot"
java --version
echo
dot -V
echo

set +e

# other useful functions
rmProcessedDotFiles(){
	find docket-* -name "*.dot"  | while read F; do if [ -e "$F.png" ]; then rm -f "$F"; fi; done
}

rmProcessedUmlFiles(){
	find docket-* -name "*.uml"  | while read F; do if [ -e "${F%.*}.png" ]; then rm -f "$F"; fi; done
}

echo "Removing processed files in docket-* directories ..."
# Saves time reprocessing dot and uml files.
# To for reprocessing, delete the associated png file
rmProcessedDotFiles
rmProcessedUmlFiles

createPngs(){
   echo "Processing dot files ..."
   find . -name "*.dot"  | while read F; do dot -O -Tpng $F; done

   if ls task_descr/*.uml &> /dev/null; then
      echo "Processing uml files in task_descr/ ... (this may take a while depending on the number of files)"
      java -jar plantuml.jar task_descr/*.uml
   fi

   for DOCSDIR in docket-*; do
      if ls task_descr/*.uml &> /dev/null; then
         echo "Processing uml files in $DOCSDIR ... (this may take a while depending on the number of files)"
         java -jar plantuml.jar $DOCSDIR/uml/*.uml
         java -jar plantuml.jar $DOCSDIR/uml/*/*.uml
      fi
   done
}
createPngs

rmExtraFiles(){
   echo "Removing dot and uml files"
   rm -f docket-*/dot/*.dot docket-*/dot/*/*.dot
   for DOCSDIR in docket-*; do
      rm -f $DOCSDIR/uml/*.uml
   done
}

rmProcessedDotFiles
rmProcessedUmlFiles

moveStaticFiles(){
   set -e
   for DOCS_DIR in docket-*; do
      pushd $DOCS_DIR/

      [ -d ../../../static/trees/$DOCS_DIR/freq-parentchild ] || mkdir ../../../static/trees/$DOCS_DIR/freq-parentchild
      [ -f dot/freq-parentchild.dot.png ] && mv -v dot/freq-parentchild.dot.png ../../../static/trees/$DOCS_DIR/freq-parentchild
      # rsync -av dot/ ../../static/trees/$DOCS_DIR/
      rm -rf dot
      popd
   done
   set +e
}
moveStaticFiles
