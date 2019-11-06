GREEN=`tput setaf 2`;
NO_CLR=`tput sgr0`;

PATTERN="^\.?[a-zA-Z0-9/]*\.h((xx)|(h)|(pp)|())$";

DEFAULT_FIND_PATH="./";
FIND_PATH=${DEFAULT_FIND_PATH};

if [[ $# -ge 1 ]]; then
  FIND_PATH=$1;
fi

headerList=`find ${FIND_PATH} -regextype 'egrep' -iregex ${PATTERN}`;

echo "Headers found:";
echo "${headerList}";
echo "";

for header in ${headerList}; do
  echo "Checking ${header} ...";
  g++ -fsyntax-only ${header};
  if [[ "$?" -eq "0" ]]; then
    echo -e "[${GREEN}OK${NO_CLR}] File \"${header}\" has no syntax errors.";
  fi
done
