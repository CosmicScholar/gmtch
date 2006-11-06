#!/bin/sh
#	$Id: make_math.sh,v 1.3 2006-11-06 20:36:58 remko Exp $

# This script puts together Xmath.h from Xmath.c and Xmath.func
# To be run from the main GMT directory.  X is either grd or gmt.
#
# Usage: make_math.sh grd|gmt [-s]
# -s for silent operation

prefix=$1
gush=1
if [ $# = 2 ]; then	# Passed optional second argument (-s) to be silent
	gush=0
fi
PRE=`echo $prefix | awk '{print toupper($1)}'`
n_op=`grep "#define ${PRE}MATH_N_OPERATORS" ${prefix}math.c | awk '{print $3}'`

if [ $gush = 1 ]; then
	echo "Making ${prefix}math_def.h"
fi
rm -f ${prefix}math_def.h

# First take out header records for simplicity

grep -v "^#" ${prefix}math.func > $$.txt
n_actual=`cat $$.txt | wc -l`

if [ $n_actual -ne $n_op ]; then
	echo "You must first set ${PRE}MATH_N_OPERATORS to $n_actual in ${prefix}math.c"
	exit
fi

# Add backward compability

cat << EOF > ${prefix}math_def.h
/*--------------------------------------------------------------------
 *
 *	${prefix}math_def.h [Generated by make_math.sh]
 *
 *	Copyright (c) 1991-2006 by P. Wessel and W. H. F. Smith
 *	See COPYING file for copying and redistribution conditions.
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; version 2 of the License.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	Contact info: gmt.soest.hawaii.edu
 *--------------------------------------------------------------------*/
/*	${prefix}math_def.h is automatically generated by make_math.sh;
 *	Do NOT edit manually!
 *
 * For backward compatibility:
 */

EOF
awk '{ if ($1 == "ADD") {printf "#define ADD\t%d\n", NR-1} \
	else if ($1 == "DIV") {printf "#define DIV\t%d\n", NR-1} \
	else if ($1 == "MUL") {printf "#define MUL\t%d\n", NR-1} \
	else if ($1 == "POW") {printf "#define RAISE\t%d\t/* (POW) */\n", NR-1} \
	else if ($1 == "SUB") {printf "#define SUB\t%d\n", NR-1}}' $$.txt >> ${prefix}math_def.h
echo "" >> ${prefix}math_def.h

# Add function declarations

echo "/* Declare all functions to return int */" >> ${prefix}math_def.h
echo "" >> ${prefix}math_def.h
if [ $1 = "gmt" ]; then
	awk '{ printf "void table_%s(struct GMTMATH_INFO *info, double **stack[], BOOLEAN *constant, double *factor, int last, int start, int n);\t\t/* id = %2.2d */\n", $1, NR-1}' $$.txt >> ${prefix}math_def.h
else
	awk '{ printf "void grd_%s(struct GRDMATH_INFO *info, float *stack[], BOOLEAN *constant, double *factor, int last);\t\t/* id=%2.2d */\n", $1, NR-1}' $$.txt >> grdmath_def.h
fi
echo "" >> ${prefix}math_def.h

# Define operator array
echo "/* Declare operator array */" >> ${prefix}math_def.h
echo "" >> ${prefix}math_def.h
echo "char *operator[${PRE}MATH_N_OPERATORS] = {" >> ${prefix}math_def.h
awk '{ if (NR < '$n_op') {printf "\t\"%s\",\t\t/* id = %2.2d */\n", $1, NR-1} else {printf "\t\"%s\"\t\t/* id = %2.2d */\n", $1, NR-1}}' $$.txt >> ${prefix}math_def.h
echo "};" >> ${prefix}math_def.h
echo "" >> ${prefix}math_def.h

# Make usage explanation include file

rm -f ${prefix}math_explain.h
if [ $gush = 1 ]; then
	echo "Making ${prefix}math_explain.h"
fi
cat << EOF > ${prefix}math_explain.h
/*--------------------------------------------------------------------
 *
 *	${prefix}math_explain.h [Generated by make_math.sh]
 *
 *	Copyright (c) 1991-2006 by P. Wessel and W. H. F. Smith
 *	See COPYING file for copying and redistribution conditions.
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; version 2 of the License.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	Contact info: gmt.soest.hawaii.edu
 *--------------------------------------------------------------------*/
/*	${prefix}math_explain.h is automatically generated by make_math.sh;
 *	Do NOT edit manually!
 *
 */
EOF
awk '{ \
	printf "\t\tfprintf (stderr, \"\t%s\t%d\t%s", $2, $3, $5; \
	for (i = 6; i <= NF; i++) printf " %s", $i; \
	printf "\\n\");\n" \
}' $$.txt | sed -e 's/%/%%/g' >> ${prefix}math_explain.h

# Make ${prefix}math_init function

if [ $gush = 1 ]; then
	echo "Making ${prefix}math.h"
fi
cat << EOF > ${prefix}math.h
/*--------------------------------------------------------------------
 *
 *	${prefix}math.h [Generated by make_math.sh]
 *
 *	Copyright (c) 1991-2006 by P. Wessel and W. H. F. Smith
 *	See COPYING file for copying and redistribution conditions.
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; version 2 of the License.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	Contact info: gmt.soest.hawaii.edu
 *--------------------------------------------------------------------*/
/*	${prefix}math.h is automatically generated by make_math.sh;
 *	Do NOT edit manually!
 */

void ${prefix}math_init (PFV ops[], int n_args[], int n_out[])
{

	/* Operator function		# of operands  		# of outputs */

EOF
if [ $1 = "gmt" ]; then
	awk '{ printf "\tops[%d] = table_%s;\t\tn_args[%d] = %d;\t\tn_out[%d] = %d;\n", NR-1, $1, NR-1, $3, NR-1, $4}' $$.txt >> ${prefix}math.h
else
	awk '{ printf "\tops[%d]=grd_%s;\t\tn_args[%d]=%d;\t\tn_out[%d]=%d;\n", NR-1, $1, NR-1, $3, NR-1, $4}' $$.txt >> grdmath.h
fi
echo "}" >> ${prefix}math.h

# Make man page explanation include file
# Make sed script file used to produce even columns in grdmath or gmtmath.
cat << EOF > $$.sed
s/ACOSH\\fP	/ACOSH\\fP/g;
s/ADD(+)\\fP	/ADD(+)\\fP/g;
s/ASINH\\fP	/ASINH\\fP/g;
s/ATAN2\\fP	/ATAN2\\fP/g;
s/ATANH\\fP	/ATANH\\fP/g;
s/CDIST\\fP	/CDIST\\fP/g;
s/CHICRIT\\fP	/CHICRIT\\fP/g;
s/CHIDIST\\fP	/CHIDIST\\fP/g;
s/D2DX2\\fP	/D2DX2\\fP/g;
s/D2DY2\\fP	/D2DY2\\fP/g;
s/DILOG\\fP	/DILOG\\fP/g;
s/DIV(\/)\\fP	/DIV(\/)\\fP/g;
s/ERFINV\\fP	/ERFINV\\fP/g;
s/EXTREMA\\fP	/EXTREMA\\fP/g;
s/FCRIT\\fP	/FCRIT\\fP/g;
s/FDIST\\fP	/FDIST\\fP/g;
s/FLOOR\\fP	/FLOOR\\fP/g;
s/GDIST\\fP	/GDIST\\fP/g;
s/HYPOT\\fP	/HYPOT\\fP/g;
s/ISNAN\\fP	/ISNAN\\fP/g;
s/LMSSCL\\fP	/LMSSCL\\fP/g;
s/LOG10\\fP	/LOG10\\fP/g;
s/LOG1P\\fP	/LOG1P\\fP/g;
s/LOWER\\fP	/LOWER\\fP/g;
s/LSQFIT\\fP	/LSQFIT\\fP/g;
s/MUL(x)\\fP	/MUL(x)\\fP/g;
s/NRAND\\fP	/NRAND\\fP/g;
s/POW(^)\\fP	/POW(^)\\fP/g;
s/STEPT\\fP	/STEPT\\fP/g;
s/STEPX\\fP	/STEPX\\fP/g;
s/STEPY\\fP	/STEPY\\fP/g;
s/SUB(-)\\fP	/SUB(-)\\fP/g;
s/TCRIT\\fP	/TCRIT\\fP/g;
s/TDIST\\fP	/TDIST\\fP/g;
s/UPPER\\fP	/UPPER\\fP/g;
s/ZCRIT\\fP	/ZCRIT\\fP/g;
EOF

if [ $gush = 1 ]; then
	echo "Making ${prefix}math_man.i"
fi
awk '{ \
	printf "\\fB%s\\fP\t\t%d\t%s", $2, $3, $5; \
	a = index($5,sprintf("%c",39)); \
	for (i = 6; i <= NF; i++) \
	{ \
		printf " %s", $i; \
		if(index($i,sprintf("%c",39))) ++a; \
	} \
	if(a) printf "\\\"%c",39; \
	printf "\n.br\n" \
}' $$.txt | sed -f $$.sed  > ${prefix}math_man.i

rm -f $$.txt $$.sed
