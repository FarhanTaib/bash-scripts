#!/bin/ksh
#########################################################################
# NAME: list_files.ksh
# PURPOSE: To list the TOP 10 biggest files and top 10 biggest folders 
#		
#          		 
#			 
#          USAGE: ./script <FILESYSTEM> [REPORT MODE]
# AUTHOR(s): Alejandro Cubero Mora (alejandro.cubero@hp.com)
# DATE WRITTEN: Dic 2013
##########################################################################
#CHANGELOG
# Dic 2013: display of top 10 largest files on a give filesystem
# March 2014:  Number of files to display and its size can now be set as a parameter
# Sept 2014: New algorithm to gather list of folders implemented to solve various issues 
# Oct 2013: Added support for AIX
#########################################################################
#Validating OS we are running on
OS=`uname`
if [ $OS != "Linux" -a $OS != "HP-UX" -a $OS != AIX -a $OS != SunOS ] ;then
	echo "OS `uname` not supported"
	exit 0
fi
#########################################################################

if [ "$1" = "-h" ];then
	printf '\n%s\n' "Usage: $0 <FILESYSTEM> [-f] [-s] "
	printf '\n\t%s\n' "- Remember that <FILESYSTEM> parameter is mandatory"
	printf '\t%s\n' "-f is the number of files and folders to display. If not specified it will display TOP 10 files and TOP 10 folders."
	printf '\t%s\n' "-s is the minimum size in MB of the files or folders you want to display. Default is 5MB"
	printf '\n%s\n\n' "Example: $0 /var/tmp -f 5 -s 10"
	exit 0
fi


if [[ $# -ne 1 &&  $# -ne 2 &&  $# -ne 3 &&  $# -ne 4 &&  $# -ne 5 ]]; then
	echo "Incorrect script usage" 
	echo "Correct usage is: "  
	echo "$0 <FILESYSTEM> [-f] [-s]"
	echo "Run $0 -h for help"
	exit 0
fi

#########################################################################
#Assigning Parameter values
while [[ $# -gt 0 ]]
do
	case $1 in
		/*)
		FILESYSTEM=$1
		;;
		-f)
		NUM_FILES=$2
		;;
		-s)
		let "SIZE=$2*1024"
		DISPLAY_SIZE=$2
		;;
		*)
		
		;;
	esac
	shift
done

#Setting default parameters if required
if [[ $NUM_FILES = "" ]]
	then NUM_FILES=10
fi 
#SIZE
if [[ $SIZE = "" ]]
then 
	SIZE=5120
	DISPLAY_SIZE=5
fi

#########################################################################

if [ ! -d $FILESYSTEM ];then
	printf '\n%s\n' "Filesystem $FILESYSTEM does not exist in the server... exiting"
	exit 0
fi

#########################################################################
#Resetting output files
> /tmp/folders_list1
> /tmp/folders_list1_filtered
> /tmp/folders_list2
> /tmp/folders_list
> /tmp/files_list1
> /tmp/files_list
> /tmp/files
#########################################################################
#Dividers that will be used for layout purposes
divider===============================================================================
divider2=------------------------------------------------------------------------------
#########################################################################
#FUNTION DEFINITIONS 

print_list()
{
	echo $divider		
	printf '%-13s %-19s %-14s %-20s\n' "Size" "Modification" "Owner" "Filename" 
	echo $divider
	LIST="$1"
	if [[ -s $LIST ]] ; then
		cat $LIST |while read line;do
			FILENAME=`echo "$line" | awk '{for(i=2;i<=NF;++i) printf("%s ",  $i);}'`
			SIZE=`echo "$line" | awk '{print $1}'`
			#Second variable required to remove garbage character that cause the ls command to fail on filenames containing spaces"
			FILENAME2="`echo $FILENAME`"
			OWNER=`ls -ld "$FILENAME2"  | awk ' {print $3} '`
			MOD_DATE=`ls -ld "$FILENAME2"  | awk ' {print $6" "$7" "$8} '`
			printf '%-13s %-19s %-14s %-20s\n' "$SIZE" "$MOD_DATE" "$OWNER" "$FILENAME" 
		done
		printf '\n'
	else
		echo "-----No files found-----"
	fi
}


find_files_size()
{
	case $OS in
		Linux)
			find $FILESYSTEM -xdev -type f -size +${SIZE}k -ls|sort -rn -k7 |head -$NUM_FILES |awk '{for(i=11;i<=NF;++i) printf("%s ",$i); printf "\n"}' > /tmp/files 2>/dev/null
		;;
		SunOS | AIX)
			let "SIZE2=$SIZE*2"
			find $FILESYSTEM -xdev -type f -size +${SIZE2} -ls|sort -rn -k7 |head -$NUM_FILES |awk '{for(i=11;i<=NF;++i) printf("%s ",$i); printf "\n"}' > /tmp/files 2>/dev/null
		;;
		HP-UX)
			let "SIZE2=$SIZE*2"
			find $FILESYSTEM -xdev -type f -size +${SIZE2} -exec ls -l {} \;|sort -rn -k5 |head -$NUM_FILES |awk '{for(i=9;i<=NF;++i) printf("%s ",$i); printf "\n"}' > /tmp/files 2>/dev/null
		;;
	esac
	
	case $OS in 
		Linux)
		cat /tmp/files |while read line
			do
				ls -lh "$line" |awk '{printf $5"\t";for(i=9;i<=NF;++i) printf("%s ",  $i); printf "\n"}' >> /tmp/files_list
			done
		;;
		SunOS | HP-UX | AIX)
			cat /tmp/files |while read line
			do
				ls -l "$line" |awk '{printf $5"\t";for(i=9;i<=NF;++i) printf("%s ",  $i); printf "\n"}' >> /tmp/files_list1
			done
			
			cat /tmp/files_list1 |while read line
			do
			#Convert to Megabytes
				SIZE_FILE=`echo "$line" | awk '{print $1}' | tr -d '[A-Z]'`
				let SIZE_M=$SIZE_FILE/1024/1024
				echo "${SIZE_M}M `echo $line |awk '{print $2}'`" >> /tmp/files_list
			done
		;;
		
	esac
}

du_folders()
{
BLOCK_DEVICE=`df $FILESYSTEM |awk '{print $1}'|grep ^/`
#echo "Block device is $BLOCK_DEVICE"

#Gathering a list of directories 
for i in `ls $FILESYSTEM`;do
        if [ -d "${FILESYSTEM}/${i}" ];then
                echo "${FILESYSTEM}/${i}" | sed 's/\/\//\//' >> /tmp/folders_list1
        fi
done

#Filtering to include only directories in the same block device
for i in `cat /tmp/folders_list1`;do
	#echo "checking $i"
	BLOCK_DEVICE2=`df $i |awk '{print $1}'|grep ^/`
	#echo $BLOCK_DEVICE2
	if [ "$BLOCK_DEVICE" = "$BLOCK_DEVICE2" ];then
			#echo "same device for $i"
			echo $i >> /tmp/folders_list1_filtered
	fi
done

	case $OS in
		Linux)
			du -xsBk `cat /tmp/folders_list1_filtered` |sort -rn |head -$NUM_FILES > /tmp/folders_list2
		;;
		SunOS)
			/usr/xpg4/bin/du -xsk `cat /tmp/folders_list1_filtered` |sort -rn |head -$NUM_FILES > /tmp/folders_list2
		;;
		HP-UX)
			du -xsk `cat /tmp/folders_list1_filtered` |sort -rn |head -$NUM_FILES > /tmp/folders_list2
		;;
	esac
	#Restrict the output of folders based on minimum size specified by the User
	cat /tmp/folders_list2 |while read line
		do
			SIZE_FILE=`echo "$line" | awk '{print $1}' | tr -d '[A-Z]'`
			if [[ $SIZE_FILE -ge $SIZE ]]
			then 
	#Convert to Megabytes
				let SIZE_M=$SIZE_FILE/1024
				echo "${SIZE_M}M `echo $line |awk '{print $2}'`" >> /tmp/folders_list
			fi
		done
}

current_fs_utilization()
{
	case $OS in
		Linux|AIX|HP-UX)
			CURRENT=`df -kP $FILESYSTEM |tail -1| awk -F" " '{print $(NF-1)}'|sed s/.$//`
			USED_SIZE=`df -kP $FILESYSTEM |grep ^/ | awk '{ USED_SIZE=$3/1024/1024; print USED_SIZE }'`
			TOTAL_SIZE=`df -kP $FILESYSTEM |grep ^/ | awk '{ TOTAL_SIZE=$2/1024/1024; print TOTAL_SIZE }'`
		;;
		SunOS)
			CURRENT=`/usr/xpg4/bin/df -kP $FILESYSTEM |tail -1| awk -F" " '{print $(NF-1)}'|sed s/.$//`
			USED_SIZE=`/usr/xpg4/bin/df -kP $FILESYSTEM |grep ^/ | awk '{ USED_SIZE=$3/1024/1024; print USED_SIZE }'`
			TOTAL_SIZE=`/usr/xpg4/bin/df -kP $FILESYSTEM |grep ^/ | awk '{ TOTAL_SIZE=$2/1024/1024; print TOTAL_SIZE }'`
		;;
	esac
	printf '%s\n' "Filesystem $FILESYSTEM current usage is $CURRENT% (Approx. ${USED_SIZE} GB used out of ${TOTAL_SIZE} GB)"
	printf '\n'
}

delete_tmp_files()
{
rm /tmp/folders_list1 /tmp/folders_list1_filtered /tmp/folders_list2 /tmp/folders_list /tmp/files_list1 /tmp/files_list /tmp/files
}


#######################################################################
#TOP N REPORT
echo $divider2
echo "Server: `uname -n`"
echo "Date: `date`"
current_fs_utilization
echo $divider2
find_files_size
du_folders
#######################################################################
#Printing List of files
printf '\n%s\n' "TOP $NUM_FILES BIGGEST FILES (Above ${DISPLAY_SIZE}MB)"
print_list /tmp/files_list
echo $divider2
#######################################################################
#Printing List of folders
printf '\n%s\n' "TOP $NUM_FILES BIGGEST FOLDERS (Above ${DISPLAY_SIZE}MB)"
print_list /tmp/folders_list
echo $divider2
delete_tmp_files
exit 0


#12:19 06/10/14
