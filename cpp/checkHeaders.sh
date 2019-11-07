#Color scheme setup
GREEN=`tput setaf 2`;
NO_CLR=`tput sgr0`;

### Path settings
#The default path is the current directory
DEFAULT_FIND_PATH="./";
FIND_PATH=${DEFAULT_FIND_PATH};

#If there is at least one argument, use the first as the path to run "find" in
if [[ $# -ge 1 ]]; then
  FIND_PATH=$1;
fi

### Support file settings
SUPP_PATH=".chkHeaders";
SUPP_FILE_NAME="headers";
supportFile="${HOME}/${SUPP_PATH}/${SUPP_FILE_NAME}"

# Regular expression which returns any file path which has an h, hh, hxx or hpp extension
PATTERN=".*\.h((xx)|(h)|(pp)|())$";

### Date settings
DATE_FORMAT="+%Y%m%d%H%M%S";

# Expands given path if it starts with "./" to be an absolute path
function expand_curr_dir {
  filepath=$1;
  # Counts the number of times the path has '../'
  numBackDir=`echo ${filepath} | sed 's/\.\.\//&\n/g' | grep '\.\.\/' | wc -l`;
  iter=0;
  cdPath="";
  while [[ ${iter} -lt ${numBackDir} ]]; do
    cdPath=${cdPath}"../";
    let iter++;
  done
  # Adds './' to the beginning of the path to say it is a relative path
  if [[ "${filepath}" = ../* ]]; then
    filepath="./"${filepath};
  fi
  # Removes every '../' substring
  filepath=`echo ${filepath} | sed 's/\.\.\///g'`;
  # Follows every '../' counted before.
  filepath=`cd ${cdPath}; pwd`$(echo ${filepath} | tail -c +2);
  echo ${filepath};
}

function checkHeader {
  if [[ ! $# -eq 1 ]]; then
    exit 1;
  else
    current_filepath="$1";
    echo "Checking ${current_filepath} ...";
    #Errors are printed anyway if g++ finds one, so this script just confirm when the header is OK.
    g++ -fsyntax-only ${full_filepath};    
    if [[ "$?" -eq "0" ]]; then
      echo -e "[${GREEN}OK${NO_CLR}] File \"${current_filepath}\" has no syntax errors.";
    fi
    echo ""
  fi
}

headerList=`find "${FIND_PATH}" -regextype 'egrep' -iregex ${PATTERN}`;

if [[ ! -d "${HOME}/${SUPP_PATH}" ]] ; then
  # The config folder does not exists, it needs to be created.
  mkdir ~/${SUPP_PATH}
fi
if [[ ! -f "${HOME}/${SUPP_PATH}/${SUPP_FILE_NAME}" ]]; then
  # The support file is not present, it needs to be created.
  printf "# This file is used by the checkHeaders script.\n# In this file are stored the headers checked and the date at which the are checked.\n# Delete this file ONLY if you want to reset the script memory.\n# Format: <filename>_<last check time (yyyymmddHHMMSS)>\n" > ~/${SUPP_PATH}/${SUPP_FILE_NAME}
fi


#The next part is executed only if find does not have an error.
if [[ $? -eq 0 ]]; then
  echo "Headers found:";
  echo "${headerList}";
  echo "";

# Controllare se la data di ultima modifica del file di header è maggiore della data di ultima compilazione nel file di supporto
# con date -r $filename "+%y%m%d%H%M%S". Confrontare con la data presente nel file di supporto (se esiste).
  for header in ${headerList}; do
    full_filepath=`expand_curr_dir ${header}`
    #echo "${full_filepath}"
    fileLine=`fgrep "${full_filepath}" "${supportFile}"`
    #echo "${fileLine}"
    if [[ -z "${fileLine}" ]] ; then
      #echo "Header not present in support file"
      compilationDate=`date ${DATE_FORMAT}`;
      echo ${full_filepath}_${compilationDate} >> ~/${SUPP_PATH}/${SUPP_FILE_NAME}
      checkHeader ${full_filepath};
    else
      #echo "Header already in support file"
      #echo "${fileLine}";
      lastCompDate=$(echo ${fileLine} | sed 's,'"${full_filepath}"',,' | tail -c +2);
      #echo ${lastCompDate};
      lastModDate=`date -r ${full_filepath} ${DATE_FORMAT}`;
      if [[ ${lastCompDate} -lt ${lastModDate} ]]; then
        checkHeader ${full_filepath};
      fi
    fi
  done
fi


### What to add
### Options: 
### --help which prints an usage message
### --only-errors which prints only headers which has errors.
###