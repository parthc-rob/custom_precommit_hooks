#!/bin/bash

# Author: github.com/parthc-rob
# Date: 2024-08-30
# This script checks for forbidden dependencies in a monorepo


# Initialize our own variables
DIRECTORY="alpha"

# Parse command line arguments
while getopts ":a:" opt; do
  case $opt in
    a)
      DIRECTORY=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# export MONOREPO_ROOT=$(echo $MONOREPO_ROOT)

# Uncomment to use MONOREPO_ROOT from environment
# if [ -z "$MONOREPO_ROOT" ]; then
#     echo -e "\n \t ---- MONOREPO_ROOT not found in environment!!"
#     echo -e "\n \t ---- Set this in a terminal using \nexport MONOREPO_ROOT=/path/to/BaseRepo4\n"
#     exit 1
# fi
# echo -e "\n \t ---- MONOREPO_ROOT found at $MONOREPO_ROOT"
MONOREPO_ROOT=$(pwd)

echo -e "\n \t ---- Checking for forbidden dependencies on $MONOREPO_ROOT/$DIRECTORY/ files in paths outside $DIRECTORY/ \n"

# In case you need to only run this on git-tracked files, use
# git ls-files -- "$(pwd)/*.py"

# Find all .py files outside the alpha directory that import something from alpha
cd $MONOREPO_ROOT
PY_FILES=$(find ./ -not -path "./$DIRECTORY/*" -wholename '**/*.py' -type f 2>/dev/null)
BAZEL_FILES=$(find ./ -not -path "./$DIRECTORY/*" -wholename '**/*.bazel' -type f 2>/dev/null)


RED='\033[0;31m'
NC='\033[0m' # No Color

# print count of files found
echo "Found $(echo $PY_FILES | wc -w) .py files"
echo "Found $(echo $BAZEL_FILES | wc -w) .bazel files"

IS_FORBIDDEN=false
for FILE in $PY_FILES; do
	if grep -Hn "from $DIRECTORY" $FILE; then
		echo -e "${RED}\n Error: $FILE imports from $DIRECTORY${NC}"
		IS_FORBIDDEN=true
	fi
	if grep -Hn "import $DIRECTORY" $FILE; then
		echo -e "${RED}\n Error: $FILE imports from $DIRECTORY${NC}"
		IS_FORBIDDEN=true
	fi
	if grep -Hn "alpha" $FILE; then
		echo -e "${RED}\n Error: $FILE imports from $DIRECTORY${NC}"
		IS_FORBIDDEN=true
	fi
done

for FILE in $BAZEL_FILES; do
	# if grep -q -e "alpha/" -e "alpha:" -e "//alpha" $FILE; then
	if grep -Hn "alpha" $FILE; then
		echo -e "${RED}\n Error: $FILE imports from $DIRECTORY${NC}"
		IS_FORBIDDEN=true
	fi
done

if $IS_FORBIDDEN; then

	echo -e "${RED} \n----- !!!!!!!!! Forbidden dependencies found by find_alpha_dependencies.sh -----${NC}"
	exit 1
fi
# If the script hasn't exited by now, there are no forbidden dependencies
echo -e "\n ---- No forbidden dependencies found by find_alpha_dependencies.sh ----\n"
exit 0
