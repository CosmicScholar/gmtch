#!/bin/sh
#	$Id: run_gmt_tests.sh,v 1.12 2008-04-15 19:33:27 remko Exp $
#
#	test script for GMT/test directory
#
# Will find all the subdirectories in GMT/test and run all the
# Bourne scripts found in each directory.
# If directory/ies are specified as arguments: will only run scripts in those.

echo "Run test scripts"
echo "------------------------------------------------------------------------------"
echo "Script:                      Purpose                                    STATUS"

# Get all directories below GMT/test and filter out the CVS directories

if [ $# -eq 0 ] ; then
   dirs=`find . -mindepth 1 -maxdepth 1 -type d -print | grep -v CVS`
else
   dirs=$*
fi

# Set here and use it to reset the dir in case a script fails to finish properly
# Each script that fails will write a line to fail_count.d so we can tally errors

rm -f fail_count.d
touch fail_count.d
here=`pwd`
for dir in $dirs; do
	cd $here/$dir
	echo "------------------------------------------------------------------------------"
	echo "Directory: $dir"
	echo "------------------------------------------------------------------------------"
	# Look for Bourne shell scripts
	ls *.sh > /tmp/$$.lis
	if [ -s /tmp/$$.lis ]; then	# Found Bourne shell scripts
		rm -f /tmp/$$.lis
		for script in *.sh; do
			gmtdefaults -Du > .gmtdefaults4
			gmtset PAPER_MEDIA letter
			sh $script
		done
	fi
done
cd $here
echo "------------------------------------------------------------------------------"
wc -l fail_count.d | awk '{printf "GMT test script failures: %d\n", $1}'
cat fail_count.d
rm -f fail_count.d
echo "------------------------------------------------------------------------------"
