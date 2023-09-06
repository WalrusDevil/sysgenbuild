#
#	Copyright (C) 2023 WalrusDevil
#
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program. If not, see <https://www.gnu.org/licenses/>. 
#
#
LICENSE="#\n#\tThis program is free software: you can redistribute it and/or modify\n#\tit under the terms of the GNU General Public License as published by\n#\tthe Free Software Foundation, either version 3 of the License, or\n#\t(at your option) any later version.\n#\n#\tThis program is distributed in the hope that it will be useful,\n#\tbut WITHOUT ANY WARRANTY; without even the implied warranty of\n#\tMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n#\tGNU General Public License for more details.\n#\n#\tYou should have received a copy of the GNU General Public License\n#\talong with this program. If not, see <https://www.gnu.org/licenses/>.\n#\n#"
TOPDIR=$PWD
SRC=build #directories inside of this directory should include the source code for compilation, ex: the output of 'ls $SRC/bash' should include the files 'Makefile', 'README', 'INSTALL', 'COPYING', 'configure.ac', 'configure'
BDIR=object #instead of building inside of the source directory building will occur in this subdirectory #TODO not all projects support this and some require it
SYSCP=sysconfigure #prefix used for SYSCSH and SYSCCONF, instead of individually setting the name for the output shell and config file you can just set the prefix, ex: if SYSCP=file, then SYSCSH=file.sh and SYSCCONF=file.conf.sh
SYSCSH=$SYSCP.sh #name for output shell script that runs configuration for projects inside of $SRC
SYSCCONF=$SYSCP.conf.sh #name for config script. used when outputting the shell script
SYSMP=sysmake #prefix used for SYSMSH and SYSMCONF
SYSMSH=$SYSMP.sh #name for output shell script
SYSMCONF=$SYSMP.conf.sh #name for the config script
#TODO add support for different build systems; add support for DENYing directories; add install script; fix how variables work (allow user to override on command line), make documentation
#check arguments
argi=1
for arg in $@;do
	argi=$(($argi + 1))
	if [[ $arg == "-h" ]];then
		DONOTHING=1
		echo -e "arguments:\n'-h'\t\tprint help\n'-c FILE'\tset a config file to use\n'-d DOC'\t\tprint documentation, without a DOC it will list available DOCs, if you want to use an example file you can use '>' to pipe output to create the file, ex: '$0 -d base.conf.sh > base.conf.sh', this will overwrite files without warning so be careful"
	fi
	if [[ $arg == "-d" ]];then
		DONOTHING=1
		if [[ ${!argi} == "" ]];then
			echo -e "available documentation:\n\tconfiguration\n\texample files:\n\t\tbase.conf.sh"
		else
			case ${!argi} in
				"base.conf.sh") echo -e "$LICENSE\n#example conf file for building a minimal base system\n#if your folders does not match the names listed either copy them or link them to the names showed\nALLOW=(\"bash\" \"binutils\" \"util-linux\" \"coreutils\" \"ncurses\" \"glibc\")\n${SRC}ncursesCAFLAGS=\"--enable-widec --with-shared\"";;
				"configuration") echo -e "#what you can configure and how to do it\nALLOW:\n\tALLOW - global, CALLOW - used for SYSCSH, MALLOW - used for SYSMSH\n\tshould be an array of strings, ex: ALLOW=(\"bash\" \"ncurses\")\n\tonly directories that are in included in this array will be factored into the outputted bash-scripts\n\tshould be useful for making system presets\nDENY:\n\t#not inplemented yet\n\tDENY - global, CDENY - used for SYSCSH, MDENY - used for SYSMSH\n\tshould be an array of strings, ex: DENY=(\"gcc\" \"xorg\")\n\tdirectories included in this array will not be factored into the outputted bash-scripts\n\tshould be useful for things you probaly dont want to recompile like gcc";;
				*) echo "not an available documentation";;
			esac
		fi
	fi
	if [[ $arg == "-c" ]];then
		if [[ -f ${!argi} ]];then
			source ./${!argi}
		else
			DONOTHING=1
			echo "ERROR: file ${!argi} given to '-c' does not exist"
		fi
	fi
done
#generate configure script
function genconfiguresh ()
(
	function genconfigureshsub ()
	{	
		if [[ ! -d $dir ]];then
			echo "WARNING: ignoring $dir as is it does not exsist"
		else
			if [[ -f $dir/configure ]]; then	
				if [[ -f $dir/$BDIR ]]; then
					mkdir $dir/$BDIR
				fi
				dirPFLAGS="$(echo $dir | tr -dc '[:alnum:]')CPFLAGS"
				dirAFLAGS="$(echo $dir | tr -dc '[:alnum:]')CAFLAGS"
				echo -e "#$dir\n#$dirPFLAGS\n#$dirAFLAGS" >> $SYSCSH
				if [[ ! ${!dirPFLAGS} == "" ]];then
					dirPFLAGS="${!dirPFLAGS}"
				else
					dirPFLAGS=""
				fi
				if [[ ! ${!dirAFLAGS} == "" ]];then
					dirAFLAGS="${!dirAFLAGS}"
				else
					dirAFLAGS=""
				fi
				echo "$CONFPFLAGS $dirPFLAGS echo "\"\#configuring $dir\""; cd $dir/$BDIR; ../configure $CONFAFLAGS $dirAFLAGS; cd $TOPDIR" >> $SYSCSH
			else
				echo "WARNING: ignoring $dir as it does not use ./configure"
			fi
		fi
	}
	echo -e "$LICENSE\n#DO NOT EDIT, CHANGES WILL BE DESTROYED\n#bash-script that was auto-generated by $0\n#if you need to add configuration make a file named $SYSCCONF\n#$SYSCCONF should be a bash-script declaring variables\n#when you edit the config file you must rerun $0" > $SYSCSH
	if [[ -f ./$SYSCCONF ]]; then
		source ./$SYSCCONF
 		ISCONF=1
	fi
	if [[ $CALLOW == "" && $ALLOW == "" ]];then
		for dir in ./$SRC/*; do
			genconfigureshsub
		done
	else
		if [[ ! $CALLOW == "" ]];then
			CALLOW=("${CALLOW[@]/#/./$SRC/}") #TODO make this better, and prevent duplicates
			for dir in ${CALLOW[@]};do
				genconfigureshsub
			done
		fi
		if [[ ! $ALLOW == "" ]];then
			ALLOW=("${ALLOW[@]/#/./$SRC/}")
			for dir in ${ALLOW[@]};do
				genconfigureshsub
			done
		fi
	fi
)
#generate make script
function genmakesh ()
(
	function genmakeshsub ()
	{
		if [[ ! -d $dir ]];then
			echo "WARNING: ignoring $dir as is does not exsist"
		else
			if [[ -f $dir/configure ]];then #TODO add more support
				ISMAKE=1
			elif [[ -f $dir/Makefile ]];then
				ISMAKE=1
			else
				ISMAKE=0
			fi
			if [[ $ISMAKE -eq 1 ]];then
				if [[ ! -d $dir/$BDIR ]];then
					mkdir $dir/$BDIR
				fi
				dirPFLAGS="$(echo $dir | tr -dc '[:alnum:]')MPFLAGS"
				dirAFLAGS="$(echo $dir | tr -dc '[:alnum:]')MAFLAGS"
				echo -e "#$dir\n#$dirPFLAGS\n#$dirAFLAGS" >> $SYSMSH
				if [[ ! ${!dirPFLAGS} == "" ]];then
					dirPFLAGS="${!dirPFLAGS}"
				else
					dirPFLAGS=""
				fi
				if [[ ! ${!dirAFLAGS} == "" ]];then
					dirAFLAGS="${!dirAFLAGS}"
				else
					dirAFLAGS=""
				fi
				echo "$CONFPFLAGS $dirPFLAGS echo "\"\#making $dir\""; cd $dir/$BDIR; make $dirAFLAGS; cd $TOPDIR" >> $SYSMSH #change command to be variable-based to allow support for more build systems
			else
				echo "WARNING: ignoring $dir as it is not a recogized build system"
			fi
		fi
	}
	echo -e "$LICENSE\n#DO NOT EDIT, CHANGES WILL BE DESTROYED\n#bash-script that was auto-generated by $0\n#if you need to add configuration make a file named $SYSMCONF\n#$SYSMCONF should be a bash-script declaring variables\n#when you edit the config file you must rerun $0" > $SYSMSH
	if [[ -f ./$SYSMCONF ]];then
		source ./$SYSMCONF
		ISCONF=1
	else
		ISCONF=0
	fi
	if [[ $MALLOW == "" && $ALLOW == "" ]];then
		for dir in ./$SRC/*; do
			genmakeshsub
		done
	else
		if [[ ! $MALLOW == "" ]];then
			MALLOW=("${MALLOW[@]/#/./$SRC/}") #TODO make this better, and prevent duplicates
			for dir in ${MALLOW[@]};do
				genmakeshsub
			done
		fi
		if [[ ! $ALLOW == "" ]];then
			ALLOW=("${ALLOW[@]/#/./$SRC/}")
			for dir in ${ALLOW[@]};do
				genmakeshsub
			done
		fi
	fi
)
if [[ $DONOTHING -eq 1 ]];then
	true
else
	genconfiguresh
	genmakesh
fi
