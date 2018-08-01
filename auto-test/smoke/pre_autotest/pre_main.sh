#!/bin/bash

# Description: this shell mean to do some options which common and only run once
#              in running plinth-test-suite.
#              if this shell finished success,it will generate ENV_OK in /home/plinth.
#              ENV_OK will not be removed by this shell.if you want to rerun this shell
#              need to rm ENV_OK.
#
# Function:    1.get the commit id of kernel now testing
#              2.run apt-get update when nessary
#              3.close sata phy when nessary
#              4.install expect cmd
#	       5.record dmesg of eth renamed
#              6.new result.txt for save fail testcase message
#
#
# Generater:  luojiaxing 00437090
#
# Maintainer: luojiaxing,chenjing


if [ -f /home/plinth/ENV_OK ];then
	exit 0
fi

if [ x"${Y_ZONE}" == x"" ]
then
    Y_ZONE="false"
fi

SAS_TOP_DIR=$(cd "`dirname $0`" ; pwd)
:> /home/dmesg.log
dmesg > /home/dmesg.log

# Load the public configuration library
if [ x"$COM" = x"" ];then
	. ${SAS_TOP_DIR}/../config/common_config
	. ${SAS_TOP_DIR}/../config/common_lib
fi

if [ x"$1" != x"" ];then
	g_client_ip=$1
fi

#--------------------------------------------------#
# Description: get the commit id of kernel now testing
#
# Coder: luojiaxing 20180520

#check the image commit id
commit_id=`cat /proc/version | awk -F' ' '{print $3}'`

echo "kernel commit ID is $commit_id"

#--------------------------------------------------#


#--------------------------------------------------#
# Description: these code mean to do apt-get update. I don't like apt because it depend on network
#              connect.huawei don't have convenient network for using apt.so i use jump_apt_get to
#              control it's using.if you wang to use apt to install cmd.set jump_apt_get as TRUE
#              I also kill apt thread before apt-get update because in influence it's running
#
# Coder: luojiaxing 20180603
if [ x"$jump_apt_get" = x"FALSE" ];then
	aptlist=`ps -e | grep apt | awk -F' ' '{print $1}'`
	for a in ${aptlist[@]}
	do
		echo $a
		kill $a
	done

	apt-get update
	[ $? -ne 0 ]  && echo "apt-get is fail, try rm /var/lib/dpkg/lock, dpkg --configure -a  To fix it"
fi
#---------------------------------------------------#

#---------------------------------------------------#
# Description: these code mean to close some phy of sata,because sata is not good in running kernel of 4.16
#
# Coder: luojiaxing 201806013

echo 0 > /sys/class/sas_phy/phy-1\:0\:5/enable
#---------------------------------------------------#

#---------------------------------------------------#
# Description: these function check the expect cmd is exist or not.if not, it will install it.
#              if you have set jump_apt_get as false.it will install expect using apt-get.other
#              it will install it using deb packet.
#	       if function return 1, it mean expect install fail! this shell will exit!
#
# Coder: luojiaxing 20180624

Check_expect_exist
if [ $? -eq 1 ];then
	echo "expect cmd install fail!"
	exit 1
fi
#---------------------------------------------------#



#---------------------------------------------------#
# Description: this action means to scan the dmesg as early as possible.
#   	       the eth renamed message may be clean as board is running test,so we save
# 	       dmesg message into file and save it to /home/plinth-test-workspace/xge/cfg dir.
#              check if client can be ping ,if connect is no OK, exit this shell.
#
# Attention: this action need to use expect cmd.so I put it after Check_expect_exist
#            Also,it need client ip to support ssh cmd,so it can be run when cip have set value.
#
# Coder: luojiaxing 20180719


if [ x"${g_client_ip}" != x"" ]
then
	setTrustRelationWithPara ${g_client_ip}

	ping $g_client_ip -c 3 | grep " 0% packet loss"
	if [ $? -ne 0 ];then
		echo "The connect between server and client is bad!"
		exit 1
	fi

	KeepNicMsg ${g_client_ip} $PLINTH_TEST_WORKSPACE/xge/cfg $G_BOARD_TYPE
fi

#---------------------------------------------------#

#---------------------------------------------------#
# Description: these code new a file: result.txt to save fail testcase and it's message for CI
#              to pick up some informance of fail testcase.but it's only a temporarily option
#              for plinth-test-suite now can generate report including these fail message, but
#              I don't have time to recode the CI code so keep it for a while.
#
# Coder: luojiaxing 20180623

        mkdir -p /home/plinth

	if [ -f /home/plinth/result.txt ];then
		rm /home/plinth/result.txt

        touch /home/plinth/result.txt
    fi
#-----------------------------------------------------#

#---------------------------------------------------#
# Description: End of shell.if it have not exist before here,it mean the shell is running normally.and
#              the ENV_OK is going to be set.
#
# Coder: luojiaxing 20180623
mkdir -p /home/plinth
touch /home/plinth/ENV_OK

#use this to tell lava that pre_main job have success!
lava_report "Prepare_test" "pass" ${commit_id}

#when main shell call this shell first without include common_cfg,COM will tell main that is no need to include common_cfg again
#also,when main include common_cfg before this shell ,this shell will not include common_cfg again.
COM="true"

# clean exit so lava-test can trust the results

