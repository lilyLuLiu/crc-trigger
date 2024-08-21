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

# modify pipeline run file
sed -i'' -e "s#<B_VERSION>#$1#g" tmp/rhel1-x86.yaml
sed -i'' -e "s#<B_VERSION>#$1#g" tmp/mac2-amd64.yaml
sed -i'' -e "s#<B_VERSION>#$1#g" tmp/mac4-arm64.yaml
sed -i'' -e "s#<B_VERSION>#$1#g" tmp/windows-x86.yaml

# confirm login the correct openshift workspace
oc project | grep "devtoolsqe--pipeline"
# create pipeline with yaml file
oc create -f tmp/rhel1-x86.yaml
oc create -f tmp/windows-x86.yaml
oc create -f tmp/mac2-amd64.yaml
sleep 10*60*60 #two mac pipeline can't run together as they use same machine to build
oc create -f tmp/mac4-arm64.yaml