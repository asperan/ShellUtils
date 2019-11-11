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

### Option settings
# Available options:
# -h    Show Help panel
# -q    Suppress output
# 

# Sets the option variables according to options passed or default behavior
function parse_options {
  while getopts ':hq' currOption; do
  #echo ${currOption}
    case ${currOption} in
      q) echo "Quiet"
      ;;
      h) echo "Help"
      ;;
      \?) echo "Unknown"
      ;;
    esac
  done
  #optionList=`getopt -o 'h'`;
  #echo ${optionList};
}

parse_options;

# Expands the given path if it starts with "./" to be an absolute path
function expand_curr_dir {
  if [[ ! $# -eq 1 ]]; then
    exit 1;
  else
    filepath=$1;
    # Removes './' from the beginning of the path
    if [[ "${filepath}" = ./* ]]; then
      filepath=`echo ${filepath} | tail -c +3`;
    fi
    
    # Counts the number of times the path has '../'
    numBackDir=`echo ${filepath} | sed 's/\.\.\//&\n/g' | grep '\.\.\/' | wc -l`;

    # The filepath start with a folder and then it goes back,
    if [[ ${numBackDir} -gt 0 && ! ${filepath} = ../* ]]; then
      printf "ERROR: filepath starts with a folder and then goes back with '../'. Please rewrite the path without this construct.\n";
      exit 1;
    fi
    
    iter=0;
    cdPath="";
    # Counts the parent dirs
    while [[ ${iter} -lt ${numBackDir} ]]; do
      cdPath=${cdPath}"../";
      let iter++;
    done

    # Removes every '../' substring
    filepath=`echo ${filepath} | sed 's/\.\.\///g'`;

    if [[ ${iter} -eq 0 && ! ${filepath} = ~/* ]]; then
      # Follows every '../' counted before.
      filepath=`pwd`"/${filepath}";
    elif [[ ! ${iter} -eq 0 && ${filepath} = ~/* ]]; then 
      printf "ERROR: filepath starts from home directory back has '../'. Please rewrite the path without this construct.\n";
      exit 1;
    else
      filepath=`cd ${cdPath}; pwd`"/${filepath}";
    fi
    echo ${filepath};
  fi
}

# Checks the given header syntax
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

# Checks whether the support file has been initialized, and if not, it is created
# No parameters required
function checkSupportFile {
  if [[ ! -d "${HOME}/${SUPP_PATH}" ]] ; then
    # The config folder does not exists, it needs to be created.
    mkdir ~/${SUPP_PATH}
  fi
  if [[ ! -f "${HOME}/${SUPP_PATH}/${SUPP_FILE_NAME}" ]]; then
    # The support file is not present, it needs to be created.
    printf "# This file is used by the checkHeaders script.\n# In this file are stored the headers checked and the date at which the are checked.\n# Delete this file ONLY if you want to reset the script memory.\n# Format: <filename>_<last check time (yyyymmddHHMMSS)>\n" > ~/${SUPP_PATH}/${SUPP_FILE_NAME}
  fi
}

checkSupportFile;

# Find every headers below the specified dir
headerList=`find "${FIND_PATH}" -regextype 'egrep' -iregex ${PATTERN}`;

#The next part is executed only if find does not have an error.
if [[ $? -eq 0 ]]; then
  echo "Headers found:";
  echo "${headerList}";
  echo "";
  for header in ${headerList}; do
    full_filepath=`expand_curr_dir ${header}`
    fileLine=`fgrep "${full_filepath}" "${supportFile}"`
    if [[ -z "${fileLine}" ]] ; then
      compilationDate=`date ${DATE_FORMAT}`;
      # If there is no file entry in the support file, a new one is appended
      echo ${full_filepath}_${compilationDate} >> ~/${SUPP_PATH}/${SUPP_FILE_NAME}
      checkHeader ${full_filepath};
    else
      lastCompDate=$(echo ${fileLine} | sed 's,'"${full_filepath}"',,' | tail -c +2);
      lastModDate=`date -r ${full_filepath} ${DATE_FORMAT}`;
      # The header is checked again only if it has been modified after the last check
      if [[ ${lastCompDate} -lt ${lastModDate} ]]; then
        checkHeader ${full_filepath};
      else
        printf "Header ${full_filepath} has already been checked after the last edit.\n"
      fi
    fi
  done
fi


### What to add
### Options: 
### --help which prints an usage message
### --only-errors which prints only headers which has errors.
###