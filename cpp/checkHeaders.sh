#!/bin/bash
set -u
set -o pipefail
### Use 'set -x' only for debug purpose
#set -x

#Color scheme setup
GREEN=`tput setaf 2`;
NO_CLR=`tput sgr0`;

### Path settings
#The default path is the current directory
DEFAULT_FIND_PATH="./";
FIND_PATH=${DEFAULT_FIND_PATH};

### Support file settings
SUPP_PATH=".chkHeaders";
SUPP_FILE_NAME="headers";
supportFile="${HOME}/${SUPP_PATH}/${SUPP_FILE_NAME}"

### Compiler settings
# Default compiler is g++, but if it not installed, it can be selected using option "-c gcc"
COMPILER="g++";

### ERROR CODES
ALL_GOOD=0;
NO_FILE_FOUND=1;
BAD_DIRECTORY=3;
WRONG_ARG_NUM=4;
UNKNOWN_OPTION=5;
ARG_NOT_VALID=6;

# Regular expression which returns any file path which has an h, hh, hxx or hpp extension
PATTERN=".*\.h((xx)|(h)|(pp)|())$";

### Date settings
DATE_FORMAT="+%Y%m%d%H%M%S";

### Option settings
# Available options:
# -h              Show Help panel
# -q              Suppress output when header is fine or is not re-checked
# -c <g[cc,++]>   Select compiler   
# -f <filename>   Use <filename> as config file

function print_help {
  echo """  Usage: checkHeaders.sh -h
         checkHeaders.sh [-q] [-c [gcc,g++]] [-f <filename>] <root directory>

  Options:
    -h             Print this message and exit.
    -q             Suppress output when header has no errors or it has not been rechecked.
    -c <gcc,g++>   Select compiler to use.
    -f <filename>  Use <filename> as config file.

  Notes:
    The root directory must be the last argument passed.

  Exit Status:
    0              Success.
    1              'find' found no files in the directory selected.
    3              The specified directory path is malformed.
    4              The number of arguments passed is not congruent to the option specified and the script specifications.
    5              One of the specified option is not known or implemented.
    6              The argument to one of the option is not valid.
""" >&2;
}

# Expands the given path if it starts with "./" to be an absolute path
function expand_curr_dir {
  if [[ ! $# -eq 1 ]]; then
    printf "ERROR: expand_curr_dir does not have 1 argument\n" >&2;
    exit ${WRONG_ARG_NUM};
  else
    filepath=$1;
    # Removes './' from the beginning of the path
    if [[ "${filepath}" = ./* ]]; then
      filepath=`echo -e "${filepath}" | tail -c +3`;
    fi
    
    # Counts the number of times the path has '../'
    numBackDir=`echo ${filepath} | sed 's/\.\.\//&\n/g' | grep '\.\.\/' | wc -l`;

    # The filepath start with a folder and then it goes back,
    if [[ ${numBackDir} -gt 0 && ! ${filepath} = ../* ]]; then
      printf "ERROR: filepath starts with a folder and then goes back with '../'. Please rewrite the path without this construct.\n" >&2; 
      exit ${BAD_DIRECTORY};
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

    if [[ ${iter} -eq 0 ]]; then
      if [[ ! ${filepath} = ~/* ]]; then
        filepath=`pwd`"/${filepath}";
      fi
      # Follows every '../' counted before.
    elif [[ ! ${iter} -eq 0 && ${filepath} = ~/* ]]; then 
      printf "ERROR: filepath starts from home directory back has '../'. Please rewrite the path without this construct.\n";
      exit ${BAD_DIRECTORY};
    else
      filepath=`cd ${cdPath}; pwd`"/${filepath}";
    fi
    echo ${filepath};
  fi
}

# Checks the given header syntax
function checkHeader {
  if [[ ! "$#" -eq 1 ]]; then
    printf "ERROR: No file specified.\n" >&2;
    exit ${WRONG_ARG_NUM};
  else
    current_filepath="$1";
    printf "Checking ${current_filepath} ...\n";
    #Errors are printed anyway if g++ finds one, so this script just confirm when the header is OK.
    ${COMPILER} -fsyntax-only ${full_filepath};    
    if [[ "$?" -eq "0" ]]; then
      printf "[${GREEN}OK${NO_CLR}] File \"${current_filepath}\" has no syntax errors.\n\n";
    fi
    #echo ""
  fi
}

# Checks whether the support file has been initialized, and if not, it is created
# No parameters required
function checkSupportFile {
  if [[ ! -d "${HOME}/${SUPP_PATH}" && "${supportFile}" -eq "${HOME}/${SUPP_PATH}/${SUPP_FILE_NAME}" ]] ; then
    # The config folder does not exists, it needs to be created.
    mkdir ~/${SUPP_PATH}
  fi
  if [[ ! -f "${supportFile}" ]]; then
    # The support file is not present, it needs to be created. The following string is appended inside the file.
    printf "# This file is used by the checkHeaders script.\n# In this file are stored the headers checked and the date at which the are checked.\n# Delete this file ONLY if you want to reset the script memory.\n# Format: <filename>_<last check time (yyyymmddHHMMSS)>\n" > "${supportFile}"
  fi
}

### Option parsing
# Sets the option variables according to options passed or default behavior
while getopts 'hqc:f:' currOption; do
  case "${currOption}" in
    c)  if [[ "${OPTARG}" = gcc || "${OPTARG}" = g++ ]]; then
          COMPILER="$OPTARG";
        else 
          printf "ERROR: Unknown or unsupported compiler.\n" >&2;
          print_help;
          exit ${ARG_NOT_VALID};
        fi
    ;;
    f)  supportFile="${OPTARG}";
    ;;
    q)  exec 1>/dev/null;
    ;;
    h)  print_help; exit ${ALL_GOOD};
    ;;
    ?)  printf "${currOption}: Unknown option.\n" >&2; print_help; exit ${UNKNOWN_OPTION};
    ;;
  esac
done
### End option parsing

#If there is at least one argument left, use the first as the path to run "find" in
if [[ ${OPTIND} -le $# ]]; then
  FIND_PATH=${!OPTIND};
else
  printf "ERROR: Argument list is malformed.\n" >&2;
  exit ${WRONG_ARG_NUM};
fi

checkSupportFile;

# Find every headers below the specified dir
#headerList=();
declare -a headerList;
while IFS= read -d $'\0' -r header ; do
     headerList=("${headerList[@]}" "$header");
done < <(find "${FIND_PATH}" -regextype 'egrep' -iregex ${PATTERN} -print0);
#echo "${headerList[@]}"
 
#headerList=`find "${FIND_PATH}" -regextype 'egrep' -iregex ${PATTERN}`;

#The next part is executed only if find does not have an error.
if [[ $? -eq 0 ]]; then
  printf "Headers found:\n";
  printf '%s\n' "${headerList[@]}";
  printf "\n";
  for header in "${headerList[@]}" ; do
    full_filepath=`expand_curr_dir "${header}"`;
    #echo ${full_filepath}
    fileLine=`fgrep "${full_filepath}" "${supportFile}"`;
    #printf "$fileLine\n"
    if [[ -z "${fileLine}" ]] ; then
      compilationDate=`date ${DATE_FORMAT}`;
      # If there is no file entry in the support file, a new one is appended
      echo "${full_filepath}_${compilationDate}" >> "${supportFile}";
      checkHeader "${full_filepath}";
    else
      lastCompDate=$(echo "${fileLine}" | sed 's,'"${full_filepath}_"',,');
      lastModDate=`date -r ${full_filepath} ${DATE_FORMAT}`;
      # The header is checked again only if it has been modified after the last check
      if [[ "${lastCompDate}" -lt "${lastModDate}" ]]; then
        checkHeader ${full_filepath};
      else
        printf "Header ${full_filepath} has already been checked after the last edit.\n"
      fi
    fi
  done
else
  printf "ERROR:  No header file found in this directory and its children.\n" >&2;
  exit ${NO_FILE_FOUND};
fi
