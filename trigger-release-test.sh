set -x
set -e

if [ $# != 2 ] ; then
echo "USAGE: $0 The CRC Version"
echo "USAGE: $1 The Bundle Version"
echo " e.g.: ./trigger-release-test 2.40.0 4.16.0"
exit 1;
fi

echo $1
level1_v=${1:0:4}
echo $level1_v
level2_v=${1:0:1}
echo $level2_v

# check qe images
# podman search didn't list all the tags

if [ -d "tmp" ];then
 rm -r tmp
fi
cp -r release-test tmp

# modify pipeline run file
sed -i'' -e "s#<VERSION>#$1#g" tmp/fedora.yaml
sed -i'' -e "s#<VERSION_1>#$level1_v#g" tmp/fedora.yaml
sed -i'' -e "s#<VERSION_2>#$level2_v#g" tmp/fedora.yaml

sed -i'' -e "s#<VERSION>#$1#g" tmp/macos.yaml
sed -i'' -e "s#<VERSION_1>#$level1_v#g" tmp/macos.yaml
sed -i'' -e "s#<VERSION_2>#$level2_v#g" tmp/macos.yaml

sed -i'' -e "s#<VERSION>#$1#g" tmp/rhel.yaml
sed -i'' -e "s#<VERSION_1>#$level1_v#g" tmp/rhel.yaml
sed -i'' -e "s#<VERSION_2>#$level2_v#g" tmp/rhel.yaml

sed -i'' -e "s#<VERSION>#$1#g" tmp/windows.yaml
sed -i'' -e "s#<VERSION_1>#$level1_v#g" tmp/windows.yaml
sed -i'' -e "s#<VERSION_2>#$level2_v#g" tmp/windows.yaml

# update config map
sed -i'' -e "s#<VERSION>#$1#g" tmp/config-crc-release.yaml
sed -i'' -e "s#<BUNDLE_VERSION>#$2#g" tmp/config-crc-release.yaml
oc project | grep "devtoolsqe--pipeline"
#oc apply -f tmp/config-crc-release.yaml

# create pipeline with yaml file
#oc create -f tmp/fedora.yaml
#oc create -f tmp/macos.yaml
#oc create -f tmp/rhel.yaml
#oc create -f tmp/windows.yaml