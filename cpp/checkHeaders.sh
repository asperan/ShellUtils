#Color scheme setup
GREEN=`tput setaf 2`;
NO_CLR=`tput sgr0`;

#Regular expression which returns any file path which has an h, hh, hxx or hpp extension
PATTERN=".*\.h((xx)|(h)|(pp)|())$";

#The default path is the current directory
DEFAULT_FIND_PATH="./";
FIND_PATH=${DEFAULT_FIND_PATH};

#If there is at least one argument, use the first as the path to run "find" in
if [[ $# -ge 1 ]]; then
  FIND_PATH=$1;
fi

headerList=`find "${FIND_PATH}" -regextype 'egrep' -iregex ${PATTERN}`;

#The next part is executed only if find does not have an error.
if [[ $? -eq 0 ]]; then
  echo "Headers found:";
  echo "${headerList}";
  echo "";

  for header in ${headerList}; do
    echo "Checking ${header} ...";
    g++ -fsyntax-only ${header};
    #Errors are printed anyway if g++ finds one, so this script just confirm when the header is OK.
    if [[ "$?" -eq "0" ]]; then
      echo -e "[${GREEN}OK${NO_CLR}] File \"${header}\" has no syntax errors.";
    fi
    echo ""
  done
fi


### What to add
### Options: 
### --help which prints an usage message
### --only-errors which prints only headers which has errors.
###