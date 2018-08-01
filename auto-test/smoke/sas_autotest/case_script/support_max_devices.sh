#!/bin/bash



# Supports full disk read and write simultaneously
# IN :N/A
# OUT:N/A
function support_max_devices()
{
    Test_Case_Title="support_max_devices"

    num=${#ALL_DISK_PART_NAME[@]}
    if [ ${num} -ne ${MAX_DEV_NUM} ]
    then
        MESSAGE="FAIL\texpander not fully loaded." && echo ${MESSAGE} && return 1
    fi

    count=0
    for disk_name in "${ALL_DISK_PART_NAME[@]}"
    do
        mkdir /mnt/${count}
        echo "y" | mkfs.ext4 ${disk_name} 1>/dev/null
        mount -t ext4 ${disk_name} /mnt/${count} 1>/dev/null

        info=`mount | grep -w "^${disk_name}"`
        if [ "${info}" = "" ]
        then
            MESSAGE="FAIL\tMount "${disk_name}" disk failure." && echo ${MESSAGE} && return 1
        fi

        time dd if=${disk_name} of=/mnt/${count}/test.img bs=1M count=1000 conv=fsync &
        let count+=1
    done

    wait
    for((dir=0;dir<${count};++dir))
    do
        umount /mnt/${dir}
        rm -rf /mnt/${dir}
    done
    MESSAGE="PASS"
    echo ${MESSAGE}
}

function main()
{
    #Judge the current environment, directly connected environment or expander environment.
    judgment_network_env
    if [ $? -ne 0 ]
    then
        MESSAGE="BLOCK\tthe current environment direct connection network, do not execute test cases."
        echo "the current environment direct connection network, do not execute test cases."
        return 0
    fi

    # call the implementation of the automation use cases
    test_case_function_run
}

main
