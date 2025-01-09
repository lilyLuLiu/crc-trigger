set -x
set -e

if [ $# != 1 ] ; then
echo "USAGE: $0 The Bundle Version"
echo " e.g.: ./trigger-bundle-test 4.16.0"
exit 1;
fi

if [ -d "tmp" ];then
 rm -r tmp
fi
cp -r bundle-test tmp

today=`date +"%Y%m%d"`

# modify pipeline run file
sed -i'' -e "s#<B_VERSION>#$1#g"  tmp/ocp/rhel1-x86.yaml
sed -i'' -e "s#<B_VERSION>#$1#g"  tmp/ocp/rhel-arm64.yaml
sed -i'' -e "s#<B_VERSION>#$1#g"  tmp/ocp/mac2-amd64.yaml
sed -i'' -e "s#<B_VERSION>#$1#g"  tmp/ocp/mac4-arm64.yaml
sed -i'' -e "s#<B_VERSION>#$1#g"  tmp/ocp/windows-x86.yaml

sed -i'' -e "s#<BUNDLE_VERSION>#$1#g" tmp/microshift/rhel.yaml
sed -i'' -e "s#<BUNDLE_VERSION>#$1#g" tmp/microshift/rhel-arm64.yaml
sed -i'' -e "s#<BUNDLE_VERSION>#$1#g" tmp/microshift/mac-x86.yaml
sed -i'' -e "s#<BUNDLE_VERSION>#$1#g" tmp/microshift/mac-arm64.yaml
sed -i'' -e "s#<BUNDLE_VERSION>#$1#g" tmp/microshift/windows.yaml

# confirm login the correct openshift workspace
oc project | grep "devtoolsqe--pipeline"
# create pipeline with yaml file
#oc create -f tmp/ocp/rhel1-x86.yaml
#oc create -f tmp/ocp/windows-x86.yaml
#oc create -f tmp/ocp/mac2-amd64.yaml
#sleep 10*60*60 #two mac pipeline can't run together as they use same machine to build
#oc create -f tmp/ocp/mac4-arm64.yaml

#oc create -f tmp/microshift/rhel.yaml
#oc create -f tmp/microshift/mac-x86.yaml
#oc create -f tmp/microshift/mac-arm64.yaml
#oc create -f tmp/microshift/windows.yaml