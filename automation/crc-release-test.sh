#!/bin/bash

if [ $# == 0 ] ; then
echo "USAGE: \$1 The CRC Version"
exit 1;
fi

function verify_file_exist() {
    check_address=$1/$2
    echo "verify existing of $check_address"
    valid_code=$(curl -s -o /dev/null -w "%{http_code}" $check_address)
    echo $valid_code
    if [ $valid_code != 200 ]; then
        echo "The url of $check_address not accessible, please check again"
        exit 1
    fi
}

baremental=(mac-1 mac-2 mac-4 rhel-1 windows-1)
virtual=(fedora-40 fedora-41 rhel-9.4 windows-10)

crc_version=$1
crc_v2=${crc_version:0:4}
crc_v1=${crc_version:0:1}
crcPath="http://download.eng.pek2.redhat.com/etera/crc/${crc_v1}/${crc_v2}/${crc_version}/staging"
shafile="sha256sum.txt"
verify_file_exist $crcPath $shafile

windowsParameter="- name: windows-featurepack\n    value: 22h2-ent\n  - name: windows-version\n    value:"
fedoraParameter="- name: fedora-version\n    value:"
rhelParameter="- name: rhel-version\n    value:"

if [ -d "test" ];then
 rm -r test
fi
mkdir test
for i in ${virtual[@]}; do
    echo "creating yaml file for $i"
    file="test/virtual-$i.yaml"
    cp -r template/virtualized-template.yaml $file
    if [[ $i == windows* ]]; then
        parameter=$windowsParameter
        crcname="crc-windows-installer.zip"
    elif [[ $i == fedora* ]]; then
        parameter=$fedoraParameter
        crcname="crc-linux-amd64.tar.xz"
    elif [[ $i == rhel* ]]; then
        parameter=$rhelParameter
        crcname="crc-linux-amd64.tar.xz"
    else
        echo "the platform $i is not support. Please check again"
        exit 1
    fi
    IFS='-' read -ra platformVersion <<< "$i"
    platV=${platformVersion[1]}
    IFS='.' read -ra platv <<< "$i"
    sed -i'' -e "s#<plafrom-parameter>#${parameter}#g"  $file
    sed -i'' -e "s#<platform-version>#${platV}#g"  $file
    sed -i'' -e "s#<Platform>#$platv#g"  $file
    sed -i'' -e "s#<crcName>#$crcname#g"  $file
    sed -i'' -e "s#<crcPath>#$crcPath#g"  $file
    sed -i'' -e "s#<Shafile>#$shafile#g"  $file
    sed -i'' -e "s#<VERSION>#$crc_version#g"  $file
    sed -i'' -e "s#<e2e>#true#g"  $file
    sed -i'' -e "s#<e2etag>#''#g"  $file
    sed -i'' -e "s#<integration>#true#g"  $file

    verify_file_exist $crcPath $crcname    
done

for i in ${baremental[@]}; do
    echo "creating yaml file for $i"
    file="test/bare-$i.yaml"
    cp -r template/baremetal-tempalte.yaml $file

    tester="host-$i-brno"

    sed -i'' -e "s#<Platform>#$i#g"  $file
    sed -i'' -e "s#<Shafile>#$shafile#g"  $file
    sed -i'' -e "s#<crcPath>#$crcPath#g"  $file
    sed -i'' -e "s#<VERSION>#$crc_version#g"  $file
    sed -i'' -e "s#<tester>#$tester#g"  $file
done

rm test/*.yaml-e
oc project | grep "devtoolsqe--pipeline"
#oc create -f test