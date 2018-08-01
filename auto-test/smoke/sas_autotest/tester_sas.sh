#!/bin/bash

TESTER_SAS_TOP_DIR=$(cd "`dirname $0`" ; pwd)

# Load common function
#. ${TESTER_SAS_TOP_DIR}/config/sas_test_config
#. ${TESTER_SAS_TOP_DIR}/config/sas_test_lib

# Load the public configuration library
#. ${TESTER_SAS_TOP_DIR}/../config/common_config

T_SERVER_IP=''
T_CLIENT_IP=''
T_CTRL_NIC=''
T_PICK_CASEC=''
T_CIP=''
T_PRE=''


checklist()
{
  list=""
#  file=`cat ${TESTER_SAS_TOP_DIR}/data/sas_test_case.table` # | while read line
  while read line
  do
    TMP_TITLE=`echo "$line" | awk -F '|' '{print $2}'`
    TMP_FUNC=`echo "$line" | awk -F '|' '{print $7}'`
    list=$list"${TMP_TITLE} ${TMP_FUNC}"
    TMP_SW=`echo "$line" | awk -F '|' '{print $8}'`
    if [ x"$TMP_SW" = x"on" ];then
        list=$list" ON "
    else
        list=$list" OFF "
    fi
  done < ${TESTER_SAS_TOP_DIR}/data/sas_test_case.table
  #echo $list
  TABLE_LIST=$( whiptail --nocancel --title "Test Case List" --checklist \
  "Choose test case you want to run this time:" 15 120 8 $list 3>&1 1>&2 2>&3)

  if [ $? -eq 0 ];then
	  echo "The choosen list is $TABLE_LIST"
  else
	echo "choose cancel"
  fi

  touch table
  while read line
  do
    TMP_TITLE=`echo "$line" | awk -F '|' '{print $2}'`
    TMP_SW=`echo "$line" | awk -F '|' '{print $8}'`
    tmp=$line
    if [[ $TABLE_LIST =~ $TMP_TITLE ]];then
        if [ x"$TMP_SW" = x"off" ];then
           tmp=`echo ${line%|*}`
           tmp=$tmp"|on"
        fi
    else
        if [ x"$TMP_SW" = x"on" ];then
            tmp=`echo ${line%|*}`
            tmp=$tmp"|off"
        fi
    fi
    echo $tmp >> table 
  done < ${TESTER_SAS_TOP_DIR}/data/sas_test_case.table
  sed -i 's/ /|/g'  table
  mv table ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/sas/

  }
###################################################################################
#Usage
###################################################################################

Usage()
{
cat <<EOF
Usage: ./sas_autotest/tester_sas.sh [options]
Options:
	-h, --help: Display this information
	-t, --test: the tester name .if other cfg is not set,
		    tester name can help to get latest cfg you used
		    this para is forced to be set.
   	-p, --pickcase: true : pick the case using UI 
   	-f, --forcepre: true : force to run pre_main
Example:
	bash tester_sas.sh -t luojiaxing -p true

	bash tester_sas.sh -t luojiaxing # if no other para,scripts will use the latest user cfg

EOF
}

##################################################################################
#Get all args
###################################################################################
echo -e "\033[5;35m Welcom to Use Plinth Test Suite! \033[0m"
cat << EOF
------------/\-------------
-----------/  \-------------
          /    \\
EOF

echo -e "\033[33m Luojiaxing \033[0m  \033[32m Chenjing \033[0m "

echo "  "
echo ">---------------------------------------------------------<"
echo "Thank you to ALL tester for providing high quality scripts!"
echo -e "Tester: \033[34m hehui\033[0m \033[35m  chenliangfei\033[0m "
echo ">---------------------------------------------------------< "
echo "  "

if [ ! -n "$1" ];then
	Usage
	exit 1
fi

while test $# != 0
do
	case $1 in
		--*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ; ac_shift=: ;;
		-*) ac_option=$1 ; ac_optarg=$2; ac_shift=shift ;;
		*) ac_option=$1 ; ac_shift=: ;;
	esac

	case $ac_option in
        	-h | --help) Usage ; exit 0 ;;
        -p | --pickcase) T_PICK_CASE=$ac_optarg ;;
     #   	-n | --ctrlNIC) T_CTRL_NIC=$ac_optarg ;;
		-t | --tester) T_TESTER=$ac_optarg ;;
		-c | --clientip) T_CIP=${ac_optarg};;
		-f | --forcepre) T_PRE=$ac_optarg;;
		*) Usage ; echo "Unknown option $1"; exit 1 ;;
	esac

	$ac_shift
	shift
done

##################################################################################
#input the parameter
###################################################################################

trap '' INT

if [ x"$T_TESTER" = x"" ];then
	echo "Tester name is not input!Please input it use -t..."
	exit 1
fi

. ${TESTER_SAS_TOP_DIR}/../config/common_config
. ${TESTER_SAS_TOP_DIR}/../config/common_lib
##################################################################################
#Get latest cfg pass to empty patameter
###################################################################################
mkdir -p ${PLINTH_TEST_WORKSPACE}

if [ x"$T_PICK_CASE" = x"true" ];then
    checklist
fi

if [ -f ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/sas/table ];then
    cp ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/sas/table ${TESTER_SAS_TOP_DIR}/data/sas_test_case.table
else
    echo ">--------------------------------------------------------------------------------<"
    echo -e "\033[31m User is not pick his own test case !use the table default.... \033[0m"
    echo ">--------------------------------------------------------------------------------<"
fi

if [ ! -d ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/sas ];then
	mkdir -p ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/sas
fi

if [ ! -f ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/sas/cfg ];then
	touch ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/sas/cfg
fi

if [ x"${T_CTRL_NIC}" = x"" ];then
	echo "User not input the cfg of NIC,use user pre-define value!"
	T_CTRL_NIC=`cat ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/sas/cfg | grep "T_CTRL_NIC" | awk -F':' '{print $NF}'`
fi

g_ctrlNIC=$T_CTRL_NIC
g_client_ip=${T_CIP}

##################################################################################
#Update the cfg
###################################################################################
echo "SAS cfg save by ${T_TESTER}" > ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/sas/cfg


if [ x"${T_CTRL_NIC}" != x"" ];then
    echo "T_CTRL_NIC:${T_CTRL_NIC}" >> ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/sas/cfg
fi

COM="true"
DEBUG="true"

if [ x"$T_PRE" != x"" ];then
	rm /home/plinth/ENV_OK
fi

trap - INT

source ${TESTER_SAS_TOP_DIR}/sas_main.sh

#COM="true"

# clean exit so lava-test can trust the results
exit 0

