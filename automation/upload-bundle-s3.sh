#!/bin/bash

if [ $# == 0 ] ; then
echo "USAGE: \$1 The bundle Version"
exit 1;
fi

function verify_bundle_exist() {
    check_address=${1}sha256sum.txt
    echo "verify existing of $check_address"
    valid_code=$(curl -s -o /dev/null -w "%{http_code}" $check_address)
    echo $valid_code
    if [ $valid_code != 200 ]; then
        echo "The url of $check_address not accessible, please check again"
        exit 1
    fi
}


if [ -d "test" ];then
 rm -r test
fi
mkdir test

bundle_version=$1
presets=(openshift microshift)

for i in ${presets[@]}; do
    echo "creating yaml file for $i $bundle_version upload "
    file="test/upload-bundle-$i.yaml" 
    cp -r template/upload-bundle-template.yaml $file

    bundleUrl="https://cdk-builds.usersys.redhat.com/builds/crc/bundles/$i/${bundle_version}/"
    echo $bundleUrl
    verify_bundle_exist $bundleUrl
    sed -i'' -e "s#<Bundle_url>#$bundleUrl#g"  $file
    sed -i'' -e "s#<Preset>#$i#g"  $file
    sed -i'' -e "s#<Bundle_version>#${bundle_version}#g"  $file
done

rm test/*.yaml-e
oc project | grep "devtoolsqe--pipeline"
#oc create -f test