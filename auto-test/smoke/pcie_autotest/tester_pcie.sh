#!/bin/bash

TESTER_PCIE_TOP_DIR=$(cd "`dirname $0`" ; pwd)

# Load common function
#. ${TESTER_PCIE_TOP_DIR}/config/pcie_test_config
#. ${TESTER_PCIE_TOP_DIR}/config/pcie_test_lib

# Load the public configuration library
#. ${TESTER_PCIE_TOP_DIR}/../config/common_config

T_SERVER_IP=''
T_CLIENT_IP=''
T_CTRL_NIC=''
T_PICK_CASEC=''

checklist()
{
  list=""
#  file=`cat ${TESTER_PCIE_TOP_DIR}/data/pcie_test_case.table`
  # | while read line
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
  done < ${TESTER_PCIE_TOP_DIR}/data/pcie_test_case.table
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
  done < ${TESTER_PCIE_TOP_DIR}/data/pcie_test_case.table
  sed -i 's/ /|/g'  table
  mv table ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/

  }

###################################################################################
#Usage
###################################################################################

Usage()
{
cat <<EOF
Usage: ./pcie_autotest/tester_pcie.sh [options]
Options:
	-h, --help: Display this information
	-s, --sip: Server IP: this ip used to ssh with client
	-c, --cip: Client IP: this ip is client ip connect with server
	-n, --ctrlNIC: the network card used to control client
	-t, --test: the tester name .if other cfg is not set,
		    tester name can help to get latest cfg you used
		    this para is forced to be set.
    -p, --pickcase: true :pick the case using UI
                    flase: do nothing
Example:
	bash tester_pcie.sh -t luojiaxing  -s "192.168.3.152" -c "192.168.3.153" -n "eth3"

	bash tester_pcie.sh -t luojiaxing # if no other para,scripts will use the latest user cfg

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
echo -e "Tester: \033[34m liudongdong\033[0m \033[35m  weiyinsheng\033[0m "
echo ">---------------------------------------------------------< "
echo "  "

#checklist

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
		-s | --sip) T_SERVER_IP=$ac_optarg ;;
        -p | --pickcase) T_PICK_CASE=$ac_optarg ;;
		-c | --cip) T_CLIENT_IP=$ac_optarg ;;
        	-n | --ctrlNIC) T_CTRL_NIC=$ac_optarg ;;
		-t | --tester) T_TESTER=$ac_optarg ;;
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

. ${TESTER_PCIE_TOP_DIR}/../config/common_config
. ${TESTER_PCIE_TOP_DIR}/../config/common_lib
##################################################################################
#Get latest cfg pass to empty patameter
###################################################################################
if [ x"$T_PICK_CASE" = x"true" ];then
    checklist
fi

if [ -f ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/table ];then
    cp ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/table ${TESTER_PCIE_TOP_DIR}/data/pcie_test_case.table
else
    echo ">--------------------------------------------------------------------------------<"
    echo -e "\033[31m User is not pick his own test case !use the table default.... \033[0m"
    echo ">--------------------------------------------------------------------------------<"
fi

if [ ! -d ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie ];then
	mkdir -p ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie
fi

if [ ! -f ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/cfg ];then
	touch ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/cfg
fi

if [ x"${T_SERVER_IP}" = x"" ];then
	echo "User not input the cfg of Server IP,use user pre-define value!"
	T_SERVER_IP=`cat ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/cfg | grep "T_SERVER_IP" | awk -F':' '{print $NF}'`
fi

g_server_ip=$T_SERVER_IP

if [ x"${T_CTRL_NIC}" = x"" ];then
	echo "User not input the cfg of NIC,use user pre-define value!"
	T_CTRL_NIC=`cat ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/cfg | grep "T_CTRL_NIC" | awk -F':' '{print $NF}'`
fi

g_ctrlNIC=$T_CTRL_NIC

if [ x"${T_CLIENT_IP}" = x"" ];then
	echo "User not input the cfg of Client IP,use user pre-define value!"
	T_CLIENT_IP=`cat ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/cfg | grep "T_CLIENT_IP" | awk -F':' '{print $NF}'`
fi

g_client_ip=$T_CLIENT_IP



##################################################################################
#Update the cfg
###################################################################################
echo "PCIE cfg save by ${T_TESTER}" > ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/cfg


if [ x"$T_SERVER_IP" != x"" ];then
    echo "T_SERVER_IP:${T_SERVER_IP}" >> ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/cfg
fi

if [ x"$T_CLIENT_IP" != x"" ];then
    echo "T_CLIENT_IP:${T_CLIENT_IP}" >> ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/cfg
fi

if [ x"${T_CTRL_NIC}" != x"" ];then
    echo "T_CTRL_NIC:${T_CTRL_NIC}" >> ${PLINTH_TEST_WORKSPACE}/user/${T_TESTER}/pcie/cfg
fi

if [ x"${T_SERVER_IP}" = x"" ] || [ x"${T_CTRL_NIC}" = x"" ] || [ x"${T_CLIENT_IP}" = x"" ];then
	echo ">--------------------------------------------------------------------------------<"
    echo -e "\033[31m Lose some cfg .Please input full parameter to recover the latest cfg! \033[0m"
    echo ">--------------------------------------------------------------------------------<"

	exit 1
else

	echo ">--------------------------------------------------------------------------------<"
    echo -e "\033[32m This time Run the test with the cfg as: SIP=${T_SERVER_IP} CIP=${T_CLIENT_IP} NIC=${T_CTRL_NIC} \033[0m"
	echo ">--------------------------------------------------------------------------------<"
fi

COM="true"
PCIE_LOCAL="True"

trap - INT

source ${TESTER_PCIE_TOP_DIR}/pcie_main.sh

#COM="true"

# clean exit so lava-test can trust the results
exit 0

